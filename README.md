# Virtual Cluster (PySide6/QML)

Wirtualne zegary silnika (RPM + Speed) z danymi z Teensy 4.1 (EMU Black CAN) lub trybem DEMO.

## Funkcje
- PySide6 + QML (pełnoekranowe, 60 FPS)
- Splash + płynne przejście do sceny głównej
- Dwie tarcze: RPM (0–8000, czerwone od 6500), prędkość (0–220 km/h)
- Ikony: kierunki L/P, długie, przeciwmgłowe, hamulec/park (placeholdery)
- Automatyczne przełączenie na DEMO jeśli brak Teensy / portu
- Parametry rozdzielczości w `config.py` (1920×720 domyślnie; można zmienić na 1280×480)

## Wymagania
Python 3.11+

## Instalacja (PC / Linux)
```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/main.py
```
Tryb DEMO uruchomi się automatycznie (brak portu /dev/ttyACM0).

## Instalacja na Raspberry Pi (Raspberry Pi OS Lite 64-bit)
```bash
sudo apt update
sudo apt install -y python3-venv python3-pip libegl1 libgles2 libxcb-xinerama0
cd ~/<katalog_repo>
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python src/main.py  # test
```

### Ustawienia HDMI w `/boot/firmware/cmdline.txt` (Pi OS Bookworm)
Dodaj do istniejącej linii (nie w nowej):
```
video=HDMI-A-1:1920x720@60D quiet loglevel=0 vt.global_cursor_default=0
```
Dla 1280×480:
```
video=HDMI-A-1:1280x480@60D quiet loglevel=0 vt.global_cursor_default=0
```

### Autostart (systemd)
Zaktualizuj ścieżkę w `systemd/gauges.service` jeśli repo jest w innej lokalizacji niż `/home/pi/virtual-cluster`.
```bash
sudo cp systemd/gauges.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable gauges.service
sudo systemctl start gauges.service
```

## Zmiana rozdzielczości
Edytuj `config.py`:
```python
WIDTH = 1280
HEIGHT = 480
```
Uruchom ponownie aplikację.

## Zmienne środowiskowe
`TEENSY_DEV` – niestandardowa ścieżka urządzenia (np. `/dev/ttyACM1`).

## Format ramki z Teensy
Binarnie (little-endian) 14 bajtów:
```
MAGIC(u16)=0xA55A, VER(u8)=1, LEN(u8)=14, RPM(u16), VSS_cm_s(u16), FLAGS(u16), CRC16-X25(u16)
```
FLAGS bity:
```
0: Left
1: Right
2: HighBeam
3: Fog
4: Park/Brake
```
Prędkość: `km/h = (VSS_cm_s / 100.0) * 0.036`.

## Testy manualne
1. DEMO: Odłącz Teensy / brak portu. Uruchom `python src/main.py` → tarcze animują się, ikonki migają.
2. Serial: Podłącz Teensy, upewnij się że widoczny `/dev/ttyACM0`, uruchom ponownie. W logu: `[io_teensy] Opened serial ...`. Wartości odpowiadają realnym danym.
3. Inny port: `export TEENSY_DEV=/dev/ttyACM1 && python src/main.py`.
4. Splash: Logo do 1.2 s lub krócej jeśli przyjdzie pierwsza ramka.

## TODO
- Backlight: BL_EN / DIM przez dodatkowe komendy do Teensy.
- Lepsze ikonki (SVG / Path) i animacje.
- Limit FPS / vsync tuning.

## Licencja
MIT (domyślnie – dostosuj w razie potrzeby).
