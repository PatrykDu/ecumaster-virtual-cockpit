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
    property int valueLineWidth: 3
    property bool valueLineSnap: true
    // Red/blue danger bars above track (outside optimal range)
    property int dangerBarHeight: 7  // +1 higher per request
    // Vertical value line extends into danger bar area
    property int valueLineHeightAbove: dangerBarHeight
    property int dangerBarOffset: 0   // gap above track (0 = touching)
    // Marker styling for optimal range boundaries
    property int markerWidth: 4
    property color markerColor: '#d62828'
    // Low-side (cold) danger color for temperatures
    property color lowTempDangerColor: '#1e66ff'
    function valueToX(v, vmin, vmax, trackW) { return trackW * (v - vmin) / (vmax - vmin); }
    function markerPos(v, vmin, vmax, trackW) { return Math.round(valueToX(v, vmin, vmax, trackW) - markerWidth/2); }
    // Ensure crisp danger bars
    property bool dangerSnap: true

    // Compute a track width so that its global right edge matches AFR track's global right edge
    function unifiedWidth(rowItem, trackLocalX) {
        if (!afrRow || !afrTrack) return barWidth; // fallback before component fully constructed
        // Global right edge of AFR track
        var afrRight = afrRow.x + afrTrack.x + afrTrack.width;
        var thisLeft = rowItem.x + trackLocalX;
        return px(Math.max(10, afrRight - thisLeft));
    }

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
                // Width so global right edge aligns with AFR track
                width: unifiedWidth(oilRow, oilTrack.x)
                height: barHeight
                radius: 0
                color: trackColor
                antialiasing: false
                border.width: 0
                clip: true
                Rectangle {
                    id: oilFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (oilTemp <= tempBarMin) ? 0 : (oilTemp >= tempBarMax ? parent.width : parent.width * (oilTemp - tempBarMin) / (tempBarMax - tempBarMin))
                    radius: 0
                    color: root.tempColor(oilTemp)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                    border.width: 0
                }
                // Optimal range markers removed – replaced by external danger bars
            }
            // Danger bars (outside optimal range) for OIL (render above track)
            Rectangle { // left danger (below optimal - cold => blue)
                y: dangerSnap ? px(oilTrack.y - dangerBarOffset - dangerBarHeight) : oilTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(oilTrack.x) : oilTrack.x
                width: dangerSnap ? px(valueToX(80, tempBarMin, tempBarMax, oilTrack.width)) : valueToX(80, tempBarMin, tempBarMax, oilTrack.width)
                height: dangerBarHeight
                color: lowTempDangerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle { // right danger (above optimal)
                y: dangerSnap ? px(oilTrack.y - dangerBarOffset - dangerBarHeight) : oilTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(oilTrack.x + valueToX(114, tempBarMin, tempBarMax, oilTrack.width)) : oilTrack.x + valueToX(114, tempBarMin, tempBarMax, oilTrack.width)
                width: dangerSnap ? px(oilTrack.width - valueToX(114, tempBarMin, tempBarMax, oilTrack.width)) : oilTrack.width - valueToX(114, tempBarMin, tempBarMax, oilTrack.width)
                height: dangerBarHeight
                color: markerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            // External value line to avoid halo artifacts
            Rectangle {
                id: oilValueLine
                width: valueLineWidth
                height: barHeight + valueLineHeightAbove
                x: (valueLineSnap ? Math.round(oilTrack.x + Math.min(oilTrack.width - valueLineWidth, Math.max(0, oilFill.width - valueLineWidth/2))) : oilTrack.x + Math.min(oilTrack.width - valueLineWidth, Math.max(0, oilFill.width - valueLineWidth/2)))
                y: valueLineSnap ? Math.round(oilTrack.y - valueLineHeightAbove) : oilTrack.y - valueLineHeightAbove
                color: root.tempColor(oilTemp)
                visible: oilTemp > tempBarMin && oilTemp < tempBarMax
                antialiasing: false
                border.width: 0
                z: 50
                layer.enabled: true
                layer.smooth: false
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
                // Align global right edge with AFR track
                width: unifiedWidth(waterRow, waterTrack.x)
                height: barHeight
                radius: 0
                color: trackColor
                antialiasing: false
                border.width: 0
                clip: true
                Rectangle {
                    id: waterFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (waterTemp <= tempBarMin) ? 0 : (waterTemp >= tempBarMax ? parent.width : parent.width * (waterTemp - tempBarMin) / (tempBarMax - tempBarMin))
                    radius: 0
                    color: root.tempColor(waterTemp)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                    border.width: 0
                }
                // markers removed
            }
            // Danger bars (outside optimal range) for WATER
            Rectangle { // left danger (below optimal - cold => blue)
                y: dangerSnap ? px(waterTrack.y - dangerBarOffset - dangerBarHeight) : waterTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(waterTrack.x) : waterTrack.x
                width: dangerSnap ? px(valueToX(80, tempBarMin, tempBarMax, waterTrack.width)) : valueToX(80, tempBarMin, tempBarMax, waterTrack.width)
                height: dangerBarHeight
                color: lowTempDangerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle { // right danger (above optimal)
                y: dangerSnap ? px(waterTrack.y - dangerBarOffset - dangerBarHeight) : waterTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(waterTrack.x + valueToX(114, tempBarMin, tempBarMax, waterTrack.width)) : waterTrack.x + valueToX(114, tempBarMin, tempBarMax, waterTrack.width)
                width: dangerSnap ? px(waterTrack.width - valueToX(114, tempBarMin, tempBarMax, waterTrack.width)) : waterTrack.width - valueToX(114, tempBarMin, tempBarMax, waterTrack.width)
                height: dangerBarHeight
                color: markerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle {
                id: waterValueLine
                width: valueLineWidth
                height: barHeight + valueLineHeightAbove
                x: (valueLineSnap ? Math.round(waterTrack.x + Math.min(waterTrack.width - valueLineWidth, Math.max(0, waterFill.width - valueLineWidth/2))) : waterTrack.x + Math.min(waterTrack.width - valueLineWidth, Math.max(0, waterFill.width - valueLineWidth/2)))
                y: valueLineSnap ? Math.round(waterTrack.y - valueLineHeightAbove) : waterTrack.y - valueLineHeightAbove
                color: root.tempColor(waterTemp)
                visible: waterTemp > tempBarMin && waterTemp < tempBarMax
                antialiasing: false
                border.width: 0
                z: 50
                layer.enabled: true
                layer.smooth: false
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
        Item { // CHARGE ROW
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
            Rectangle { // Track + fill
                id: chargeTrack
                x: chargeIconWrap.x + chargeIconWrap.width + iconPaddingH
                y: barYOffset
                // Align global right edge with AFR track
                width: unifiedWidth(chargeRow, chargeTrack.x)
                height: barHeight
                radius: 0
                color: trackColor
                antialiasing: false
                border.width: 0
                clip: true
                Rectangle {
                    id: chargeFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (chargingVolt <= chargeBarMin) ? 0 : (chargingVolt >= chargeBarMax ? parent.width : parent.width * (chargingVolt - chargeBarMin) / (chargeBarMax - chargeBarMin))
                    radius: 0
                    color: chargeColor(chargingVolt)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                    border.width: 0
                }
                // markers removed
            }
            // Danger bars (outside optimal range 13 - 15 V)
            Rectangle { // left danger
                y: dangerSnap ? px(chargeTrack.y - dangerBarOffset - dangerBarHeight) : chargeTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(chargeTrack.x) : chargeTrack.x
                width: dangerSnap ? px(valueToX(13, chargeBarMin, chargeBarMax, chargeTrack.width)) : valueToX(13, chargeBarMin, chargeBarMax, chargeTrack.width)
                height: dangerBarHeight
                color: markerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle { // right danger
                y: dangerSnap ? px(chargeTrack.y - dangerBarOffset - dangerBarHeight) : chargeTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(chargeTrack.x + valueToX(15, chargeBarMin, chargeBarMax, chargeTrack.width)) : chargeTrack.x + valueToX(15, chargeBarMin, chargeBarMax, chargeTrack.width)
                width: dangerSnap ? px(chargeTrack.width - valueToX(15, chargeBarMin, chargeBarMax, chargeTrack.width)) : chargeTrack.width - valueToX(15, chargeBarMin, chargeBarMax, chargeTrack.width)
                height: dangerBarHeight
                color: markerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle {
                id: chargeValueLine
                width: valueLineWidth
                height: barHeight + valueLineHeightAbove
                x: (valueLineSnap ? Math.round(chargeTrack.x + Math.min(chargeTrack.width - valueLineWidth, Math.max(0, chargeFill.width - valueLineWidth/2))) : chargeTrack.x + Math.min(chargeTrack.width - valueLineWidth, Math.max(0, chargeFill.width - valueLineWidth/2)))
                y: valueLineSnap ? Math.round(chargeTrack.y - valueLineHeightAbove) : chargeTrack.y - valueLineHeightAbove
                color: chargeColor(chargingVolt)
                visible: chargingVolt > chargeBarMin && chargingVolt < chargeBarMax
                antialiasing: false
                border.width: 0
                z: 50
                layer.enabled: true
                layer.smooth: false
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
        Item { // OIL PRESSURE ROW
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
            Rectangle { // Track + fill (oil pressure shortened)
                id: oilPressTrack
                x: px(oilPressIconWrap.x + oilPressIconWrap.width + iconPaddingH)
                y: barYOffset
                // Align global right edge with AFR track
                width: unifiedWidth(oilPressRow, oilPressTrack.x)
                height: barHeight
                radius: 0
                color: trackColor
                antialiasing: false
                border.width: 0
                clip: true
                Rectangle {
                    id: oilPressFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (oilPressure <= oilPressBarMin) ? 0 : (oilPressure >= oilPressBarMax ? parent.width : parent.width * (oilPressure - oilPressBarMin) / (oilPressBarMax - oilPressBarMin))
                    radius: 0
                    color: oilPressColor(oilPressure)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                    border.width: 0
                }
                // markers removed
            }
            // Danger bars (outside optimal range 1.2 - 6.5 bar)
            Rectangle { // left danger
                y: dangerSnap ? px(oilPressTrack.y - dangerBarOffset - dangerBarHeight) : oilPressTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(oilPressTrack.x) : oilPressTrack.x
                width: dangerSnap ? px(valueToX(1.2, oilPressBarMin, oilPressBarMax, oilPressTrack.width)) : valueToX(1.2, oilPressBarMin, oilPressBarMax, oilPressTrack.width)
                height: dangerBarHeight
                color: markerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle { // right danger
                y: dangerSnap ? px(oilPressTrack.y - dangerBarOffset - dangerBarHeight) : oilPressTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(oilPressTrack.x + valueToX(6.5, oilPressBarMin, oilPressBarMax, oilPressTrack.width)) : oilPressTrack.x + valueToX(6.5, oilPressBarMin, oilPressBarMax, oilPressTrack.width)
                width: dangerSnap ? px(oilPressTrack.width - valueToX(6.5, oilPressBarMin, oilPressBarMax, oilPressTrack.width)) : oilPressTrack.width - valueToX(6.5, oilPressBarMin, oilPressBarMax, oilPressTrack.width)
                height: dangerBarHeight
                color: markerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle {
                id: oilPressValueLine
                width: valueLineWidth
                height: barHeight + valueLineHeightAbove
                x: (valueLineSnap ? Math.round(oilPressTrack.x + Math.min(oilPressTrack.width - valueLineWidth, Math.max(0, oilPressFill.width - valueLineWidth/2))) : oilPressTrack.x + Math.min(oilPressTrack.width - valueLineWidth, Math.max(0, oilPressFill.width - valueLineWidth/2)))
                y: valueLineSnap ? Math.round(oilPressTrack.y - valueLineHeightAbove) : oilPressTrack.y - valueLineHeightAbove
                color: oilPressColor(oilPressure)
                visible: oilPressure > oilPressBarMin && oilPressure < oilPressBarMax
                antialiasing: false
                border.width: 0
                z: 50
                layer.enabled: true
                layer.smooth: false
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
        Item { // AFR ROW
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
            Rectangle { // Track + fill
                id: afrTrack
                x: px(afrIconWrap.x + afrIconWrap.width + iconPaddingH)
                y: px(barYOffset)
                width: barWidth
                height: barHeight
                radius: 0
                color: trackColor
                antialiasing: false
                border.width: 0
                clip: true
                Rectangle {
                    id: afrFill
                    anchors.left: parent.left
                    y: 0
                    height: parent.height
                    width: (afr <= afrBarMin) ? 0 : (afr >= afrBarMax ? parent.width : parent.width * (afr - afrBarMin) / (afrBarMax - afrBarMin))
                    radius: 0
                    color: root.afrColor(afr)
                    Behavior on color { ColorAnimation { duration: 180 } }
                    antialiasing: false
                    border.width: 0
                }
                // markers removed
            }
            // Danger bars (outside optimal range 12.5 - 15.5 AFR)
            Rectangle { // left danger
                y: dangerSnap ? px(afrTrack.y - dangerBarOffset - dangerBarHeight) : afrTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(afrTrack.x) : afrTrack.x
                width: dangerSnap ? px(valueToX(12.5, afrBarMin, afrBarMax, afrTrack.width)) : valueToX(12.5, afrBarMin, afrBarMax, afrTrack.width)
                height: dangerBarHeight
                color: markerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle { // right danger
                y: dangerSnap ? px(afrTrack.y - dangerBarOffset - dangerBarHeight) : afrTrack.y - dangerBarOffset - dangerBarHeight
                x: dangerSnap ? px(afrTrack.x + valueToX(15.5, afrBarMin, afrBarMax, afrTrack.width)) : afrTrack.x + valueToX(15.5, afrBarMin, afrBarMax, afrTrack.width)
                width: dangerSnap ? px(afrTrack.width - valueToX(15.5, afrBarMin, afrBarMax, afrTrack.width)) : afrTrack.width - valueToX(15.5, afrBarMin, afrBarMax, afrTrack.width)
                height: dangerBarHeight
                color: markerColor
                antialiasing: false
                border.width: 0
                z: 40
                layer.enabled: true; layer.smooth: false
            }
            Rectangle {
                id: afrValueLine
                width: valueLineWidth
                height: barHeight + valueLineHeightAbove
                x: (valueLineSnap ? Math.round(afrTrack.x + Math.min(afrTrack.width - valueLineWidth, Math.max(0, afrFill.width - valueLineWidth/2))) : afrTrack.x + Math.min(afrTrack.width - valueLineWidth, Math.max(0, afrFill.width - valueLineWidth/2)))
                y: valueLineSnap ? Math.round(afrTrack.y - valueLineHeightAbove) : afrTrack.y - valueLineHeightAbove
                color: root.afrColor(afr)
                visible: afr > afrBarMin && afr < afrBarMax
                antialiasing: false
                border.width: 0
                z: 50
                layer.enabled: true
                layer.smooth: false
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
