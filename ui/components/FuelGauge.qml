import QtQuick 2.15

// FUEL GAUGE
Item {
    id: root
    property int level: TEL ? TEL.fuel : 0     // 0..100 percentage

    property var bars: [
        { w: 150, shift: 5,  thick: 6, label: 'E' },
        { w: 75,  shift: 15, thick: 3 },
        { w: 150, shift: 30, thick: 6, label: '1/2' },
        { w: 78,  shift: 50, thick: 3 },
        { w: 155, shift: 80, thick: 6, label: 'F' }
    ]

    property int fuelIconSize: 60
    property int fuelIconGap: 10
    property int fuelIconGapRight: 8
    property url fuelIconSource: "../../assets/fuel.png"
    property int fuelIconBackingSideTrim: 6
    property real fuelIconVerticalLift: (fuelIconSize - fullLabelSize)/2
    property int fuelIconExtraLift: 0

    property color barColor: 'white'
    property color labelColor: 'white'
    property int labelGap: 8
    property int halfLabelSize: 30
    property int fullLabelSize: 38
    property int vSpacing: Math.round(height / (bars.length + 0.5))

    property int fillWidth: 155
    property bool clampInside: false
    property int lowFuelThreshold: 20
    property color fillColor: '#ffd000'
    property color lowFuelColor: '#ff2a00'
    property int redZoneMax: 14
    property int gradientStart: 15
    property int gradientEnd: 30
    property int iconSecondGradientStart: 31
    property int iconSecondGradientEnd: 49
    property int leftPad: 1
    property real fillInwardNudge: 0.5

    property int topFBarLeftExtend: 2

    property bool showLeftGuide: true
    property color guideColor: 'white'
    property int guideWidth: bars.length ? bars[0].thick : 6

    property var fullLeftEdgePoints: []

    function barCenterY(i) { return height - (i + 0.5) * vSpacing }
    function bottomFullY() { return barCenterY(0) + bars[0].thick/2 }
    function topFullY() { return barCenterY(bars.length -1) - bars[bars.length-1].thick/2 }

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

    // FILL CANVAS
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
            var widthUsed = fillWidth + leftPad
            if (clampInside) {
                for (var bClamp = 0; bClamp < bars.length; ++bClamp) {
                    var maxR = bars[bClamp].shift + bars[bClamp].w
                    var cand = maxR - (leftPts[0].x - leftPad)
                    if (cand < widthUsed) widthUsed = cand
                }
                if (widthUsed < 20) widthUsed = 20
            }
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

    function blendChannel(a,b,t){ return Math.round(a + (b-a)*t) }
    function hexToRgb(col) {
        // Ensure we operate on a string (QML color literals may not be plain strings)
        var h = String(col)
        if (h[0] !== '#') {
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
    function fuelFillColor(lvl) {
        if (lvl <= redZoneMax) return lowFuelColor
        if (lvl >= gradientEnd + 1) return fillColor // >=31
        var gs = gradientStart
        var ge = gradientEnd
        var t = (lvl - gs) / (ge - gs) // 0 at 15, 1 at 30
        t = t < 0 ? 0 : (t > 1 ? 1 : (t*t*(3 - 2*t)))
        var cR = hexToRgb(lowFuelColor)
        var cY = hexToRgb(fillColor)
        return rgbToHex(blendChannel(cR.r,cY.r,t), blendChannel(cR.g,cY.g,t), blendChannel(cR.b,cY.b,t))
    }

    function fuelIconColor(lvl) {
        if (lvl <= redZoneMax) return lowFuelColor
        if (lvl <= gradientEnd) return fuelFillColor(lvl)
        var s2 = iconSecondGradientStart
        var e2 = iconSecondGradientEnd
        if (lvl < s2) return fillColor
        if (lvl >= e2 + 1) return '#ffffff'
        var t = (lvl - s2)/(e2 - s2) // 0 at start, 1 at end
        t = t*t*(3 - 2*t)
        var cY = hexToRgb(fillColor)
        var cW = hexToRgb('#ffffff')
        return rgbToHex(blendChannel(cY.r,cW.r,t), blendChannel(cY.g,cW.g,t), blendChannel(cY.b,cW.b,t))
    }

    // BARS
    Repeater {
        model: bars.length
        delegate: Item {
            width: root.width
            height: vSpacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: index * vSpacing
            Rectangle {
                property bool isTopF: bars[index].label === 'F'
                width: bars[index].w + (isTopF ? topFBarLeftExtend : 0)
                height: bars[index].thick
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: bars[index].shift - (isTopF ? topFBarLeftExtend : 0)
                color: barColor
            }
            Text {
                id: labelText
                visible: typeof bars[index].label !== 'undefined'
                text: (typeof bars[index].label === 'undefined' ? '' : bars[index].label)
                color: labelColor
                font.pixelSize: bars[index].label === '1/2' ? halfLabelSize : fullLabelSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: bars[index].w + bars[index].shift + labelGap
                renderType: Text.NativeRendering
            }
            Item {
                visible: bars[index].label === 'E'
                width: fuelIconSize
                height: fuelIconSize
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -(fuelIconVerticalLift + fuelIconExtraLift)
                x: labelText.x + labelText.width + fuelIconGapRight
                Rectangle {
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

    // GUIDE CANVAS
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
