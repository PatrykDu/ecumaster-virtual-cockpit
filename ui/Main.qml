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

        // Concentric layout: Outer RPM ring + inner speed circle
        Item {
            id: clusterCenter
            // replace centerIn with explicit centers + downward offset
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: parent.height * 0.10 // shift down (tune as needed)
            width: parent.height * 1.20 // size of the center gauge
            height: width

            // Outer RPM gauge (ring only)
            Gauge {
                id: rpmRing
                anchors.fill: parent
                value: TEL.rpm
                max: 7000
                min: 0
                redFrom: 5994
                redTo: 7000
                label: "" // hide label here
                majorStep: 1000
                minorStep: 500
                abbreviateThousands: true
                showValueInThousands: true
                showCenterValue: false
                showCenterLabel: false
                useTextLabels: true
                drawCanvasLabels: false
                fontSizeLabels: width * 0.07    // RPM number size
                labelDistance: width * 0.05    // adjust inward so they sit nicely
                ringWidth: width * 0.04
                tickMajorLen: width * 0.075
                tickMinorLen: width * 0.045
                backgroundArcColor: "#1d1d1d"
                tickColorMajor: "#e6e6e6"
                tickColorMinor: "#5f5f5f"
                redlineColor: "#d62828"
                needleColor: '#ff4040'
                needleTipInset: width * 0.015
                needleTail: width * 0.13
                needleThickness: width * 0.1
                warnFrom: 5300
                warnTo: 6000
                warnColor: '#ffcc33'
            }

            // Inner circle (speed display) - simplified (only one circle now)
            Item {
                id: speedInner
                anchors.centerIn: parent
                width: parent.width * 0.58
                height: width
                layer.enabled: true
                layer.smooth: true

                Canvas {
                    id: innerBg
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext('2d')
                        ctx.reset()
                        var cx = width/2
                        var cy = height/2
                        var r = width/2
                        ctx.translate(cx, cy)
                        // fill circle gradient
                        var grad = ctx.createRadialGradient(0,0, r*0.10, 0,0, r)
                        grad.addColorStop(0, '#141414')
                        grad.addColorStop(1, '#070707')
                        ctx.fillStyle = grad
                        ctx.beginPath(); ctx.arc(0,0,r,0,Math.PI*2); ctx.fill()
                        // single thin outline (remove extra inner ring)
                        ctx.lineWidth = r * 0.018
                        ctx.strokeStyle = '#2f2f2f'
                        ctx.beginPath(); ctx.arc(0,0,r*0.965,0,Math.PI*2); ctx.stroke()
                    }
                    Component.onCompleted: requestPaint()
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { // speed value centered (no lateral shift when width changes)
                        id: speedValue
                        text: Math.round(TEL.speed)
                        color: 'white'
                        font.pixelSize: speedInner.width * 0.40
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text { // unit label also centered, independent of number width
                        text: 'km/h'
                        color: '#888'
                        font.pixelSize: speedInner.width * 0.12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        // Fuel gauge (extracted component) bottom-left
        FuelGauge {
            id: fuelGauge
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: width * 0.02 + 20 // shifted 20px to the right (kept)
            anchors.bottomMargin: height * 0.02 + 20 // raised 20px upward
            width: root.width * 0.22
            height: root.height * 0.32
        }
        // Water temp gauge bottom-right (mirrored counterpart)
        WaterTempGauge {
            id: waterTempGauge
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: width * 0.02 + 20
            anchors.bottomMargin: height * 0.02 + 20
            width: root.width * 0.22
            height: root.height * 0.32
            tempC: TEL ? TEL.waterTemp : 0
        }
    }
}
