import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

// DEV PANEL WINDOW
Window {
    id: dev
    title: "Dev Panel"
    width: 420
    height: 600
    visible: true
    color: "#202225"
    Component.onCompleted: {
        // AUTO CENTER ALL ON OPEN
        TEL.rpm = 3500;
        TEL.speed = 150;
        TEL.fuel = 50;
        TEL.waterTemp = 90;
        TEL.oilTemp = 90;
        TEL.leftBlink = false; TEL.rightBlink = false; TEL.highBeam = false; TEL.fog = false; TEL.park = false; TEL.checkEngine = false;
    }

    ColumnLayout {
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

    // WATER TEMP SLIDER
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Water Temp: ' + TEL.waterTemp + ' °C'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: waterTempSlider; from: 0; to: 150; stepSize: 1; Layout.fillWidth: true; value: TEL.waterTemp; onValueChanged: TEL.waterTemp = Math.round(value) }
        }

    // OIL TEMP SLIDER
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Oil Temp: ' + TEL.oilTemp + ' °C'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: oilTempSlider; from: 0; to: 150; stepSize: 1; Layout.fillWidth: true; value: TEL.oilTemp; onValueChanged: TEL.oilTemp = Math.round(value) }
        }

    // STATUS TOGGLES
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            Repeater {
                model: [
                    { key: 'leftBlink', label: 'Left' },
                    { key: 'rightBlink', label: 'Right' },
                    { key: 'highBeam', label: 'High' },
                    { key: 'fog', label: 'Fog' },
                    { key: 'park', label: 'Park' },
                    { key: 'checkEngine', label: 'Chk' }
                ]
                delegate: CheckBox {
                    text: modelData.label
                    checked: TEL[modelData.key]
                    onToggled: TEL[modelData.key] = checked
                    palette { button: '#333'; buttonText: 'white' }
                }
            }
        }
    // EXHAUST TOGGLE
    RowLayout {
            Layout.fillWidth: true; spacing: 8
            CheckBox {
                id: exhaustBox
                text: 'Exhaust'
                checked: false
                palette { button: '#333'; buttonText: 'white' }
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
        Rectangle { Layout.fillWidth: true; height: 1; color: '#444' }
        Button { text: "Center All"; Layout.fillWidth: true; onClicked: {
                TEL.rpm = 3500;
                TEL.speed = 150;
                TEL.fuel = 50;
                TEL.waterTemp = 90;
                TEL.oilTemp = 90;
                TEL.leftBlink = false; TEL.rightBlink = false; TEL.highBeam = false; TEL.fog = false; TEL.park = false; TEL.checkEngine = false;
            } }
        Button { text: "Zero"; Layout.fillWidth: true; onClicked: {
                TEL.rpm = 0; TEL.speed = 0; TEL.fuel = 0; TEL.waterTemp = 0; TEL.oilTemp = 0;
                TEL.leftBlink = false; TEL.rightBlink = false; TEL.highBeam = false; TEL.fog = false; TEL.park = false; TEL.checkEngine = false;
            } }
        Button { text: "Redline"; Layout.fillWidth: true; onClicked: { TEL.rpm = 6800; TEL.speed = 299 } }
        Button { text: "Blink All"; Layout.fillWidth: true; onClicked: { TEL.leftBlink = true; TEL.rightBlink = true; TEL.highBeam = true; TEL.fog = true; TEL.park = true; TEL.checkEngine = true } }
        Button { text: "Clear All"; Layout.fillWidth: true; onClicked: { TEL.leftBlink = false; TEL.rightBlink = false; TEL.highBeam = false; TEL.fog = false; TEL.park = false; TEL.checkEngine = false } }
        Item { Layout.fillHeight: true }
    }
}
