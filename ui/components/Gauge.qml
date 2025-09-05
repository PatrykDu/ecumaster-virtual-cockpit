import QtQuick 2.15
import QtQuick.Controls 2.15
Item {
    id: root
    property real min: 0
    property real max: 100
    property real value: 0
    property real majorStep: 10
    property real minorStep: 5
    property real startAngle: -130
    property real endAngle: 130
    property real orientationOffset: -90
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
    property bool abbreviateThousands: false
    property bool showValueInThousands: false
    property bool showCenterValue: true
    property bool showCenterLabel: true
    property real labelOffsetFactor: 0.9
    property real labelDistance: 42
    property bool drawCanvasLabels: true
    property bool useTextLabels: false

    
    property bool showInnerProgress: false
    property color innerProgressColor: 'white'
    property real innerProgressWidth: ringWidth * 0.33
    property real innerProgressRadius: radius - ringWidth * 1.10
    property bool innerProgressRoundCap: true
    property bool innerProgressGlow: true
    property bool innerProgressWhiteGlow: true
    
    property real innerProgressGlowSpreadPx: 4.0
    property int innerProgressGlowPasses: 4
    property real innerProgressGlowMaxAlpha: 0.21
    property real innerProgressGlowFalloffPower: 1.4
    property real innerProgressWhiteGlowSpreadPx: 6.0
    property int innerProgressWhiteGlowPasses: 5
    property real innerProgressWhiteGlowMaxAlpha: 0.38
    property real innerProgressWhiteGlowFalloffPower: 1.05
    property bool innerProgressAdditive: true

    
    property real markerStartRadius: (root.showInnerProgress ? innerProgressRadius : (radius * 0.30))
    
    property real markerEndRadius: radius - ringWidth
    
    property real markerBaseWidth: Math.max(6, radius * 0.065)
    
    property color markerColor: '#ff3333'
    property color markerCoreEffectiveColor: (value >= redFrom ? redlineColor : (warnFrom >= 0 && value >= warnFrom && value <= warnTo ? warnColor : markerColor))
    
    property color innerProgressCoreEffectiveColor: (value >= redFrom ? redlineColor : (warnFrom >= 0 && value >= warnFrom && value <= warnTo ? warnColor : innerProgressColor))
    property color innerProgressWhiteGlowEffectiveColor: innerProgressCoreEffectiveColor

    property bool smoothMarker: true
    property real markerSmoothedValue: value
    property real markerSmoothVelocity: (max - min) / 0.25
    SmoothedAnimation on markerSmoothedValue { velocity: root.markerSmoothVelocity; running: root.smoothMarker }

    property real radius: Math.min(width, height)/2 * 0.95

    width: 600; height: 600

    onFontSizeLabelsChanged: { scaleCanvas.requestPaint(); labelsRepeater.model = labelsRepeater.model }
    onLabelOffsetFactorChanged: scaleCanvas.requestPaint()
    onLabelDistanceChanged: scaleCanvas.requestPaint()
    onTickMajorLenChanged: scaleCanvas.requestPaint()
    onTickMinorLenChanged: scaleCanvas.requestPaint()
    onRingWidthChanged: scaleCanvas.requestPaint()
    onRedFromChanged: { scaleCanvas.requestPaint(); markerCanvas.requestPaint() }
    onRedToChanged: { scaleCanvas.requestPaint(); markerCanvas.requestPaint() }
    onWarnFromChanged: scaleCanvas.requestPaint()
    onWarnToChanged: scaleCanvas.requestPaint()

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
            ctx.lineWidth = root.ringWidth
            ctx.strokeStyle = root.backgroundArcColor
            ctx.beginPath()
            ctx.arc(0,0, arcRadius, angleFor(root.min), angleFor(root.max), false)
            ctx.stroke()
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

    Canvas {
        id: innerProgressCanvas
        anchors.fill: parent
        visible: root.showInnerProgress
        onPaint: {
            if (!root.showInnerProgress) return
            var ctx = getContext('2d'); ctx.reset();
            var cx = width/2, cy = height/2; ctx.translate(cx, cy)
            function angleFor(v) {
                var frac = (v - root.min)/(root.max - root.min)
                if (frac < 0) frac = 0; if (frac > 1) frac = 1
                return (root.startAngle + frac*(root.endAngle-root.startAngle) + root.orientationOffset) * Math.PI/180.0
            }
            var a0 = angleFor(root.min)
            var a1 = angleFor(root.value)
            var r = root.innerProgressRadius
            if (r <= 0) return
            ctx.lineWidth = root.innerProgressWidth
            ctx.lineCap = root.innerProgressRoundCap ? 'round' : 'butt'
            ctx.strokeStyle = root.innerProgressCoreEffectiveColor
            ctx.beginPath(); ctx.arc(0,0, r, a0, a1, false); ctx.stroke()
            var savedComp = ctx.globalCompositeOperation
            if (root.innerProgressAdditive)
                ctx.globalCompositeOperation = 'lighter'

            // 1) Czerwone zewnętrzne halo (dedykowane parametry)
            if (root.innerProgressGlow) {
                var passes = Math.max(1, root.innerProgressGlowPasses)
                for (var gp = passes; gp >= 1; gp--) {
                    var outerFrac = gp / passes
                    var innerFrac = 1 - outerFrac
                    var alphaFrac = Math.pow(innerFrac, root.innerProgressGlowFalloffPower)
                    if (alphaFrac <= 0) continue
                    var expansion = root.innerProgressGlowSpreadPx * outerFrac
                    ctx.lineWidth = root.innerProgressWidth + expansion * 2
                    ctx.lineCap = root.innerProgressRoundCap ? 'round' : 'butt'
                    ctx.strokeStyle = root.markerCoreEffectiveColor
                    ctx.globalAlpha = root.innerProgressGlowMaxAlpha * alphaFrac
                    ctx.beginPath(); ctx.arc(0,0, r, a0, a1, false); ctx.stroke()
                }
                ctx.globalAlpha = 1.0
            }

            if (root.innerProgressWhiteGlow) {
                var wPasses = Math.max(1, root.innerProgressWhiteGlowPasses)
                for (var wp = wPasses; wp >= 1; wp--) {
                    var wOuterFrac = wp / wPasses
                    var wInnerFrac = 1 - wOuterFrac
                    var wAlphaFrac = Math.pow(wInnerFrac, root.innerProgressWhiteGlowFalloffPower)
                    if (wAlphaFrac <= 0) continue
                    var wExpansion = root.innerProgressWhiteGlowSpreadPx * wOuterFrac
                    ctx.lineWidth = root.innerProgressWidth + wExpansion * 2
                    ctx.lineCap = root.innerProgressRoundCap ? 'round' : 'butt'
                    ctx.strokeStyle = root.innerProgressWhiteGlowEffectiveColor
                    ctx.globalAlpha = root.innerProgressWhiteGlowMaxAlpha * wAlphaFrac
                    ctx.beginPath(); ctx.arc(0,0, r, a0, a1, false); ctx.stroke()
                }
                ctx.globalAlpha = 1.0
            }

            ctx.globalCompositeOperation = savedComp
        }
    }

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

    Text {
        id: centerValue
        visible: root.showCenterValue
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: root.showValueInThousands ? (root.value/1000).toFixed(1) : Math.round(root.value)
        color: root.centerValueColor
        font.pixelSize: root.fontSizeValue
        font.bold: true
        renderType: Text.NativeRendering
    }
    Text {
        id: centerLabel
        visible: root.showCenterLabel && root.label.length > 0
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: centerValue.bottom
        anchors.topMargin: 8
        text: root.label
        color: root.centerLabelColor
        font.pixelSize: 40
        font.bold: false
        renderType: Text.NativeRendering
    }

    Canvas {
        id: markerCanvas
        anchors.fill: parent
        visible: true
        onPaint: {
            var ctx = getContext('2d'); ctx.reset();
            var cx = width/2, cy = height/2; ctx.translate(cx, cy)
            var useVal = (root.smoothMarker ? root.markerSmoothedValue : root.value)
            var frac = (useVal - root.min)/(root.max - root.min)
            if (frac < 0) frac = 0; if (frac > 1) frac = 1
            var ang = (root.startAngle + frac*(root.endAngle-root.startAngle) + root.orientationOffset) * Math.PI/180.0
            var baseR = root.markerStartRadius
            var tipR = root.markerEndRadius
            if (tipR < baseR) { var tmp = tipR; tipR = baseR; baseR = tmp }
            var halfW = root.markerBaseWidth / 2
            ctx.save(); ctx.rotate(ang)
                ctx.beginPath()
                ctx.moveTo(baseR, -halfW)
                ctx.lineTo(tipR, 0)
                ctx.lineTo(baseR,  halfW)
                ctx.closePath()
                ctx.fillStyle = (root.value >= root.redFrom ? root.redlineColor : root.markerColor)
                ctx.fill()
            ctx.restore()
        }
    Component.onCompleted: requestPaint()
    }

    onValueChanged: {
        if (showInnerProgress) innerProgressCanvas.requestPaint()
        if (smoothMarker) {
            markerSmoothedValue = value
        } else {
            markerCanvas.requestPaint()
        }
    }
    onMarkerSmoothedValueChanged: if (smoothMarker) { markerCanvas.requestPaint(); if (showInnerProgress) innerProgressCanvas.requestPaint() }
    onStartAngleChanged: { markerCanvas.requestPaint(); if (showInnerProgress) innerProgressCanvas.requestPaint() }
    onEndAngleChanged: { markerCanvas.requestPaint(); if (showInnerProgress) innerProgressCanvas.requestPaint() }
    onInnerProgressRadiusChanged: if (showInnerProgress) innerProgressCanvas.requestPaint()
    onInnerProgressWidthChanged: if (showInnerProgress) innerProgressCanvas.requestPaint()
    onInnerProgressColorChanged: if (showInnerProgress) innerProgressCanvas.requestPaint()
}
