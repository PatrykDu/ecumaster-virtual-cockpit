import QtQuick 2.15
import QtQuick.Controls 2.15

Item {
    id: root
    property real min: 0
    property real max: 100
    property real value: 0
    property real majorStep: 10
    property real minorStep: 5
    property real startAngle: -220
    property real endAngle: 40
    property real redFrom: 80
    property real redTo: 100
    property string label: ""

    property real radius: Math.min(width, height)/2 * 0.95

    width: 600; height: 600

    Canvas {
        id: scaleCanvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext('2d')
            ctx.reset()
            var cx = width/2
            var cy = height/2
            ctx.translate(cx, cy)
            ctx.rotate(Math.PI/2) // so angle 0 is up

            function angleFor(v) {
                var frac = (v - root.min)/(root.max - root.min)
                return (root.startAngle + frac*(root.endAngle-root.startAngle))*Math.PI/180.0
            }
            // background arc
            ctx.lineWidth = 14
            ctx.strokeStyle = '#333'
            ctx.beginPath()
            ctx.arc(0,0, root.radius-10, angleFor(root.min), angleFor(root.max), false)
            ctx.stroke()
            // red zone
            ctx.strokeStyle = '#ff3333'
            ctx.beginPath()
            ctx.arc(0,0, root.radius-10, angleFor(root.redFrom), angleFor(root.redTo), false)
            ctx.stroke()
            // ticks
            ctx.lineWidth = 4
            var a0, a1
            for (var v = root.min; v <= root.max + 0.001; v += root.majorStep) {
                var a = angleFor(v)
                ctx.save()
                ctx.rotate(a)
                ctx.beginPath()
                ctx.moveTo(root.radius-10,0)
                ctx.lineTo(root.radius-60,0)
                ctx.strokeStyle = '#ccc'
                ctx.stroke()
                ctx.restore()
                // label
                ctx.save()
                ctx.rotate(a)
                ctx.translate(root.radius-90,0)
                ctx.rotate(-a)
                ctx.fillStyle = '#ddd'
                ctx.font = '32px DejaVu Sans'
                ctx.textAlign = 'center'
                ctx.textBaseline = 'middle'
                ctx.fillText(String(Math.round(v)),0,0)
                ctx.restore()
            }
            // minor ticks
            ctx.lineWidth = 2
            for (var mv = root.min; mv <= root.max + 0.001; mv += root.minorStep) {
                if (Math.abs(mv % root.majorStep) < 0.001) continue
                var ma = angleFor(mv)
                ctx.save()
                ctx.rotate(ma)
                ctx.beginPath()
                ctx.moveTo(root.radius-10,0)
                ctx.lineTo(root.radius-35,0)
                ctx.strokeStyle = '#888'
                ctx.stroke()
                ctx.restore()
            }
        }
    }

    Text { // center label value
        id: valueText
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(root.value)
        color: 'white'
        font.pixelSize: 96
        font.bold: true
        layer.enabled: true
    }
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: valueText.bottom
        anchors.topMargin: 8
        text: root.label
        color: '#bbb'
        font.pixelSize: 40
    }

    // needle
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
        Behavior on currentAngle { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
        onTargetAngleChanged: currentAngle = targetAngle

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext('2d')
                ctx.reset()
                var cx = width/2
                var cy = height/2
                ctx.translate(cx, cy)
                ctx.rotate(Math.PI/2)
                ctx.rotate(needle.currentAngle * Math.PI/180.0)
                ctx.fillStyle = '#ffdd55'
                ctx.beginPath()
                ctx.moveTo(root.radius-20,0)
                ctx.lineTo(-40,-6)
                ctx.lineTo(-40,6)
                ctx.closePath()
                ctx.fill()
                ctx.fillStyle = '#222'
                ctx.beginPath()
                ctx.arc(0,0,24,0,Math.PI*2)
                ctx.fill()
                ctx.fillStyle = '#666'
                ctx.beginPath()
                ctx.arc(0,0,18,0,Math.PI*2)
                ctx.fill()
            }
        }
    }
}
