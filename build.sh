#!/bin/bash
# MacPet 构建脚本
# 支持 Intel (x86_64) 和 Apple Silicon (arm64)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/MacPet"

echo "🐾 正在构建 MacPet..."
echo "=========================="

# 检查动画资源
ANIM_COUNT=$(ls Sources/MacPet/Resources/Animations/*.webm 2>/dev/null | wc -l)
if [ "$ANIM_COUNT" -gt 0 ]; then
    echo "✅ 已找到 $ANIM_COUNT 个动画资源"
else
    echo "⚠️  未找到动画资源，请先运行 ../download-animations.sh"
fi

# 检查 Swift 是否可用
if ! command -v swiftc &> /dev/null; then
    echo "❌ 错误: 未找到 Swift 编译器"
    echo "   请先安装 Xcode 或 Xcode Command Line Tools:"
    echo "   xcode-select --install"
    exit 1
fi

# 构建版本
BUILD_TYPE=${1:-release}

if [ "$BUILD_TYPE" = "release" ]; then
    echo "📦 构建 Release 版本 (Universal Binary)..."
    swift build -c release --arch x86_64 --arch arm64
    
    # 获取构建产物路径（apple/Products/Release 是 Xcode-style 路径）
    BUILD_DIR=$(swift build -c release --arch x86_64 --arch arm64 --show-bin-path)
    BIN_PATH="$BUILD_DIR/MacPet"
    if [ ! -f "$BIN_PATH" ]; then
        # 回退查找
        BIN_PATH=$(find .build -name MacPet -type f -path "*release*" | head -1)
    fi
    
    APP_DIR="$SCRIPT_DIR/MacPet.app"
    APP_CONTENTS="$APP_DIR/Contents"
    APP_MACOS="$APP_CONTENTS/MacOS"
    APP_RESOURCES="$APP_CONTENTS/Resources"
    
    echo "📀 创建 .app 包..."
    rm -rf "$APP_DIR"
    mkdir -p "$APP_MACOS"
    mkdir -p "$APP_RESOURCES"
    
    # 复制二进制
    if [ -f "$BIN_PATH" ]; then
        cp "$BIN_PATH" "$APP_MACOS/MacPet"
    else
        echo "❌ 找不到构建产物"
        exit 1
    fi
    
    # 复制动画资源（所有webm）
    if [ -d "Sources/MacPet/Resources/Animations" ]; then
        mkdir -p "$APP_RESOURCES/Animations"
        cp Sources/MacPet/Resources/Animations/*.webm "$APP_RESOURCES/Animations/" 2>/dev/null || true
        echo "✅ 已复制动画资源到 .app 包"
    fi
    
    # 创建 Info.plist
    cat > "$APP_CONTENTS/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>MacPet</string>
    <key>CFBundleIdentifier</key>
    <string>com.macpet.app</string>
    <key>CFBundleName</key>
    <string>MacPet</string>
    <key>CFBundleDisplayName</key>
    <string>MacPet 桌宠</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <false/>
    </dict>
</dict>
</plist>
PLIST
    
    echo "✅ 构建完成!"
    echo "📍 App 路径: $APP_DIR"
    echo ""
    echo "🚀 运行方式:"
    echo "   open $APP_DIR"
    echo ""
    echo "📝 注意: 首次运行需在系统设置中允许运行:"
    echo "   系统设置 → 隐私与安全性 → 仍要打开"
else
    echo "🔨 构建 Debug 版本..."
    swift build
    echo ""
    echo "✅ 构建完成!"
    echo "🚀 运行调试版本:"
    echo "   swift run"
fi

echo ""
echo "📂 添加动画资源:"
echo "   将 dsh-pet 的 webm 动画文件放入 MacPet/Sources/MacPet/Resources/Animations/ 目录"
echo "   详见该目录下的 README.md"
