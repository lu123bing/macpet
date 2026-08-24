//
//  PetWindowController.swift
//  MacPet
//
//  Created by MacPet on 2026/8/23.
//
//  高性能无边框窗口管理
//  - 桌面级窗口（不抢焦点）
//  - 支持鼠标穿透
//  - 边缘吸附
//  - Spaces 全空间显示
//

import SwiftUI
import AppKit
import Combine

@MainActor
final class PetWindowController: NSObject {
    private var window: NSWindow?
    private var petState: PetState
    private var cancellables = Set<AnyCancellable>()
    
    // 键盘监听
    private var eventMonitor: Any?
    private var localMonitor: Any?
    
    init(petState: PetState) {
        self.petState = petState
        super.init()
        setupWindow()
        setupGlobalKeyboardMonitor()
        setupStateObservers()
    }
    
    private func setupWindow() {
        // 获取主屏幕尺寸
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.visibleFrame
        
        // 创建无边框窗口
        let window = NSWindow(
            contentRect: NSRect(
                x: petState.position.x - 150,
                y: petState.position.y - 100,
                width: 300,
                height: 400
            ),
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false,
            screen: screen
        )
        
        // 窗口级别：桌面之上、普通窗口之下
        // .floating 太高，.desktop 太低，使用 .normal + canHide = false
        window.level = .floating
        window.collectionBehavior = [
            .canJoinAllSpaces,      // 所有桌面空间都显示
            .transient,             // 不显示在 Cmd+Tab 列表中
            .ignoresCycle,          // 不参与窗口循环
            .stationary,            // 不随 Spaces 切换移动
            .fullScreenAuxiliary    // 全屏时也显示在旁
        ]
        
        window.backgroundColor = .clear
        window.isOpaque = false
        window.hasShadow = false
        window.ignoresMouseEvents = petState.isMouseThrough
        window.canHide = false
        window.isReleasedWhenClosed = false
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.animationBehavior = .none
        
        // 设置内容视图
        let petView = PetView(petState: petState)
            .background(WindowAccessor { [weak self] window in
                self?.window = window
            })
        window.contentView = NSHostingView(rootView: petView)
        
        // 窗口初始位置
        let origin = NSPoint(
            x: screenRect.midX - 150,
            y: screenRect.minY + 50
        )
        window.setFrameOrigin(origin)
        petState.position = CGPoint(x: screenRect.midX, y: screenRect.minY + 200)
        
        window.orderFrontRegardless()
        
        self.window = window
    }
    
    private func setupStateObservers() {
        // 监听鼠标穿透状态
        petState.$isMouseThrough
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mouseThrough in
                self?.window?.ignoresMouseEvents = mouseThrough
            }
            .store(in: &cancellables)
        
        // 监听隐藏状态
        petState.$isHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hidden in
                if hidden {
                    self?.window?.orderOut(nil)
                } else {
                    self?.window?.orderFrontRegardless()
                }
            }
            .store(in: &cancellables)
        
        // 监听位置变化，同步更新窗口
        petState.$position
            .receive(on: DispatchQueue.main)
            .sink { [weak self] position in
                guard let self = self, let window = self.window else { return }
                let size = window.frame.size
                let newOrigin = NSPoint(
                    x: position.x - size.width / 2,
                    y: position.y - size.height / 2
                )
                window.setFrameOrigin(newOrigin)
            }
            .store(in: &cancellables)
    }
    
    private func setupGlobalKeyboardMonitor() {
        // Command 键按下时透明穿透
        // 使用 Fn (Globe) 键作为触发键，不与常见快捷键冲突
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.flagsChanged, .keyDown, .keyUp]) { [weak self] event in
            guard let self = self else { return event }
            
            if event.type == .flagsChanged {
                // Fn/Globe 键 = 0x800000 (deviceIndependentFlagsMask 中的 deviceIndependentFlags)
                let fnKeyPressed = event.modifierFlags.contains(.function) &&
                    !event.modifierFlags.contains(.command) &&
                    !event.modifierFlags.contains(.option) &&
                    !event.modifierFlags.contains(.control)
                self.petState.setTransparentMode(fnKeyPressed)
            }
            
            // 隐藏快捷键: Cmd+Ctrl+H
            if event.type == .keyDown {
                let command = event.modifierFlags.contains(.command)
                let control = event.modifierFlags.contains(.control)
                let hKey = event.keyCode == 0x04 // H key
                
                if command && control && hKey {
                    if self.petState.isHidden {
                        self.petState.show()
                    } else {
                        self.petState.hide()
                    }
                    return nil
                }
            }
            
            return event
        }
        
        // 全局监听
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.flagsChanged]) { [weak self] event in
            Task { @MainActor in
                let fnKeyPressed = event.modifierFlags.contains(.function) &&
                    !event.modifierFlags.contains(.command) &&
                    !event.modifierFlags.contains(.option) &&
                    !event.modifierFlags.contains(.control)
                self?.petState.setTransparentMode(fnKeyPressed)
            }
        }
    }
    
    func show() {
        window?.orderFrontRegardless()
    }
    
    func hide() {
        window?.orderOut(nil)
    }
    
    func cleanup() {
        if let monitor = localMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        window?.close()
        window = nil
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - Window Accessor
struct WindowAccessor: NSViewRepresentable {
    var callback: (NSWindow?) -> Void
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { [weak view] in
            self.callback(view?.window)
        }
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { [weak nsView] in
            self.callback(nsView?.window)
        }
    }
}
