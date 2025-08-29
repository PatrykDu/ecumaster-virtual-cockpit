import QtQuick 2.15

// RIGHT CLUSTER (OIL & WATER TEMPS)
Item {
    id: root
    property int oilTemp: TEL ? TEL.oilTemp : 0
    property int waterTemp: TEL ? TEL.waterTemp : 0
    property real afr: TEL ? TEL.afr : 0
    property real chargingVolt: TEL ? TEL.chargingVolt : 0
    property real oilPressure: TEL ? TEL.oilPressure : 0

    property int tempBarMin: 40
    property int tempBarMax: 140

    property int rowHeight: 60
    property int iconSize: 46
    property int iconPaddingH: 8
    property int rowSpacing: -20
    property int barWidth: width * 0.55
    // Exact pixel bar height (must be integer for all rows)
    property int barHeight: 12
    // Integer-aligned bar vertical offset for crisp rendering
    property int barYOffset: Math.round((rowHeight - barHeight) / 2)
    function px(v) { return Math.round(v); }
    property color trackColor: '#404040'
    property int valueFontSize: 26
    // Marker styling for optimal range boundaries
    property int markerWidth: 4
    property color markerColor: '#d62828'
    function valueToX(v, vmin, vmax, trackW) { return trackW * (v - vmin) / (vmax - vmin); }
    function markerPos(v, vmin, vmax, trackW) { return Math.round(valueToX(v, vmin, vmax, trackW) - markerWidth/2); }

    function tempColor(t) { return t < 80 ? '#1e66ff' : (t > 114 ? '#d62828' : 'white'); }

    implicitWidth: 320
    implicitHeight: (rowHeight * 5) + (rowSpacing * 4)
    clip: false

    // Arc layout: ensure track start (icon right edge + padding) follows linear progression
    property int rowCount: 5
    property real trackBase: 54      // pixels: start (bottom row) track x relative to row.x=0
    property real trackStep: 14      // how much earlier (to the left) each upper row begins
    function desiredTrackStart(idx) { return trackBase - trackStep * (rowCount - 1 - idx); }
    // Fine adjustment for bottom AFR row
    property real afrRowExtraShift: -20

    // CHARGING VOLTAGE RANGE
    property real chargeBarMin: 11.0
    property real chargeBarMax: 16.0
    function chargeColor(v) { return (v < 13.0 || v > 15.0) ? '#d62828' : 'white'; }

    // OIL PRESSURE RANGE
    property real oilPressBarMin: 0.0
    property real oilPressBarMax: 8.0
    function oilPressColor(p) { return (p < 1.2 || p > 6.5) ? '#d62828' : 'white'; }

    // AFR RANGE
    property real afrBarMin: 10.0
    property real afrBarMax: 18.0
    function afrColor(a) { return (a < 12.5 || a > 15.5) ? '#d62828' : 'white'; }

    // LAYOUT
    Column {
        id: rows
        anchors.fill: parent
        spacing: rowSpacing

    // (oil pressure row moved lower, see after charging row)

        // Oil temperature row
    // OIL TEMP ROW
    Item {
            id: oilRow
            // Position row so that oilTrack.x (computed from icon geometry) equals desiredTrackStart(0)
            x: desiredTrackStart(0) - (oilIconWrap.x + oilIconWrap.width + iconPaddingH)
            height: rowHeight
            width: parent.width

            // Icon + backing
            Item {
                id: oilIconWrap
                // Shift & enlarge to fully show wide icon
                property real protrudeFactor: 0.22
                property real scaleFactor: 1.10
                x: -iconSize * protrudeFactor
                width: iconSize * scaleFactor
                height: iconSize * scaleFactor
                anchors.verticalCenter: parent.verticalCenter
                Item {
                    id: oilTempInner
                    anchors.centerIn: parent
                    width: Math.round(parent.width * 0.94)
                    height: Math.round(parent.height * 0.94)
                    Image {
                        id: oilTempImg
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: Qt.resolvedUrl('../../assets/oil_temp.png')
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Rectangle {
                        id: oilIconBg
                        anchors.centerIn: oilTempImg
                        // Match rendered size exactly (no vertical trim to avoid cutting icon)
                        width: oilTempImg.paintedWidth > 0 ? oilTempImg.paintedWidth : oilTempInner.width
                        height: oilTempImg.paintedHeight > 0 ? oilTempImg.paintedHeight : oilTempInner.height
                        radius: 6
                        color: root.tempColor(oilTemp)
                        z: -1
                        anchors.verticalCenterOffset: 0
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }
            }

            // Track + fill
            Rectangle {
                id: oilTrack
                // Keep bar aligned with standard column, independent of protrusion
                x: px(oilIconWrap.x + oilIconWrap.width + iconPaddingH)
                y: px(barYOffset)
                width: barWidth
                height: barHeight
                radius: barHeight / 2
                color: trackColor
                antialiasing: false
                Rectangle {
                    id: oilFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (oilTemp <= tempBarMin) ? 0 : (oilTemp >= tempBarMax ? parent.width : parent.width * (oilTemp - tempBarMin) / (tempBarMax - tempBarMin))
                    radius: parent.radius
                    color: root.tempColor(oilTemp)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                }
                // Optimal range markers (80 - 114 C)
                Rectangle {
                    x: markerPos(80, tempBarMin, tempBarMax, oilTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
                }
                Rectangle {
                    x: markerPos(114, tempBarMin, tempBarMax, oilTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
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
    // WATER TEMP ROW
    Item {
            id: waterRow
            x: desiredTrackStart(1) - (waterIconWrap.x + waterIconWrap.width + iconPaddingH)
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
                x: px(waterIconWrap.x + waterIconWrap.width + iconPaddingH)
                y: px(barYOffset)
                width: barWidth
                height: barHeight
                radius: barHeight / 2
                color: trackColor
                antialiasing: false
                Rectangle {
                    id: waterFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (waterTemp <= tempBarMin) ? 0 : (waterTemp >= tempBarMax ? parent.width : parent.width * (waterTemp - tempBarMin) / (tempBarMax - tempBarMin))
                    radius: parent.radius
                    color: root.tempColor(waterTemp)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                }
                // Optimal range markers (80 - 114 C)
                Rectangle {
                    x: markerPos(80, tempBarMin, tempBarMax, waterTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
                }
                Rectangle {
                    x: markerPos(114, tempBarMin, tempBarMax, waterTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
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

        // Charging voltage row (now just above AFR)
        Item {
            id: chargeRow
            x: desiredTrackStart(2) - (chargeIconWrap.x + chargeIconWrap.width + iconPaddingH)
            height: rowHeight
            width: parent.width
            Item {
                id: chargeIconWrap
                width: iconSize
                height: iconSize
                anchors.verticalCenter: parent.verticalCenter
                Item {
                    id: chargeInner
                    anchors.centerIn: parent
                    width: parent.width * 0.84
                    height: parent.height * 0.84
                    Image {
                        id: chargeImg
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: Qt.resolvedUrl('../../assets/charging.png')
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Rectangle {
                        id: chargeIconBg
                        anchors.centerIn: chargeImg
                        width: chargeImg.paintedWidth > 0 ? chargeImg.paintedWidth : chargeInner.width
                        height: chargeImg.paintedHeight > 0 ? chargeImg.paintedHeight : chargeInner.height
                        radius: 6
                        color: chargeColor(chargingVolt)
                        z: -1
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }
            }
            Rectangle {
                id: chargeTrack
                x: chargeIconWrap.x + chargeIconWrap.width + iconPaddingH
                y: barYOffset
                width: barWidth
                height: barHeight
                radius: barHeight / 2
                color: trackColor
                antialiasing: false
                Rectangle {
                    id: chargeFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (chargingVolt <= chargeBarMin) ? 0 : (chargingVolt >= chargeBarMax ? parent.width : parent.width * (chargingVolt - chargeBarMin) / (chargeBarMax - chargeBarMin))
                    radius: parent.radius
                    color: chargeColor(chargingVolt)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                }
                // Optimal range markers (13 - 15 V)
                Rectangle {
                    x: markerPos(13, chargeBarMin, chargeBarMax, chargeTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
                }
                Rectangle {
                    x: markerPos(15, chargeBarMin, chargeBarMax, chargeTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
                }
            }
            Text {
                id: chargeValue
                text: (chargingVolt ? chargingVolt.toFixed(1) : '0.0') + ' V'
                color: chargeColor(chargingVolt)
                Behavior on color { ColorAnimation { duration: 180 } }
                font.pixelSize: valueFontSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: chargeTrack.x + chargeTrack.width + 12
            }
        }

        // Oil PRESSURE row (moved below charging)
        Item {
            id: oilPressRow
            x: desiredTrackStart(3) - (oilPressIconWrap.x + oilPressIconWrap.width + iconPaddingH)
            height: rowHeight
            width: parent.width
            Item {
                id: oilPressIconWrap
                // Larger and further left for wide pressure symbol
                // Keep (scaleFactor - protrudeFactor) ≈ 0.83 so right gap to track stays similar
                property real protrudeFactor: 0.52
                property real scaleFactor: 1.35   // enlarged
                x: -iconSize * protrudeFactor
                width: iconSize * scaleFactor
                height: iconSize * scaleFactor
                anchors.verticalCenter: parent.verticalCenter
                Item {
                    id: oilPressInner
                    anchors.centerIn: parent
                    width: parent.width * 0.94
                    height: parent.height * 0.94
                    Image {
                        id: oilPressImg
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: Qt.resolvedUrl('../../assets/oil_pressure.png')
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                    Rectangle {
                        id: oilPressIconBg
                        anchors.centerIn: oilPressImg
                        property int trimY: 4
                        width: oilPressImg.paintedWidth > 0 ? oilPressImg.paintedWidth : oilPressInner.width
                        height: (oilPressImg.paintedHeight > 0 ? oilPressImg.paintedHeight : oilPressInner.height) - trimY
                        anchors.verticalCenterOffset: -trimY/2
                        radius: 6
                        color: oilPressColor(oilPressure)
                        z: -1
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                }
            }
            Rectangle {
                id: oilPressTrack
                x: px(oilPressIconWrap.x + oilPressIconWrap.width + iconPaddingH)
                y: barYOffset
                width: barWidth
                height: barHeight
                radius: barHeight / 2
                color: trackColor
                antialiasing: false
                Rectangle {
                    id: oilPressFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (oilPressure <= oilPressBarMin) ? 0 : (oilPressure >= oilPressBarMax ? parent.width : parent.width * (oilPressure - oilPressBarMin) / (oilPressBarMax - oilPressBarMin))
                    radius: parent.radius
                    color: oilPressColor(oilPressure)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                }
                // Optimal range markers (1.2 - 6.5 Bar)
                Rectangle {
                    x: markerPos(1.2, oilPressBarMin, oilPressBarMax, oilPressTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
                }
                Rectangle {
                    x: markerPos(6.5, oilPressBarMin, oilPressBarMax, oilPressTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
                }
            }
            Text {
                id: oilPressValue
                text: (oilPressure ? oilPressure.toFixed(1) : '0.0') + ' Bar'
                color: oilPressColor(oilPressure)
                Behavior on color { ColorAnimation { duration: 180 } }
                font.pixelSize: valueFontSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: oilPressTrack.x + oilPressTrack.width + 12
            }
        }

        // AFR row (bottom)
        Item {
            id: afrRow
            x: desiredTrackStart(4) - (afrIconWrap.x + afrIconWrap.width + iconPaddingH) + afrRowExtraShift
            height: rowHeight
            width: parent.width

            // Icon + backing
            Item {
                id: afrIconWrap
                width: iconSize
                height: iconSize
                anchors.verticalCenter: parent.verticalCenter
                // Inner container to shrink actual graphics (keep same track alignment as other rows)
                Item {
                    id: afrInner
                    // Center with integer pixel snap to avoid fractional crop
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    property real scale: 0.82  // was 0.85
                    width: Math.round(parent.width * scale)
                    height: Math.round(parent.height * scale)
                    Rectangle {
                        id: afrIconBg
                        anchors.centerIn: parent
                        // Slightly larger background with symmetric padding
                        property int pad: 6
                        width: afrInner.width - pad
                        height: afrInner.height - pad
                        radius: 6
                        color: root.afrColor(afr)
                        Behavior on color { ColorAnimation { duration: 180 } }
                    }
                    Image {
                        anchors.centerIn: afrInner
                        // Add internal margin so bitmap edges never touch container edges
                        width: afrInner.width * 0.92
                        height: afrInner.height * 0.92
                        source: Qt.resolvedUrl('../../assets/afr.png')
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        sourceSize.width: 128
                        sourceSize.height: 128
                    }
                }
            }
            // Track + fill
            Rectangle {
                id: afrTrack
                x: px(afrIconWrap.x + afrIconWrap.width + iconPaddingH)
                y: px(barYOffset)
                width: barWidth
                height: barHeight
                radius: barHeight / 2
                color: trackColor
                antialiasing: false
                Rectangle {
                    id: afrFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (afr <= afrBarMin) ? 0 : (afr >= afrBarMax ? parent.width : parent.width * (afr - afrBarMin) / (afrBarMax - afrBarMin))
                    radius: parent.radius
                    color: root.afrColor(afr)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                }
                // Optimal range markers (12.5 - 15.5 AFR)
                Rectangle {
                    x: markerPos(12.5, afrBarMin, afrBarMax, afrTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
                }
                Rectangle {
                    x: markerPos(15.5, afrBarMin, afrBarMax, afrTrack.width)
                    width: markerWidth
                    height: parent.height
                    radius: 1
                    color: markerColor
                }
            }
            Text {
                id: afrValue
                text: (afr.toFixed ? afr.toFixed(1) : afr) + ' AFR'
                color: root.afrColor(afr)
                Behavior on color { ColorAnimation { duration: 180 } }
                font.pixelSize: valueFontSize
                font.bold: true
                anchors.verticalCenter: parent.verticalCenter
                x: afrTrack.x + afrTrack.width + 12
            }
        }
    }
}
