from __future__ import annotations
import os, time, math
from PySide6.QtCore import QTimer

# Provides synthetic telemetry values and automated menu navigation.

TRI = lambda t, p: ((t % p) / p * 2.0) if ((t % p) / p) < 0.5 else 2.0 - ((t % p) / p) * 2.0

def demo_tick(tel, t: float):
    """Generate synthetic data (mirrors previous Telemetry.demoTick)."""
    def tri(time_s: float, period: float) -> float:
        ph = (time_s % period) / period
        return ph * 2.0 if ph < 0.5 else 2.0 - ph * 2.0

    rpm_frac = tri(t, 6.0)
    rpm = int(rpm_frac * 7000)
    speed = rpm_frac * 230.0
    fuel_val = int(tri(t, 22.0) * 100)

    water_temp = int(40 + tri(t * 0.85, 14.0) * 100)
    oil_temp   = int(20 + tri(t * 0.80 + 1.3, 15.0) * 120)
    charging_volt = 11.0 + tri(t * 0.95, 11.0) * 5.0
    oil_press = tri(t * 1.10, 7.5) * 8.0
    afr_val = 10.0 + tri(t * 0.75 + 0.4, 13.0) * 8.0

    blink_left = int((t * 1.5) % 2) == 0
    blink_right = not blink_left
    high_beam = rpm > 6000
    park = int((t / 10) % 2) == 0
    check_engine = int((t / 15) % 30) == 0
    low_beam = True
    fog_rear = int((t / 5) % 2) == 0
    underglow = int((t * 0.5) % 2) == 0

    tel.setRpm(rpm)
    tel.setSpeed(speed)
    tel.setLeftBlink(blink_left)
    tel.setRightBlink(blink_right)
    tel.setHighBeam(high_beam)
    tel.setPark(park)
    tel.setFuel(fuel_val)
    tel.setWaterTemp(water_temp)
    tel.setOilTemp(oil_temp)
    tel.setCheckEngine(check_engine)
    tel.setLowBeam(low_beam)
    tel.setFogRear(fog_rear)
    tel.setUnderglow(underglow)
    tel.setCharging(int((t / 7) % 2) == 0 and rpm > 2500)
    tel.setAbs(int((t / 11) % 3) == 0 and speed > 80)
    tel.setWheelPressure(int((t / 9) % 2) == 0 and fuel_val < 30)
    tel.setAfr(afr_val)
    tel.setChargingVolt(charging_volt)
    tel.setOilPressure(oil_press)
    if not tel._got_first:  # pylint: disable=protected-access
        tel._got_first = True
        tel.firstFrameReceived.emit()


def start_demo(tel):
    """Start periodic synthetic telemetry + automated menu navigation.

    Timery są przypięte do obiektu telemetry (parent) aby nie zostały
    odgarbagecollectowane i aby wartości aktualizowały wskazówki.
    """
    start_t = time.time()
    demo_timer = QTimer(tel)
    demo_timer.setInterval(16)
    def _tick():
        demo_tick(tel, time.time() - start_t)
    demo_timer.timeout.connect(_tick)
    demo_timer.start()

    # Automated navigation sequence
    delay = 2000
    nav_actions = [
        ("right", delay),   # open menu
        ("right", delay),   # enter suspension
        ("left", delay),    # exit suspension
        ("down", delay),    # move to exhaust
        ("right", delay),   # enter exhaust
        ("left", delay),    # exit exhaust
        ("down", delay),    # highlight reset trip (skip activation)
        ("down", delay),    # move to settings
        ("right", delay),   # enter settings (longer animation)
        ("left", delay),    # exit settings
        ("down", delay),    # move to suspension
        ("left", delay)     # close menu fully + idle
    ]
    idx = { 'i': 0 }
    nav_timer = QTimer(tel); nav_timer.setSingleShot(True)

    def _nav_step():
        if os.environ.get("DEVELOP_MODE") != "2":
            return
        action, delay = nav_actions[idx['i']]
        if action == 'right':
            tel.invokeNavRight()
        elif action == 'left':
            tel.invokeNavLeft()
        elif action == 'down':
            tel.invokeNavDown()
        elif action == 'up':
            tel.invokeNavUp()
        idx['i'] = (idx['i'] + 1) % len(nav_actions)
        nav_timer.setInterval(delay)
        nav_timer.start()

    nav_timer.timeout.connect(_nav_step)
    QTimer.singleShot(3000, _nav_step)
    try:
        tel._demo_timer = demo_timer  # type: ignore[attr-defined]
        tel._demo_nav_timer = nav_timer  # type: ignore[attr-defined]
    except Exception:
        pass
    print('[DEMO] Synthetic telemetry + menu automation started')
    return demo_timer, nav_timer
