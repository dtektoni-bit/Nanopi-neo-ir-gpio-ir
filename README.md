# NanoPi NEO — IR Remote Control via gpio-ir

IR remote control setup for NanoPi NEO running Volumio 3 (Nikkov image, kernel 5.10.60-sunxi).

Uses the **gpio-ir-recv** kernel driver instead of the hardware CIR receiver (GPIOL11), which has timing issues when the i2s_clock_board module releases the I2S bus on pause.

## Hardware

| Signal | NanoPi NEO GPIO1 Pin |
|--------|----------------------|
| VCC    | Pin 1 (3.3V)         |
| GND    | Pin 6 (GND)          |
| OUT    | Pin 18 (GPIOG9)      |

> ⚠️ Do NOT use Pin 11 (PA0) — it is UART2_TX and generates noise on the IR receiver line.

## Remote

Xtreamer remote (NEC protocol). Config files included in this repository.

## Installation

### Prerequisites

- NanoPi NEO with Volumio 3 (Nikkov image)
- Fresh image, SSH access
- IR receiver connected to Pin 18 (GPIOG9)

### Part 1 — System setup

```bash
wget https://raw.githubusercontent.com/dtektoni-bit/Nanopi-neo-ir-gpio-ir/main/install_ir_part1.sh
sudo bash install_ir_part1.sh
```

The system will reboot automatically. After reboot verify:

```bash
ls /dev/lirc0
```

### Manual step — Install IR Controller plugin

Open Volumio web UI → Plugins → Search → **ir controller** → Install.

### Part 2 — LIRC and irexec setup

```bash
wget https://raw.githubusercontent.com/dtektoni-bit/Nanopi-neo-ir-gpio-ir/main/install_ir_part2.sh
sudo bash install_ir_part2.sh
```

### Final step

Open Volumio web UI → Plugins → IR Controller → select **Xtreamer**.

## Repository structure

```
overlay-user/
    sun8i-h3-gpio-ir.dts          # gpio-ir device tree overlay source
lircd.service.d/
    override.conf                  # lircd systemd override (fixes socket activation)
irexec.service.d/
    override.conf                  # irexec systemd override (depends on lircd)
INTERNAL/ir_controller/configurations/Xtreamer/
    lircd.conf                     # Xtreamer remote LIRC config
    lircrc                         # Button-to-command mapping
install_ir_part1.sh               # Setup script part 1
install_ir_part2.sh               # Setup script part 2
```

## Button mapping

| Button       | Volumio command         |
|--------------|-------------------------|
| PLAYPAUSE    | volumio toggle          |
| STOP         | volumio stop            |
| PAGEUP       | volumio previous        |
| PAGEDOWN     | volumio next            |
| REWIND       | volumio seek minus      |
| FORWARD      | volumio seek plus       |
| RESTART      | volumio repeat          |
| 1..9         | Play track N from queue |

## Troubleshooting

| Symptom | Cause | Solution |
|---------|-------|----------|
| /dev/lirc0 missing | Overlay not loaded | Check armbianEnv.txt, recompile dtbo |
| lirc install fails | Broken apt repo | Part 1 fixes this automatically |
| irw shows no output | lircd socket issue | Part 2 fixes this (disables socket activation) |
| irexec not starting | Starts before lircd | Part 2 fixes this (adds After=lircd.service) |
| Commands not executing | CRLF in lircrc | Part 2 fixes this automatically |
| Noise on IR input | Wrong GPIO pin | Use GPIOG9 (pin 18), not PA0 (pin 11) |
