import QtQuick 2.15
import QtQuick.Controls 2.15

// GAUGE COMPONENT

Item {
    id: root
    property real min: 0
    property real max: 100
    property real value: 0
    property real majorStep: 10
    property real minorStep: 5
    property real startAngle: -130
    property real endAngle: 130
    property real orientationOffset: -90 // degrees: rotate whole gauge so 0 is up
    property real redFrom: 80
    property real redTo: 100
    property real warnFrom: -1
    property real warnTo: -1
    property color warnColor: '#e6c400'
    property string label: ""

    property real ringWidth: 26
    property real tickMajorLen: 50
    property real tickMinorLen: 28
    property int fontSizeLabels: 32
    property int fontSizeValue: 96
    property color backgroundArcColor: '#262626'
    property color redlineColor: '#ff3333'
    property color tickColorMajor: '#d0d0d0'
    property color tickColorMinor: '#808080'
    property color centerValueColor: 'white'
    property color centerLabelColor: '#bbbbbb'
    property bool abbreviateThousands: false   // for scales like RPM 0..8000 show 0..8
    property bool showValueInThousands: false  // center value division
    property bool showCenterValue: true
    property bool showCenterLabel: true
    property real labelOffsetFactor: 0.9 // kept for backwards compatibility (unused now)
    property real labelDistance: 42       // px distance inward from end of major tick
    property bool drawCanvasLabels: true
    property bool useTextLabels: false

    property color needleColor: '#ff3333'
    property real needleTipInset: 14       // distance from outer radius to needle tip
    property real needleTail: 60           // tail length behind center (px)
    property real needleThickness: 14      // total thickness of needle body (px)

    property real radius: Math.min(width, height)/2 * 0.95

    width: 600; height: 600

    onFontSizeLabelsChanged: { scaleCanvas.requestPaint(); labelsRepeater.model = labelsRepeater.model } // force reposition
    onLabelOffsetFactorChanged: scaleCanvas.requestPaint()
    onLabelDistanceChanged: scaleCanvas.requestPaint()
    onTickMajorLenChanged: scaleCanvas.requestPaint()
    onTickMinorLenChanged: scaleCanvas.requestPaint()
    onRingWidthChanged: scaleCanvas.requestPaint()
    onNeedleColorChanged: needleCanvas.requestPaint()
    onNeedleTipInsetChanged: needleCanvas.requestPaint()
    onNeedleTailChanged: needleCanvas.requestPaint()
    onNeedleThicknessChanged: needleCanvas.requestPaint()
    onRedFromChanged: scaleCanvas.requestPaint()
    onRedToChanged: scaleCanvas.requestPaint()
    onWarnFromChanged: scaleCanvas.requestPaint()
    onWarnToChanged: scaleCanvas.requestPaint()

    // SCALE CANVAS
    Canvas {
        id: scaleCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext('2d')
            ctx.reset()
            var cx = width/2
            var cy = height/2
            ctx.translate(cx, cy)

            function angleFor(v) {
                var frac = (v - root.min)/(root.max - root.min)
                return (root.startAngle + frac*(root.endAngle-root.startAngle) + root.orientationOffset) * Math.PI/180.0
            }
            var arcRadius = root.radius - root.ringWidth/2
            // background arc
            ctx.lineWidth = root.ringWidth
            ctx.strokeStyle = root.backgroundArcColor
            ctx.beginPath()
            ctx.arc(0,0, arcRadius, angleFor(root.min), angleFor(root.max), false)
            ctx.stroke()
            // warning (yellow) zone
            if (root.warnTo > root.warnFrom && root.warnFrom >= root.min) {
                ctx.strokeStyle = root.warnColor
                ctx.beginPath()
                ctx.arc(0,0, arcRadius, angleFor(root.warnFrom), angleFor(root.warnTo), false)
                ctx.stroke()
            }
            // red zone
            ctx.strokeStyle = root.redlineColor
            ctx.beginPath()
            ctx.arc(0,0, arcRadius, angleFor(root.redFrom), angleFor(root.redTo), false)
            ctx.stroke()
            // ticks
            ctx.lineWidth = 4
            for (var v = root.min; v <= root.max + 0.001; v += root.majorStep) {
                var a = angleFor(v)
                var isRed = v >= root.redFrom
                ctx.save(); ctx.rotate(a)
                ctx.beginPath(); ctx.moveTo(root.radius-10,0); ctx.lineTo(root.radius-10 - root.tickMajorLen,0)
                ctx.strokeStyle = isRed ? root.redlineColor : root.tickColorMajor; ctx.stroke(); ctx.restore()
                if (root.drawCanvasLabels && !root.useTextLabels) {
                    ctx.save(); ctx.rotate(a)
                    ctx.translate(root.radius-10 - root.tickMajorLen - root.labelDistance,0)
                    ctx.rotate(-a)
                    ctx.fillStyle = isRed ? root.redlineColor : root.tickColorMajor
                    ctx.font = root.fontSizeLabels + 'px DejaVu Sans'
                    ctx.textAlign = 'center'; ctx.textBaseline = 'middle'
                    var display = root.abbreviateThousands ? String(Math.round(v/1000)) : String(Math.round(v))
                    ctx.fillText(display,0,0)
                    ctx.restore()
                }
            }
            // minor ticks
            ctx.lineWidth = 2
            for (var mv = root.min; mv <= root.max + 0.001; mv += root.minorStep) {
                if (Math.abs(mv % root.majorStep) < 0.001) continue
                var ma = angleFor(mv)
                ctx.save(); ctx.rotate(ma)
                ctx.beginPath(); ctx.moveTo(root.radius-10,0); ctx.lineTo(root.radius-10 - root.tickMinorLen,0)
                if (mv >= root.redFrom) {
                    ctx.strokeStyle = root.redlineColor
                } else if (mv >= root.warnFrom && mv <= root.warnTo) {
                    ctx.strokeStyle = root.warnColor
                } else {
                    ctx.strokeStyle = root.tickColorMinor
                }
                ctx.stroke(); ctx.restore()
            }
        }
    }

    // TEXT LABELS (WHEN useTextLabels TRUE)
    Repeater {
        id: labelsRepeater
        model: useTextLabels ? Math.floor((root.max - root.min)/root.majorStep) + 1 : 0
        delegate: Text {
            property real v: root.min + index * root.majorStep
            property real frac: (v - root.min)/(root.max - root.min)
            property real angleDeg: root.startAngle + frac*(root.endAngle-root.startAngle) + root.orientationOffset
            property real angleRad: angleDeg * Math.PI/180.0
            text: root.abbreviateThousands ? Math.round(v/1000) : Math.round(v)
            color: v >= root.redFrom ? root.redlineColor : root.tickColorMajor
            font.pixelSize: root.fontSizeLabels
            font.bold: false
            x: root.width/2 + Math.cos(angleRad)*(root.radius -10 - root.tickMajorLen - root.labelDistance) - width/2
            y: root.height/2 + Math.sin(angleRad)*(root.radius -10 - root.tickMajorLen - root.labelDistance) - height/2
            renderType: Text.NativeRendering
        }
    }

    // CENTER VALUE
    Text {
        id: valueText
        visible: root.showCenterValue
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: root.showValueInThousands ? (root.value/1000).toFixed(1) : Math.round(root.value)
        color: root.centerValueColor
        font.pixelSize: root.fontSizeValue
        font.bold: true
        layer.enabled: true
    }
    Text {
        visible: root.showCenterLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: valueText.bottom
        anchors.topMargin: 8
        text: root.label
        color: root.centerLabelColor
        font.pixelSize: 40
    }

    // NEEDLE (simplified red line pointer)
    Item {
        id: needle
        width: root.width
        height: root.height
        // reuse existing animation logic
        property real targetAngle: {
            var frac = (root.value - root.min)/(root.max - root.min)
            if (frac < 0) frac = 0
            if (frac > 1) frac = 1
            return (root.startAngle + frac*(root.endAngle-root.startAngle))
        }
        property real currentAngle: 0
        Behavior on currentAngle { NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
        onTargetAngleChanged: currentAngle = targetAngle
        onCurrentAngleChanged: needleCanvas.requestPaint()
        property real lineWidth: Math.max(2, root.needleThickness * 0.22) // thin line derived from old thickness
        property real hubRadius: lineWidth * 2.2
        Canvas {
            id: needleCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext('2d')
                ctx.reset()
                var cx = width/2
                var cy = height/2
                ctx.translate(cx, cy)
                var ang = (needle.currentAngle + root.orientationOffset) * Math.PI/180.0
                var tip = root.radius - root.needleTipInset
                // draw glow (optional subtle outer stroke)
                ctx.save()
                ctx.rotate(ang)
                ctx.lineCap = 'round'
                // main line
                ctx.strokeStyle = root.needleColor
                ctx.lineWidth = needle.lineWidth
                ctx.beginPath()
                ctx.moveTo(0,0)
                ctx.lineTo(tip,0)
                ctx.stroke()
                ctx.restore()
                // hub
                ctx.fillStyle = '#222'
                ctx.beginPath(); ctx.arc(0,0, needle.hubRadius, 0, Math.PI*2); ctx.fill()
                ctx.strokeStyle = root.needleColor
                ctx.lineWidth = 1
                ctx.beginPath(); ctx.arc(0,0, needle.hubRadius*0.65, 0, Math.PI*2); ctx.stroke()
            }
            Component.onCompleted: requestPaint()
        }
    }
}
