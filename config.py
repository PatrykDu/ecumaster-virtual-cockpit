"""Global configuration.

The UI was originally authored for a 1920x720 logical canvas. The target
hardware now uses 1280x480 (same 8:3 aspect). To avoid hand‑editing every
pixel constant we keep the original design resolution (DESIGN_WIDTH/HEIGHT)
and scale the whole scene uniformly to the target (WIDTH/HEIGHT).

Any new hard pixel values added in QML should normally refer to the logical
design coordinate system (DESIGN_*), so they will scale automatically.
"""

# TARGET (physical) resolution
WIDTH = 1280
HEIGHT = 480

# ORIGINAL logical design resolution (do not change unless redesigning)
DESIGN_WIDTH = 1920
DESIGN_HEIGHT = 720

# Derived scale (exported to QML via context for convenience)
SCALE = WIDTH / DESIGN_WIDTH  # = 2/3 for 1280->1920

# SERIAL
SERIAL_DEV = "/dev/ttyACM0"
BAUD = 2_000_000

# DEMO
DEMO_FALLBACK = True

# FRAME
FRAME_MAGIC = 0xA55A
FRAME_VERSION = 1
FRAME_LEN_BYTES = 14
