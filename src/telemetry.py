from __future__ import annotations
from PySide6.QtCore import QObject, Signal, Property, QMutex, QMutexLocker, Slot
import os, json

# TELEMETRY OBJECT

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
    checkEngineChanged = Signal(bool)

    # NAV EVENTS
    navUpEvent = Signal()
    navDownEvent = Signal()
    navLeftEvent = Signal()
    navRightEvent = Signal()

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
        self._checkEngine = False
        self._got_first = False
        self._mtx = QMutex()

    # NAV SLOTS
    @Slot()
    def invokeNavUp(self):
        self.navUpEvent.emit()

    @Slot()
    def invokeNavDown(self):
        self.navDownEvent.emit()

    @Slot()
    def invokeNavLeft(self):
        self.navLeftEvent.emit()

    @Slot()
    def invokeNavRight(self):
        self.navRightEvent.emit()

    # RPM
    def getRpm(self) -> int:
        return self._rpm

    def setRpm(self, v: int):
        if v == self._rpm:
            return
        self._rpm = v
        self.rpmChanged.emit(v)

    rpm = Property(int, getRpm, setRpm, notify=rpmChanged)

    # SPEED
    def getSpeed(self) -> float:
        return self._speed

    def setSpeed(self, v: float):
        if v == self._speed:
            return
        self._speed = v
        self.speedChanged.emit(v)

    speed = Property(float, getSpeed, setSpeed, notify=speedChanged)

    # LEFT BLINK
    def getLeftBlink(self) -> bool:
        return self._leftBlink

    def setLeftBlink(self, v: bool):
        if v == self._leftBlink:
            return
        self._leftBlink = v
        self.leftBlinkChanged.emit(v)

    leftBlink = Property(bool, getLeftBlink, setLeftBlink, notify=leftBlinkChanged)

    # RIGHT BLINK
    def getRightBlink(self) -> bool:
        return self._rightBlink

    def setRightBlink(self, v: bool):
        if v == self._rightBlink:
            return
        self._rightBlink = v
        self.rightBlinkChanged.emit(v)

    rightBlink = Property(bool, getRightBlink, setRightBlink, notify=rightBlinkChanged)

    # HIGH BEAM
    def getHighBeam(self) -> bool:
        return self._highBeam

    def setHighBeam(self, v: bool):
        if v == self._highBeam:
            return
        self._highBeam = v
        self.highBeamChanged.emit(v)

    highBeam = Property(bool, getHighBeam, setHighBeam, notify=highBeamChanged)

    # FOG
    def getFog(self) -> bool:
        return self._fog

    def setFog(self, v: bool):
        if v == self._fog:
            return
        self._fog = v
        self.fogChanged.emit(v)

    fog = Property(bool, getFog, setFog, notify=fogChanged)

    # PARK
    def getPark(self) -> bool:
        return self._park

    def setPark(self, v: bool):
        if v == self._park:
            return
        self._park = v
        self.parkChanged.emit(v)

    park = Property(bool, getPark, setPark, notify=parkChanged)

    # FUEL
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

    # WATER TEMP
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

    # OIL TEMP
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

    # CHECK ENGINE
    def getCheckEngine(self) -> bool:
        return self._checkEngine

    def setCheckEngine(self, v: bool):
        if v == self._checkEngine:
            return
        self._checkEngine = v
        self.checkEngineChanged.emit(v)

    checkEngine = Property(bool, getCheckEngine, setCheckEngine, notify=checkEngineChanged)

    def updateFromFrame(self, rpm: int, speed_kmh: float, flags: int):
        with QMutexLocker(self._mtx):
            self.setRpm(rpm)
            self.setSpeed(speed_kmh)
            self.setLeftBlink(bool(flags & (1 << 0)))
            self.setRightBlink(bool(flags & (1 << 1)))
            self.setHighBeam(bool(flags & (1 << 2)))
            self.setFog(bool(flags & (1 << 3)))
            self.setPark(bool(flags & (1 << 4)))
            self.setFuel((flags >> 5) & 0xFF)
            self.setWaterTemp(min(150, int(self._fuel * 1.5)))
            est_oil = int(self._waterTemp * 0.9 + 10)
            self.setOilTemp(est_oil)
            if not self._got_first:
                self._got_first = True
                self.firstFrameReceived.emit()

    def demoTick(self, t: float):
        # DEMO FULL STATE (simulate everything adjustable in DevPanel except nav arrows)
        # RPM/SPEED triangle wave (fast)
        base_period = 6.0
        phase = (t % base_period) / base_period  # 0..1
        if phase < 0.5:
            frac = phase * 2.0
        else:
            frac = 2.0 - phase * 2.0
        rpm = int(frac * 7800)  # cap near redline
        speed = frac * 230.0

        # Fuel slower saw/triangle (0..100)
        fuel_period = 22.0
        f_phase = (t % fuel_period) / fuel_period
        if f_phase < 0.5:
            fuel_frac = f_phase * 2.0
        else:
            fuel_frac = 2.0 - f_phase * 2.0
        fuel_val = int(fuel_frac * 100)

        # Temps derived with slight lag / scaling
        water_period = 30.0
        w_phase = (t % water_period) / water_period
        if w_phase < 0.5:
            w_frac = w_phase * 2.0
        else:
            w_frac = 2.0 - w_phase * 2.0
        water_temp = int(60 + w_frac * 90)  # 60..150
        oil_temp = int(50 + w_frac * 95)    # 50..145

        # Indicators / lights patterns
        blink_left = int((t * 1.5) % 2) == 0
        blink_right = not blink_left
        high_beam = rpm > 6000  # same logic as before
        fog = int((t / 4) % 2) == 0
        park = int((t / 10) % 2) == 0
        check_engine = int((t / 15) % 30) == 0  # brief flash every 15s

        # Pack flags: bits0..4 booleans, bits5-12 fuel (8 bits)
        flags = (
            (1 if blink_left else 0) |
            ((1 if blink_right else 0) << 1) |
            ((1 if high_beam else 0) << 2) |
            ((1 if fog else 0) << 3) |
            ((1 if park else 0) << 4) |
            ((fuel_val & 0xFF) << 5)
        )

        self.updateFromFrame(rpm, speed, flags)
        # Override temps + check engine each tick (not in frame spec)
        self.setWaterTemp(water_temp)
        self.setOilTemp(oil_temp)
        self.setCheckEngine(check_engine)

    # PERSISTENCE
    @Slot(int, int, int, int)
    def saveSuspension(self, fr: int, fl: int, rr: int, rl: int):
        """Persist suspension values to data/data.json (merging with existing fields)."""
        try:
            data_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'data.json'))
            obj = {}
            if os.path.isfile(data_path):
                try:
                    with open(data_path, 'r', encoding='utf-8') as f:
                        obj = json.load(f) or {}
                except Exception:
                    obj = {}
            obj['fr'] = fr
            obj['fl'] = fl
            obj['rr'] = rr
            obj['rl'] = rl
            # keep odometer/trip if present unchanged
            with open(data_path, 'w', encoding='utf-8') as f:
                json.dump(obj, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"[saveSuspension] error: {e}")

    @Slot(bool)
    def saveExhaust(self, exhaust_enabled: bool):
        """Persist exhaust value to data/data.json, merging with existing keys."""
        try:
            data_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'data.json'))
            obj = {}
            if os.path.isfile(data_path):
                try:
                    with open(data_path, 'r', encoding='utf-8') as f:
                        obj = json.load(f) or {}
                except Exception:
                    obj = {}
            obj['exhaust'] = bool(exhaust_enabled)
            with open(data_path, 'w', encoding='utf-8') as f:
                json.dump(obj, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"[saveExhaust] error: {e}")

    @Slot(float)
    def saveOdometer(self, odometer_value: float):
        """Persist odometer (float) to data/data.json, merging with existing keys."""
        try:
            data_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'data.json'))
            obj = {}
            if os.path.isfile(data_path):
                try:
                    with open(data_path, 'r', encoding='utf-8') as f:
                        obj = json.load(f) or {}
                except Exception:
                    obj = {}
            obj['odometer'] = float(odometer_value)
            with open(data_path, 'w', encoding='utf-8') as f:
                json.dump(obj, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"[saveOdometer] error: {e}")

    @Slot(float)
    def saveTrip(self, trip_value: float):
        """Persist trip (float) to data/data.json, merging with existing keys."""
        try:
            data_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'data.json'))
            obj = {}
            if os.path.isfile(data_path):
                try:
                    with open(data_path, 'r', encoding='utf-8') as f:
                        obj = json.load(f) or {}
                except Exception:
                    obj = {}
            obj['trip'] = float(trip_value)
            with open(data_path, 'w', encoding='utf-8') as f:
                json.dump(obj, f, ensure_ascii=False, indent=2)
        except Exception as e:
            print(f"[saveTrip] error: {e}")
