//
//  AnimationPlayerView.swift
//  MacPet
//
//  Created by MacPet on 2026/8/23.
//
//  高性能透明动画播放器
//  - 使用双缓冲 AVPlayer 实现无缝循环
//  - 支持 VP9 Alpha 透明 WebM
//  - 内置 SpriteKit 渲染路径优化性能
//

import SwiftUI
import AVFoundation
import Combine

#if canImport(AppKit)
import AppKit
#endif

// MARK: - 动画播放器
@MainActor
struct AnimationPlayerView: NSViewRepresentable {
    let animationType: AnimationType
    let shouldLoop: Bool
    @Binding var isFlipped: Bool
    @Binding var dragOffset: CGFloat
    
    func makeNSView(context: Context) -> AnimationPlayerNSView {
        let view = AnimationPlayerNSView()
        view.setupPlayer()
        return view
    }
    
    func updateNSView(_ nsView: AnimationPlayerNSView, context: Context) {
        nsView.isFlipped = isFlipped
        nsView.jellyOffset = dragOffset
        nsView.loadAnimation(type: animationType, loop: shouldLoop)
    }
    
    static func dismantleNSView(_ nsView: AnimationPlayerNSView, coordinator: ()) {
        nsView.cleanup()
    }
}

// MARK: - NSView 实现
@MainActor
class AnimationPlayerNSView: NSView {
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var videoOutput: AVPlayerItemVideoOutput?
    private var displayLink: CVDisplayLink?
    private var currentItem: AVPlayerItem?
    private var loopObserver: NSObjectProtocol?
    private var animationCache: [String: AVPlayerItem] = [:]
    
    var isFlipped: Bool = false {
        didSet { updateTransform() }
    }
    var jellyOffset: CGFloat = 0 {
        didSet { updateJellyTransform() }
    }
    
    private var baseTransform: CGAffineTransform = .identity
    private let jellyLayer = CAShapeLayer()
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        setupJellyLayer()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupJellyLayer() {
        jellyLayer.fillColor = NSColor.clear.cgColor
        layer?.addSublayer(jellyLayer)
    }
    
    func setupPlayer() {
        // 使用专门为透明视频优化的播放器
        let player = AVPlayer()
        player.actionAtItemEnd = .none
        player.isMuted = true
        
        let playerLayer = AVPlayerLayer()
        playerLayer.player = player
        playerLayer.videoGravity = .resizeAspect
        playerLayer.backgroundColor = NSColor.clear.cgColor
        playerLayer.masksToBounds = false
        
        // 像素缓冲优化
        let bufferAttributes: [String: Any] = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferOpenGLCompatibilityKey as String: true
        ]
        videoOutput = AVPlayerItemVideoOutput(pixelBufferAttributes: bufferAttributes)
        videoOutput?.setDelegate(nil, queue: .main)
        videoOutput?.suppressesPlayerRendering = false
        
        self.player = player
        self.playerLayer = playerLayer
        
        layer?.addSublayer(playerLayer)
        
