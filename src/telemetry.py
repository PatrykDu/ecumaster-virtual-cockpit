from __future__ import annotations
from PySide6.QtCore import QObject, Signal, Property, QMutex, QMutexLocker

# Telemetry object exposed to QML.
# Provides thread-safe property updates via signals.

class Telemetry(QObject):
    rpmChanged = Signal(int)
    speedChanged = Signal(float)
    leftBlinkChanged = Signal(bool)
    rightBlinkChanged = Signal(bool)
    highBeamChanged = Signal(bool)
    fogChanged = Signal(bool)
    parkChanged = Signal(bool)
    firstFrameReceived = Signal()

    def __init__(self):
        super().__init__()
        self._rpm = 0
        self._speed = 0.0
        self._leftBlink = False
        self._rightBlink = False
        self._highBeam = False
        self._fog = False
        self._park = False
        self._got_first = False
        self._mtx = QMutex()

    # RPM
    def getRpm(self) -> int:
        return self._rpm

    def setRpm(self, v: int):
        if v == self._rpm:
            return
        self._rpm = v
        self.rpmChanged.emit(v)

    rpm = Property(int, getRpm, setRpm, notify=rpmChanged)

    # Speed (km/h)
    def getSpeed(self) -> float:
        return self._speed

    def setSpeed(self, v: float):
        if v == self._speed:
            return
        self._speed = v
        self.speedChanged.emit(v)

    speed = Property(float, getSpeed, setSpeed, notify=speedChanged)

    # Left blink
    def getLeftBlink(self) -> bool:
        return self._leftBlink

    def setLeftBlink(self, v: bool):
        if v == self._leftBlink:
            return
        self._leftBlink = v
        self.leftBlinkChanged.emit(v)

    leftBlink = Property(bool, getLeftBlink, setLeftBlink, notify=leftBlinkChanged)

    # Right blink
    def getRightBlink(self) -> bool:
        return self._rightBlink

    def setRightBlink(self, v: bool):
        if v == self._rightBlink:
            return
        self._rightBlink = v
        self.rightBlinkChanged.emit(v)

    rightBlink = Property(bool, getRightBlink, setRightBlink, notify=rightBlinkChanged)

    # High beam
    def getHighBeam(self) -> bool:
        return self._highBeam

    def setHighBeam(self, v: bool):
        if v == self._highBeam:
            return
        self._highBeam = v
        self.highBeamChanged.emit(v)

    highBeam = Property(bool, getHighBeam, setHighBeam, notify=highBeamChanged)

    # Fog
    def getFog(self) -> bool:
        return self._fog

    def setFog(self, v: bool):
        if v == self._fog:
            return
        self._fog = v
        self.fogChanged.emit(v)

    fog = Property(bool, getFog, setFog, notify=fogChanged)

    # Park / Brake
    def getPark(self) -> bool:
        return self._park

    def setPark(self, v: bool):
        if v == self._park:
            return
        self._park = v
        self.parkChanged.emit(v)

    park = Property(bool, getPark, setPark, notify=parkChanged)

    def updateFromFrame(self, rpm: int, speed_kmh: float, flags: int):
        with QMutexLocker(self._mtx):
            self.setRpm(rpm)
            self.setSpeed(speed_kmh)
            self.setLeftBlink(bool(flags & (1 << 0)))
            self.setRightBlink(bool(flags & (1 << 1)))
            self.setHighBeam(bool(flags & (1 << 2)))
            self.setFog(bool(flags & (1 << 3)))
            self.setPark(bool(flags & (1 << 4)))
            if not self._got_first:
                self._got_first = True
                self.firstFrameReceived.emit()

    def demoTick(self, t: float):
        # Simple sine-like sweep without importing math heavy each frame.
        # Use triangular wave approximation.
        period = 5.0
        phase = (t % period) / period  # 0..1
        if phase < 0.5:
            frac = phase * 2.0
        else:
            frac = 2.0 - phase * 2.0
        rpm = int(frac * 8000)
        speed = frac * 220.0
        # Blinkers toggle every ~0.5s
        blink = int((t * 2) % 2) == 0
        self.updateFromFrame(rpm, speed, (
            (1 if blink else 0) | (1 if not blink else 0) << 1 | (1 << 2 if rpm > 6000 else 0)
        ))
