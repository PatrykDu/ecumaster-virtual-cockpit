import QtQuick 2.15

// LeftCluster: rectangular utility panel with clock above and animated menu selection.
Item {
    id: root
    property real base: 110
    readonly property real ratioW: 2
    readonly property real ratioH: 3
    property real heightOverride: -1
    width: base * ratioW
    height: heightOverride > 0 ? heightOverride : base * ratioH

    // Menu options
    property var menuItems: ["suspension", "reset trip", "exhaust", "settings"]
    property int menuIndex: 0

    // Animation metrics
    property real slotSpacing: base * 0.42   // vertical distance between consecutive items
    property real selectedFont: base * 0.30
    property real dimFont: base * 0.16
    property int animMs: 180

    // Time
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // Clock above frame (fixed)
    Text {
        id: clockText
        text: Qt.formatTime(root.now, "hh:mm")
        color: "white"
        font.pixelSize: base * 0.6
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: frame.top
        anchors.bottomMargin: base * 0.55
    }

    // Frame (selection window)
    Rectangle {
        id: frame
        anchors.fill: parent
        color: "#00000000"
        border.color: "#00000000" // disable default border
        border.width: 0
        radius: 8
        antialiasing: true

        // Gradient stroke (very transparent red)
        readonly property color gradStart: Qt.rgba(1,0.1,0.1,0.12)
        readonly property color gradEnd: Qt.rgba(1,0.0,0.0,0.02)
        readonly property real strokeWidth: 3

        Canvas {
            id: frameStroke
            anchors.fill: parent
            onPaint: {
                var ctx = getContext('2d');
                ctx.reset();
                var w = width; var h = height; var r = frame.radius; var sw = frame.strokeWidth;
                // Gradient vertical
                var g = ctx.createLinearGradient(0,0,0,h);
                g.addColorStop(0, frame.gradStart);
                g.addColorStop(0.5, frame.gradEnd);
                g.addColorStop(1, frame.gradStart);
                ctx.lineWidth = sw;
                ctx.strokeStyle = g;
                ctx.beginPath();
                var inset = sw/2;
                var x0 = inset, y0 = inset, x1 = w - inset, y1 = h - inset;
                var rr = Math.max(0, r - inset);
                ctx.moveTo(x0+rr, y0);
                ctx.lineTo(x1-rr, y0);
                ctx.quadraticCurveTo(x1, y0, x1, y0+rr);
                ctx.lineTo(x1, y1-rr);
                ctx.quadraticCurveTo(x1, y1, x1-rr, y1);
                ctx.lineTo(x0+rr, y1);
                ctx.quadraticCurveTo(x0, y1, x0, y1-rr);
                ctx.lineTo(x0, y0+rr);
                ctx.quadraticCurveTo(x0, y0, x0+rr, y0);
                ctx.stroke();
            }
            Component.onCompleted: requestPaint()
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
        }

        // Menu label (current selection) -- removed (handled by animated layer)
        // Text {
        //     id: menuLabel
        //     text: root.menuItems[root.menuIndex]
        //     color: 'white'
        //     font.pixelSize: base * 0.30
        //     font.bold: true
        //     anchors.centerIn: parent
        //     width: parent.width * 0.9
        //     horizontalAlignment: Text.AlignHCenter
        //     elide: Text.ElideRight
        // }
    }

    // Animated menu layer (items slide & fade)
    Item {
        id: menuLayer
        anchors.fill: parent
        // Center Y reference for selected item
        property real centerY: frame.y + frame.height/2
        Repeater {
            model: root.menuItems.length
            delegate: Text {
                id: opt
                property int idx: index
                text: root.menuItems[idx]
                color: "white"
                // Circular minimal distance
                property int n: root.menuItems.length
                property int raw: idx - root.menuIndex
                property int dist: {
                    var d = raw;
                    var half = n / 2.0;
                    if (d > half) d -= n; else if (d < -half) d += n;
                    return d;
                }
                font.pixelSize: (dist === 0 ? root.selectedFont : root.dimFont)
                opacity: (Math.abs(dist) === 0 ? 1.0 : (Math.abs(dist) === 1 ? 0.35 : 0.0))
                scale: dist === 0 ? 1.0 : 0.85
                anchors.horizontalCenter: parent.horizontalCenter
                y: menuLayer.centerY + dist * root.slotSpacing - height/2
                width: frame.width * 0.9
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                visible: opacity > 0.01
                Behavior on y { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                Behavior on opacity { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                Behavior on scale { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
                Behavior on font.pixelSize { NumberAnimation { duration: root.animMs; easing.type: Easing.OutCubic } }
            }
        }
    }

    // Listen to navigation signals from TEL
    Connections {
        target: TEL
        function onNavUpEvent() { root.menuIndex = (root.menuIndex - 1 + root.menuItems.length) % root.menuItems.length }
        function onNavDownEvent() { root.menuIndex = (root.menuIndex + 1) % root.menuItems.length }
    }
}
