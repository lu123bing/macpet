#!/bin/bash
# 从 dsh-pet 下载/复制动画资源

set -e

ANIM_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/MacPet/Sources/MacPet/Resources/Animations"
echo "🐾 动画资源目录: $ANIM_DIR"

# 检查是否已经有 /tmp/dsh-pet
if [ -d "/tmp/dsh-pet/dsh-pet/assets/thumb" ]; then
    echo "📂 检测到已克隆的 dsh-pet，直接复制..."
    mkdir -p "$ANIM_DIR"
    cp /tmp/dsh-pet/dsh-pet/assets/thumb/*.webm "$ANIM_DIR/"
    COUNT=$(ls "$ANIM_DIR"/*.webm | wc -l)
    echo "✅ 已复制 $COUNT 个动画文件"
    du -sh "$ANIM_DIR"
    exit 0
fi

echo "正在克隆 dsh-pet 仓库（只获取动画目录）..."
rm -rf /tmp/dsh-pet
cd /tmp
git clone --depth 1 --filter=blob:none --sparse https://github.com/PC2005-cloud/dsh-pet.git
cd dsh-pet
git sparse-checkout set dsh-pet/assets/thumb

mkdir -p "$ANIM_DIR"
cp dsh-pet/assets/thumb/*.webm "$ANIM_DIR/"
COUNT=$(ls "$ANIM_DIR"/*.webm | wc -l)
echo "✅ 下载完成！共 $COUNT 个动画文件"
du -sh "$ANIM_DIR"

echo ""
echo "文件都是中文名 VP9 透明 webm，直接可播放，无需额外配置"
