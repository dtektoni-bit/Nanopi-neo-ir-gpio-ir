#!/bin/bash
# =============================================================================
# install_ir_part2.sh — NanoPi NEO IR Remote Control Setup (Part 2)
# Запустить ПОСЛЕ: перезагрузки и установки плагина IR Controller
# Запустить: sudo bash install_ir_part2.sh
# =============================================================================

set -e

REPO="https://raw.githubusercontent.com/dtektoni-bit/Nanopi-neo-ir-gpio-ir/main"

echo "=== IR Remote Setup Part 2 ==="
echo ""

# --- Проверить что /dev/lirc0 есть ---
if [ ! -e /dev/lirc0 ]; then
    echo "ERROR: /dev/lirc0 not found!"
    echo "Убедись что Part 1 выполнен и система перезагружена."
    exit 1
fi
echo "OK: /dev/lirc0 found."

# --- Проверить что плагин IR Controller установлен ---
if [ ! -d /data/plugins/system_hardware/ir_controller ]; then
    echo "ERROR: Плагин IR Controller не установлен!"
    echo "Установи его через Volumio UI: Plugins -> Search -> ir controller"
    exit 1
fi
echo "OK: IR Controller plugin found."

# --- 1. Скопировать конфиг пульта Xtreamer ---
echo "[1/6] Copying Xtreamer remote config..."
mkdir -p /data/INTERNAL/ir_controller/configurations/Xtreamer
wget -q -O /data/INTERNAL/ir_controller/configurations/Xtreamer/lircd.conf "${REPO}/INTERNAL/ir_controller/configurations/Xtreamer/lircd.conf"
wget -q -O /data/INTERNAL/ir_controller/configurations/Xtreamer/lircrc "${REPO}/INTERNAL/ir_controller/configurations/Xtreamer/lircrc"
# Исправить Windows CRLF -> Unix LF
sed -i 's/\r//' /data/INTERNAL/ir_controller/configurations/Xtreamer/lircrc
sed -i 's/\r//' /data/INTERNAL/ir_controller/configurations/Xtreamer/lircd.conf
echo "Done."

# --- 2. Отключить lircd socket activation ---
echo "[2/6] Disabling lircd socket activation..."
systemctl stop lircd.socket 2>/dev/null || true
systemctl disable lircd.socket 2>/dev/null || true
echo "Done."

# --- 3. Создать override для lircd ---
echo "[3/6] Creating lircd override..."
mkdir -p /etc/systemd/system/lircd.service.d
wget -q -O /etc/systemd/system/lircd.service.d/override.conf "${REPO}/lircd.service.d/override.conf"
echo "Done."

# --- 4. Создать override для irexec ---
echo "[4/6] Creating irexec override..."
mkdir -p /etc/systemd/system/irexec.service.d
wget -q -O /etc/systemd/system/irexec.service.d/override.conf "${REPO}/irexec.service.d/override.conf"
echo "Done."

# --- 5. Создать симлинк irexec.lircrc ---
echo "[5/6] Creating irexec.lircrc symlink..."
ln -sf /data/INTERNAL/ir_controller/configurations/Xtreamer/lircrc /etc/lirc/irexec.lircrc
echo "Done."

# --- 6. Включить и запустить сервисы ---
echo "[6/6] Enabling and starting services..."
systemctl daemon-reload
systemctl enable lircd
systemctl enable irexec
# Убрать стale pid если есть
rm -f /var/run/lirc/lircd.pid /run/lirc/lircd.pid
systemctl start lircd
sleep 2
systemctl start irexec
echo "Done."

# --- Проверка ---
echo ""
echo "=== Status ==="
systemctl is-active lircd && echo "lircd: OK" || echo "lircd: FAILED"
systemctl is-active irexec && echo "irexec: OK" || echo "irexec: FAILED"
echo ""
echo "=== Done! ==="
echo ""
echo "В Volumio UI: Plugins -> IR Controller -> выбери Xtreamer"
echo "Проверить декодирование: irw /run/lirc/lircd"
