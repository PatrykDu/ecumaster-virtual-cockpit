from __future__ import annotations
import os, sys, json

# PATH SETUP
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
if PROJECT_ROOT not in sys.path: sys.path.insert(0, PROJECT_ROOT)

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import Qt, QUrl, qInstallMessageHandler, QtMsgType

import config
from telemetry import Telemetry
import io_teensy


# QML LOG HANDLER
def _qt_msg_handler(mode, ctx, message):
    if mode in (QtMsgType.QtWarningMsg, QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg):
        print(f"[QML] {message}")


qInstallMessageHandler(_qt_msg_handler)


def main():  # MAIN
    # ENV
    os.environ.setdefault("QML_XHR_ALLOW_FILE_READ", "1")
    os.environ.setdefault("QT_QUICK_BACKEND", "software")  # fallback safety; can remove if GPU OK
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
    dev_mode = os.environ.get("DEVELOP_MODE", "").lower() in ("1", "true", "yes", "on")
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
