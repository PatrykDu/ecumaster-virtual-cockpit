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
    property int odometerValue: 0
    property real tripValue: 0.0   // changed to real (float)

    signal requestStart()

    Component.onCompleted: {
        // safety timeout
        splashTimer.start()
        loadOdometer()
        odometerPoll.start()
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

        // Fullscreen mazdaspeed image (fills screen, preserves aspect)
        Image {
            id: splashFull
            anchors.fill: parent
            source: Qt.resolvedUrl("../assets/mazdaspeed.png")
            fillMode: Image.PreserveAspectFit
            smooth: true
            cache: true
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
                tickColorMinor: "#5f5f5f" // fixed missing digit
                redlineColor: "#d62828"
                needleColor: '#ff4040'
                needleTipInset: width * 0.015
                needleTail: width * 0.13
                needleThickness: width * 0.1
                warnFrom: 5300
                warnTo: 6000
                warnColor: '#ffcc33'
                // red zone dynamic
                property int oilTempLocal: TEL ? TEL.oilTemp : 0
                property int dynRedline: redlineForOilTemp(oilTempLocal)
                // Animate red zone boundary
                Behavior on redFrom { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                Behavior on redTo { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                onDynRedlineChanged: {
                    redFrom = dynRedline
                    redTo = 7000
                }
            }

            // Inner circle (speed display) - simplified (only one circle now)
            Item {
                id: speedInner
                anchors.centerIn: parent
                width: parent.width * 0.58
                height: width
                layer.enabled: true
                layer.smooth: true

                // Opaque base circle to hide RPM needle during gradient cross-fade
                Canvas {
                    id: speedInnerBase
                    anchors.fill: parent
                    onPaint: {
                        var ctx = getContext('2d'); ctx.reset();
                        var r = width/2; ctx.translate(r,r)
                        ctx.fillStyle = '#0d0d0d' // neutral dark fill
                        ctx.beginPath(); ctx.arc(0,0,r,0,Math.PI*2); ctx.fill()
                    }
                    Component.onCompleted: requestPaint()
                }

                // Dynamic RPM state: 0 neutral, 1 warn (yellow), 2 red
                property int rpmState: (TEL.rpm >= rpmRing.redFrom ? 2 : (TEL.rpm >= rpmRing.warnFrom && TEL.rpm <= rpmRing.warnTo ? 1 : 0))

                // Three layered gradients with animated cross‑fade
                Item { anchors.fill: parent; id: gradientStack }
                Canvas { // neutral (gray)
                    id: neutralBg
                    anchors.fill: parent
                    opacity: speedInner.rpmState === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
                    onPaint: {
                        var ctx = getContext('2d'); ctx.reset();
                        var cx = width/2, cy = height/2, r = width/2; ctx.translate(cx, cy)
                        var grad = ctx.createRadialGradient(0,0,r*0.10,0,0,r)
                        grad.addColorStop(0,'#141414'); grad.addColorStop(1,'#070707')
                        ctx.fillStyle = grad; ctx.beginPath(); ctx.arc(0,0,r,0,Math.PI*2); ctx.fill()
                        ctx.lineWidth = r*0.018; ctx.strokeStyle = '#2f2f2f'
                        ctx.beginPath(); ctx.arc(0,0,r*0.965,0,Math.PI*2); ctx.stroke()
                    }
                    Component.onCompleted: requestPaint()
                }
                Canvas { // warn (yellow tint)
                    id: warnBg
                    anchors.fill: parent
                    opacity: speedInner.rpmState === 1 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
                    onPaint: {
                        var ctx = getContext('2d'); ctx.reset();
                        var cx = width/2, cy = height/2, r = width/2; ctx.translate(cx, cy)
                        var grad = ctx.createRadialGradient(0,0,r*0.05,0,0,r)
                        // Multi‑stop: dark center -> bright mid ring -> darker outer fade
                        grad.addColorStop(0.0,'#1e1600')
                        grad.addColorStop(0.45,'#e2b600')
                        grad.addColorStop(0.70,'#614800')
                        grad.addColorStop(1.0,'#120d00')
                        ctx.fillStyle = grad; ctx.beginPath(); ctx.arc(0,0,r,0,Math.PI*2); ctx.fill()
                        ctx.lineWidth = r*0.018; ctx.strokeStyle = '#b89000'
                        ctx.beginPath(); ctx.arc(0,0,r*0.965,0,Math.PI*2); ctx.stroke()
                    }
                    Component.onCompleted: requestPaint()
                }
                Canvas { // red (hot)
                    id: redBg
                    anchors.fill: parent
                    opacity: speedInner.rpmState === 2 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.InOutQuad } }
                    onPaint: {
                        var ctx = getContext('2d'); ctx.reset();
                        var cx = width/2, cy = height/2, r = width/2; ctx.translate(cx, cy)
                        var grad = ctx.createRadialGradient(0,0,r*0.05,0,0,r)
                        grad.addColorStop(0.0,'#220000')
                        grad.addColorStop(0.45,'#d80000')
                        grad.addColorStop(0.70,'#5c0000')
                        grad.addColorStop(1.0,'#170000')
                        ctx.fillStyle = grad; ctx.beginPath(); ctx.arc(0,0,r,0,Math.PI*2); ctx.fill()
                        ctx.lineWidth = r*0.018; ctx.strokeStyle = '#b00000'
                        ctx.beginPath(); ctx.arc(0,0,r*0.965,0,Math.PI*2); ctx.stroke()
                    }
                    Component.onCompleted: requestPaint()
                }

                // Force repaints when state changes (so newly faded-in canvas has fresh frame)
                onRpmStateChanged: { neutralBg.requestPaint(); warnBg.requestPaint(); redBg.requestPaint() }

                Column {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        id: speedValue
                        text: Math.round(TEL.speed)
                        color: 'white'
                        font.pixelSize: speedInner.width * 0.40
                        font.bold: true
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    Text {
                        text: 'km/h'
                        color: '#888'
                        font.pixelSize: speedInner.width * 0.12
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }

        FuelGauge {
            id: fuelGauge
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: width * 0.02 + 25 // shifted 20px to the right (kept)
            anchors.bottomMargin: height * 0.02 + 20 // raised 20px upward
            width: root.width * 0.22
            height: root.height * 0.32
        }
        // New LeftCluster rectangle (2:3 width:height ratio)
        LeftCluster {
            id: leftCluster
            base: clusterCenter.width * 0.15
            heightOverride: base * 0.3   // lowered height (instead of 3 * base)
            width: base * ratioW + 50
            anchors.verticalCenter: clusterCenter.verticalCenter
            anchors.verticalCenterOffset: 20
            anchors.right: clusterCenter.left
            anchors.rightMargin: 20
        }
        WaterTempGauge {
            id: waterTempGauge
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: width * 0.02 + 25
            anchors.bottomMargin: height * 0.02 + 20
            width: root.width * 0.22
            height: root.height * 0.32
            tempC: TEL ? TEL.waterTemp : 0
        }
        RightCluster {
            id: rightCluster
            anchors.bottom: waterTempGauge.top
            anchors.bottomMargin: 24
            anchors.right: waterTempGauge.left
            anchors.rightMargin: -280 // adjust gap between cluster and water gauge (smaller = more to right)
            width: root.width * 0.18
        }

        Text { // Odometer display bottom-left (adjusted position)
            id: odometerText
            text: 'ODO: ' + root.odometerValue
            color: 'white'
            font.pixelSize: 28
            font.bold: true
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.leftMargin: 340
            anchors.bottomMargin: 35
            z: 600
        }
        Text { // Trip display bottom-right
            id: tripText
            text: 'TRIP: ' + tripValue.toFixed(1)
            color: 'white'
            font.pixelSize: 28
            font.bold: true
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 360
            anchors.bottomMargin: 35
            z: 600
        }
    }

    function redlineForOilTemp(oilTemp) {
        // Interpolation table (oil_temp_c -> redline_rpm)
        // Based on provided photo (approx):
        // 20:2500, 25:2750, 30:3000, 35:3250, 40:3500, 45:3850,
        // 50:4200, 55:4500, 60:4800, 65:5100, 70:5400, 75:5700,
        // 80:5994, 85:5994, 90:5994 (plateau from 80 up)
        var table = [
            [20,2500],[25,2750],[30,3000],[35,3250],[40,3500],[45,3850],
            [50,4200],[55,4500],[60,4800],[65,5100],[70,5400],[75,5700],
            [80,5994]
        ];
        if (oilTemp <= table[0][0]) return table[0][1];
        if (oilTemp >= table[table.length-1][0]) return table[table.length-1][1];
        for (var i=0;i<table.length-1;i++) {
            var a = table[i]; var b = table[i+1];
            if (oilTemp >= a[0] && oilTemp <= b[0]) {
                var t = (oilTemp - a[0])/(b[0]-a[0]);
                return a[1] + t*(b[1]-a[1]);
            }
        }
        return 5994;
    }

    function loadOdometer() {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', Qt.resolvedUrl('../data/odometer.json'))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    var obj = JSON.parse(xhr.responseText);
                    if (obj) {
                        if (obj.odometer !== undefined) root.odometerValue = obj.odometer
                        if (obj.trip !== undefined) root.tripValue = parseFloat(obj.trip)
                    }
                } catch(e) {}
            }
        }
        xhr.send()
    }

    Timer { id: odometerPoll; interval: 5000; repeat: true; running: false; onTriggered: loadOdometer() }
}
