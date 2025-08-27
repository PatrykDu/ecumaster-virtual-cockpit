import QtQuick 2.15

// FuelGauge: Bar-style fuel level indicator composed of staggered horizontal bars.
// Default model matches the previously inlined version in Main.qml.
Item {
    id: root
    // Bars from bottom (index 0) upward. Each object: width (w), horizontal shift (shift), thickness (thick), optional label.
    // The shifting creates the rightward staggered visual progression.
    property var bars: [
        { w: 150, shift: 5,  thick: 6, label: 'E' },   // bottom (slight)
        { w: 75,  shift: 15, thick: 3 },               // half of 150 (thin)
        { w: 150, shift: 30, thick: 6, label: '1/2' }, // middle
        { w: 78,  shift: 50, thick: 3 },               // ~half of 155 (thin)
        { w: 155, shift: 80, thick: 6, label: 'F' }    // top (full)
    ]
    // Appearance customization
    property color barColor: 'white'
    property color labelColor: 'white'
    property int labelGap: 8
    property int halfLabelSize: 30
    property int fullLabelSize: 38

    // Vertical spacing between slots (slightly more than exact division for air on top)
    property int vSpacing: Math.round(height / (bars.length + 0.5))

    // Internal layout repeater
    Repeater {
        model: root.bars.length
        delegate: Item {
            width: root.width
            height: root.vSpacing
            anchors.bottom: parent.bottom
            anchors.bottomMargin: index * root.vSpacing
            Rectangle {
                width: root.bars[index].w
                height: root.bars[index].thick
                radius: height / 2
                anchors.verticalCenter: parent.verticalCenter
                x: root.bars[index].shift
                color: root.barColor
            }
            Text {
                visible: typeof root.bars[index].label !== 'undefined'
                text: root.bars[index].label
                color: root.labelColor
                font.pixelSize: root.bars[index].label === '1/2' ? root.halfLabelSize : root.fullLabelSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: root.bars[index].w + root.bars[index].shift + root.labelGap
                renderType: Text.NativeRendering
            }
        }
    }
}
