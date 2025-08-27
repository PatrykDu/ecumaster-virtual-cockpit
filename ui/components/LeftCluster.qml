import QtQuick 2.15

// LeftCluster: rectangular utility panel with empty selectable area and a clock displayed above.
Item {
    id: root
    property real base: 110
    readonly property real ratioW: 2
    readonly property real ratioH: 3
    property real heightOverride: -1
    width: base * ratioW
    height: heightOverride > 0 ? heightOverride : base * ratioH

    // Time state (updates once per second)
    property date now: new Date()
    Timer { interval: 1000; running: true; repeat: true; onTriggered: root.now = new Date() }

    // Clock ABOVE the frame
    Text {
        id: clockText
        text: Qt.formatTime(root.now, "hh:mm")
        color: "white"
        font.pixelSize: base * 0.9
        font.bold: true
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: frame.top
        anchors.bottomMargin: 14
    }

    // Visual outline rectangle (empty content area for future menu/pages)
    Rectangle {
        id: frame
        anchors.fill: parent
        color: "#00000000"
        border.color: "white"
        border.width: 3
        radius: 8
        antialiasing: true
    }
}
