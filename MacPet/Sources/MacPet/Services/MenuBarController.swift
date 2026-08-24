//
//  MenuBarController.swift
//  MacPet
//
//  Created by MacPet on 2026/8/23.
//

import SwiftUI
import AppKit
import Combine

@MainActor
final class MenuBarController: NSObject {
    private var statusItem: NSStatusItem?
    private var petState: PetState
    private var windowController: PetWindowController?
    private var cancellables = Set<AnyCancellable>()
    
    init(petState: PetState, windowController: PetWindowController) {
        self.petState = petState
        self.windowController = windowController
        super.init()
        setupStatusItem()
        setupStateObservers()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem?.button {
            let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
            let image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "MacPet")?
                .withSymbolConfiguration(config)
            button.image = image
            button.toolTip = "MacPet 桌宠"
            button.target = self
            button.action = #selector(statusBarButtonClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        updateMenu()
    }
    
    private func setupStateObservers() {
        petState.$isHidden
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        petState.$isFocusMode
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateMenu()
            }
            .store(in: &cancellables)
        
        petState.$mood
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mood in
                self?.updateMenuBarIcon(mood: mood)
            }
            .store(in: &cancellables)
    }
    
    private func updateMenuBarIcon(mood: PetMood) {
        guard let button = statusItem?.button else { return }
        
        let iconName: String
        switch mood {
        case .happy: iconName = "pawprint.fill"
        case .sleepy: iconName = "moon.stars.fill"
        case .hungry: iconName = "fork.knife"
        case .angry: iconName = "exclamationmark.circle.fill"
        case .excited: iconName = "star.fill"
        case .shy: iconName = "heart.fill"
        case .normal: iconName = "pawprint.fill"
        }
        
        let config = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        let image = NSImage(systemSymbolName: iconName, accessibilityDescription: "MacPet")?
            .withSymbolConfiguration(config)
        button.image = image
    }
    
    @objc private func statusBarButtonClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            showMenu()
        } else {
            // 左键点击：切换显示/隐藏
            if petState.isHidden {
                petState.show()
            } else {
                // 点击一次先显示状态气泡
                petState.showStatusBubble()
            }
            updateMenu()
        }
    }
    
    private func showMenu() {
        updateMenu()
        if let menu = statusItem?.menu {
            statusItem?.button?.performClick(nil)
        }
    }
    
    private func updateMenu() {
        let menu = NSMenu()
        
        // 显示/隐藏
        let toggleItem = NSMenuItem(
            title: petState.isHidden ? "显示桌宠" : "隐藏桌宠",
            action: #selector(toggleVisibility),
            keyEquivalent: "h"
        )
        toggleItem.keyEquivalentModifierMask = [.command, .control]
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        menu.addItem(.separator())
        
        // 专注模式
        let focusItem = NSMenuItem(
            title: petState.isFocusMode ? "退出专注模式" : "进入专注模式",
            action: #selector(toggleFocusMode),
            keyEquivalent: "f"
        )
        focusItem.keyEquivalentModifierMask = [.command, .shift]
        focusItem.target = self
        focusItem.state = petState.isFocusMode ? .on : .off
        menu.addItem(focusItem)
        
        // 自动检测专注
        let autoFocusItem = NSMenuItem(
            title: "自动检测专注模式",
            action: #selector(toggleAutoFocus),
            keyEquivalent: ""
        )
        autoFocusItem.target = self
        autoFocusItem.state = petState.focusModeAutoDetect ? .on : .off
        menu.addItem(autoFocusItem)
        
        menu.addItem(.separator())
        
        // 大小子菜单
        let sizeMenu = NSMenu()
        for size in PetSize.allCases {
            let item = NSMenuItem(
                title: size.displayName,
                action: #selector(setSize(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.tag = Int(size.rawValue * 10)
            item.state = petState.size == size ? .on : .off
            sizeMenu.addItem(item)
        }
        let sizeItem = NSMenuItem(title: "桌宠大小", action: nil, keyEquivalent: "")
        sizeItem.submenu = sizeMenu
        menu.addItem(sizeItem)
        
        menu.addItem(.separator())
        
        // 投喂子菜单
        let feedMenu = NSMenu()
        for food in FoodType.allCases {
            let item = NSMenuItem(
                title: "\(food.icon) \(food.rawValue)",
                action: #selector(feedFood(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = food
            feedMenu.addItem(item)
        }
        let feedItem = NSMenuItem(title: "投喂", action: nil, keyEquivalent: "")
        feedItem.submenu = feedMenu
        menu.addItem(feedItem)
        
        // 丢爱心
        let heartItem = NSMenuItem(
            title: "❤️ 丢一个爱心",
            action: #selector(throwHeart),
            keyEquivalent: ""
        )
        heartItem.target = self
        menu.addItem(heartItem)
        
        menu.addItem(.separator())
        
        // 下一个动画
        let nextAnimItem = NSMenuItem(
            title: "换一个动画",
            action: #selector(nextAnimation),
            keyEquivalent: "n"
        )
        nextAnimItem.keyEquivalentModifierMask = .command
        nextAnimItem.target = self
        menu.addItem(nextAnimItem)
        
        menu.addItem(.separator())
        
        // 状态显示
        let statusItem = NSMenuItem()
        statusItem.isEnabled = false
        statusItem.title = "精力: \(Int(petState.energy))% | 心情: \(Int(petState.happiness))%"
        menu.addItem(statusItem)
        
        menu.addItem(.separator())
        
        // 关于
        let aboutItem = NSMenuItem(
            title: "关于 MacPet",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)
        
        // 退出
        let quitItem = NSMenuItem(
            title: "退出",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.keyEquivalentModifierMask = .command
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    // MARK: - Menu Actions
    @objc private func toggleVisibility() {
        if petState.isHidden {
            petState.show()
        } else {
            petState.hide()
        }
        updateMenu()
    }
    
    @objc private func toggleFocusMode() {
        petState.toggleFocusMode()
        updateMenu()
    }
    
    @objc private func toggleAutoFocus() {
        petState.focusModeAutoDetect.toggle()
        updateMenu()
    }
    
    @objc private func setSize(_ sender: NSMenuItem) {
        let rawValue = CGFloat(sender.tag) / 10.0
        if let size = PetSize.allCases.first(where: { abs($0.rawValue - rawValue) < 0.01 }) {
            petState.size = size
        }
        updateMenu()
    }
    
    @objc private func feedFood(_ sender: NSMenuItem) {
        guard let food = sender.representedObject as? FoodType else { return }
        if !petState.isWaitingForFood {
            petState.startWaitingForFood()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.petState.feed(food: food)
        }
    }
    
    @objc private func throwHeart() {
        petState.startWaitingForFood()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.petState.feed(food: .heart)
        }
    }
    
    @objc private func nextAnimation() {
        petState.playNextRandomAnimation()
    }
    
    @objc private func showAbout() {
        let alert = NSAlert()
        alert.messageText = "MacPet 桌宠"
        alert.informativeText = """
        一款高性能 macOS 原生桌宠
        
        快捷键：
        • Fn/Globe 键：临时透明穿透
        • Cmd+Ctrl+H：显示/隐藏
        • Cmd+N：切换动画
        
        动画资源来自 dsh-pet 项目
        将 webm 动画放入 Resources/Animations 目录即可
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "好的")
        alert.runModal()
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    func cleanup() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }
    
    deinit {
        cleanup()
    }
}
