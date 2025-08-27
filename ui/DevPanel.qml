import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Window {
    id: dev
    title: "Dev Panel"
    width: 420
    height: 560
    visible: true
    color: "#202225"

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 12

        Text { text: "Developer Panel"; color: 'white'; font.pixelSize: 20; font.bold: true }

        // RPM row: value label on the left, slider on the right
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: 'RPM: ' + TEL.rpm
                color: 'white'
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 90
            }
            Slider {
                id: rpmSlider
                from: 0; to: 7000; stepSize: 10
                Layout.fillWidth: true
                value: TEL.rpm
                onValueChanged: TEL.rpm = Math.round(value)
            }
        }

        // Speed row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: 'Speed: ' + TEL.speed.toFixed(1) + ' km/h'
                color: 'white'
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 90
            }
            Slider {
                id: speedSlider
                from: 0; to: 300; stepSize: 0.5
                Layout.fillWidth: true
                value: TEL.speed
                onValueChanged: TEL.speed = value
            }
        }

        // Fuel row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: 'Fuel: ' + TEL.fuel + ' %'
                color: 'white'
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 90
            }
            Slider {
                id: fuelSlider
                from: 0; to: 100; stepSize: 1
                Layout.fillWidth: true
                value: TEL.fuel
                onValueChanged: TEL.fuel = Math.round(value)
            }
        }

        // Water temp row
        RowLayout {
            Layout.fillWidth: true
            spacing: 8
            Text {
                text: 'Temp: ' + TEL.waterTemp + ' °C'
                color: 'white'
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: 90
            }
            Slider {
                id: waterTempSlider
                from: 0; to: 150; stepSize: 1
                Layout.fillWidth: true
                value: TEL.waterTemp
                onValueChanged: TEL.waterTemp = Math.round(value)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8
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

        Rectangle { Layout.fillWidth: true; height: 1; color: '#444' }

        Button {
            text: "Center RPM/Speed"
            Layout.fillWidth: true
            onClicked: { TEL.rpm = 4000; TEL.speed = 110 }
        }
        Button {
            text: "Zero"
            Layout.fillWidth: true
            onClicked: { TEL.rpm = 0; TEL.speed = 0 }
        }
        Button {
            text: "Redline"
            Layout.fillWidth: true
            onClicked: { TEL.rpm = 7800; TEL.speed = 200 }
        }
        Button {
            text: "Blink All"
            Layout.fillWidth: true
            onClicked: {
                TEL.leftBlink = true; TEL.rightBlink = true; TEL.highBeam = true; TEL.fog = true; TEL.park = true
            }
        }
        Button {
            text: "Clear All"
            Layout.fillWidth: true
            onClicked: {
                TEL.leftBlink = false; TEL.rightBlink = false; TEL.highBeam = false; TEL.fog = false; TEL.park = false
            }
        }
        Item { Layout.fillHeight: true }
    }
}
