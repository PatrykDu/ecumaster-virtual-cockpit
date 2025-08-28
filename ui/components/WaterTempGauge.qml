import QtQuick 2.15

// WaterTempGauge: Mirrored version of FuelGauge for coolant / water temperature.
// Labels: C (cold) at bottom, 95 (normal) mid, H (hot) at top.
// Geometry is mirrored horizontally (guide + slanted fill on the RIGHT side instead of left).
// Fill extends leftwards from the irregular right edge polyline.
Item {
    id: root
    // External temperature value (0..150). Only 50..130 is displayed as fill.
    property int tempC: 0
    // Backward compatibility read-only style: level mirrors tempC (not an alias)
    property int level: tempC
    property int minVisible: 50
    property int maxVisible: 130

    // Bars (labels updated to temperature values)
    property var bars: [
        { w: 150, shift: 5,  thick: 6, label: '50' },
        { w: 75,  shift: 15, thick: 3 },
        { w: 150, shift: 30, thick: 6, label: '90' },
        { w: 78,  shift: 50, thick: 3 },
        { w: 155, shift: 80, thick: 6, label: '130' }
    ]

    // Icon configuration
    property int iconSize: 60
    property int iconGap: 8                // gap between icon and label
    property url iconSource: '../../assets/water_temp.png'
    property int iconBackingSideTrim: 6
    property real iconVerticalLift: (iconSize - fullLabelSize)/2
    property int iconExtraLift: -4

    // Appearance customization (mirrors FuelGauge defaults)
    property color barColor: 'white'
    property color labelColor: 'white'
    property int labelGap: 8               // gap from bar to label (label on LEFT side for mirrored gauge)
    property int halfLabelSize: 30
    property int fullLabelSize: 38
    property int vSpacing: Math.round(height / (bars.length + 0.5))

    // Fill configuration (constant width parallelogram, solid color) – extends LEFT from right edge polyline
    property int fillWidth: 155
    property bool clampInside: false
    // Temperature color thresholds (will be used as gradient anchors, not abrupt states)
    property int lowTempThreshold: 80      // below => blue
    property int highTempThreshold: 114    // above => red
    property color lowTempColor: '#0078ff'
    property color neutralTempColor: '#F0F0E8'
    property color highTempColor: '#ff2a00'
    // New gradient range definitions
    property int coldGradientStart: 70   // <= -> fully blue
    property int coldGradientEnd: 80     // >= -> fully neutral
    property int hotGradientStart: 110   // <= -> still neutral
    property int hotGradientEnd: 120     // >= -> fully red
    // Extension ONLY for fill (not for guide). Here we extend rightwards (since guide sits exactly on right edge);
    // then subtract this when building fill left points.
    property int rightPad: 1
    property real fillInwardNudge: 0.5 // keeps fill just inside guide to avoid AA seam

    // Slight extra right extension ONLY for top 'H' bar to hide seam with guide.
    property int topBarRightExtend: 2

    // Guide line settings (mirrored: at right irregular edge)
    property bool showRightGuide: true
    property color guideColor: 'white'
    property int guideWidth: bars.length ? bars[0].thick : 6

    // Precomputed full RIGHT edge points (no rightPad so bars touch guide)
    property var fullRightEdgePoints: []

    function barCenterY(i) { return height - (i + 0.5) * vSpacing }
    function bottomFullY() { return barCenterY(0) + bars[0].thick/2 }
    function topFullY() { return barCenterY(bars.length -1) - bars[bars.length-1].thick/2 }

    function rightX(shift) { return root.width - shift }

    function computeFullRightEdge() {
        if (!bars.length || height <= 0 || width <= 0) { fullRightEdgePoints = []; return }
        var pts = []
        pts.push({x: rightX(bars[0].shift), y: bottomFullY()})
        for (var i = 1; i < bars.length - 1; ++i) {
            pts.push({x: rightX(bars[i].shift), y: barCenterY(i)})
        }
        pts.push({x: rightX(bars[bars.length -1].shift), y: topFullY()})
        fullRightEdgePoints = pts
        guideCanvas.requestPaint()
        fillCanvas.requestPaint()
    }

    Canvas {
        id: fillCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext('2d')
            ctx.reset(); ctx.clearRect(0,0,width,height)
            var raw = root.tempC
            if (raw < root.minVisible) raw = root.minVisible
            if (raw > root.maxVisible) raw = root.maxVisible
            var frac = (raw - root.minVisible)/(root.maxVisible - root.minVisible)
            if (frac <= 0) return
            var yBottom = bottomFullY()
            var yTopLimit = topFullY()
            var totalSpan = yBottom - yTopLimit
            if (totalSpan <= 0) return
            var currentTopY = yBottom - totalSpan * frac

            // Build partial right edge
            var rightPts = []
            rightPts.push({x: rightX(bars[0].shift), y: yBottom})
            for (var i = 1; i < bars.length; ++i) {
                var cy = barCenterY(i)
                var sx = rightX(bars[i].shift)
                if (cy >= currentTopY) {
                    rightPts.push({x: sx, y: cy})
                } else {
                    var cyPrev = barCenterY(i-1)
                    var sxPrev = rightX(bars[i-1].shift)
                    var t = (cyPrev - currentTopY) / (cyPrev - cy)
                    var sInterp = sxPrev + (sx - sxPrev) * t
                    rightPts.push({x: sInterp, y: currentTopY})
                    break
                }
            }
            if (frac >= 1.0) rightPts.push({x: rightX(bars[bars.length-1].shift), y: yTopLimit})

            var widthUsed = fillWidth + rightPad
            if (clampInside) {
                for (var bClamp = 0; bClamp < bars.length; ++bClamp) {
                    var minL = rightX(bars[bClamp].shift) - bars[bClamp].w
                    var cand = (rightPts[0].x + rightPad) - minL
                    if (cand < widthUsed) widthUsed = cand
                }
                if (widthUsed < 20) widthUsed = 20
            }
            // Adjust right edge outward a bit then compute left parallelogram points
            for (var rp = 0; rp < rightPts.length; ++rp) rightPts[rp].x += (rightPad - fillInwardNudge)
            var leftPts = []
            for (var p = 0; p < rightPts.length; ++p) leftPts.push({x: rightPts[p].x - widthUsed, y: rightPts[p].y})

            ctx.beginPath()
            ctx.moveTo(rightPts[0].x, rightPts[0].y)
            for (var r2 = 1; r2 < rightPts.length; ++r2) ctx.lineTo(rightPts[r2].x, rightPts[r2].y)
            for (var lp = leftPts.length -1; lp >=0; --lp) ctx.lineTo(leftPts[lp].x, leftPts[lp].y)
            ctx.closePath()
            // Smooth gradient temperature color selection
            ctx.fillStyle = root.tempFillColor(root.tempC)
            ctx.globalAlpha = 0.90
            ctx.fill()
        }
    }

    onRightPadChanged: computeFullRightEdge()
    onWidthChanged: computeFullRightEdge()
    onHeightChanged: computeFullRightEdge()
    onLevelChanged: fillCanvas.requestPaint()
    onTempCChanged: fillCanvas.requestPaint()
    Component.onCompleted: computeFullRightEdge()

    // Color blending helpers
    function blendChannel(a,b,t){ return Math.round(a + (b-a)*t) }
    function hexToRgb(col) {
        var h = String(col)
        if (h[0] !== '#') {
            var map = { red:'#ff0000', yellow:'#ffff00', blue:'#0000ff', white:'#ffffff', black:'#000000' }
            h = map[h.toLowerCase()] || '#ffffff'
        }
        h = h.slice(1)
        if (h.length === 3) h = h[0]+h[0]+h[1]+h[1]+h[2]+h[2]
        return { r: parseInt(h.substr(0,2),16), g: parseInt(h.substr(2,2),16), b: parseInt(h.substr(4,2),16) }
    }
    function rgbToHex(r,g,b){
        function c(v){ var s=v.toString(16); return s.length===1 ? '0'+s : s }
        return '#'+c(r)+c(g)+c(b)
    }
    // Gradient: blue (<=70) -> blend 70-80 -> neutral 80-110 -> blend 110-120 -> red >=120
    function tempFillColor(tC) {
        var coldStart = coldGradientStart
        var coldEnd = coldGradientEnd
        var hotStart = hotGradientStart
        var hotEnd = hotGradientEnd
        if (tC <= coldStart) return lowTempColor
        if (tC < coldEnd) {
            var t1 = (tC - coldStart)/(coldEnd - coldStart) // 0..1
            // ease-in a bit
            t1 = t1*t1
            var cB = hexToRgb(lowTempColor); var cN = hexToRgb(neutralTempColor)
            return rgbToHex(blendChannel(cB.r,cN.r,t1), blendChannel(cB.g,cN.g,t1), blendChannel(cB.b,cN.b,t1))
        }
        if (tC <= hotStart) return neutralTempColor
        if (tC < hotEnd) {
            var t2 = (tC - hotStart)/(hotEnd - hotStart)
            // ease-out
            t2 = 1 - (1-t2)*(1-t2)
            var cN2 = hexToRgb(neutralTempColor); var cR = hexToRgb(highTempColor)
            return rgbToHex(blendChannel(cN2.r,cR.r,t2), blendChannel(cN2.g,cR.g,t2), blendChannel(cN2.b,cR.b,t2))
        }
        return highTempColor
    }

    // Bars + labels drawn ABOVE fill but BELOW guide line (mirrored)
    Repeater {
        model: bars.length
        delegate: Item {
            width: root.width
            height: vSpacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: index * vSpacing
            Rectangle {
                property bool isTopH: bars[index].label === '130'
                width: bars[index].w + (isTopH ? topBarRightExtend : 0)
                height: bars[index].thick
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.width - bars[index].shift - width
                color: barColor
            }
            Text { // label (to LEFT of bar)
                id: labelText
                visible: typeof bars[index].label !== 'undefined'
                text: bars[index].label
                color: labelColor
                // All labels unified to full size (same as FuelGauge F / E)
                font.pixelSize: fullLabelSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: root.width - bars[index].shift - bars[index].w - labelGap - width
                renderType: Text.NativeRendering
            }
            // Water temp icon for bottom 50 label (placed to LEFT)
            Item {
                visible: bars[index].label === '50'
                width: iconSize
                height: iconSize
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -(iconVerticalLift + iconExtraLift)
                x: labelText.x - iconGap - width
                Rectangle {
                    anchors.centerIn: parent
                    width: Math.max(4, parent.width - 2*iconBackingSideTrim)
                    // Reduce height (trim top/bottom) so it does not stick out
                    height: parent.height - 12
                    // Icon background: keep blue when cold, red when hot, pure white in neutral band
                    color: root.tempFillColor(root.tempC)
                    radius: 4
                    Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                }
                Image {
                    anchors.fill: parent
                    source: iconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: true
                }
            }
        }
    }

    // Static full guide line on RIGHT edge
    Canvas {
        id: guideCanvas
        anchors.fill: parent
        z: 100
        visible: showRightGuide && fullRightEdgePoints.length > 1
        onPaint: {
            var ctx = getContext('2d')
            ctx.reset(); ctx.clearRect(0,0,width,height)
            var pts = fullRightEdgePoints
            if (!visible || pts.length < 2) return
            ctx.beginPath()
            ctx.moveTo(pts[0].x, pts[0].y)
            for (var i = 1; i < pts.length; ++i) ctx.lineTo(pts[i].x, pts[i].y)
            ctx.lineWidth = guideWidth
            ctx.strokeStyle = guideColor
            ctx.globalAlpha = 0.95
            ctx.stroke()
        }
    }
}
