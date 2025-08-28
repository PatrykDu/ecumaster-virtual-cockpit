import QtQuick 2.15

// FuelGauge: Bar-style fuel level indicator composed of staggered horizontal bars.
// Exposes a 'level' property (0..100) to control the yellow slanted fill.
Item {
    id: root
    property int level: TEL ? TEL.fuel : 0     // 0..100 percentage

    // Bars from bottom (index 0) upward. Each object: width (w), horizontal shift (shift), thickness (thick), optional label.
    property var bars: [
        { w: 150, shift: 5,  thick: 6, label: 'E' },
        { w: 75,  shift: 15, thick: 3 },
        { w: 150, shift: 30, thick: 6, label: '1/2' },
        { w: 78,  shift: 50, thick: 3 },
        { w: 155, shift: 80, thick: 6, label: 'F' }
    ]

    // Fuel icon configuration (added fuel_raw.png which is colored)
    property int fuelIconSize: 60          // increased from 40 (50% larger)
    property int fuelIconGap: 10           // (legacy) gap from end of bar if used directly
    property int fuelIconGapRight: 8       // gap to the right of the E label
    property url fuelIconSource: "../../assets/fuel.png"  // monochrome: black bg, transparent glyph
    property int fuelIconBackingSideTrim: 6 // how many px to trim from each horizontal side of white backing
    property real fuelIconVerticalLift: (fuelIconSize - fullLabelSize)/2 // raise so bottoms align
    property int fuelIconExtraLift: 0    // increased (was 30) for much higher placement

    // Appearance customization
    property color barColor: 'white'
    property color labelColor: 'white'
    property int labelGap: 8
    property int halfLabelSize: 30
    property int fullLabelSize: 38
    property int vSpacing: Math.round(height / (bars.length + 0.5))

    // Fill configuration (strict constant width parallelogram, solid color)
    property int fillWidth: 155   // width measured from original (un-padded) left edge
    // When true, the fill right edge is clamped per bar so it never sticks out past any shorter bar (except the longest where it fits already).
    property bool clampInside: false // constant width; ignore shorter bars
    // Dynamic color: previously abrupt switch to red below threshold; now smooth gradient
    property int lowFuelThreshold: 20
    property color fillColor: '#ffd000'
    property color lowFuelColor: '#ff2a00'
    // New explicit zones: 0-14 full red, 15-30 gradient red->yellow, >=31 full yellow
    property int redZoneMax: 14
    property int gradientStart: 15
    property int gradientEnd: 30
    // Icon-only extra gradient: 31-49 yellow->white, >=50 white
    property int iconSecondGradientStart: 31
    property int iconSecondGradientEnd: 49
    // Extension only for the FILL (not for the guide). We keep the guide exactly at bar left edges
    // so the top F bar visually touches the guide and the bottom segment is not clipped.
    // Reduced from 6 -> 3 to keep yellow fill from poking outside the guide line.
    // Reduced from 3 -> 1 and add subPixelNudge to move fill just inside guide (prevent any visible protrusion)
    property int leftPad: 1       // pixels to extend fill leftwards (guide ignores this)
    property real fillInwardNudge: 0.5 // pushes fill rightwards inside guide to avoid AA leak

    // Slight extra left extension ONLY for drawing the top 'F' bar to hide the tiny seam with the guide.
    property int topFBarLeftExtend: 2

    // Static guide line (always full shape) settings
    property bool showLeftGuide: true
    property color guideColor: 'white'
    property int guideWidth: bars.length ? bars[0].thick : 6

    // Precomputed FULL left edge points for the GUIDE ONLY (no leftPad applied so bars touch it).
    property var fullLeftEdgePoints: []

    function barCenterY(i) { return height - (i + 0.5) * vSpacing }
    function bottomFullY() { return barCenterY(0) + bars[0].thick/2 }
    function topFullY() { return barCenterY(bars.length -1) - bars[bars.length-1].thick/2 }

    // Recompute static full left edge polyline (guide path). No leftPad subtraction here to avoid clipping
    // and to make the top 'F' bar touch the guide.
    function computeFullLeftEdge() {
        if (!bars.length || height <= 0) { fullLeftEdgePoints = []; return }
        var pts = []
        pts.push({x: bars[0].shift, y: bottomFullY()})
        for (var i = 1; i < bars.length - 1; ++i) {
            pts.push({x: bars[i].shift, y: barCenterY(i)})
        }
        // Final top cap point (top of last bar)
        pts.push({x: bars[bars.length -1].shift, y: topFullY()})
        fullLeftEdgePoints = pts
        guideCanvas.requestPaint()
        fillCanvas.requestPaint() // ensure fill updates after geometry changes
    }

    Canvas {
        id: fillCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext('2d')
            ctx.reset(); ctx.clearRect(0,0,width,height)
            var frac = Math.max(0, Math.min(1, root.level/100.0))
            if (frac <= 0) return
            var yBottom = bottomFullY()
            var yTopLimit = topFullY()
            var totalSpan = yBottom - yTopLimit
            if (totalSpan <= 0) return
            var currentTopY = yBottom - totalSpan * frac
            // Build partial left edge for current fill (copy of static logic but truncated at currentTopY)
            var leftPts = []
            leftPts.push({x: bars[0].shift, y: yBottom})
            for (var i = 1; i < bars.length; ++i) {
                var cy = barCenterY(i)
                var sx = bars[i].shift
                if (cy >= currentTopY) {
                    leftPts.push({x: sx, y: cy})
                } else {
                    var cyPrev = barCenterY(i-1)
                    var sxPrev = bars[i-1].shift
                    var t = (cyPrev - currentTopY) / (cyPrev - cy)
                    var sInterp = sxPrev + (sx - sxPrev) * t
                    leftPts.push({x: sInterp, y: currentTopY})
                    break
                }
            }
            if (frac >= 1.0) leftPts.push({x: bars[bars.length-1].shift, y: yTopLimit})
            // Constant-width parallelogram (ignore shorter bars)
            var widthUsed = fillWidth + leftPad
            if (clampInside) {
                // (Kept for potential future use; currently disabled)
                for (var bClamp = 0; bClamp < bars.length; ++bClamp) {
                    var maxR = bars[bClamp].shift + bars[bClamp].w
                    var cand = maxR - (leftPts[0].x - leftPad)
                    if (cand < widthUsed) widthUsed = cand
                }
                if (widthUsed < 20) widthUsed = 20
            }
            // Apply leftPad only to fill (not guide)
            for (var lp = 0; lp < leftPts.length; ++lp) leftPts[lp].x -= (leftPad - fillInwardNudge)
            var rightPts = []
            for (var p = 0; p < leftPts.length; ++p) rightPts.push({x: leftPts[p].x + widthUsed, y: leftPts[p].y})
            ctx.beginPath()
            ctx.moveTo(leftPts[0].x, leftPts[0].y)
            for (var lp2 = 1; lp2 < leftPts.length; ++lp2) ctx.lineTo(leftPts[lp2].x, leftPts[lp2].y)
            for (var rp = rightPts.length -1; rp >=0; --rp) ctx.lineTo(rightPts[rp].x, rightPts[rp].y)
            ctx.closePath()
            ctx.fillStyle = root.fuelFillColor(root.level)
            ctx.globalAlpha = 0.90
            ctx.fill()
        }
    }
    onLeftPadChanged: { computeFullLeftEdge() }
    onWidthChanged: { computeFullLeftEdge() }
    onHeightChanged: { computeFullLeftEdge() }
    onLevelChanged: fillCanvas.requestPaint() // repaint when fuel changes
    Component.onCompleted: computeFullLeftEdge()

    // Smooth gradient color helper (linear blend)
    function blendChannel(a,b,t){ return Math.round(a + (b-a)*t) }
    function hexToRgb(col) {
        // Ensure we operate on a string (QML color literals may not be plain strings)
        var h = String(col)
        // Convert named colors if ever used (fallback to yellowish neutral)
        if (h[0] !== '#') {
            // Minimal named color support; extend if needed
            var map = { red:'#ff0000', yellow:'#ffff00', blue:'#0000ff', white:'#ffffff', black:'#000000' }
            h = map[h.toLowerCase()] || '#ffd000'
        }
        h = h.slice(1)
        if (h.length === 3) h = h[0]+h[0]+h[1]+h[1]+h[2]+h[2]
        return { r: parseInt(h.substr(0,2),16), g: parseInt(h.substr(2,2),16), b: parseInt(h.substr(4,2),16) }
    }
    function rgbToHex(r,g,b){
        function c(v){ var s=v.toString(16); return s.length===1 ? '0'+s : s }
        return '#'+c(r)+c(g)+c(b)
    }
    // Returns a color based on new zones: red (0-14), gradient (15-30), yellow (>=31)
    function fuelFillColor(lvl) {
        if (lvl <= redZoneMax) return lowFuelColor
        if (lvl >= gradientEnd + 1) return fillColor // >=31
        // Gradient segment
        var gs = gradientStart
        var ge = gradientEnd
        var t = (lvl - gs) / (ge - gs) // 0 at 15, 1 at 30
        // Ease-in-out slight smoothing
        t = t < 0 ? 0 : (t > 1 ? 1 : (t*t*(3 - 2*t)))
        var cR = hexToRgb(lowFuelColor)
        var cY = hexToRgb(fillColor)
        return rgbToHex(blendChannel(cR.r,cY.r,t), blendChannel(cR.g,cY.g,t), blendChannel(cR.b,cY.b,t))
    }

    // Icon-specific color (adds second gradient yellow->white 31-49, white 50+)
    function fuelIconColor(lvl) {
        if (lvl <= redZoneMax) return lowFuelColor
        if (lvl <= gradientEnd) return fuelFillColor(lvl)
        var s2 = iconSecondGradientStart
        var e2 = iconSecondGradientEnd
        if (lvl < s2) return fillColor
        if (lvl >= e2 + 1) return '#ffffff'
        var t = (lvl - s2)/(e2 - s2) // 0 at start, 1 at end
        // gentle ease
        t = t*t*(3 - 2*t)
        var cY = hexToRgb(fillColor)
        var cW = hexToRgb('#ffffff')
        return rgbToHex(blendChannel(cY.r,cW.r,t), blendChannel(cY.g,cW.g,t), blendChannel(cY.b,cW.b,t))
    }

    // Bars + labels drawn ABOVE fill but BELOW guide line
    Repeater {
        model: bars.length
        delegate: Item {
            width: root.width
            height: vSpacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: index * vSpacing
            Rectangle {
                // Extend only the top 'F' bar slightly to the left to hide seam with guide
                property bool isTopF: bars[index].label === 'F'
                width: bars[index].w + (isTopF ? topFBarLeftExtend : 0)
                height: bars[index].thick
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: bars[index].shift - (isTopF ? topFBarLeftExtend : 0)
                color: barColor
            }
            Text { // label
                id: labelText
                visible: typeof bars[index].label !== 'undefined'
                text: bars[index].label
                color: labelColor
                font.pixelSize: bars[index].label === '1/2' ? halfLabelSize : fullLabelSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: bars[index].w + bars[index].shift + labelGap
                renderType: Text.NativeRendering
            }
            // Fuel icon for E bar (positioned after the E label)
            Item {
                visible: bars[index].label === 'E'
                width: fuelIconSize
                height: fuelIconSize
                anchors.verticalCenter: parent.verticalCenter
                // Use verticalCenterOffset instead of y (y is ignored when verticalCenter anchor set)
                anchors.verticalCenterOffset: -(fuelIconVerticalLift + fuelIconExtraLift)
                x: labelText.x + labelText.width + fuelIconGapRight
                Rectangle { // white backing so transparent glyph becomes visible as white / turns red on low fuel
                    anchors.centerIn: parent
                    width: Math.max(4, parent.width - 2*fuelIconBackingSideTrim)
                    height: parent.height
                        color: root.fuelIconColor(root.level)
                    radius: 4
                    visible: true
                    Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                }
                Image {
                    anchors.fill: parent
                    source: fuelIconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    cache: true
                }
            }
        }
    }

    // Static full guide line (independent of level)
    Canvas {
        id: guideCanvas
        anchors.fill: parent
        z: 100
        visible: showLeftGuide && fullLeftEdgePoints.length > 1
        onPaint: {
            var ctx = getContext('2d')
            ctx.reset(); ctx.clearRect(0,0,width,height)
            var pts = fullLeftEdgePoints
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
