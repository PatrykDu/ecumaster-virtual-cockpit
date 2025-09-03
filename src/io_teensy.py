from __future__ import annotations
import os, struct, threading, time, sys
import crcmod, serial  # type: ignore
from telemetry import Telemetry
import config

_crc_func = crcmod.mkCrcFun(0x11021, rev=True, initCrc=0xFFFF, xorOut=0xFFFF)

class TeensyReader(threading.Thread):
    def __init__(self, telemetry: Telemetry):
        super().__init__(daemon=True)
        self.telemetry = telemetry
        self.stop_event = threading.Event()
        self.port = None

    def open_serial(self):
        dev = os.environ.get("TEENSY_DEV", config.SERIAL_DEV)
        try:
            self.port = serial.Serial(dev, config.BAUD, timeout=0.05)
            print(f"[io_teensy] Opened serial {dev} @ {config.BAUD}")
        except Exception as e:
            print(f"[io_teensy] Serial open failed ({e})")
            self.port = None

    def run(self):
        self.open_serial()
        buf = bytearray()
        while not self.stop_event.is_set():
            if self.port is None:
                self.open_serial()
                if self.port is None:
                    time.sleep(1.0)
                    continue
            else:
                try:
                    chunk = self.port.read(64)
                    if chunk:
                        buf.extend(chunk)
                        self._consume_buffer(buf)
                    else:
                        time.sleep(0.002)
                except Exception as e:
                    print(f"[io_teensy] Serial error: {e}; disconnecting")
                    self.port = None
        if self.port:
            try:
                self.port.close()
            except Exception:
                pass

    def _consume_buffer(self, buf: bytearray):
        FRAME_LEN = config.FRAME_LEN_BYTES
        while len(buf) >= FRAME_LEN:
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

def start_serial(telemetry: Telemetry):
    reader = TeensyReader(telemetry)
    reader.start()
    return reader

if __name__ == '__main__':
    tel = Telemetry()
    start_serial(tel)
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        sys.exit(0)
