#!/bin/bash
set -e

mkdir -p ota

OTA_URL="https://gh-proxy.kejizero.xyz/https://github.com/Xiaokailnol/openwrt-actions-builder/releases/download"
VERSION="${latest_release#v}"

MODEL="${{ matrix.model }}"

# 默认值
TARGET=""
IMAGE_GLOB=""
DEVICE=""
JSON_NAME=""
IMAGE_NAME=""

case "$MODEL" in
  friendlyarm_nanopi-r2c|friendlyarm_nanopi-r2s|friendlyarm_nanopi-r3s|friendlyarm_nanopi-r4s)
    TARGET="bin/targets/rockchip/armv8"
    IMAGE_GLOB="*-squashfs-sysupgrade.img.gz"
    DEVICE="${MODEL/friendlyarm_/friendlyarm,}"
    JSON_NAME="${MODEL#friendlyarm_}.json"
    IMAGE_NAME="openwrt-$VERSION-rockchip-armv8-$MODEL-squashfs-sysupgrade.img.gz"
    ;;
  x86_64)
    TARGET="bin/targets/x86/64"
    IMAGE_GLOB="*-generic-squashfs-combined-efi.img.gz"
    DEVICE="x86_64"
    JSON_NAME="x86_64.json"
    IMAGE_NAME="openwrt-$VERSION-x86-64-generic-squashfs-combined-efi.img.gz"
    ;;
  *)
    echo "❌ Unsupported model: $MODEL"
    exit 1
    ;;
esac

# 计算 SHA256（只取第一个匹配文件）
IMAGE_PATH=$(ls $TARGET/$IMAGE_GLOB | head -n 1)
SHA256=$(sha256sum "$IMAGE_PATH" | awk '{print $1}')

# 生成 OTA JSON
cat > "ota/$JSON_NAME" <<EOF
{
  "$DEVICE": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$OTA_URL/$IMAGE_NAME"
    }
  ]
}
EOF

echo "✅ OTA file generated: ota/$JSON_NAME"

