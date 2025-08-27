import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components" // add custom components (Gauge.qml, Icons.qml)

// Main UI for virtual cluster
Window {
    id: root
    width: WIDTH
    height: HEIGHT
    color: "black"
    visible: true

    property bool splashDone: false
    property bool firstData: false

    signal requestStart()

    Component.onCompleted: {
        // safety timeout
        splashTimer.start()
    }

    Connections {
        target: TEL
        function onFirstFrameReceived() {
            root.firstData = true
            if (!root.splashDone) startTransition()
        }
    }

    function startTransition() {
        splashAnim.running = true
    }

    Timer {
        id: splashTimer
        interval: 1200
        repeat: false
        onTriggered: if (!root.splashDone) startTransition()
    }

    // Splash Overlay
    Rectangle {
        id: splash
        anchors.fill: parent
        color: "black"
        opacity: 1.0
        z: 10
        visible: !root.splashDone

        Column {
            anchors.centerIn: parent
            spacing: 24
            Image { source: Qt.resolvedUrl("../assets/logo.png"); width: 320; height: 120; fillMode: Image.PreserveAspectFit }
            Text { text: root.firstData ? "starting…" : "loading…"; color: "white"; font.pixelSize: 32; font.family: "DejaVu Sans" }
        }
    }

    SequentialAnimation {
        id: splashAnim
        running: false
        onFinished: { root.splashDone = true }
        PropertyAnimation { target: splash; property: "opacity"; to: 0; duration: 280; easing.type: Easing.InOutQuad }
        ScriptAction { script: splash.visible = false }
    }

    // Main content container
    Item {
        id: content
        anchors.fill: parent
        opacity: root.splashDone ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

        // Gauges layout
        RowLayout {
            id: gaugesRow
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 40 }
            spacing: width * 0.15

            Gauge {
                id: rpmGauge
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: TEL.rpm
                max: 8000
                min: 0
                redFrom: 6500
                redTo: 8000
                label: "RPM"
                majorStep: 1000
                minorStep: 500
            }
            Gauge {
                id: speedGauge
                Layout.fillWidth: true
                Layout.fillHeight: true
                value: TEL.speed
                max: 220
                min: 0
                redFrom: 9999 // no red
                redTo: 10000
                label: "km/h"
                majorStep: 20
                minorStep: 10
            }
        }

        // Icons bar
        Row {
            id: iconBar
            spacing: 32
            anchors { bottom: parent.bottom; horizontalCenter: parent.horizontalCenter; bottomMargin: 28 }
            height: 64

            Repeater {
                model: [
                    { name: "L", active: TEL.leftBlink, color: "#00ff66" },
                    { name: "R", active: TEL.rightBlink, color: "#00ff66" },
                    { name: "HB", active: TEL.highBeam, color: "#4488ff" },
                    { name: "FG", active: TEL.fog, color: "#88ff44" },
                    { name: "P", active: TEL.park, color: "#ff3333" }
                ]
                delegate: Rectangle {
                    width: 72; height: 48; radius: 8
                    color: modelData.active ? modelData.color : "#222"
                    border.color: modelData.active ? modelData.color : "#444"
                    border.width: 2
                    Text { anchors.centerIn: parent; text: modelData.name; color: modelData.active ? "black" : "#aaa"; font.pixelSize: 22 }
                }
            }
        }
    }
}
