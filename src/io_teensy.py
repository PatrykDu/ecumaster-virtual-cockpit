from __future__ import annotations
import os, struct, threading, time, sys
import crcmod, serial  # type: ignore
from PySide6.QtCore import QTimer
from telemetry import Telemetry
import config

# CRC16
_crc_func = crcmod.mkCrcFun(0x11021, rev=True, initCrc=0xFFFF, xorOut=0xFFFF)

class TeensyReader(threading.Thread):  # READER THREAD
    def __init__(self, telemetry: Telemetry, demo: bool):
        super().__init__(daemon=True)
        self.telemetry = telemetry
        self.demo = demo
        self.stop_event = threading.Event()
        self.port = None
        self.last_demo_t0 = time.time()

    def open_serial(self):
        dev = os.environ.get("TEENSY_DEV", config.SERIAL_DEV)
        try:
            self.port = serial.Serial(dev, config.BAUD, timeout=0.05)
            print(f"[io_teensy] Opened serial {dev} @ {config.BAUD}")
        except Exception as e:
            print(f"[io_teensy] Serial open failed ({e})")
            self.port = None

    def run(self):
        if not self.demo:
            self.open_serial()
        buf = bytearray()
        while not self.stop_event.is_set():
            if self.demo or self.port is None:
                self._demo_loop()
            else:
                try:
                    chunk = self.port.read(64)
                    if chunk:
                        buf.extend(chunk)
                        self._consume_buffer(buf)
                    else:
                        # small sleep to avoid busy loop
                        time.sleep(0.002)
                except Exception as e:
                    print(f"[io_teensy] Serial error: {e}; falling back to DEMO")
                    self.port = None
                    self.demo = True
        if self.port:
            try:
                self.port.close()
            except Exception:
                pass

    def _consume_buffer(self, buf: bytearray):
    # PARSE
        FRAME_LEN = config.FRAME_LEN_BYTES
        while len(buf) >= FRAME_LEN:
            # MAGIC
            if buf[0] != (config.FRAME_MAGIC & 0xFF) or (len(buf) >= 2 and buf[1] != (config.FRAME_MAGIC >> 8) & 0xFF):
                buf.pop(0)
                continue
            if len(buf) < FRAME_LEN:
                return
            frame = bytes(buf[:FRAME_LEN])
            del buf[:FRAME_LEN]
            try:
                magic, ver, ln, rpm, vss_cm_s, flags, crc = struct.unpack('<HBBHHHH', frame)
            except struct.error:
                continue
            if magic != config.FRAME_MAGIC or ver != config.FRAME_VERSION:
                continue
            if ln != FRAME_LEN:
                continue
            calc_crc = _crc_func(frame[:-2])
            if calc_crc != crc:
                continue
            speed_kmh = (vss_cm_s / 100.0) * 0.036
            self.telemetry.updateFromFrame(int(rpm), float(speed_kmh), int(flags))

    def _demo_loop(self):
        # Legacy thread-based demo (kept for fallback if serial disconnects after start)
        now = time.time()
        t = now - self.last_demo_t0
        self.telemetry.demoTick(t)
        time.sleep(1/60.0)


_demo_timer = None
_demo_start_t = None

def _start_demo_gui(telemetry: Telemetry):
    global _demo_timer, _demo_start_t
    if _demo_timer:
        return _demo_timer
    _demo_start_t = time.time()
    _demo_timer = QTimer()
    _demo_timer.setInterval(16)  # ~60 FPS
    def tick():
        try:
            t = time.time() - _demo_start_t
            telemetry.demoTick(t)
        except Exception as e:
            print(f"[io_teensy][demoTimer] error: {e}")
    _demo_timer.timeout.connect(tick)
    _demo_timer.start()
    print("[io_teensy] GUI demo timer started (60 FPS)")
    return _demo_timer

def start(telemetry: Telemetry):  # START
    # Attempt serial first unless forced demo via config
    if config.DEMO_FALLBACK:
        print("[io_teensy] DEMO_FALLBACK=True -> GUI demo mode")
        _start_demo_gui(telemetry)
        return None
    reader = TeensyReader(telemetry, demo=False)
    reader.open_serial()
    if reader.port is None:
        print("[io_teensy] No serial -> GUI demo mode")
        _start_demo_gui(telemetry)
        return None
    print("[io_teensy] Starting serial reader thread")
    reader.start()
    return reader

if __name__ == '__main__':  # TEST
    tel = Telemetry()
    start(tel)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        sys.exit(0)