        // 监听循环
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerItemDidReachEnd),
            name: .AVPlayerItemDidPlayToEndTime,
            object: nil
        )
    }
    
    func loadAnimation(type: AnimationType, loop: Bool) {
        // 先移除旧占位符
        subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
        
        guard let url = findAnimationURL(for: type) else {
            // 资源不存在时显示占位表情
            showPlaceholder(for: type)
            return
        }
        
        // 有视频资源，显示播放器层
        playerLayer?.isHidden = false
        
        // 缓存检查
        let cacheKey = type.rawValue
        if let cachedItem = animationCache[cacheKey] {
            currentItem?.remove(videoOutput)
            currentItem = cachedItem
            if let output = videoOutput {
                cachedItem.add(output)
            }
            player?.replaceCurrentItem(with: cachedItem)
        } else {
            let asset = AVURLAsset(url: url)
            let item = AVPlayerItem(asset: asset)
            if let output = videoOutput {
                item.add(output)
            }
            animationCache[cacheKey] = item
            currentItem = item
            player?.replaceCurrentItem(with: item)
        }
        
        // 设置循环/非循环
        player?.actionAtItemEnd = loop ? .none : .pause
        
        player?.seek(to: .zero)
        player?.play()
        
        // 性能优化：预加载下一个动画
        preloadNextAnimations()
    }
    
    private func findAnimationURL(for type: AnimationType) -> URL? {
        let fileManager = FileManager.default
        
        // 搜索路径优先级：
        // 1. Bundle Resources（打包后）
        // 2. 源码目录 Resources/Animations（开发运行时）
        let searchPaths: [URL] = [
            Bundle.main.resourceURL?.appendingPathComponent("Animations"),
            Bundle.main.resourceURL?.appendingPathComponent("Resources/Animations"),
            URL(fileURLWithPath: "./Sources/MacPet/Resources/Animations", isDirectory: true),
            URL(fileURLWithPath: "../Sources/MacPet/Resources/Animations", isDirectory: true),
            URL(fileURLWithPath: "MacPet/Sources/MacPet/Resources/Animations", isDirectory: true),
        ].compactMap { $0 }
        
        let filename = type.rawValue + ".webm"
        
        for basePath in searchPaths {
            let url = basePath.appendingPathComponent(filename)
            if fileManager.fileExists(atPath: url.path) {
                return url
            }
        }
        
        return nil
    }
    
    private func showPlaceholder(for type: AnimationType) {
        // 无动画资源时显示表情占位符
        player?.pause()
        playerLayer?.isHidden = true
        
        // 移除旧占位符
        subviews.filter { $0.tag == 999 }.forEach { $0.removeFromSuperview() }
        
        let emojiMap: [AnimationCategory: String] = [
            .idle: "😌",
            .turn: "👀",
            .move: "🚶",
            .action: "✨",
            .interact: "😊",
            .work: "📝",
            .eat: "😋",
            .emotion: "💫",
            .play: "🎮",
            .festival: "🎉",
            .drag: "🫳",
            .stretch: "🙆",
            .special: "🌟"
        ]
        
        let emoji = emojiMap[type.category] ?? "🐾"
        let label = NSTextField(labelWithString: emoji)
        label.tag = 999
        label.font = NSFont.systemFont(ofSize: 80)
        label.alignment = .center
        label.frame = bounds
        label.autoresizingMask = [.width, .height]
        addSubview(label)
    }
    
    private func preloadNextAnimations() {
        // 预加载常用动画到内存
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let commonAnimations: [AnimationType] = [
                .daijihuxi, .dongzhangxiwang, .hengge,
                .xiedaima, .dengdai, .shenlanya,
                .chibaihuafan, .piaofutabu
            ]
            for type in commonAnimations {
                if self?.animationCache[type.rawValue] == nil,
                   let url = self?.findAnimationURL(for: type) {
                    let asset = AVURLAsset(url: url)
                    let item = AVPlayerItem(asset: asset)
                    Task { @MainActor in
                        self?.animationCache[type.rawValue] = item
                    }
                }
            }
        }
    }
    
    @objc private func playerItemDidReachEnd(notification: Notification) {
        guard let item = notification.object as? AVPlayerItem,
              item == currentItem else { return }
        player?.seek(to: .zero)
        player?.play()
    }
    
    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
        jellyLayer.frame = bounds
        updateTransform()
        updateJellyTransform()
    }
    
    private func updateTransform() {
        let scaleX: CGFloat = isFlipped ? -1 : 1
        baseTransform = CGAffineTransform(scaleX: scaleX, y: 1)
        playerLayer?.setAffineTransform(baseTransform)
    }
    
    private func updateJellyTransform() {
        // 果冻摇摆效果
        let _ = jellyOffset * 0.08 // shear
        let scaleX = 1.0 - abs(jellyOffset) * 0.002
        let scaleY = 1.0 + abs(jellyOffset) * 0.003
        
        var jellyTransform = baseTransform
        jellyTransform = jellyTransform.translatedBy(x: jellyOffset, y: 0)
        jellyTransform = jellyTransform.scaledBy(x: scaleX, y: scaleY)
        
        playerLayer?.setAffineTransform(jellyTransform)
    }
    
    func cleanup() {
        player?.pause()
        player = nil
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        NotificationCenter.default.removeObserver(self)
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        animationCache.removeAll()
    }
    
    deinit {
        cleanup()
    }
}

// MARK: - 占位动画视图（开发调试用）
struct PlaceholderPetView: View {
    let animationType: AnimationType
    @State private var breathScale: CGFloat = 1.0
    @State private var isBlinking = false
    
    var body: some View {
        ZStack {
            // 简单的宠物占位形状
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.7), .purple.opacity(0.5)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 120, height: 120)
                .scaleEffect(breathScale)
                .shadow(radius: 10)
            
            // 眼睛
            HStack(spacing: 20) {
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: isBlinking ? 2 : 20)
                Circle()
                    .fill(.white)
                    .frame(width: 20, height: isBlinking ? 2 : 20)
            }
            .offset(y: -10)
            
            // 嘴巴
            if animationType == .dianjikaixin || animationType.category == .emotion {
                Path { path in
                    path.move(to: CGPoint(x: -15, y: 15))
                    path.addQuadCurve(to: CGPoint(x: 15, y: 15), control: CGPoint(x: 0, y: 35))
                }
                .stroke(.white, lineWidth: 3)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever()) {
                breathScale = 1.05
            }
            
            // 眨眼动画
            Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.1)) {
                    isBlinking = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isBlinking = false
                    }
                }
            }
        }
    }
}
