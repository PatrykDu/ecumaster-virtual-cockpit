from __future__ import annotations
from PySide6.QtCore import QObject, Signal, Property, QMutex, QMutexLocker, Slot, QTimer
import os, json, math, time

# TELEMETRY OBJECT

class Telemetry(QObject):
    rpmChanged = Signal(int)
    speedChanged = Signal(float)
    tripChanged = Signal(float)  # emits displayed trip (0.1 km resolution)
    odometerChanged = Signal(int)  # emits whole km odometer
    leftBlinkChanged = Signal(bool)
    rightBlinkChanged = Signal(bool)
    highBeamChanged = Signal(bool)
    lowBeamChanged = Signal(bool)
    fogRearChanged = Signal(bool)
    parkChanged = Signal(bool)
    firstFrameReceived = Signal()
    fuelChanged = Signal(int)
    waterTempChanged = Signal(int)
    oilTempChanged = Signal(int)
    checkEngineChanged = Signal(bool)
    underglowChanged = Signal(bool)
    chargingChanged = Signal(bool)
    absChanged = Signal(bool)
    wheelPressureChanged = Signal(bool)
    afrChanged = Signal(float)
    chargingVoltChanged = Signal(float)
    oilPressureChanged = Signal(float)

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
        self._lowBeam = False
        self._fogRear = False
        self._park = False
        self._underglow = False
        self._fuel = 0
        self._waterTemp = 0
        self._oilTemp = 0
        self._checkEngine = False
        self._got_first = False
        self._mtx = QMutex()
        self._charging = False
        self._abs = False
        self._wheelPressure = False
        self._afr = 14.7  # Air-Fuel Ratio (stoich baseline)
        self._chargingVolt = 14.2  # Battery/charging voltage
        self._oilPressure = 0.0  # bar
    # Distance / odometer tracking
        self._odometer_km = 0.0  # accumulated precise odometer (km, fractional)
        self._trip_precise_km = 0.0  # precise trip distance (km, fractional)
        self._last_trip_saved_tenth = 0  # last persisted trip tenth (trip * 10 as int)
        self._last_odo_saved_int = 0  # last emitted odometer whole km (int)
        self._last_odo_saved_tenth = 0  # last persisted odometer tenth (odometer *10)
        self._last_speed_time = None  # set on first speed sample
        self._last_speed_value = 0.0
        self._distance_enabled = True  # could expose toggle later

        # Attempt to load persisted odometer/trip so we continue counting
        try:
            data_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'data', 'data.json'))
            if os.path.isfile(data_path):
                with open(data_path, 'r', encoding='utf-8') as f:
                    obj = json.load(f) or {}
                if isinstance(obj.get('odometer'), (int, float)):
                    self._odometer_km = float(obj['odometer'])
                    self._last_odo_saved_int = int(self._odometer_km)
                    self._last_odo_saved_tenth = int(self._odometer_km * 10 + 1e-6)
                if isinstance(obj.get('trip'), (int, float)):
                    self._trip_precise_km = float(obj['trip'])
                    self._last_trip_saved_tenth = int(self._trip_precise_km * 10 + 1e-6)
        except Exception as e:
            print(f"[Telemetry:init] load distance error: {e}")

        # Periodic distance integration (ensures accumulation even with steady speed)
        self._distance_timer = QTimer()
        self._distance_timer.setInterval(500)  # 0.5s -> resolution ~14 m at 100 km/h
        self._distance_timer.timeout.connect(self._distance_tick)
        self._distance_timer.start()

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
        # Just record speed; periodic timer integrates.
        if self._last_speed_time is None:
            self._last_speed_time = time.monotonic()
        self._last_speed_value = v
        if v != self._speed:
            self._speed = v
            self.speedChanged.emit(v)

    # Expose properties for direct QML binding (optional)
    def getTrip(self) -> float:
        # Displayed trip rounded down to 0.1 km like persistence logic
        return self._last_trip_saved_tenth / 10.0

    def getOdometer(self) -> int:
        return self._last_odo_saved_int

    trip = Property(float, getTrip, notify=tripChanged)
    odometer = Property(int, getOdometer, notify=odometerChanged)

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

    # LOW BEAM
    def getLowBeam(self) -> bool:
        return self._lowBeam

    def setLowBeam(self, v: bool):
        if v == self._lowBeam:
            return
        self._lowBeam = v
        self.lowBeamChanged.emit(v)

    lowBeam = Property(bool, getLowBeam, setLowBeam, notify=lowBeamChanged)

    # REAR FOG
    def getFogRear(self) -> bool:
        return self._fogRear

    def setFogRear(self, v: bool):
        if v == self._fogRear:
            return
        self._fogRear = v
        self.fogRearChanged.emit(v)

    fogRear = Property(bool, getFogRear, setFogRear, notify=fogRearChanged)

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

    # UNDERGLOW
    def getUnderglow(self) -> bool:
        return self._underglow

    def setUnderglow(self, v: bool):
        if v == self._underglow:
            return
        self._underglow = v
        self.underglowChanged.emit(v)

    underglow = Property(bool, getUnderglow, setUnderglow, notify=underglowChanged)

    # CHARGING (battery warning)
    def getCharging(self) -> bool:
        return self._charging

    def setCharging(self, v: bool):
        if v == self._charging:
            return
        self._charging = v
        self.chargingChanged.emit(v)

    charging = Property(bool, getCharging, setCharging, notify=chargingChanged)

    # ABS WARNING
    def getAbs(self) -> bool:
        return self._abs

    def setAbs(self, v: bool):
        if v == self._abs:
            return
        self._abs = v
        self.absChanged.emit(v)

    abs = Property(bool, getAbs, setAbs, notify=absChanged)

    # WHEEL PRESSURE WARNING
    def getWheelPressure(self) -> bool:
        return self._wheelPressure

    def setWheelPressure(self, v: bool):
        if v == self._wheelPressure:
            return
        self._wheelPressure = v
        self.wheelPressureChanged.emit(v)

    wheelPressure = Property(bool, getWheelPressure, setWheelPressure, notify=wheelPressureChanged)

    # AFR (Air-Fuel Ratio)
    def getAfr(self) -> float:
        return self._afr

    def setAfr(self, v: float):
        # Clamp broader dev range 0..25 (gauge still visualizes 10..18 window)
        if v < 0.0: v = 0.0
        if v > 25.0: v = 25.0
        # Avoid excessive signal spam for tiny fluctuations <0.01
        if abs(v - self._afr) < 0.01:
            return
        self._afr = v
        self.afrChanged.emit(v)

    afr = Property(float, getAfr, setAfr, notify=afrChanged)

    # CHARGING VOLTAGE (separate from boolean warning)
    def getChargingVolt(self) -> float:
        return self._chargingVolt

    def setChargingVolt(self, v: float):
        # Accept a broad engineering range; gauge will clamp visually 10..16
        if v < 0.0: v = 0.0
        if v > 20.0: v = 20.0
        if abs(v - self._chargingVolt) < 0.01:
            return
        self._chargingVolt = v
        self.chargingVoltChanged.emit(v)

    chargingVolt = Property(float, getChargingVolt, setChargingVolt, notify=chargingVoltChanged)

    # OIL PRESSURE (bar)
    def getOilPressure(self) -> float:
        return self._oilPressure

    def setOilPressure(self, v: float):
        if v < 0.0: v = 0.0
        if v > 10.0: v = 10.0
        if abs(v - self._oilPressure) < 0.01:
            return
        self._oilPressure = v
        self.oilPressureChanged.emit(v)

    oilPressure = Property(float, getOilPressure, setOilPressure, notify=oilPressureChanged)

    def updateFromFrame(self, rpm: int, speed_kmh: float, flags: int):
        with QMutexLocker(self._mtx):
            self.setRpm(rpm)
            self.setSpeed(speed_kmh)
            self.setLeftBlink(bool(flags & (1 << 0)))
            self.setRightBlink(bool(flags & (1 << 1)))
            self.setHighBeam(bool(flags & (1 << 2)))
            # bit3 previously fog (removed)
            self.setPark(bool(flags & (1 << 3)))
            self.setFuel((flags >> 4) & 0xFF)
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
        park = int((t / 10) % 2) == 0
        check_engine = int((t / 15) % 30) == 0  # brief flash every 15s
        low_beam = True  # keep on for demo
        fog_rear = int((t / 5) % 2) == 0
        underglow = int((t * 0.5) % 2) == 0  # slow pulse

        # Pack flags: bits0..4 booleans, bits5-12 fuel (8 bits)
        # bit0 leftBlink, bit1 rightBlink, bit2 highBeam, bit3 park, bits4-11 fuel
        flags = (
            (1 if blink_left else 0) |
            ((1 if blink_right else 0) << 1) |
            ((1 if high_beam else 0) << 2) |
            ((1 if park else 0) << 3) |
            ((fuel_val & 0xFF) << 4)
        )

        self.updateFromFrame(rpm, speed, flags)
        # Override temps + check engine each tick (not in frame spec)
        self.setWaterTemp(water_temp)
        self.setOilTemp(oil_temp)
        self.setCheckEngine(check_engine)
        self.setLowBeam(low_beam)
        self.setFogRear(fog_rear)
        self.setUnderglow(underglow)
        # Demo patterns for new indicators (simple periodic toggles)
        self.setCharging(int((t / 7) % 2) == 0 and rpm > 2500)
        self.setAbs(int((t / 11) % 3) == 0 and speed > 80)
        self.setWheelPressure(int((t / 9) % 2) == 0 and fuel_val < 30)
        # AFR oscillation: center 14.4..15.0 with occasional rich dip
        afr_base = 14.7 + math.sin(t * 0.8) * 0.6  # 14.1..15.3
        if int(t) % 7 == 0:  # brief rich event
            afr_base -= 2.0 * max(0.0, 0.5 - ((t % 7) * 0.5))  # quick dip
        self.setAfr(afr_base)
        # Charging voltage slight ripple 14.0..14.5 with occasional dips/spikes
        volt = 14.25 + math.sin(t * 0.35) * 0.25
        if int(t) % 19 == 0:
            volt += 0.6 * math.sin(t * 3.0)  # brief spike ripple
        if int(t) % 23 == 0:
            volt -= 0.8 * math.sin(t * 4.0)  # brief dip ripple
        self.setChargingVolt(volt)
        # Oil pressure simulated: rises with rpm, small noise
        press = max(0.0, min(8.0, 1.0 + (self._rpm / 7000.0) * 5.5 + math.sin(t * 1.1) * 0.4))
        self.setOilPressure(press)

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
            # If trip reset requested (value == 0), also reset internal precise counters
            if abs(trip_value) < 1e-9:
                self._trip_precise_km = 0.0
                self._last_trip_saved_tenth = 0
                try:
                    self.tripChanged.emit(0.0)
                except Exception:
                    pass
        except Exception as e:
            print(f"[saveTrip] error: {e}")

    # --- INTERNAL DISTANCE INTEGRATION LOGIC ---
    def _accumulate_distance(self, dist_km: float):
        """Accumulate distance travelled (km) updating trip/odometer thresholds.

        Rules:
        - Trip persists each 0.1 km (100 m) increment
        - Odometer persists each 1 km increment
        This keeps file writes modest while providing required resolution.
        """
        self._trip_precise_km += dist_km
        self._odometer_km += dist_km

        # Trip threshold (0.1 km)
        new_trip_tenth = int(self._trip_precise_km * 10 + 1e-6)
        if new_trip_tenth > self._last_trip_saved_tenth:
            # Write every missing 0.1 so UI (polling) can catch intermediate states
            while self._last_trip_saved_tenth < new_trip_tenth:
                self._last_trip_saved_tenth += 1
                trip_to_store = self._last_trip_saved_tenth / 10.0
                try:
                    self.saveTrip(trip_to_store)
                    self.tripChanged.emit(trip_to_store)
                except Exception:
                    break

        # Odometer threshold (1 km)
        # Odometer persistence: save every 0.1 km but only emit signal on whole km
        new_odo_tenth = int(self._odometer_km * 10 + 1e-6)
        if new_odo_tenth > self._last_odo_saved_tenth:
            while self._last_odo_saved_tenth < new_odo_tenth:
                self._last_odo_saved_tenth += 1
                odo_to_store = self._last_odo_saved_tenth / 10.0
                try:
                    self.saveOdometer(odo_to_store)
                except Exception:
                    break
        new_odo_int = new_odo_tenth // 10
        if new_odo_int > self._last_odo_saved_int:
            self._last_odo_saved_int = new_odo_int
            try:
                self.odometerChanged.emit(self._last_odo_saved_int)
            except Exception:
                pass

    # Optional helper for external debug/testing
    def debugGetDistances(self):
        return {
            'odometer_km_precise': self._odometer_km,
            'trip_km_precise': self._trip_precise_km,
            'trip_saved_tenth': self._last_trip_saved_tenth,
            'odometer_saved_int': self._last_odo_saved_int,
            'odometer_saved_tenth': self._last_odo_saved_tenth
        }

    def _distance_tick(self):
        if not self._distance_enabled or self._last_speed_time is None:
            return
        try:
            now = time.monotonic()
            dt = now - self._last_speed_time
            if dt <= 0:
                return
            if self._last_speed_value <= 0:
                self._last_speed_time = now
                return
            # Clamp dt to avoid huge jumps after pauses (e.g., app start/sleep)
            if dt > 5.0:
                dt = 1.0  # treat as one second of travel at current speed
            dist_km = self._last_speed_value * (dt / 3600.0)
            if dist_km > 0:
                self._accumulate_distance(dist_km)
            self._last_speed_time = now
        except Exception as e:
            print(f"[Telemetry:_distance_tick] error: {e}")
