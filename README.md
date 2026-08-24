# 🐾 MacPet - macOS 原生桌宠

基于 SwiftUI 开发的高性能 macOS 原生桌面宠物，支持 Intel 芯片。动画资源兼容 [dsh-pet](https://github.com/PC2005-cloud/dsh-pet) 项目。

## ✨ 功能特性

### 核心功能
- **🖥️ 边缘吸附但不隐藏** - 拖到屏幕边缘自动吸附，保持可见
- **📋 菜单栏控制** - 菜单栏图标一键控制显示/隐藏、投喂、设置等
- **⌨️ 快捷键透明穿透** - 按住 `Fn/Globe` 键自动降低透明度+鼠标穿透，不与常见快捷键冲突
- **🙈 隐藏快捷键** - `Cmd+Ctrl+H` 切换显示/隐藏；隐藏会消耗精力，精力低于25会自动出来觅食
- **🎯 专注模式** - 自动检测当前活动窗口（WPS、微信、Xcode、VS Code等）判定工作状态，自动缩小并减少交互，增加工作/看书动画概率
- **👀 久坐护眼提醒** - 连续工作45分钟后弹出轻量气泡提醒喝水，点击播放伸懒腰动画，5秒自动淡出，无系统通知
- **🔘 桌宠自带菜单** - 右键点击桌宠可控制大小、切动画、投喂、丢爱心
- **🍜 投喂系统** - 支持多种食物，不同食物有对应动画；等待时显示等待动画，超时会生气催促
- **🫧 Q弹点击反馈** - 点击时有弹簧缩放效果，随机播放回应动画
- **🫳 拖拽果冻效果** - 拖拽时跟随鼠标左右摇摆，具有果冻弹性
- **💬 聊天气泡** - 点击显示状态，随机鼓励话语，所有提醒通过气泡传达

### 性能优化
- 双缓冲 `AVPlayer` 无缝循环播放
- 动画资源预加载缓存
- `CVDisplayLink` 垂直同步渲染
- 窗口级别优化，不抢焦点不占Dock
- 按需播放，非活跃时降低帧率
- 支持 VP9 Alpha 透明 WebM 硬件解码

## 🚀 快速开始

### 环境要求
- macOS 12.0+ (Monterey)
- Xcode 14+ 或 Command Line Tools
- 支持 Intel (x86_64) 和 Apple Silicon (arm64)

### 构建运行

```bash
cd macpet

# 方式1: 一键构建 Release .app（Universal Binary 支持Intel/M1）
./build.sh

# 打开构建好的 App
open MacPet.app

# 方式2: Debug 直接运行
cd MacPet && swift run
```

### 动画资源

本仓库已内置从 [PC2005-cloud/dsh-pet](https://github.com/PC2005-cloud/dsh-pet) 获取的 **91 个 VP9 透明 WebM 动画**（共 47MB）作为测试资源，位于：
```
MacPet/Sources/MacPet/Resources/Animations/
```

文件名对应中文动作名（如 `待机呼吸休闲.webm`、`吃白饭.webm`），程序直接按文件名匹配播放。

如需重新下载最新动画：
```bash
./download-animations.sh
```

> 注意：这些动画是测试用资源，和代码里定义的"语义动作"不完全一一对应；`AnimationType.swift` 中已经做了近似映射（如用"玩游戏气急败坏"作为生气动画），你可以替换成自己的角色动画。

## ⌨️ 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Fn/Globe` (按住) | 临时降低透明度 + 鼠标穿透（可点击桌宠下方的窗口） |
| `Cmd + Ctrl + H` | 切换显示/隐藏桌宠 |
| `Cmd + N` | 随机切换下一动画 |
| `Cmd + Shift + F` | 切换专注模式 |
| `右键点击桌宠` | 打开功能菜单 |
| `左键点击桌宠` | Q弹反馈 + 显示状态气泡 |
| `拖拽` | 移动桌宠（带果冻摇摆效果） |

> **为什么选 Fn/Globe 键？** 
> - 位于键盘左下角，位置顺手
> - 独立修饰键，不与 Cmd/Opt/Shift 组合冲突
> - 单键切换，松开即恢复

## 🧠 状态系统

### 精力值 (Energy)
- 初始100，每30秒自然下降1点
- 隐藏一次消耗10点，最低25点（不会更低）
- 精力 ≤25 时宠物处于饥饿状态，会自动出来觅食
- 投喂不同食物恢复不同精力：
  - ❤️ 爱心: +30
  - 🍚 白饭: +25
  - 🥟 饺子/汤圆/月饼: +20
  - 🍿 零食: +15
  - 💧 水: +10

### 心情值 (Happiness)
- 投喂、丢爱心提升心情
- 等待投喂超时生气扣心情
- 心情低时宠物会傲娇不理人

## 🎯 专注模式自动检测

检测到以下应用活动时自动进入专注模式：
- WPS Office (Word/Excel/PPT)
- 微信、企业微信
- Microsoft Office
- Xcode、VS Code
- Figma、Photoshop
- Safari、Chrome、Edge
- Pages/Numbers/Keynote

专注模式行为变化：
- 桌宠缩小到 80%
- 大幅减少主动交互频率
- 动画优先选择工作类（看书、写代码、记录）
- 启用45分钟久坐计时

## 📁 项目结构

```
macpet/
├── MacPet/
│   ├── Package.swift
│   └── Sources/MacPet/
│       ├── MacPetApp.swift          # App入口、设置界面
│       ├── Models/
│       │   ├── AnimationType.swift  # 动画类型枚举、分类、权重
│       │   └── PetState.swift       # 核心状态、状态机逻辑
│       ├── Views/
│       │   ├── AnimationPlayerView.swift  # 高性能透明动画播放器
│       │   └── PetView.swift        # 宠物主视图、气泡、菜单
│       ├── Services/
│       │   ├── PetWindowController.swift  # 无边框窗口管理
│       │   └── MenuBarController.swift    # 菜单栏图标菜单
│       └── Resources/
│           └── Animations/          # WebM动画资源目录
├── build.sh                         # 构建脚本
└── README.md
```

## 🎬 动画资源说明

本项目兼容 [PC2005-cloud/dsh-pet](https://github.com/PC2005-cloud/dsh-pet) 的透明动画资源。推荐使用 VP9 编码的透明 WebM 格式。

目前已支持 50+ 种动画场景：
- 待机类：呼吸、休闲、东张西望、打瞌睡
- 移动类：走路、奔跑、漂浮
- 交互类：点击开心/害羞/傲娇回应、吓一跳
- 进食类：吃饭、吃零食、喝水、吃节日食物
- 工作类：写代码、看书、记录、深度思考
- 情绪类：开心、伤心、害羞、惊讶、爱心
- 玩耍类：玩魔方、哼歌、吐泡泡、跳舞、乐器

## 🔧 技术实现要点

1. **无边框透明窗口**：使用 `NSWindow` 边框less样式，`backgroundColor = .clear`，`isOpaque = false`
2. **窗口级别**：`level = .floating` 保证置顶但不影响全屏，`collectionBehavior` 配置全Space显示
3. **鼠标穿透**：动态切换 `ignoresMouseEvents`，按键时透明穿透，松开恢复
4. **透明视频**：AVPlayer 支持 VP9 Alpha 通道 WebM 硬件解码，比 GIF/APNG 小80%
5. **果冻效果**：拖拽时实时计算水平偏移，通过 CGAffineTransform 错切+缩放实现
6. **边缘吸附**：松手时检测与屏幕四边距离，在margin范围内自动吸附
7. **前端应用检测**：`NSWorkspace.shared.frontmostApplication` 轮询当前活跃App
8. **双缓冲循环**：监听 `AVPlayerItemDidPlayToEndTime` 通知无缝 seekToZero 实现无卡顿循环

## 📄 开源许可

- 代码：MIT License
- 动画素材：遵循 [dsh-pet](https://github.com/PC2005-cloud/dsh-pet) 项目许可
