import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// DEV PANEL WINDOW
Window {
    id: dev
    title: "Dev Panel"
    width: 420
    // Dynamic height to fit all controls (with padding)
    height: devCol ? Math.min(900, devCol.implicitHeight + 24) : 700
    visible: true
    color: "#202225"
    Component.onCompleted: {
        // AUTO CENTER + BLINK ALL ON OPEN
        TEL.rpm = 3500;
        TEL.speed = 150;
        TEL.fuel = 50;
        TEL.waterTemp = 90;
        TEL.oilTemp = 90;
    TEL.leftBlink = true; TEL.rightBlink = true; TEL.lowBeam = true; TEL.highBeam = true; TEL.fogRear = true; TEL.underglow = true; TEL.park = true; TEL.checkEngine = true; TEL.charging = true; TEL.abs = true; TEL.wheelPressure = true;
    }

    ColumnLayout {
        id: devCol
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text { text: "Developer Panel"; color: 'white'; font.pixelSize: 20; font.bold: true }

    // RPM SLIDER
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'RPM: ' + TEL.rpm; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: rpmSlider; from: 0; to: 7000; stepSize: 10; Layout.fillWidth: true; value: TEL.rpm; onValueChanged: TEL.rpm = Math.round(value) }
        }

    // SPEED SLIDER
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Speed: ' + TEL.speed.toFixed(1) + ' km/h'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: speedSlider; from: 0; to: 300; stepSize: 0.5; Layout.fillWidth: true; value: TEL.speed; onValueChanged: TEL.speed = value }
        }

    // FUEL SLIDER
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Fuel: ' + TEL.fuel + ' %'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: fuelSlider; from: 0; to: 100; stepSize: 1; Layout.fillWidth: true; value: TEL.fuel; onValueChanged: TEL.fuel = Math.round(value) }
        }

    // OIL TEMP SLIDER (moved before water per requested order)
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Oil Temp: ' + TEL.oilTemp + ' °C'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: oilTempSlider; from: 0; to: 150; stepSize: 1; Layout.fillWidth: true; value: TEL.oilTemp; onValueChanged: TEL.oilTemp = Math.round(value) }
        }

    // WATER TEMP SLIDER (after oil temp)
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Water Temp: ' + TEL.waterTemp + ' °C'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: waterTempSlider; from: 0; to: 150; stepSize: 1; Layout.fillWidth: true; value: TEL.waterTemp; onValueChanged: TEL.waterTemp = Math.round(value) }
        }

        // CHARGING VOLTAGE SLIDER (before oil pressure & AFR)
        RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text { text: 'Charge V: ' + (TEL.chargingVolt ? TEL.chargingVolt.toFixed(2) : '0.00'); color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
                Slider { id: chargeSlider; from: 0.0; to: 20.0; stepSize: 0.05; Layout.fillWidth: true; value: TEL.chargingVolt; onValueChanged: TEL.chargingVolt = Math.round(value * 100) / 100 }
            }

        // OIL PRESSURE SLIDER (after charging)
        RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text { text: 'Oil P: ' + (TEL.oilPressure ? TEL.oilPressure.toFixed(1) : '0.0') + ' bar'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
                Slider { id: oilPressSlider; from: 0.0; to: 8.0; stepSize: 0.1; Layout.fillWidth: true; value: TEL.oilPressure; onValueChanged: TEL.oilPressure = Math.round(value * 10) / 10 }
            }

        // AFR SLIDER (last)
        RowLayout {
                Layout.fillWidth: true; spacing: 8
                Text { text: 'AFR: ' + (TEL.afr ? TEL.afr.toFixed(1) : '0.0'); color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
                Slider { id: afrSlider; from: 0.0; to: 25.0; stepSize: 0.1; Layout.fillWidth: true; value: TEL.afr; onValueChanged: TEL.afr = Math.round(value * 10) / 10 }
            }

    // STATUS TOGGLES (custom rows)
    // Row 1 centered: Left, Chk, Right
    RowLayout {
        Layout.fillWidth: true
        Layout.topMargin: -4
        Item { Layout.fillWidth: true }
        CheckBox {
            id: cbLeft
            text: "Left"
            font.pixelSize: 12
            checked: TEL.leftBlink
            onToggled: TEL.leftBlink = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbLeft.text
                color: 'white'
                font: cbLeft.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbLeft.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
        CheckBox {
            id: cbChk
            text: "Chk"
            font.pixelSize: 12
            checked: TEL.checkEngine
            onToggled: TEL.checkEngine = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbChk.text
                color: 'white'
                font: cbChk.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbChk.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
            Layout.leftMargin: 18
            Layout.rightMargin: 18
        }
        CheckBox {
            id: cbRight
            text: "Right"
            font.pixelSize: 12
            checked: TEL.rightBlink
            onToggled: TEL.rightBlink = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbRight.text
                color: 'white'
                font: cbRight.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbRight.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
        Item { Layout.fillWidth: true }
    }
    // Row 2: left group High Low, right group Chg Park
    RowLayout {
        Layout.fillWidth: true; spacing: 10
        // Left group
        CheckBox {
            id: cbLow
            text: 'Low'
            font.pixelSize: 12
            checked: TEL.lowBeam
            onToggled: TEL.lowBeam = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbLow.text
                color: 'white'
                font: cbLow.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbLow.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
        CheckBox {
            id: cbHigh
            text: 'High'
            font.pixelSize: 12
            checked: TEL.highBeam
            onToggled: TEL.highBeam = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbHigh.text
                color: 'white'
                font: cbHigh.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbHigh.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
        Item { Layout.fillWidth: true }
        // Right group
        CheckBox {
            id: cbChg
            text: 'Chg'
            font.pixelSize: 12
            checked: TEL.charging
            onToggled: TEL.charging = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbChg.text
                color: 'white'
                font: cbChg.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbChg.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
        CheckBox {
            id: cbPark
            text: 'Park'
            font.pixelSize: 12
            checked: TEL.park
            onToggled: TEL.park = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbPark.text
                color: 'white'
                font: cbPark.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbPark.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
    }
    // Row 3: left group FogR Under, right group ABS TPMS
    RowLayout {
        Layout.fillWidth: true; spacing: 10
        CheckBox {
            id: cbFog
            text: 'FogR'
            font.pixelSize: 12
            checked: TEL.fogRear
            onToggled: TEL.fogRear = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbFog.text
                color: 'white'
                font: cbFog.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbFog.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
        CheckBox {
            id: cbUnder
            text: 'Under'
            font.pixelSize: 12
            checked: TEL.underglow
            onToggled: TEL.underglow = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbUnder.text
                color: 'white'
                font: cbUnder.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbUnder.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
        Item { Layout.fillWidth: true }
        CheckBox {
            id: cbAbs
            text: 'ABS'
            font.pixelSize: 12
            checked: TEL.abs
            onToggled: TEL.abs = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbAbs.text
                color: 'white'
                font: cbAbs.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbAbs.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
        CheckBox {
            id: cbTpms
            text: 'TPMS'
            font.pixelSize: 12
            checked: TEL.wheelPressure
            onToggled: TEL.wheelPressure = checked
            palette { button: '#333'; buttonText: 'white' }
            contentItem: Text {
                text: cbTpms.text
                color: 'white'
                font: cbTpms.font
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: cbTpms.indicator.right
                anchors.leftMargin: 6
            }
            implicitWidth: indicator.width + 6 + contentItem.implicitWidth
        }
    }

    Rectangle { Layout.fillWidth: true; height: 1; color: '#444' }
    // LEFT CLUSTER NAVIGATION
        Text { text: "Left Cluster Navigation"; color: '#bbb'; font.pixelSize: 14; Layout.topMargin: -4 }
    // NAV UP
    RowLayout {
            Layout.fillWidth: true
            Item { Layout.preferredWidth: 1; Layout.fillWidth: true }
            Button { text: "\u2191"; width: 60; onClicked: TEL.invokeNavUp() }
            Item { Layout.preferredWidth: 1; Layout.fillWidth: true }
        }
    // NAV LEFT / DOWN / RIGHT
    RowLayout {
            Layout.fillWidth: true; spacing: 12
            Item { Layout.fillWidth: true }
            Button { text: "\u2190"; width: 60; onClicked: TEL.invokeNavLeft() }
            Button { text: "\u2193"; width: 60; onClicked: TEL.invokeNavDown() }
            Button { text: "\u2192"; width: 60; onClicked: TEL.invokeNavRight() }
            Item { Layout.fillWidth: true }
        }
        // Exhaust checkbox relocated under arrows
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Item { Layout.fillWidth: true }
            CheckBox {
                id: exhaustBox
                text: 'Exhaust'
                checked: false
                font.pixelSize: 12
                palette { button: '#333'; buttonText: 'white' }
                contentItem: Text {
                    text: exhaustBox.text
                    color: 'white'
                    font: exhaustBox.font
                    elide: Text.ElideRight
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: exhaustBox.indicator.right
                    anchors.leftMargin: 6
                }
                implicitWidth: indicator.width + 6 + contentItem.implicitWidth
                onToggled: if (TEL.saveExhaust) TEL.saveExhaust(checked)
                Component.onCompleted: {
                    try {
                        var xhr = new XMLHttpRequest();
                        xhr.open('GET', Qt.resolvedUrl('../data/data.json'));
                        xhr.onreadystatechange = function() {
                            if (xhr.readyState === XMLHttpRequest.DONE) {
                                try { var obj = JSON.parse(xhr.responseText); exhaustBox.checked = !!obj.exhaust; } catch(e) {}
                            }
                        }
                        xhr.send();
                    } catch(e) {}
                }
            }
            Item { Layout.fillWidth: true }
        }
        Rectangle { Layout.fillWidth: true; height: 1; color: '#444' }
        Button { text: "Center All"; Layout.fillWidth: true; onClicked: {
                TEL.rpm = 3500;
                TEL.speed = 150;
                TEL.fuel = 50;
                TEL.waterTemp = 90;
                TEL.oilTemp = 90;
    TEL.leftBlink = false; TEL.rightBlink = false; TEL.lowBeam = false; TEL.highBeam = false; TEL.fogRear = false; TEL.underglow = false; TEL.park = false; TEL.checkEngine = false; TEL.charging = false; TEL.abs = false; TEL.wheelPressure = false;
            } }
        Button { text: "Zero"; Layout.fillWidth: true; onClicked: {
                TEL.rpm = 0; TEL.speed = 0; TEL.fuel = 0; TEL.waterTemp = 0; TEL.oilTemp = 0;
    TEL.leftBlink = false; TEL.rightBlink = false; TEL.lowBeam = false; TEL.highBeam = false; TEL.fogRear = false; TEL.underglow = false; TEL.park = false; TEL.checkEngine = false; TEL.charging = false; TEL.abs = false; TEL.wheelPressure = false;
            } }
    Button { text: "Blink All"; Layout.fillWidth: true; onClicked: { TEL.leftBlink = true; TEL.rightBlink = true; TEL.lowBeam = true; TEL.highBeam = true; TEL.fogRear = true; TEL.underglow = true; TEL.park = true; TEL.checkEngine = true; TEL.charging = true; TEL.abs = true; TEL.wheelPressure = true } }
    Button { text: "Clear All"; Layout.fillWidth: true; onClicked: { TEL.leftBlink = false; TEL.rightBlink = false; TEL.lowBeam = false; TEL.highBeam = false; TEL.fogRear = false; TEL.underglow = false; TEL.park = false; TEL.checkEngine = false; TEL.charging = false; TEL.abs = false; TEL.wheelPressure = false } }
        Item { Layout.fillHeight: true }
    }
}
