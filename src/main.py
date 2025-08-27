from __future__ import annotations
import os
import sys

# --- Ensure project root is on sys.path so that config.py (located one level up) is importable ---
PROJECT_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), os.pardir))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)
# -----------------------------------------------------------------------------------------------

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import Qt, QUrl, qInstallMessageHandler, QtMsgType

import config
from telemetry import Telemetry
import io_teensy


# Optional: capture QML warnings
def _qt_msg_handler(mode, ctx, message):
    if mode in (QtMsgType.QtWarningMsg, QtMsgType.QtCriticalMsg, QtMsgType.QtFatalMsg):
        print(f"[QML] {message}")


qInstallMessageHandler(_qt_msg_handler)


def main():
    os.environ.setdefault("QT_QUICK_BACKEND", "software")  # fallback safety; can remove if GPU OK
    app = QGuiApplication(sys.argv)
    app.setApplicationName("VirtualCluster")

    tel = Telemetry()

    engine = QQmlApplicationEngine()
    engine.rootContext().setContextProperty("WIDTH", config.WIDTH)
    engine.rootContext().setContextProperty("HEIGHT", config.HEIGHT)
    engine.rootContext().setContextProperty("TEL", tel)

    # Resolve QML absolute path
    qml_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'ui', 'Main.qml'))
    if not os.path.isfile(qml_path):
        print(f"QML not found: {qml_path}")
        return 1
    engine.load(QUrl.fromLocalFile(qml_path))

    if not engine.rootObjects():
        print("Failed to load QML (no root objects)")
        return 1

    win = engine.rootObjects()[0]
    # Fullscreen frameless
    win.setFlags(Qt.FramelessWindowHint | Qt.Window)
    win.showFullScreen()

    # Start IO thread
    io_teensy.start(tel)

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
