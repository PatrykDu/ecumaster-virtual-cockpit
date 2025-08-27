import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: dev
    title: "Dev Panel"
    width: 420
    height: 600
    visible: true
    color: "#202225"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text { text: "Developer Panel"; color: 'white'; font.pixelSize: 20; font.bold: true }

        // RPM row: value label on the left, slider on the right
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'RPM: ' + TEL.rpm; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: rpmSlider; from: 0; to: 7000; stepSize: 10; Layout.fillWidth: true; value: TEL.rpm; onValueChanged: TEL.rpm = Math.round(value) }
        }

        // Speed row
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Speed: ' + TEL.speed.toFixed(1) + ' km/h'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: speedSlider; from: 0; to: 300; stepSize: 0.5; Layout.fillWidth: true; value: TEL.speed; onValueChanged: TEL.speed = value }
        }

        // Fuel row
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Fuel: ' + TEL.fuel + ' %'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: fuelSlider; from: 0; to: 100; stepSize: 1; Layout.fillWidth: true; value: TEL.fuel; onValueChanged: TEL.fuel = Math.round(value) }
        }

        // Water temp row (renamed label)
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Water Temp: ' + TEL.waterTemp + ' °C'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: waterTempSlider; from: 0; to: 150; stepSize: 1; Layout.fillWidth: true; value: TEL.waterTemp; onValueChanged: TEL.waterTemp = Math.round(value) }
        }

        // Oil temp row (range adjusted to 0-150)
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Text { text: 'Oil Temp: ' + TEL.oilTemp + ' °C'; color: 'white'; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 110 }
            Slider { id: oilTempSlider; from: 0; to: 150; stepSize: 1; Layout.fillWidth: true; value: TEL.oilTemp; onValueChanged: TEL.oilTemp = Math.round(value) }
        }

        RowLayout {
            Layout.fillWidth: true; spacing: 8
            Repeater {
                model: [
                    { key: 'leftBlink', label: 'Left' },
                    { key: 'rightBlink', label: 'Right' },
                    { key: 'highBeam', label: 'High' },
                    { key: 'fog', label: 'Fog' },
                    { key: 'park', label: 'Park' }
                ]
                delegate: CheckBox {
                    text: modelData.label
                    checked: TEL[modelData.key]
                    onToggled: TEL[modelData.key] = checked
                    palette { button: '#333'; buttonText: 'white' }
                }
            }
        }

        // --- Left Cluster Navigation (arrow buttons) ---
        Rectangle { Layout.fillWidth: true; height: 1; color: '#444' }
        Text { text: "Left Cluster Navigation"; color: '#bbb'; font.pixelSize: 14; Layout.topMargin: -4 }
        // Grid-like arrangement using two RowLayouts
        RowLayout { // Up button centered
            Layout.fillWidth: true
            Item { Layout.preferredWidth: 1; Layout.fillWidth: true }
            Button { text: "\u2191"; width: 60; onClicked: TEL.invokeNavUp() }
            Item { Layout.preferredWidth: 1; Layout.fillWidth: true }
        }
        RowLayout { // Left, Down, Right
            Layout.fillWidth: true; spacing: 12
            Item { Layout.fillWidth: true }
            Button { text: "\u2190"; width: 60; onClicked: TEL.invokeNavLeft() }
            Button { text: "\u2193"; width: 60; onClicked: TEL.invokeNavDown() }
            Button { text: "\u2192"; width: 60; onClicked: TEL.invokeNavRight() }
            Item { Layout.fillWidth: true }
        }
        // ----------------------------------------------

        Rectangle { Layout.fillWidth: true; height: 1; color: '#444' }
        Button { text: "Center RPM/Speed"; Layout.fillWidth: true; onClicked: { TEL.rpm = 4000; TEL.speed = 110 } }
        Button { text: "Zero"; Layout.fillWidth: true; onClicked: { TEL.rpm = 0; TEL.speed = 0 } }
        Button { text: "Redline"; Layout.fillWidth: true; onClicked: { TEL.rpm = 7800; TEL.speed = 200 } }
        Button { text: "Blink All"; Layout.fillWidth: true; onClicked: { TEL.leftBlink = true; TEL.rightBlink = true; TEL.highBeam = true; TEL.fog = true; TEL.park = true } }
        Button { text: "Clear All"; Layout.fillWidth: true; onClicked: { TEL.leftBlink = false; TEL.rightBlink = false; TEL.highBeam = false; TEL.fog = false; TEL.park = false } }
        Item { Layout.fillHeight: true }
    }
}
