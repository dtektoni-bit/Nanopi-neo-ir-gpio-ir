#!/bin/bash
# =============================================================================
# install_ir_part1.sh — NanoPi NEO IR Remote Control Setup (Part 1)
# Запустить: sudo bash install_ir_part1.sh
# После выполнения: система перезагрузится автоматически
# Затем: установить плагин IR Controller через Volumio UI
# Затем: запустить install_ir_part2.sh
# =============================================================================

set -e

REPO="https://raw.githubusercontent.com/dtektoni-bit/Nanopi-neo-ir-gpio-ir/main"

echo "=== IR Remote Setup Part 1 ==="
echo ""

# --- 1. Починить apt репозиторий ---
echo "[1/5] Fixing apt repository..."
echo "deb http://archive.debian.org/debian buster main contrib non-free" > /etc/apt/sources.list
apt-get update -q
echo "Done."

# --- 2. Установить lirc ---
echo "[2/5] Installing lirc..."
apt-get install -y lirc
echo "Done."

# --- 3. Скачать и скомпилировать gpio-ir оверлей ---
echo "[3/5] Setting up gpio-ir overlay..."
wget -q -O /boot/overlay-user/sun8i-h3-gpio-ir.dts "${REPO}/overlay-user/sun8i-h3-gpio-ir.dts"
dtc -I dts -O dtb -o /boot/overlay-user/sun8i-h3-gpio-ir.dtbo /boot/overlay-user/sun8i-h3-gpio-ir.dts 2>/dev/null
echo "Done."

# --- 4. Добавить оверлей в armbianEnv.txt ---
echo "[4/5] Updating armbianEnv.txt..."
if grep -q "user_overlays=" /boot/armbianEnv.txt; then
    if ! grep -q "sun8i-h3-gpio-ir" /boot/armbianEnv.txt; then
        sed -i 's/user_overlays=\(.*\)/user_overlays=\1 sun8i-h3-gpio-ir/' /boot/armbianEnv.txt
        echo "Added sun8i-h3-gpio-ir to user_overlays."
    else
        echo "sun8i-h3-gpio-ir already in user_overlays, skipping."
    fi
else
    echo "user_overlays=sun8i-h3-gpio-ir" >> /boot/armbianEnv.txt
    echo "Added user_overlays line."
fi

# --- 5. Перезагрузка ---
echo "[5/5] Done. Rebooting in 5 seconds..."
echo ""
echo "После перезагрузки:"
echo "  1. Проверить: ls /dev/lirc0"
echo "  2. Установить плагин IR Controller через Volumio UI"
echo "  3. Запустить: sudo bash install_ir_part2.sh"
echo ""
sleep 5
reboot
