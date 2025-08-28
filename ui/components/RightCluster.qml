import QtQuick 2.15

// RightCluster: vertical stack of small horizontal bar gauges (oil temp, water temp)
// Bars show only 40–140°C range; below 40 -> empty, above 140 -> full.
Item {
    id: root
    property int oilTemp: TEL ? TEL.oilTemp : 0
    property int waterTemp: TEL ? TEL.waterTemp : 0

    // Display range for bar scaling
    property int tempBarMin: 40
    property int tempBarMax: 140

    // Layout tuning
    property int rowHeight: 60
    property int iconSize: 46
    property int iconPaddingH: 8
    property int rowSpacing: -20
    property int barWidth: width * 0.55
    property int barHeight: 14
    property color trackColor: '#404040'
    property int valueFontSize: 26

    // Helper to compute dynamic color (blue <80, white 80-114, red >114)
    function tempColor(t) { return t < 80 ? '#1e66ff' : (t > 114 ? '#d62828' : 'white'); }

    implicitWidth: 320
    implicitHeight: (rowHeight * 2) + rowSpacing

    Column {
        id: rows
        anchors.fill: parent
        spacing: rowSpacing

        // Oil temperature row
        Item {
            id: oilRow
            height: rowHeight
            width: parent.width

            // Icon + backing
            Item {
                id: oilIconWrap
                width: iconSize
                height: iconSize
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    id: oilIconBg
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: parent.height - 12
                    radius: 6
                    color: root.tempColor(oilTemp)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl('../../assets/oil_temp.png')
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }

            // Track + fill
            Rectangle {
                id: oilTrack
                x: oilIconWrap.x + oilIconWrap.width + iconPaddingH
                anchors.verticalCenter: parent.verticalCenter
                width: barWidth
                height: barHeight
                radius: barHeight / 2
                color: trackColor
                Rectangle {
                    id: oilFill
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: (oilTemp <= tempBarMin) ? 0 : (oilTemp >= tempBarMax ? parent.width : parent.width * (oilTemp - tempBarMin) / (tempBarMax - tempBarMin))
                    radius: parent.radius
                    color: root.tempColor(oilTemp)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
            }
            Text {
                id: oilValue
                text: oilTemp + '\u00B0C'
                color: root.tempColor(oilTemp)
                Behavior on color { ColorAnimation { duration: 180 } }
                font.pixelSize: valueFontSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: oilTrack.x + oilTrack.width + 12
            }
        }

        // Water temperature row
        Item {
            id: waterRow
            height: rowHeight
            width: parent.width

            Item {
                id: waterIconWrap
                width: iconSize
                height: iconSize
                anchors.verticalCenter: parent.verticalCenter
                Rectangle {
                    id: waterIconBg
                    anchors.centerIn: parent
                    width: parent.width - 8
                    height: parent.height - 8
                    radius: 6
                    color: root.tempColor(waterTemp)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
                Image {
                    anchors.fill: parent
                    source: Qt.resolvedUrl('../../assets/water_temp.png')
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                }
            }
            Rectangle {
                id: waterTrack
                x: waterIconWrap.x + waterIconWrap.width + iconPaddingH
                anchors.verticalCenter: parent.verticalCenter
                width: barWidth
                height: barHeight
                radius: barHeight / 2
                color: trackColor
                Rectangle {
                    id: waterFill
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: (waterTemp <= tempBarMin) ? 0 : (waterTemp >= tempBarMax ? parent.width : parent.width * (waterTemp - tempBarMin) / (tempBarMax - tempBarMin))
                    radius: parent.radius
                    color: root.tempColor(waterTemp)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
            }
            Text {
                id: waterValue
                text: waterTemp + '\u00B0C'
                color: root.tempColor(waterTemp)
                Behavior on color { ColorAnimation { duration: 180 } }
                font.pixelSize: valueFontSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: waterTrack.x + waterTrack.width + 12
            }
        }
    }
}
