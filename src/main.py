from __future__ import annotations
import os, sys, json

# PATH SETUP
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
if PROJECT_ROOT not in sys.path: sys.path.insert(0, PROJECT_ROOT)

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import Qt, QUrl, qInstallMessageHandler, QtMsgType, QLibraryInfo

import config
from telemetry import Telemetry
import io_teensy


# QML LOG HANDLER
def _qt_msg_handler(mode, ctx, message):
    if mode in (QtMsgType.QtWarningMsg, QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg):
        print(f"[QML] {message}")


qInstallMessageHandler(_qt_msg_handler)


def _choose_platform_for_prod():
    """Minimal platform chooser (prod only). Prefers linuxfb, then eglfs, else minimal when headless.
       Respects existing QT_QPA_PLATFORM or DISPLAY. Adds light preflight for plugin presence."""
    if os.environ.get("QT_QPA_PLATFORM"):
        print(f"[PLATFORM] Keep user QT_QPA_PLATFORM={os.environ['QT_QPA_PLATFORM']}")
        return
    if os.environ.get("DISPLAY"):
        print("[PLATFORM] DISPLAY present -> desktop plugin auto")
        return
    have_fb = os.path.exists('/dev/fb0')
    have_dri = os.path.exists('/dev/dri/card0')
    order = [('linuxfb', have_fb), ('eglfs', have_dri)]
    chosen = next((n for n, ok in order if ok), 'minimal')
    # Preflight: ensure plugin library exists (skip for minimal)
    try:
        plat_dir = os.path.join(QLibraryInfo.path(QLibraryInfo.PluginsPath), 'platforms')
        def exists(p): return os.path.isfile(os.path.join(plat_dir, f'libq{p}.so'))
        if chosen != 'minimal' and not exists(chosen):
            alt = 'eglfs' if chosen == 'linuxfb' else 'linuxfb'
            if exists(alt):
                print(f"[PLATFORM] '{chosen}' missing, fallback -> {alt}")
                chosen = alt
            else:
                print(f"[PLATFORM] Neither linuxfb/eglfs available -> minimal")
                chosen = 'minimal'
    except Exception as e:
        print(f"[PLATFORM] preflight error: {e}")
    os.environ['QT_QPA_PLATFORM'] = chosen
    print(f"[PLATFORM] Using {chosen}")
    if chosen == 'linuxfb':
        # Remove stray eglfs vars that can confuse plugin loading
        removed = []
        for k in list(os.environ):
            if k.startswith('QT_QPA_EGLFS'):
                removed.append(k); del os.environ[k]
        if removed:
            print(f"[PLATFORM] linuxfb: cleared {', '.join(removed)}")
    # Headless rendering backend: prefer software RHI for stability
    if chosen in ('linuxfb','eglfs','minimal') and not os.environ.get('DISPLAY'):
        os.environ.setdefault('QSG_RHI_BACKEND','software')
    # Avoid legacy path forcing odd blending
    if os.environ.get('QT_QUICK_BACKEND'):
        try:
            del os.environ['QT_QUICK_BACKEND']
            print('[PLATFORM] Cleared QT_QUICK_BACKEND')
        except Exception:
            pass


def main():  # MAIN
    # Determine mode early
    dev_mode = os.environ.get("DEVELOP_MODE", "").lower() in ("1","true","yes","on")
    if dev_mode:
        # Dev: leave previous simple behaviour intact
        os.environ.setdefault("QML_XHR_ALLOW_FILE_READ", "1")
        os.environ.setdefault("QT_QUICK_BACKEND", "software")  # keep legacy path if you liked current look
    else:
        print("[MODE] Production startup -> platform auto-selection")
        os.environ.setdefault("QML_XHR_ALLOW_FILE_READ", "1")
        _choose_platform_for_prod()
    app = QGuiApplication(sys.argv)
    app.setApplicationName("VirtualCluster")

    tel = Telemetry()

    engine = QQmlApplicationEngine()
    # Expose both target and design sizes + scale so QML can adapt.
    engine.rootContext().setContextProperty("WIDTH", config.WIDTH)
    engine.rootContext().setContextProperty("HEIGHT", config.HEIGHT)
    engine.rootContext().setContextProperty("DESIGN_WIDTH", getattr(config, 'DESIGN_WIDTH', config.WIDTH))
    engine.rootContext().setContextProperty("DESIGN_HEIGHT", getattr(config, 'DESIGN_HEIGHT', config.HEIGHT))
    engine.rootContext().setContextProperty("SCALE", getattr(config, 'SCALE', 1.0))
    engine.rootContext().setContextProperty("TEL", tel)
    engine.rootContext().setContextProperty("DEV_MODE", dev_mode)

    # QML PATH
    qml_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'ui', 'Main.qml'))
    if not os.path.isfile(qml_path):
        print(f"QML not found: {qml_path}")
        return 1
    engine.load(QUrl.fromLocalFile(qml_path))

    if not engine.rootObjects():
        print("Failed to load QML (no root objects)")
        return 1

    win = engine.rootObjects()[0]
    # DATA LOAD
    data_path = os.path.join(PROJECT_ROOT, 'data', 'data.json')
    if os.path.isfile(data_path):
        try:
            with open(data_path, 'r', encoding='utf-8') as f:
                data_obj = json.load(f)
            key_map = [
                ('FR','fr'), ('FL','fl'), ('RR','rr'), ('RL','rl'),
                ('fr','fr'), ('fl','fl'), ('rr','rr'), ('rl','rl'),
                ('odometer','odometerValue'), ('trip','tripValue')
            ]
            for key_json, key_qml in key_map:
                if key_json in data_obj:
                    try:
                        win.setProperty(key_qml, data_obj[key_json])
                    except Exception:
                        pass
        except Exception as e:
            print(f"[data.json] Python load error: {e}")
    # SIZE
    try:
        win.setWidth(config.WIDTH)
        win.setHeight(config.HEIGHT)
    except Exception:
        pass

    # MODE
    if dev_mode:
        win.setFlags(Qt.Window)
        win.show()
    else:
        win.setFlags(Qt.FramelessWindowHint | Qt.Window)
        win.showFullScreen()

    if dev_mode:  # DEV PANEL
        dev_qml = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'ui', 'DevPanel.qml'))
        if os.path.isfile(dev_qml):
            engine.load(QUrl.fromLocalFile(dev_qml))
    else:
        io_teensy.start(tel)

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
