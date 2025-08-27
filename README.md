# Virtual Cluster (PySide6/QML)

Virtual engine cluster (RPM + Speed) with data from a Teensy 4.1 (EMU Black CAN) or a DEMO mode fallback.

## Features
- PySide6 + QML (fullscreen, target 60 FPS)
- Splash screen + smooth transition to the main scene
- Two dials: RPM (0–8000, red from 6500), Speed (0–220 km/h)
- Icons: turn signals L/R, high beam, fog, park/brake (placeholders)
- Automatic switch to DEMO if Teensy / serial port is not available
- Resolution parameters in `config.py` (1920×720 default; can change to 1280×480)

## Requirements
Python 3.11+

## Installation (PC / Linux)
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/main.py
```
DEMO mode starts automatically if `/dev/ttyACM0` is not present.

## Installation on Raspberry Pi (Raspberry Pi OS Lite 64-bit)
```bash
sudo apt update
sudo apt install -y python3-venv python3-pip libegl1 libgles2 libxcb-xinerama0
cd ~/<repo_directory>
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/main.py  # test run
```

### HDMI settings in `/boot/firmware/cmdline.txt` (Pi OS Bookworm)
Append to the existing single line (do NOT create a new line):
```
video=HDMI-A-1:1920x720@60D quiet loglevel=0 vt.global_cursor_default=0
```
For 1280×480:
```
video=HDMI-A-1:1280x480@60D quiet loglevel=0 vt.global_cursor_default=0
```

### Autostart (systemd)
Update the path in `systemd/gauges.service` if the repository is not at `/home/pi/virtual-cluster`.
```bash
sudo cp systemd/gauges.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable gauges.service
sudo systemctl start gauges.service
```

## Changing resolution
Edit `config.py`:
```python
WIDTH = 1280
HEIGHT = 480
```
Restart the application.

## Environment variables
`TEENSY_DEV` – custom serial device path (e.g. `/dev/ttyACM1`).

## Frame format from Teensy
Binary (little-endian) 14 bytes:
```
MAGIC(u16)=0xA55A, VER(u8)=1, LEN(u8)=14, RPM(u16), VSS_cm_s(u16), FLAGS(u16), CRC16-X25(u16)
```
FLAGS bits:
```
0: Left turn
1: Right turn
2: High beam
3: Fog
4: Park / Brake
```
Speed: `km/h = (VSS_cm_s / 100.0) * 0.036`.

## Manual tests
1. DEMO: Disconnect Teensy / missing port. Run `python src/main.py` → dials animate, icons blink.
2. Serial: Connect Teensy, ensure `/dev/ttyACM0` exists, restart. Log shows `[io_teensy] Opened serial ...`. Values update with real data.
3. Different port: `export TEENSY_DEV=/dev/ttyACM1 && python src/main.py`.
4. Splash: Logo up to 1.2 s or shorter if first frame arrives earlier.

## TODO
- Backlight: BL_EN / DIM via additional commands to Teensy.
- Better icons (SVG / Path) and animations.
- FPS / vsync tuning or capping.

## License
MIT (adjust if needed).
