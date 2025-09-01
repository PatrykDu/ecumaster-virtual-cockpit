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

    // Optional smoothing mode for high-jitter sources (set per instance)
    property bool smoothNeedle: false
    // Toggle between classic needle and sweep arc
    property bool showNeedle: true
    property color valueArcColor: needleColor // legacy (unused after marker change)
    property real valueArcThickness: Math.min(ringWidth * 0.65, 20) // legacy
    // Marker (radial bar) properties when showNeedle == false
    property color markerColor: needleColor
    property real markerInnerRadius: radius * 0.32
    property real markerOuterRadius: radius - ringWidth
    property real markerWidth: Math.max(3, radius * 0.025) // doubled thickness
        // Visual enhancement properties for marker mode
        property bool markerGradient: true
        property color markerColorEnd: Qt.rgba(
            Math.min(1, (Qt.rgba(markerColor.r, markerColor.g, markerColor.b, markerColor.a).r * 0.85) + 0.05),
            Math.min(1, (Qt.rgba(markerColor.r, markerColor.g, markerColor.b, markerColor.a).g * 0.85) + 0.05),
            Math.min(1, (Qt.rgba(markerColor.r, markerColor.g, markerColor.b, markerColor.a).b * 0.85) + 0.05),
            1)
        property bool markerGlow: true
        property real markerGlowAlpha: 0.28
        property color markerBorderColor: Qt.rgba(0,0,0,0.55)
    // White pointer mode (biała kreska z czerwoną poświatą) – domyślnie off, żeby nie psuć innych wskaźników
    property bool markerWhiteNeedle: false
    property color markerCoreColor: 'white'
    property color markerGlowColor: redlineColor   // poświata
    property int markerGlowPasses: 4
    property real markerGlowMaxAlpha: 0.18
    property real markerGlowSpreadPx: 4.5          // przyrost szerokości halo na pass
    property bool markerSharpTip: true             // jeśli true rysuje trójkątny czubek
    property real markerTaperStartFraction: 0.70   // od ilu % długości zaczyna się zwężanie (0..1)
    property real markerTipCurveFactor: 0.55       // 0..1 jak bardzo zaokrąglone boki czubka (0=ostry trójkąt, 0.5..0.7=łagodny)
    property bool markerGlowClip: true             // przycina poświatę aby nie wychodziła poza długość markera
    property real markerGlowFalloffPower: 1.4      // kształt zaniku (większe = szybsze wygaszanie na zewnątrz)
    property real markerGlowInwardFactor: 1.25     // mnożnik jak daleko halo wchodzi do środka względem expansion
    property real markerGlowExtraInward: 6         // stały dodatkowy pikselowy zasięg do środka niezależny od expansion
    property bool markerRoundBase: true            // zaokrąglone wewnętrzne (bliżej centrum) zakończenie markera
    property bool markerRoundOuterTip: false       // zaokrąglony zewnętrzny koniec (zamiast ostrego czubka)
    // Dodatkowe wewnętrzne białe halo (delikatne rozmycie bieli zanim przejdzie w czerwone)
    property bool markerInnerWhiteGlow: true
    property color markerInnerGlowColor: 'white'
    property int markerInnerGlowPasses: 5           // więcej warstw dla płynniejszego gradientu
    property real markerInnerGlowMaxAlpha: 0.38     // mocniejsze – bardziej rzeczywiście białe
    property real markerInnerGlowSpreadPx: 7.5      // odrobinę większe
    property real markerInnerGlowFalloffPower: 1.05 // wolniejszy zanik = jaśniejszy środek
    property real markerInnerGlowInwardFactor: 1.1
    property real markerInnerGlowExtraInward: 4

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
    onRedFromChanged: { scaleCanvas.requestPaint(); if (!showNeedle) valueArc.requestPaint() }
    onRedToChanged: { scaleCanvas.requestPaint(); if (!showNeedle) valueArc.requestPaint() }
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
    // CENTER LABEL
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

    // NEEDLE (simplified red line pointer with optional smoothing)
    Loader {
        id: needleLoader
        active: root.showNeedle
        sourceComponent: Component {
            Item {
                id: needle
                width: root.width
                height: root.height
                property real targetAngle: {
                    var frac = (root.value - root.min)/(root.max - root.min)
                    if (frac < 0) frac = 0
                    if (frac > 1) frac = 1
                    return (root.startAngle + frac*(root.endAngle-root.startAngle))
                }
                property real currentAngle: 0
                Behavior on currentAngle { enabled: !root.smoothNeedle; NumberAnimation { duration: 110; easing.type: Easing.OutCubic } }
                SmoothedAnimation { id: smoothAnim; target: needle; property: "currentAngle"; velocity: 2200; running: false }
                onTargetAngleChanged: {
                    if (root.smoothNeedle) {
                        smoothAnim.stop();
                        smoothAnim.to = targetAngle;
                        smoothAnim.running = true;
                    } else {
                        currentAngle = targetAngle;
                    }
                }
                onCurrentAngleChanged: needleCanvas.requestPaint()
                property real lineWidth: Math.max(2, root.needleThickness * 0.22)
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
                        ctx.save(); ctx.rotate(ang)
                        ctx.lineCap = 'round'
                        ctx.strokeStyle = root.needleColor
                        ctx.lineWidth = needle.lineWidth
                        ctx.beginPath(); ctx.moveTo(0,0); ctx.lineTo(tip,0); ctx.stroke(); ctx.restore()
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
    }

    // VALUE MARKER (radial bar) when showNeedle == false
    Canvas {
        id: markerCanvas
        anchors.fill: parent
        visible: !root.showNeedle
        onPaint: {
            var ctx = getContext('2d'); ctx.reset();
            var cx = width/2, cy = height/2; ctx.translate(cx, cy)
            var frac = (root.value - root.min)/(root.max - root.min)
            if (frac < 0) frac = 0; if (frac > 1) frac = 1
            var ang = (root.startAngle + frac*(root.endAngle-root.startAngle) + root.orientationOffset) * Math.PI/180.0
            var innerR = root.markerInnerRadius
            var outerR = root.markerOuterRadius
            if (outerR < innerR) { var tmp = outerR; outerR = innerR; innerR = tmp }
            ctx.save(); ctx.rotate(ang)
                var w = root.markerWidth
                if (root.markerWhiteNeedle) {
                    // Hybrid shape: prosty pasek do ~taperStart, potem zwężenie do ostrego czubka
                    var baseHalf = w/2
                    var useTaper = root.markerSharpTip && !root.markerRoundOuterTip
                    var taperFrac = useTaper ? root.markerTaperStartFraction : 1.0
                    if (taperFrac < 0.05) taperFrac = 0.05
                    if (taperFrac > 0.95) taperFrac = 0.95
                    var taperX = innerR + (outerR - innerR) * taperFrac
                    function buildPointerPath(innerShift) {
                        // innerShift (>=0) allows glow to extend further inward than white core
                        ctx.beginPath()
                        if (root.markerRoundOuterTip) {
                            var innerStartR = innerR - (innerShift||0)
                            var bodyEnd = outerR - baseHalf // tak aby łuk sięgał do outerR
                            if (bodyEnd < innerStartR + 0.5) bodyEnd = innerStartR + 0.5
                            // prostokątny korpus
                            ctx.moveTo(innerStartR, -baseHalf)
                            ctx.lineTo(bodyEnd, -baseHalf)
                            // półkole zewnętrzne
                            ctx.arc(bodyEnd, 0, baseHalf, -Math.PI/2, Math.PI/2, false)
                            ctx.lineTo(innerStartR, baseHalf)
                            if (root.markerRoundBase) {
                                ctx.arc(innerStartR, 0, baseHalf, Math.PI/2, -Math.PI/2, true)
                            }
                            ctx.closePath(); return;
                        }
                        if (useTaper && taperFrac < 0.999) {
                            var innerStart = innerR - (innerShift||0)
                            // Start górą prostego odcinka, potem do taperX
                            ctx.moveTo(innerStart + (markerRoundBase ? 0 : 0), -baseHalf)
                            ctx.lineTo(taperX, -baseHalf)
                            var tipLen = outerR - taperX
                            if (tipLen < 2) {
                                ctx.lineTo(outerR, -baseHalf)
                                ctx.lineTo(outerR, baseHalf)
                                ctx.lineTo(taperX, baseHalf)
                            } else {
                                var cf = Math.max(0, Math.min(1, root.markerTipCurveFactor))
                                var ctrlX = taperX + tipLen * cf
                                var ctrlYOffset = baseHalf * 0.9
                                ctx.quadraticCurveTo(ctrlX, -ctrlYOffset, outerR, 0)
                                ctx.quadraticCurveTo(ctrlX, ctrlYOffset, taperX, baseHalf)
                            }
                            ctx.lineTo(innerStart, baseHalf)
                            if (root.markerRoundBase) {
                                // półkole przesunięte do środka (powiększa długość o baseHalf do wewnątrz)
                                ctx.arc(innerStart - baseHalf, 0, baseHalf, Math.PI/2, -Math.PI/2, true)
                            }
                        } else {
                            if (root.markerSharpTip) {
                                var cf2 = Math.max(0, Math.min(1, root.markerTipCurveFactor))
                                var ctrlX2 = innerR + (outerR - innerR) * cf2
                                var innerStart2 = innerR - (innerShift||0)
                                ctx.moveTo(innerStart2, -baseHalf)
                                ctx.quadraticCurveTo(ctrlX2, -baseHalf*0.9, outerR, 0)
                ctx.quadraticCurveTo(ctrlX2, baseHalf*0.9, innerStart2, baseHalf)
                                if (root.markerRoundBase) {
                                    ctx.arc(innerStart2 - baseHalf, 0, baseHalf, Math.PI/2, -Math.PI/2, true)
                                }
                            } else {
                var innerStart3 = innerR - (innerShift||0)
                ctx.moveTo(innerStart3, -baseHalf)
                ctx.lineTo(outerR, -baseHalf)
                ctx.lineTo(outerR, baseHalf)
                ctx.lineTo(innerStart3, baseHalf)
                if (root.markerRoundBase) {
                    ctx.arc(innerStart3 - baseHalf, 0, baseHalf, Math.PI/2, -Math.PI/2, true)
                }
                            }
                        }
                        ctx.closePath()
                    }
                    function buildPointerPathWithHalf(h) {
                        var savedBase = baseHalf
                        baseHalf = h
            buildPointerPath(0)
                        baseHalf = savedBase
                    }
                    // Poświata wypełniana poszerzonymi kształtami (dopasowana do czubka)
                    if (root.markerGlow) {
                        var passes2 = Math.max(1, root.markerGlowPasses)
                        // Rysujemy od najbardziej zewnętrznej warstwy do wewnętrznej.
                        for (var gp = passes2; gp >= 1; gp--) {
                            var outerFrac = gp / passes2         // 1..(1/passes)
                            var expansion = root.markerGlowSpreadPx * outerFrac
                            var innerFrac = 1 - outerFrac        // 0 przy zewnętrznej, ~1 przy wewnętrznej
                            var alphaFrac = Math.pow(innerFrac, root.markerGlowFalloffPower)
                            if (alphaFrac <= 0) continue
                            // Also expand inward by same expansion * 0.6 to get halo inside
                            var inward = expansion * root.markerGlowInwardFactor + root.markerGlowExtraInward
                            var savedBase2 = baseHalf
                            baseHalf = savedBase2 + expansion
                            buildPointerPath(inward)
                            baseHalf = savedBase2
                            ctx.fillStyle = root.markerGlowColor
                            ctx.globalAlpha = root.markerGlowMaxAlpha * alphaFrac
                            ctx.fill()
                        }
                        ctx.globalAlpha = 1.0
                        // Wewnętrzne białe halo (rysujemy po czerwonym aby biały "rdzeń rozmyty" przykrył środek)
                        if (root.markerInnerWhiteGlow) {
                            var passesW = Math.max(1, root.markerInnerGlowPasses)
                            for (var wp = passesW; wp >= 1; wp--) {
                                var wOuterFrac = wp / passesW
                                var wExpansion = root.markerInnerGlowSpreadPx * wOuterFrac
                                var wInnerFrac = 1 - wOuterFrac
                                var wAlphaFrac = Math.pow(wInnerFrac, root.markerInnerGlowFalloffPower)
                                if (wAlphaFrac <= 0) continue
                                var wInward = wExpansion * root.markerInnerGlowInwardFactor + root.markerInnerGlowExtraInward
                                var savedBaseW = baseHalf
                                baseHalf = savedBaseW + wExpansion
                                buildPointerPath(wInward)
                                baseHalf = savedBaseW
                                ctx.fillStyle = root.markerInnerGlowColor
                                ctx.globalAlpha = root.markerInnerGlowMaxAlpha * wAlphaFrac
                                ctx.fill()
                            }
                            ctx.globalAlpha = 1.0
                        }
                    }
                    // Rdzeń biały
                    buildPointerPath(0)
                    ctx.fillStyle = root.markerCoreColor
                    ctx.fill()
                    // Cienka linia wewnętrzna
                    if (w > 3) {
                        ctx.strokeStyle = 'rgba(0,0,0,0.32)'
                        ctx.lineWidth = 1
                        ctx.beginPath();
                        ctx.moveTo(innerR + 1.0, 0)
                        ctx.lineTo(taperX - 0.6, 0)
                        ctx.stroke()
                    }
                } else {
                    var baseColor = (root.value >= root.redFrom ? root.redlineColor : root.markerColor)
                    if (root.markerGlow) {
                        ctx.globalAlpha = root.markerGlowAlpha
                        ctx.fillStyle = baseColor
                        for (var g=0; g<3; g++) {
                            ctx.beginPath(); ctx.rect(innerR - g*1.5, -(w/2) - g*1.2, (outerR - innerR) + g*3.0, w + g*2.4); ctx.fill()
                        }
                        ctx.globalAlpha = 1.0
                    }
                    if (root.markerGradient) {
                        var grd = ctx.createLinearGradient(innerR,0, outerR,0)
                        grd.addColorStop(0, baseColor)
                        grd.addColorStop(1, (root.value >= root.redFrom ? root.redlineColor : root.markerColorEnd))
                        ctx.fillStyle = grd
                    } else {
                        ctx.fillStyle = baseColor
                    }
                    ctx.beginPath(); ctx.rect(innerR, -w/2, (outerR - innerR), w); ctx.fill()
                    ctx.strokeStyle = root.markerBorderColor
                    ctx.lineWidth = 1
                    ctx.beginPath(); ctx.moveTo(innerR, -w/2); ctx.lineTo(outerR, -w/2); ctx.stroke()
                    ctx.beginPath(); ctx.moveTo(innerR,  w/2); ctx.lineTo(outerR,  w/2); ctx.stroke()
                }
            ctx.restore()
        }
        Component.onCompleted: if (!root.showNeedle) requestPaint()
    }

    // Update marker when value or geometry changes
    onValueChanged: if (!showNeedle) markerCanvas.requestPaint()
    onStartAngleChanged: if (!showNeedle) markerCanvas.requestPaint()
    onEndAngleChanged: if (!showNeedle) markerCanvas.requestPaint()
    // (redFrom handled above with scale repaint & marker repaint)
}
