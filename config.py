# Global configuration for virtual cluster
# Resolution parameters (modifiable for 1920x720 or 1280x480)
WIDTH = 1920
HEIGHT = 720

# Serial communication
SERIAL_DEV = "/dev/ttyACM0"  # Default Teensy CDC device
BAUD = 2_000_000

# Demo fallback if serial not available
DEMO_FALLBACK = True

# Frame format constants
FRAME_MAGIC = 0xA55A
FRAME_VERSION = 1
# Bytes: MAGIC(2) + VER(1) + LEN(1) + RPM(2) + VSS_cm_s(2) + FLAGS(2) + CRC(2) = 14
FRAME_LEN_BYTES = 14

# RPM & speed scaling
MAX_RPM = 8000
MAX_SPEED_KMH = 220

# Timeout (ms) before leaving splash if no real data
SPLASH_TIMEOUT_MS = 1200

# TODO: Future: brightness / backlight control via Teensy (BL_EN, DIM)
