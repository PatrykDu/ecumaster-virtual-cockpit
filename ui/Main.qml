import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "components"
Window {
    id: root
    width: WIDTH
    height: HEIGHT
    color: "black"
    visible: true

    readonly property int designWidth: typeof DESIGN_WIDTH !== 'undefined' ? DESIGN_WIDTH : width
    readonly property int designHeight: typeof DESIGN_HEIGHT !== 'undefined' ? DESIGN_HEIGHT : height
    readonly property real uiScale: Math.min(width / designWidth, height / designHeight)

    property bool splashDone: false
    property bool firstData: false
    property int odometerValue: 0
    property real tripValue: 0.0
    property real fr: 0
    property real fl: 0
    property real rr: 0
    property real rl: 0

    signal requestStart()

    Item {
        id: escCatcher
        anchors.fill: parent
        focus: true
        Keys.onReleased: if (event.key === Qt.Key_Escape) Qt.quit()
        Component.onCompleted: escCatcher.forceActiveFocus()
    }

    Component.onCompleted: {
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

    Connections {
        target: TEL
        function onTripChanged(v) { root.tripValue = v }
        function onOdometerChanged(v) { root.odometerValue = v }
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

    Rectangle {
        id: splash
        anchors.fill: parent
        color: "black"
        opacity: 1.0
        z: 10
        visible: !root.splashDone
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

    Item {
        id: content
        width: root.designWidth
        height: root.designHeight
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        scale: root.uiScale
        opacity: root.splashDone ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutQuad } }

        Item {
            id: leftIndicatorsCluster
            anchors.bottom: odometerText.top
            anchors.bottomMargin: 10
            anchors.left: parent.left
            anchors.leftMargin: 340
        width: content.width * 0.095
            property int topRowOffset: 30
            height: width + topRowOffset
            visible: true
            z: 600
        property real cell: width * 0.50
            Grid {
                id: licGrid
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
            rows: 2; columns: 2;
            rowSpacing: leftIndicatorsCluster.cell * 0.09
            columnSpacing: leftIndicatorsCluster.width * 0.04
                Repeater {
                    model: [
                        { key: 'lowBeam', src: '../assets/low_beam.png', color: '#009a1e' },
                        { key: 'highBeam', src: '../assets/high_beam.png', color: '#0040ff' },
                        { key: 'fogRear', src: '../assets/fog_rear.png', color: '#e6cc00' },
                        { key: 'underglow', src: '../assets/underglow.png', color: '#ff2020' }
                    ]
                    delegate: Item {
                        width: leftIndicatorsCluster.cell
                        height: width
                        property bool active: TEL && TEL[modelData.key]
                        transform: Translate { y: index < 2 ? leftIndicatorsCluster.topRowOffset : 0 }
                        opacity: 1
                        Image {
                            id: indicatorImg
                            anchors.centerIn: parent
                            source: Qt.resolvedUrl(modelData.src)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            cache: true
                            opacity: (active || bgRect.opacity > 0.05) ? 1 : 0
                            width: parent.width
                            height: parent.height
                        }
                        Rectangle {
                            id: bgRect
                            anchors.centerIn: indicatorImg
                            width: Math.max(0, indicatorImg.paintedWidth - (index < 2 ? 3 : 5))
                            height: Math.max(0, indicatorImg.paintedHeight - (index < 2 ? 3 : 5))
                            radius: width * 0.18
                            color: modelData.color
                            opacity: active ? 0.95 : 0.0
                            z: -1
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                        }
                    }
                }
            }
        }

        Item { // RIGHT INDICATORS CLUSTER
            id: rightIndicatorsCluster
            anchors.bottom: tripText.top
            anchors.bottomMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 370
            width: content.width * 0.09
            property int topRowOffset: 20
            height: width + topRowOffset
            visible: true
            z: 600
            property real cell: width * 0.48
            Grid {
                id: ricGrid
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                rows: 2; columns: 2;
                rowSpacing: rightIndicatorsCluster.cell * 0.14
                columnSpacing: rightIndicatorsCluster.width * 0.04
                Repeater {
                    model: [
                        { key: 'charging', src: '../assets/charging.png', color: '#ff2020' },
                        { key: 'park',     src: '../assets/parking.png',  color: '#ff2020' },
                        { key: 'abs',      src: '../assets/abs.png',      color: '#e6cc00' },
                        { key: 'wheelPressure', src: '../assets/wheel_pressure.png', color: '#e6cc00' }
                    ]
                    delegate: Item {
                        width: rightIndicatorsCluster.cell
                        height: width
                        property bool active: TEL && TEL[modelData.key]
                        transform: Translate { y: index < 2 ? rightIndicatorsCluster.topRowOffset : 0 }
                        opacity: 1
                        Image {
                            id: ricIndicatorImg
                            anchors.centerIn: parent
                            source: Qt.resolvedUrl(modelData.src)
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                            cache: true
                            opacity: (active || ricBgRect.opacity > 0.05) ? 1 : 0
                            width: parent.width
                            height: parent.height
                        }
                        Rectangle {
                            id: ricBgRect
                            anchors.centerIn: ricIndicatorImg
                            width: Math.max(0, ricIndicatorImg.paintedWidth - (index < 2 ? 3 : 5))
                            height: Math.max(0, ricIndicatorImg.paintedHeight - (index < 2 ? 3 : 5))
                            radius: width * 0.18
                            color: modelData.color
                            opacity: active ? 0.95 : 0.0
                            z: -1
                            Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }
                        }
                    }
                }
            }
        }

    Item {
            id: checkEngineIcon
            property bool active: TEL && TEL.checkEngine
            property bool fadingOut: false
            visible: active || fadingOut
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: -230
            property real baseHeight: parent.width * 0.04
            height: baseHeight
            width: engineImage.width
            z: -1
            Image {
                id: engineImage
                height: parent.height
                width: height * (sourceSize.width > 0 && sourceSize.height > 0 ? sourceSize.width / sourceSize.height : 1)
                source: Qt.resolvedUrl('../assets/check_engine.png')
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: true
            }
            Rectangle {
                id: checkEngineBg
                width: engineImage.width - 10
                height: engineImage.height
                anchors.centerIn: engineImage
                radius: height * 0.18
                color: '#ff9900'
                property real pulseLevel: 1.0
                property real fadeFactor: 0.0
                opacity: fadeFactor * (checkEngineIcon.active ? pulseLevel : 1)
                SequentialAnimation {
                    id: pulse
                    running: checkEngineIcon.active
                    loops: Animation.Infinite
                    PropertyAnimation { target: checkEngineBg; property: 'pulseLevel'; to: 0.55; duration: 540; easing.type: Easing.InOutQuad }
                    PropertyAnimation { target: checkEngineBg; property: 'pulseLevel'; to: 1.0;  duration: 620; easing.type: Easing.InOutQuad }
                }
                NumberAnimation { id: ceFadeIn;  target: checkEngineBg; property: 'fadeFactor'; to: 1.0; duration: 180; easing.type: Easing.InOutQuad }
                NumberAnimation { id: ceFadeOut; target: checkEngineBg; property: 'fadeFactor'; to: 0.0; duration: 180; easing.type: Easing.InOutQuad; onFinished: { if (!checkEngineIcon.active) checkEngineIcon.fadingOut = false } }
                Component.onCompleted: { if (checkEngineIcon.active) { fadeFactor = 0; ceFadeIn.restart(); pulse.start(); } }
                z: -1
            }
            onActiveChanged: {
                if (active) {
                    fadingOut = false
                    ceFadeOut.stop()
                    checkEngineBg.fadeFactor = 0
                    ceFadeIn.restart()
                    if (!pulse.running) pulse.start()
                } else {
                    if (checkEngineBg.fadeFactor > 0) {
                        fadingOut = true
                        ceFadeIn.stop()
                        ceFadeOut.restart()
                    } else {
                        fadingOut = false
                    }
                }
            }
        }

        Item {
            id: clusterCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            anchors.verticalCenterOffset: content.height * 0.10
            width: content.height * 1.20 // size of the center gauge
            height: width

            Gauge {
                id: rpmRing
                anchors.fill: parent
                value: TEL.rpm
                max: 7000
                min: 0
                showNeedle: false
                showInnerProgress: true
                innerProgressColor: 'white'
                innerProgressWidth: width * 0.012
                innerProgressRadius: radius - ringWidth * 1.55
                innerProgressGlowSpreadPx: markerGlowSpreadPx * 0.70
                innerProgressGlowPasses: 8
                innerProgressGlowMaxAlpha: markerGlowMaxAlpha * 0.85
                innerProgressWhiteGlowSpreadPx: markerInnerGlowSpreadPx * 0.75
                innerProgressWhiteGlowPasses: 6
                innerProgressWhiteGlowMaxAlpha: markerInnerGlowMaxAlpha * 0.90
                innerProgressRoundCap: false
                markerWhiteNeedle: true
                markerSharpTip: true
                markerGlow: true
                markerGlowPasses: 10
                markerGlowMaxAlpha: 0.30
                markerGlowSpreadPx: 24
                markerGlowFalloffPower: 1.25
                markerGlowInwardFactor: 1.55
                markerGlowExtraInward: 10
                markerWidth: width * 0.010
                markerInnerRadius: radius * 0.68
                markerOuterRadius: radius - ringWidth - width * 0.004
                markerTaperStartFraction: 0.63
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
                fontSizeLabels: width * 0.07
                labelDistance: width * 0.05
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
                    property bool demo2: (typeof DEV_MODE_INT !== 'undefined' && DEV_MODE_INT === 2)
                    property int oilTempLocal: TEL ? TEL.oilTemp : 0
                    property int dynRedlineRaw: redlineForOilTemp(oilTempLocal)
                    property int dynRedline: demo2 ? Math.round(dynRedlineRaw / 50) * 50 : dynRedlineRaw
                    onDynRedlineChanged: {
                        if (redFrom !== dynRedline) {
                            redFrom = dynRedline
                            redTo = 7000
                        }
                    }
                    Behavior on redFrom { enabled: !demo2; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Behavior on redTo { enabled: !demo2; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    smoothNeedle: demo2
            }
            
            Item {
                id: speedInner
                anchors.centerIn: parent
                width: parent.width * 0.58
                height: width
                layer.enabled: true
                layer.smooth: true

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

                property int rpmState: (TEL.rpm >= rpmRing.redFrom ? 2 : (TEL.rpm >= rpmRing.warnFrom && TEL.rpm <= rpmRing.warnTo ? 1 : 0))

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

                onRpmStateChanged: { neutralBg.requestPaint(); warnBg.requestPaint(); redBg.requestPaint() }

                Column {
                    id: speedStack
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -speedInner.width * 0.0375
                    spacing: 4
                    property real logoScale: 1.5
                    Image {
                        id: mazdaspeedLogo
                        source: Qt.resolvedUrl('../assets/mazdaspeed.png')
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        cache: true
                        width: speedInner.width * 0.6 * speedStack.logoScale
                        height: width * 0.25
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
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

    Item {
            id: leftTurnIndicator
            width: clusterCenter.width * 0.11
            height: width
            // Final placement: slightly below top of gauge, to its left
            anchors.top: clusterCenter.top
            anchors.topMargin: 58 // moved down by +30
            anchors.right: clusterCenter.left
            anchors.rightMargin: -130
            z: 500
            property bool active: TEL ? TEL.leftBlink : false
            property bool fadingOut: false
            visible: active || fadingOut
            opacity: 1
            onActiveChanged: {
                if (active) {
                    fadingOut = false
                    leftTurnFadeOut.stop()
                    leftTurnBg.opacity = 0
                    leftTurnFadeIn.restart()
                } else {
                    if (leftTurnBg.opacity > 0) {
                        fadingOut = true
                        leftTurnFadeIn.stop()
                        leftTurnFadeOut.restart()
                    } else {
                        fadingOut = false
                    }
                }
            }
            Rectangle {
                id: leftTurnBg
                anchors.centerIn: parent
                width: parent.width * 0.96
                height: parent.height * 0.72
                radius: width * 0.20
                color: '#00c040'
                opacity: 0
                NumberAnimation { id: leftTurnFadeIn; target: leftTurnBg; property: 'opacity'; to: 0.95; duration: 180; easing.type: Easing.InOutQuad }
                NumberAnimation { id: leftTurnFadeOut; target: leftTurnBg; property: 'opacity'; to: 0.0; duration: 180; easing.type: Easing.InOutQuad; onFinished: { if (!leftTurnIndicator.active) leftTurnIndicator.fadingOut = false } }
            }
            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl('../assets/left_turn.png')
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: true
                opacity: 1
            }
            Connections { target: TEL; function onLeftBlinkChanged(v) { leftTurnIndicator.active = v } }
        }

    Item {
            id: rightTurnIndicator
            width: clusterCenter.width * 0.11
            height: width
            anchors.top: clusterCenter.top
            anchors.topMargin: 58
            anchors.left: clusterCenter.right
            anchors.leftMargin: -130
            z: 500
            property bool active: TEL ? TEL.rightBlink : false
            property bool fadingOut: false
            visible: active || fadingOut
            opacity: 1
            onActiveChanged: {
                if (active) {
                    fadingOut = false
                    rightTurnFadeOut.stop()
                    rightTurnBg.opacity = 0
                    rightTurnFadeIn.restart()
                } else {
                    if (rightTurnBg.opacity > 0) {
                        fadingOut = true
                        rightTurnFadeIn.stop()
                        rightTurnFadeOut.restart()
                    } else {
                        fadingOut = false
                    }
                }
            }
            Rectangle {
                id: rightTurnBg
                anchors.centerIn: parent
                width: parent.width * 0.98
                height: parent.height * 0.7
                radius: width * 0.20
                color: '#00c040'
                opacity: 0
                NumberAnimation { id: rightTurnFadeIn; target: rightTurnBg; property: 'opacity'; to: 0.95; duration: 180; easing.type: Easing.InOutQuad }
                NumberAnimation { id: rightTurnFadeOut; target: rightTurnBg; property: 'opacity'; to: 0.0; duration: 180; easing.type: Easing.InOutQuad; onFinished: { if (!rightTurnIndicator.active) rightTurnIndicator.fadingOut = false } }
            }
            Image {
                anchors.fill: parent
                source: Qt.resolvedUrl('../assets/right_turn.png')
                fillMode: Image.PreserveAspectFit
                smooth: true
                cache: true
                opacity: 1
            }
            Connections { target: TEL; function onRightBlinkChanged(v) { rightTurnIndicator.active = v } }
        }

    FuelGauge {
            id: fuelGauge
            anchors.left: content.left
            anchors.bottom: content.bottom
            anchors.leftMargin: width * 0.02 + 25
            anchors.bottomMargin: height * 0.02 + 20
            width: content.width * 0.22
            height: content.height * 0.32
        }
    LeftCluster {
            id: leftCluster
            base: clusterCenter.width * 0.15
            heightOverride: base * 0.3   // lowered height (instead of 3 * base)
            width: base * ratioW + 50
            anchors.verticalCenter: clusterCenter.verticalCenter
            anchors.verticalCenterOffset: -30
            anchors.right: clusterCenter.left
            anchors.rightMargin: 20
            fl: root.fl
            fr: root.fr
            rr: root.rr
            rl: root.rl
            windowRoot: root
        }
    WaterTempGauge {
            id: waterTempGauge
            anchors.right: content.right
            anchors.bottom: content.bottom
            anchors.rightMargin: width * 0.02 + 25
            anchors.bottomMargin: height * 0.02 + 20
            width: content.width * 0.22
            height: content.height * 0.32
            tempC: TEL ? TEL.waterTemp : 0
        }
        RightCluster {
            id: rightCluster
            anchors.bottom: waterTempGauge.top
            anchors.bottomMargin: 24
            anchors.right: waterTempGauge.left
            anchors.rightMargin: -280
            width: content.width * 0.18
        }

    Text {
            id: odometerText
            text: 'ODO: ' + root.odometerValue
            color: 'white'
            font.pixelSize: 28
            font.bold: true
            anchors.left: content.left
            anchors.bottom: content.bottom
            anchors.leftMargin: 340
            anchors.bottomMargin: 35
            z: 600
        }
    Text {
            id: tripText
            text: 'TRIP: ' + tripValue.toFixed(1)
            color: 'white'
            font.pixelSize: 28
            font.bold: true
            anchors.right: content.right
            anchors.bottom: content.bottom
            anchors.rightMargin: 360
            anchors.bottomMargin: 35
            z: 600
            property color baseColor: 'white'
            property bool flash: false
            SequentialAnimation {
                id: tripPulse
                running: false
                PropertyAnimation { target: tripText; property: 'scale'; to: 1.22; duration: 120; easing.type: Easing.OutCubic }
                PropertyAnimation { target: tripText; property: 'scale'; to: 1.0; duration: 180; easing.type: Easing.InOutCubic }
            }
            SequentialAnimation {
                id: tripFlash
                running: false
                ColorAnimation { target: tripText; property: 'color'; to: '#ff5050'; duration: 160 }
                ColorAnimation { target: tripText; property: 'color'; to: tripText.baseColor; duration: 300 }
            }
        }
    }

    function animateTripReset() {
        tripPulse.start();
        tripFlash.start();
    }

    function redlineForOilTemp(oilTemp) {
        var table = [
            [30,2498],
            [35,2750],
            [40,2994],
            [45,3250],
            [50,3498],
            [55,3700],
            [60,3994],
            [65,4250],
            [70,4498],
            [75,4750],
            [80,4994],
            [85,5498],
            [90,5994]
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
        xhr.open('GET', Qt.resolvedUrl('../data/data.json'))
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                try {
                    var obj = JSON.parse(xhr.responseText);
                    if (obj) {
                        if (obj.odometer !== undefined) root.odometerValue = obj.odometer;
                        if (obj.trip !== undefined) root.tripValue = parseFloat(obj.trip);
                        if (obj.FR !== undefined) root.fr = obj.FR;
                        if (obj.FL !== undefined) root.fl = obj.FL;
                        if (obj.RR !== undefined) root.rr = obj.RR;
                        if (obj.RL !== undefined) root.rl = obj.RL;
                        if (obj.fr !== undefined) root.fr = obj.fr;
                        if (obj.fl !== undefined) root.fl = obj.fl;
                        if (obj.rr !== undefined) root.rr = obj.rr;
                        if (obj.rl !== undefined) root.rl = obj.rl;
                        function clamp(v) { return Math.max(1, Math.min(32, v)); }
                        root.fr = clamp(root.fr); root.fl = clamp(root.fl); root.rr = clamp(root.rr); root.rl = clamp(root.rl);
                        console.log('[data.json] loaded FR='+root.fr+' FL='+root.fl+' RR='+root.rr+' RL='+root.rl)
                    }
                } catch(e) {}
            }
        }
        xhr.send();
    }

    Timer { id: odometerPoll; interval: 5000; repeat: true; running: false; onTriggered: loadOdometer() }
}
