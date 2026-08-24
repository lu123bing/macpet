//
//  PetState.swift
//  MacPet
//
//  Created by MacPet on 2026/8/23.
//

import Foundation
import SwiftUI
import Combine

/// 宠物状态枚举
enum PetMood: String, CaseIterable {
    case happy = "开心"
    case normal = "普通"
    case hungry = "饥饿"
    case sleepy = "困倦"
    case excited = "兴奋"
    case angry = "生气"
    case shy = "害羞"
    
    var emoji: String {
        switch self {
        case .happy: return "😊"
        case .normal: return "🙂"
        case .hungry: return "😋"
        case .sleepy: return "😴"
        case .excited: return "🤩"
        case .angry: return "😠"
        case .shy: return "😳"
        }
    }
}

/// 食物类型
enum FoodType: String, CaseIterable, Identifiable {
    case rice = "白饭"
    case snack = "零食"
    case tangyuan = "汤圆"
    case jiaozi = "饺子"
    case yuebing = "月饼"
    case water = "水"
    case heart = "爱心"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .rice: return "🍚"
        case .snack: return "🍿"
        case .tangyuan: return "🥮"
        case .jiaozi: return "🥟"
        case .yuebing: return "🥮"
        case .water: return "💧"
        case .heart: return "❤️"
        }
    }
    
    var energyRestore: Double {
        switch self {
        case .rice: return 25
        case .snack: return 15
        case .tangyuan: return 20
        case .jiaozi: return 20
        case .yuebing: return 20
        case .water: return 10
        case .heart: return 30
        }
    }
    
    var eatAnimation: AnimationType {
        switch self {
        case .rice: return .chibaihuafan
        case .snack: return .dakouchilingshi
        case .tangyuan: return .chitangyuan
        case .jiaozi: return .chijiaozi
        case .yuebing: return .chiyuebing
        case .water: return .shuxiya  // 刷牙喝水代替
        case .heart: return .hudiekaihua  // 蝴蝶开花爱心
        }
    }
}

/// 宠物大小选项
enum PetSize: CGFloat, CaseIterable, Identifiable {
    case small = 0.7
    case medium = 1.0
    case large = 1.3
    case huge = 1.6
    
    var id: CGFloat { rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "小"
        case .medium: return "中"
        case .large: return "大"
        case .huge: return "巨大"
        }
    }
}

/// 气泡消息
struct BubbleMessage: Identifiable, Equatable {
    let id = UUID()
    let text: String
    let timestamp: Date
    let autoDismiss: Bool
    
    init(text: String, autoDismiss: Bool = true) {
        self.text = text
        self.timestamp = Date()
        self.autoDismiss = autoDismiss
    }
}

/// 宠物核心状态
@MainActor
final class PetState: ObservableObject {
    // MARK: - 位置与显示
    @Published var position: CGPoint = .zero
    @Published var isHidden: Bool = false
    @Published var opacity: Double = 1.0
    @Published var isMouseThrough: Bool = false
    @Published var size: PetSize = .medium
    @Published var scale: CGFloat = 1.0
    @Published var isFacingLeft: Bool = false
    
    // 边缘吸附相关
    @Published var isDockedToEdge: Bool = false
    var dockedEdge: Edge? = nil
    
    // MARK: - 属性值
    @Published var energy: Double = 100 {
        didSet {
            energy = min(max(energy, 0), 100)
            updateMood()
        }
    }
    @Published var happiness: Double = 80 {
        didSet {
            happiness = min(max(happiness, 0), 100)
            updateMood()
        }
    }
    @Published var mood: PetMood = .normal
    
    // MARK: - 动画状态
    @Published var currentAnimation: AnimationType = .daijihuxi
    @Published var isDragging: Bool = false
    @Published var dragJellyOffset: CGFloat = 0
    @Published var isWaitingForFood: Bool = false
    @Published var waitingFoodStartTime: Date?
    @Published var isPlayingSpecialAnimation: Bool = false
    
    // MARK: - 气泡消息
    @Published var bubbleMessage: BubbleMessage?
    @Published var isBubbleVisible: Bool = false
    
