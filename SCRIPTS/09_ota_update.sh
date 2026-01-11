#!/bin/bash

mkdir -p ota

OTA_URL="https://gh-proxy.kejizero.xyz/https://github.com/Xiaokailnol/openwrt-actions-builder/releases/download"

VERSION="${latest_release#v}"
    
case "$1" in
  friendlyarm_nanopi-r2c)
    SHA256=$(sha256sum bin/targets/rockchip/armv8*/*-squashfs-sysupgrade.img.gz | awk '{print $1}')
    ;;
  friendlyarm_nanopi-r2s)
    SHA256=$(sha256sum bin/targets/rockchip/armv8*/*-squashfs-sysupgrade.img.gz | awk '{print $1}')
    ;;
  friendlyarm_nanopi-r3s)
    SHA256=$(sha256sum bin/targets/rockchip/armv8*/*-squashfs-sysupgrade.img.gz | awk '{print $1}')
    ;;
  friendlyarm_nanopi-r4s)
    SHA256=$(sha256sum bin/targets/rockchip/armv8*/*-squashfs-sysupgrade.img.gz | awk '{print $1}')
    ;;            
  x86_64)
    SHA256=$(sha256sum bin/targets/x86/64*/*-generic-squashfs-combined-efi.img.gz | awk '{print $1}')
    ;;
esac

case "$1" in
  x86_64)
    cat > ota/x86_64.json <<EOF
{
  "x86_64": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$OTA_URL/openwrt-$VERSION-x86-64-generic-squashfs-combined-efi.img.gz"
    }
  ]
}
EOF
    ;;    
  friendlyarm_nanopi-r2c)
    cat > ota/nanopi-r2c.json <<EOF
{
  "friendlyarm,nanopi-r2c": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$OTA_URL/openwrt-$VERSION-rockchip-armv8-friendlyarm_nanopi-r2c-squashfs-sysupgrade.img.gz"
    }
  ]
}
EOF
    ;;    
  friendlyarm_nanopi-r2s)
    cat > ota/nanopi-r2s.json <<EOF
{
  "friendlyarm,nanopi-r2s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$OTA_URL/openwrt-$VERSION-rockchip-armv8-friendlyarm_nanopi-r2s-squashfs-sysupgrade.img.gz"
    }
  ]
}
EOF
    ;;    
  friendlyarm_nanopi-r3s)
    cat > ota/nanopi-r3s.json <<EOF
{
  "friendlyarm,nanopi-r3s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$OTA_URL/openwrt-$VERSION-rockchip-armv8-friendlyarm_nanopi-r3s-squashfs-sysupgrade.img.gz"
    }
  ]
}
EOF
    ;;    
  friendlyarm_nanopi-r4s)
    cat > ota/nanopi-r4s.json <<EOF
{
  "friendlyarm,nanopi-r4s": [
    {
      "build_date": "$CURRENT_DATE",
      "sha256sum": "$SHA256",
      "url": "$OTA_URL/openwrt-$VERSION-rockchip-armv8-friendlyarm_nanopi-r4s-squashfs-sysupgrade.img.gz"
    }
  ]
}
EOF
    ;;
esac
