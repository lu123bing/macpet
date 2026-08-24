//
//  MacPetApp.swift
//  MacPet
//
//  Created by MacPet on 2026/8/23.
//

import SwiftUI
import AppKit

// MARK: - App 入口
@main
struct MacPetApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        // 使用 Settings 场景提供偏好设置，但不显示主窗口
        Settings {
            SettingsView()
        }
        .windowStyle(.hiddenTitleBar)
    }
}

// MARK: - AppDelegate
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    var petState: PetState!
    var petWindowController: PetWindowController!
    var menuBarController: MenuBarController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // 配置应用
        NSApp.setActivationPolicy(.accessory) // 不在Dock显示
        
        // 初始化核心组件
        petState = PetState()
        petWindowController = PetWindowController(petState: petState)
        menuBarController = MenuBarController(petState: petState, windowController: petWindowController)
        
        // 欢迎气泡
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.petState.showBubble("你好呀！我是你的桌宠~ 💕\n右键我可以看到更多功能哦")
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false // 关闭所有窗口后不退出
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        petWindowController?.cleanup()
        menuBarController?.cleanup()
    }
}

// MARK: - 设置界面
struct SettingsView: View {
    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem {
                    Label("通用", systemImage: "gear")
                }
            ShortcutsSettingsView()
                .tabItem {
                    Label("快捷键", systemImage: "keyboard")
                }
            AboutSettingsView()
                .tabItem {
                    Label("关于", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 300)
        .padding()
    }
}

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("showWelcomeBubble") private var showWelcomeBubble = true
    @AppStorage("eyeCareReminder") private var eyeCareReminder = true
    
    var body: some View {
        Form {
            Section("启动") {
                Toggle("开机时启动", isOn: $launchAtLogin)
                Toggle("启动时显示欢迎气泡", isOn: $showWelcomeBubble)
            }
            
            Section("显示") {
                LabeledContent("边缘吸附") { Text("已启用（不隐藏）") }
                LabeledContent("Spaces 显示") { Text("所有 Spaces 都显示") }
            }
            
            Section("提醒") {
                Toggle("久坐/护眼提醒", isOn: $eyeCareReminder)
                Text("工作 45 分钟后提醒休息")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

struct ShortcutsSettingsView: View {
    var body: some View {
        Form {
            Section("桌宠控制") {
                LabeledContent("显示/隐藏") { Text("Cmd + Ctrl + H").foregroundColor(.secondary) }
                LabeledContent("临时透明穿透") { Text("按住 Fn/Globe 键").foregroundColor(.secondary) }
                LabeledContent("切换下一动画") { Text("Cmd + N").foregroundColor(.secondary) }
                LabeledContent("切换专注模式") { Text("Cmd + Shift + F").foregroundColor(.secondary) }
            }
            
            Text("提示：Fn/Globe 键位于键盘左下角，独立不与其他快捷键冲突")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "pawprint.fill")
                .font(.system(size: 48))
                .foregroundColor(.accentColor)
            
            Text("MacPet")
                .font(.title)
                .bold()
            
            Text("版本 1.0.0")
                .foregroundColor(.secondary)
            
            Text("基于 SwiftUI 的高性能 macOS 原生桌宠")
                .multilineTextAlignment(.center)
            
            Divider()
            
            Text("动画资源来源于 dsh-pet 项目 (PC2005-cloud)")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Link("获取更多动画资源...", destination: URL(string: "https://github.com/PC2005-cloud/dsh-pet")!)
                .font(.caption)
        }
        .padding()
    }
}
