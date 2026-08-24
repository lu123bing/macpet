//
//  PetView.swift
//  MacPet
//
//  Created by MacPet on 2026/8/23.
//

import SwiftUI
import AppKit

// MARK: - 宠物主视图
struct PetView: View {
    @ObservedObject var petState: PetState
    @State private var showingPetMenu = false
    @State private var showingFeedMenu = false
    @State private var dragStart: CGPoint = .zero
    @State private var lastDragDelta: CGFloat = 0
    
    // 基础尺寸
    private let baseSize: CGFloat = 200
    
    private var currentSize: CGFloat {
        baseSize * petState.size.rawValue * (petState.isFocusMode ? 0.8 : 1.0)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // 气泡（护眼提醒）
            if petState.showEyeCareBubble {
                EyeCareBubble(
                    onTap: { petState.handleEyeCareBubbleTap() },
                    onDismiss: { petState.dismissEyeCareBubble() }
                )
                .offset(y: -currentSize * 0.7)
                .transition(.scale.combined(with: .opacity))
            }
            
            // 聊天气泡
            if petState.isBubbleVisible, let message = petState.bubbleMessage {
                ChatBubble(text: message.text, isUser: false)
                    .offset(y: -currentSize * 0.75)
                    .transition(.scale(scale: 0.1).combined(with: .opacity))
                    .onTapGesture {
                        petState.hideBubble()
                    }
            }
            
            // 宠物主体
            VStack(spacing: 0) {
                ZStack {
                    // 动画播放器（已内置找不到资源时显示占位表情）
                    AnimationPlayerView(
                        animationType: petState.currentAnimation,
                        shouldLoop: petState.currentAnimation.shouldLoop,
                        isFlipped: $petState.isFacingLeft,
                        dragOffset: $petState.dragJellyOffset
                    )
                    .frame(width: currentSize, height: currentSize * 0.65)
                    .scaleEffect(petState.scale)
                }
                
                // 宠物自身菜单按钮
                if !petState.isFocusMode {
                    PetMenuButton(
                        isActive: showingPetMenu,
                        onAction: { showingPetMenu.toggle() }
                    )
                    .offset(y: -10)
                    .popover(isPresented: $showingPetMenu, arrowEdge: .bottom) {
                        PetContextMenu(petState: petState, isPresented: $showingPetMenu)
                            .padding(.vertical, 4)
                    }
                }
            }
        }
        .frame(width: currentSize * 1.2, height: currentSize * 1.5)
        .opacity(petState.opacity)
        .contentShape(Rectangle())
        .onTapGesture {
            if !showingPetMenu {
                petState.playClickFeedback()
            }
        }
        .gesture(dragGesture)
        .contextMenu {
            PetContextMenu(petState: petState, isPresented: .constant(true))
        }
        .allowsHitTesting(!petState.isMouseThrough)
    }
    
    // MARK: - 拖拽手势
    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 5)
            .onChanged { value in
                let delta = value.translation.width
                lastDragDelta = delta
                
                if !petState.isDragging {
                    petState.startDragging()
                    dragStart = petState.position
                }
                
                petState.position = CGPoint(
                    x: dragStart.x + value.translation.width,
                    y: dragStart.y - value.translation.height
                )
                petState.updateDragJelly(dx: delta)
            }
            .onEnded { _ in
                petState.endDragging()
                lastDragDelta = 0
                
                // 边缘吸附
                if let window = NSApp.keyWindow {
                    petState.snapToEdgeIfNeeded(
                        in: window.frame,
                        petSize: CGSize(width: currentSize, height: currentSize * 0.65)
                    )
                }
            }
    }
}

// MARK: - 宠物菜单按钮
struct PetMenuButton: View {
    let isActive: Bool
    let onAction: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onAction) {
            Image(systemName: "ellipsis.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isActive ? .accentColor : .gray.opacity(isHovered ? 0.8 : 0.5))
                .background(
                    Circle()
                        .fill(.white.opacity(isHovered ? 0.3 : 0.1))
                        .frame(width: 28, height: 28)
                )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
                if hovering { NSCursor.pointingHand.push() } else { NSCursor.pop() }
            }
        }
    }
}

// MARK: - 气泡组件
struct ChatBubble: View {
    let text: String
    let isUser: Bool
    @State private var opacity: Double = 1
    
    var body: some View {
        VStack(spacing: 2) {
            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.black)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                )
            
            // 气泡尖角
            Path { path in
                path.move(to: CGPoint(x: -8, y: 0))
                path.addLine(to: CGPoint(x: 8, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 10))
                path.closeSubpath()
            }
            .fill(.white)
            .frame(width: 16, height: 10)
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - 护眼提醒气泡
struct EyeCareBubble: View {
    let onTap: () -> Void
    let onDismiss: () -> Void
    
    @State private var pulse = false
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "cup.and.saucer.fill")
                .foregroundColor(.blue)
            Text("起来喝杯水吧~")
                .font(.system(size: 12, weight: .medium))
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray.opacity(0.5))
                .onTapGesture(perform: onDismiss)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: .black.opacity(0.15), radius: 8, y: 3)
        )
        .overlay(
            Capsule()
                .stroke(Color.blue.opacity(0.3), lineWidth: pulse ? 2 : 1)
                .scaleEffect(pulse ? 1.05 : 1)
                .opacity(pulse ? 0.5 : 1)
                .animation(.easeInOut(duration: 1).repeatForever(), value: pulse)
        )
        .onAppear { pulse = true }
        .onTapGesture(perform: onTap)
        .cursor(.pointingHand)
    }
}

// MARK: - 宠物右键菜单
struct PetContextMenu: View {
    @ObservedObject var petState: PetState
    @Binding var isPresented: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            // 大小控制
            Menu("大小 \(petState.size.displayName)") {
                ForEach(PetSize.allCases) { size in
                    Button {
                        petState.size = size
                    } label: {
                        Label(size.displayName, systemImage: petState.size == size ? "checkmark" : "")
                    }
                }
            }
            
            Divider()
            
            // 动画控制
            Button("下一个动画") {
                petState.playNextRandomAnimation()
                isPresented = false
            }
            .keyboardShortcut("n", modifiers: .command)
            
            Divider()
            
            // 投喂
            Menu("投喂 🍽️") {
                ForEach(FoodType.allCases) { food in
                    Button(food.icon + " " + food.rawValue) {
                        if !petState.isWaitingForFood {
                            petState.startWaitingForFood()
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            petState.feed(food: food)
                        }
                        isPresented = false
                    }
                }
            }
            
            // 丢爱心
            Button("丢一个爱心 ❤️") {
                petState.startWaitingForFood()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    petState.feed(food: .heart)
                }
                isPresented = false
            }
            
            Divider()
            
            // 专注模式
            Button(petState.isFocusMode ? "退出专注模式" : "进入专注模式") {
                petState.toggleFocusMode()
                isPresented = false
            }
            
            Divider()
            
            // 显示状态
            Button("查看状态") {
                petState.showStatusBubble()
                isPresented = false
            }
            
            Divider()
            
            // 隐藏
            Button("隐藏桌宠") {
                petState.hide()
                isPresented = false
            }
            .keyboardShortcut("h", modifiers: [.command, .control])
            
            // 退出
            Button("退出") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .padding(8)
        .frame(width: 180)
    }
}

// MARK: - View 扩展
extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
