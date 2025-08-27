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
    fuelChanged = Signal(int)  # 0..100 percent
    waterTempChanged = Signal(int)  # coolant temperature (0..150 C)
    oilTempChanged = Signal(int)  # oil temperature (0..160 C typical)

    def __init__(self):
        super().__init__()
        self._rpm = 0
        self._speed = 0.0
        self._leftBlink = False
        self._rightBlink = False
        self._highBeam = False
        self._fog = False
        self._park = False
        self._fuel = 0  # percent
        self._waterTemp = 0  # degrees C (0..150)
        self._oilTemp = 0  # degrees C (0..160)
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

    # Fuel (0-100%)
    def getFuel(self) -> int:
        return self._fuel

    def setFuel(self, v: int):
        if v < 0: v = 0
        if v > 100: v = 100
        if v == self._fuel:
            return
        self._fuel = v
        self.fuelChanged.emit(v)

    fuel = Property(int, getFuel, setFuel, notify=fuelChanged)

    # Water temperature (0-150 C)
    def getWaterTemp(self) -> int:
        return self._waterTemp

    def setWaterTemp(self, v: int):
        if v < 0: v = 0
        if v > 150: v = 150
        if v == self._waterTemp:
            return
        self._waterTemp = v
        self.waterTempChanged.emit(v)

    waterTemp = Property(int, getWaterTemp, setWaterTemp, notify=waterTempChanged)

    # Oil temperature (0-160 C)
    def getOilTemp(self) -> int:
        return self._oilTemp

    def setOilTemp(self, v: int):
        if v < 0: v = 0
        if v > 160: v = 160
        if v == self._oilTemp:
            return
        self._oilTemp = v
        self.oilTempChanged.emit(v)

    oilTemp = Property(int, getOilTemp, setOilTemp, notify=oilTempChanged)

    def updateFromFrame(self, rpm: int, speed_kmh: float, flags: int):
        with QMutexLocker(self._mtx):
            self.setRpm(rpm)
            self.setSpeed(speed_kmh)
            self.setLeftBlink(bool(flags & (1 << 0)))
            self.setRightBlink(bool(flags & (1 << 1)))
            self.setHighBeam(bool(flags & (1 << 2)))
            self.setFog(bool(flags & (1 << 3)))
            self.setPark(bool(flags & (1 << 4)))
            # Update fuel level from flags (example)
            self.setFuel((flags >> 5) & 0xFF)
            # Water temp demo mapping (reuse fuel for now if not present)
            self.setWaterTemp(min(150, int(self._fuel * 1.5)))
            # Oil temp typically lags water temp; simple smoothing / offset demo
            est_oil = int(self._waterTemp * 0.9 + 10)
            self.setOilTemp(est_oil)
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
        # Demo gradual warm-up of oil temp if not driven by real frames
        # (If real frames present, updateFromFrame already sets values)
        if not self._got_first:
            self.setWaterTemp(int(frac * 150))
            self.setOilTemp(int(frac * 160 * 0.85 + 15))