    // MARK: - 专注模式
    @Published var isFocusMode: Bool = false
    @Published var focusModeAutoDetect: Bool = true
    private var lastActiveApp: String = ""
    private let focusAppIdentifiers: Set<String> = [
        "com.microsoft.Word", "com.microsoft.Excel", "com.microsoft.Powerpoint",
        "com.microsoft.edgemac", "com.google.Chrome", "com.apple.Safari",
        "com.tencent.xinWeChat", "com.tencent.WeWorkMac",
        "com.apple.dt.Xcode", "com.microsoft.VSCode",
        "com.figma.Desktop", "com.adobe.Photoshop",
        "com.apple.iWork.Pages", "com.apple.iWork.Numbers", "com.apple.iWork.Keynote",
        "cn.wps.macoffice3.word", "cn.wps.macoffice3.excel", "cn.wps.macoffice3.powerpoint"
    ]
    
    // MARK: - 久坐提醒
    @Published var showEyeCareBubble: Bool = false
    private var workStartTime: Date?
    private let eyeCareInterval: TimeInterval = 45 * 60 // 45分钟
    private var eyeCareTimer: Timer?
    
    // MARK: - 内部状态
    private var animationTimer: Timer?
    private var idleTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        position = defaultPosition()
        setupTimers()
        updateMood()
        scheduleNextIdleAnimation()
    }
    
    // MARK: - 位置管理
    func defaultPosition() -> CGPoint {
        guard let screen = NSScreen.main else { return .zero }
        let frame = screen.visibleFrame
        return CGPoint(x: frame.midX, y: frame.minY + 100)
    }
    
    /// 边缘吸附
    func snapToEdgeIfNeeded(in frame: CGRect, petSize: CGSize) {
        let screenFrame = NSScreen.main?.visibleFrame ?? frame
        let margin: CGFloat = 20
        
        var newPosition = position
        var docked = false
        
        // 检测边缘并吸附（不隐藏，保持可见）
        if newPosition.x - petSize.width / 2 < screenFrame.minX + margin {
            newPosition.x = screenFrame.minX + petSize.width / 2 + margin
            docked = true
            dockedEdge = .leading
        } else if newPosition.x + petSize.width / 2 > screenFrame.maxX - margin {
            newPosition.x = screenFrame.maxX - petSize.width / 2 - margin
            docked = true
            dockedEdge = .trailing
        }
        
        if newPosition.y - petSize.height / 2 < screenFrame.minY + margin {
            newPosition.y = screenFrame.minY + petSize.height / 2 + margin
            docked = true
            dockedEdge = .bottom
        } else if newPosition.y + petSize.height / 2 > screenFrame.maxY - margin {
            newPosition.y = screenFrame.maxY - petSize.height / 2 - margin
            docked = true
            dockedEdge = .top
        }
        
        isDockedToEdge = docked
        position = newPosition
    }
    
    // MARK: - 状态更新
    private func updateMood() {
        if energy < 25 {
            mood = .hungry
        } else if happiness < 30 {
            mood = .angry
        } else if energy < 40 {
            mood = .sleepy
        } else if happiness > 80 {
            mood = .excited
        } else {
            mood = .happy
        }
    }
    
    /// 隐藏宠物（降低精力）
    func hide() {
        isHidden = true
        energy = max(energy - 10, 25) // 最低25
        isMouseThrough = true
        opacity = 0.0
        
        if energy <= 25 {
            // 饿了会自己出来找吃的
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.show()
                self?.showBubble("肚子好饿啊~")
                self?.autoEat()
            }
        }
    }
    
    /// 显示宠物
    func show() {
        isHidden = false
        opacity = 1.0
        isMouseThrough = false
        showBubble("我回来啦~")
    }
    
    /// 切换透明+鼠标穿透模式（Command键按住）
    func setTransparentMode(_ enabled: Bool) {
        guard !isHidden else { return }
        if enabled {
            opacity = 0.3
            isMouseThrough = true
        } else {
            opacity = 1.0
            isMouseThrough = false
        }
    }
    
    // MARK: - 动画调度
    private func setupTimers() {
        // 属性自然衰减
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.naturalDecay()
                }
            }
            .store(in: &cancellables)
        
        // 专注模式检测
        Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { @MainActor in
                    self?.checkFocusMode()
                    self?.checkEyeCare()
                }
            }
            .store(in: &cancellables)
    }
    
    private func naturalDecay() {
        guard !isHidden else { return }
        energy -= 1
        happiness -= 0.5
        
        // 随机说句话
        if Int.random(in: 1...10) == 1 {
            sayRandomMessage()
        }
    }
    
    func scheduleNextIdleAnimation() {
        animationTimer?.invalidate()
        
        let delay: TimeInterval
        if isFocusMode {
            delay = TimeInterval.random(in: 30...60)
        } else {
            delay = TimeInterval.random(in: 10...25)
        }
        
        // 使用 RunLoop.main 调度
        let timer = Timer(timeInterval: delay, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playRandomIdleAnimation()
                self?.scheduleNextIdleAnimation()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        animationTimer = timer
    }
    
    func playRandomIdleAnimation() {
        guard !isDragging, !isWaitingForFood, !isPlayingSpecialAnimation else { return }
        
        let candidates = AnimationType.allCases.filter { animation in
            if isFocusMode {
                return [.idle, .work].contains(animation.category)
            } else {
                return [.idle, .turn, .move, .play, .emotion].contains(animation.category)
            }
        }
        
        // 按权重随机选择
        let weights = candidates.map { isFocusMode ? $0.focusWeight : $0.weight }
        if let selected = weightedRandom(candidates: candidates, weights: weights) {
            playAnimation(selected)
        }
    }
    
    func playAnimation(_ type: AnimationType, force: Bool = false) {
        guard force || (!isDragging && !isPlayingSpecialAnimation) else { return }
        currentAnimation = type
        
        // 非循环动画播放完后回到待机
        if !type.shouldLoop {
            let duration: TimeInterval = type == .shenlanya ? 3 : 2.5
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                guard let self = self, !self.isDragging, !self.isWaitingForFood else { return }
                if self.currentAnimation == type {
                    self.currentAnimation = .daijihuxi
                }
            }
        }
    }
    
    func playSpecialAnimation(_ type: AnimationType, duration: TimeInterval = 2.5) {
        isPlayingSpecialAnimation = true
        playAnimation(type, force: true)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.isPlayingSpecialAnimation = false
            self?.playAnimation(.daijihuxi)
        }
    }
    
    /// 点击反馈动画（Q弹效果）
    func playClickFeedback() {
        withAnimation(.spring(response: 0.2, dampingFraction: 0.4)) {
            scale = 0.85
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                self.scale = 1.0
            }
        }
        
        // 随机点击回应动画（5种回应）
        let responses: [AnimationType] = [
            .dianjikaixin, .dianjishaonu, .dianjiaojiao,
            .dianjiyuanqi, .dianjinaoyang, .beixiayitiao
        ]
        if let response = responses.randomElement(), !isFocusMode || Int.random(in: 1...4) == 1 {
            playSpecialAnimation(response, duration: 3)
        }
        
        // 显示状态气泡
        showStatusBubble()
    }
    
    // MARK: - 拖拽果冻效果
    func startDragging() {
        isDragging = true
        playAnimation(.tuozhuai, force: true)
    }
    
    func updateDragJelly(dx: CGFloat) {
        dragJellyOffset = dx * 0.15
        isFacingLeft = dx < 0
    }
    
    func endDragging() {
        isDragging = false
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            dragJellyOffset = 0
        }
        playAnimation(.daijihuxi)
        scheduleNextIdleAnimation()
    }
    
    // MARK: - 投喂系统
    func startWaitingForFood() {
        isWaitingForFood = true
        waitingFoodStartTime = Date()
        playAnimation(.dengdai, force: true)  // 摇扇纳凉作为悠闲等待
        
        // 等待超时后生气
        DispatchQueue.main.asyncAfter(deadline: .now() + 10) { [weak self] in
            guard let self = self, self.isWaitingForFood else { return }
            self.playAnimation(.shengqi, force: true)  // 玩游戏气急败坏作为生气
            self.showBubble("等太久了！我生气了！😤")
            self.happiness -= 10
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.cancelFeeding()
            }
        }
    }
    
    func feed(food: FoodType) {
        guard isWaitingForFood else { return }
        isWaitingForFood = false
        waitingFoodStartTime = nil
        
        playSpecialAnimation(food.eatAnimation, duration: 4)
        energy += food.energyRestore
        happiness += food == .heart ? 20 : 10
        
        if food == .heart {
            showBubble("谢谢你的爱心~ 💕")
        } else {
            showBubble("好吃！还要吃~")
        }
    }
    
    func cancelFeeding() {
        isWaitingForFood = false
        waitingFoodStartTime = nil
        playAnimation(.daijihuxi)
    }
    
    /// 自动吃东西（隐藏后饿了）
    func autoEat() {
        energy = min(energy + 30, 100)
        playSpecialAnimation(.chibaihuafan, duration: 4)
    }
    
    // MARK: - 气泡消息
    func showBubble(_ text: String, autoDismiss: Bool = true, dismissDelay: TimeInterval = 4) {
        bubbleMessage = BubbleMessage(text: text, autoDismiss: autoDismiss)
        isBubbleVisible = true
        
        if autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) { [weak self] in
                withAnimation(.easeOut(duration: 0.5)) {
                    self?.isBubbleVisible = false
                }
            }
        }
    }
    
    func hideBubble() {
        withAnimation(.easeOut(duration: 0.3)) {
            isBubbleVisible = false
        }
    }
    
    func showStatusBubble() {
        var statusText = mood.emoji + " "
        switch mood {
        case .happy: statusText += "今天心情不错~"
        case .normal: statusText += "元气满满！"
        case .hungry: statusText += "肚子饿了...想吃东西"
        case .sleepy: statusText += "有点困了..."
        case .excited: statusText += "哇！好开心！"
        case .angry: statusText += "哼，不理你了"
        case .shy: statusText += "你、你干嘛..."
        }
        statusText += "\n精力: \(Int(energy)) | 心情: \(Int(happiness))"
        showBubble(statusText, dismissDelay: 3)
    }
    
    func sayRandomMessage() {
        let messages = [
            "加油加油！💪",
            "要不要休息一下？",
            "今天也要开心哦~",
            "我在这里陪着你~",
            "别忘了喝水哦~",
            "工作久了站起来走走吧",
            "你已经很棒了！",
            "再坚持一下就可以休息啦"
        ]
        if let msg = messages.randomElement() {
            showBubble(msg, dismissDelay: 5)
        }
    }
    
    // MARK: - 专注模式
    private func checkFocusMode() {
        guard focusModeAutoDetect else { return }
        
        if let frontApp = NSWorkspace.shared.frontmostApplication,
           let bundleId = frontApp.bundleIdentifier {
            let isWorkApp = focusAppIdentifiers.contains(bundleId)
            if isWorkApp != isFocusMode {
                isFocusMode = isWorkApp
                if isWorkApp {
                    workStartTime = Date()
                    showBubble("进入专注模式啦~ 我会安静一点", dismissDelay: 3)
                } else {
                    workStartTime = nil
                    showEyeCareBubble = false
                    showBubble("休息一下吧~", dismissDelay: 3)
                }
            }
        }
    }
    
    func toggleFocusMode() {
        focusModeAutoDetect = false
        isFocusMode.toggle()
        if isFocusMode {
            workStartTime = Date()
            showBubble("专注模式已开启")
        } else {
            workStartTime = nil
            showEyeCareBubble = false
            showBubble("专注模式已关闭")
        }
    }
    
    // MARK: - 护眼提醒
    private func checkEyeCare() {
        guard isFocusMode, let startTime = workStartTime else {
            showEyeCareBubble = false
            return
        }
        
        let workDuration = Date().timeIntervalSince(startTime)
        if workDuration >= eyeCareInterval && !showEyeCareBubble {
            showEyeCareBubble = true
        }
    }
    
    func handleEyeCareBubbleTap() {
        showEyeCareBubble = false
        workStartTime = Date() // 重置计时
        playSpecialAnimation(.shenlanya, duration: 3)
        showBubble("伸个懒腰~ 继续加油！")
    }
    
    func dismissEyeCareBubble() {
        withAnimation(.easeOut(duration: 0.5)) {
            showEyeCareBubble = false
        }
    }
    
    /// 随机下一动画
    func playNextRandomAnimation() {
        playRandomIdleAnimation()
    }
    
    // MARK: - 工具方法
    private func weightedRandom<T>(candidates: [T], weights: [Int]) -> T? {
        guard !candidates.isEmpty, candidates.count == weights.count else { return nil }
        let totalWeight = weights.reduce(0, +)
        guard totalWeight > 0 else { return candidates.randomElement() }
        
        var random = Int.random(in: 0..<totalWeight)
        for (index, candidate) in candidates.enumerated() {
            random -= weights[index]
            if random < 0 {
                return candidate
            }
        }
        return candidates.last
    }
}
