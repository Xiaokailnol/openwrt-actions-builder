#!/bin/bash
set -e

# --- 权限与依赖检查 ---
if [ "$(id -u)" -ne 0 ]; then
    echo "Error: 请使用 sudo (root权限) 运行"
    exit 1
fi

# GitHub Actions 环境自动安装 (使用 apt-fast)
if [ "$GITHUB_ACTIONS" = "true" ]; then
    echo "正在安装依赖..."
    sudo apt-fast install -y -qq btrfs-progs rsync pigz
fi

# 检查必要工具
for cmd in mkfs.btrfs rsync losetup blkid pigz; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: 缺少工具 $cmd"
        exit 1
    fi
done

# --- 输入校验 ---
SOURCE_FILE="$1"
if [[ -z "$SOURCE_FILE" || "$SOURCE_FILE" != *.gz ]]; then
    echo "用法: $0 <image.img.gz>"
    echo "Error: 仅支持 .gz 格式的压缩镜像"
    exit 1
fi

if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: 文件不存在 $SOURCE_FILE"
    exit 1
fi

# --- 变量定义 ---
BASENAME=$(basename "$SOURCE_FILE" .gz)

# --- 替换文件名 ext4 为 btrfs ---
if [[ "$BASENAME" == *"ext4"* ]]; then
    # 如果文件名包含 ext4，则进行替换
    WORK_IMG="${BASENAME//ext4/btrfs}"
else
    # 如果原文件名不含 ext4，则在 .img 前面加上 -btrfs 后缀
    WORK_IMG="${BASENAME%.img}-btrfs.img"
fi

# 使用当前目录下的 tmp 文件夹
TEMP_BASE="./tmp"
TEMP_MNT="${TEMP_BASE}/btrfs_mnt_$$"
TEMP_DATA="${TEMP_BASE}/btrfs_data_$$"
LOOP_DEV=""

# 定义退出清理函数
cleanup() {
    mountpoint -q "$TEMP_MNT" && umount "$TEMP_MNT"
    [ -n "$LOOP_DEV" ] && losetup -d "$LOOP_DEV"
    # 仅删除本次运行生成的临时子目录，保留 ./tmp 父目录
    rm -rf "$TEMP_MNT" "$TEMP_DATA"
}
trap cleanup EXIT

# --- 核心流程 ---

echo "1. 解压镜像到: $WORK_IMG ..."
pigz -d -c "$SOURCE_FILE" > "$WORK_IMG"

echo "2. 挂载镜像..."
LOOP_DEV=$(losetup -fP --show "$WORK_IMG")
ROOT_PART="${LOOP_DEV}p2" # 默认 OpenWrt Rootfs 为 p2

if [ ! -b "$ROOT_PART" ]; then
    echo "Error: 未找到分区 $ROOT_PART"
    exit 1
fi

OLD_UUID=$(blkid -s UUID -o value "$ROOT_PART")
echo "原 UUID 为: $OLD_UUID"
OLD_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")
echo "原 Partition UUID : $OLD_PARTUUID"

# 创建临时目录
mkdir -p "$TEMP_MNT" "$TEMP_DATA"

echo "3. 提取原系统数据..."
mount "$ROOT_PART" "$TEMP_MNT"
rsync -aAX --exclude "lost+found" "$TEMP_MNT/" "$TEMP_DATA/"
umount "$TEMP_MNT"

echo "4. 格式化为 Btrfs..."
mkfs.btrfs -f -L rootfs -m single -U "$OLD_UUID" "$ROOT_PART"

echo "5. 还原数据..."
mount -t btrfs -o compress=zstd "$ROOT_PART" "$TEMP_MNT"
btrfs property set "$TEMP_MNT" compression zstd
rsync -aAX "$TEMP_DATA/" "$TEMP_MNT/"

echo "6. 更新系统配置..."
# 验证 Filesystem UUID (mkfs -U 参数的效果)
NEW_UUID=$(blkid -s UUID -o value "$ROOT_PART")
echo "验证 UUID 完整性..."
if [ "$NEW_UUID" != "$OLD_UUID" ]; then
    echo "Error: Filesystem UUID 未能保留！"
    echo "期望: $OLD_UUID"
    echo "实际: $NEW_UUID"
    exit 1
fi
echo "   [OK] Filesystem UUID 保持一致: $NEW_UUID"
# 验证 PARTUUID (mkfs 通常不会改变这个)
NEW_PARTUUID=$(blkid -s PARTUUID -o value "$ROOT_PART")
if [ "$NEW_PARTUUID" != "$OLD_PARTUUID" ]; then
    echo "Error: PARTUUID 发生了改变！"
    echo "原: $OLD_PARTUUID"
    echo "新: $NEW_PARTUUID"
    exit 1
fi
echo "   [OK] PARTUUID 保持一致: $NEW_PARTUUID"

# 修改 fstab
mkdir -p "$TEMP_MNT/etc/config"
cat >> "$TEMP_MNT/etc/config/fstab" <<EOF

config mount
	option target '/'
	option uuid '$NEW_UUID'
	option enabled '1'
	option fstype 'btrfs'
	option options 'rw,noatime,compress=zstd,space_cache=v2'
EOF

# 删除所有挂载点为 / 的行，如果有
sed -i '\#\s/\s#d' "$TEMP_MNT/etc/fstab" 2>/dev/null || true
echo "PARTUUID=$NEW_PARTUUID / btrfs rw,noatime,compress=zstd,space_cache=v2 0 0" >> "$TEMP_MNT/etc/fstab"

# --- 收尾 ---
umount "$TEMP_MNT"
losetup -d "$LOOP_DEV"
LOOP_DEV=""

if [ "$GITHUB_ACTIONS" != "true" ]; then
    echo "7. 压缩输出文件..."
    pigz -9 "$WORK_IMG"
    # 这里的 WORK_IMG 已经是替换过名字的文件，pigz 会生成 WORK_IMG.gz
    rm -f "$WORK_IMG"
fi

echo "=== 转换成功 ==="