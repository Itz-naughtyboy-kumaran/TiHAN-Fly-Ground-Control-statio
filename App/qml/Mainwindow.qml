// MainWindow.qml - Example of how to integrate the calibration window
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: mainWindow
    visible: true
    width: 1200
    height: 800
    title: "Drone Control Center"

    // Your DroneModel instance (passed from Python or created here)
    property var droneModel: null

    // Calibration window component
    Component {
        id: calibrationWindowComponent
        
        AccelCalibration {
            // Pass the droneModel to the calibration window
            droneModel: mainWindow.droneModel
            calibrationModel: null // Pass your calibration model if you have one
            
            onClosing: {
                console.log("[MainWindow] Calibration window closing")
            }
        }
    }

    // Main UI
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#34495e"
            radius: 10

            RowLayout {
                anchors.centerIn: parent
                spacing: 20

                Label {
                    text: "🚁 Drone Control Center"
                    font.pixelSize: 24
                    font.bold: true
                    color: "white"
                }

                Item { Layout.fillWidth: true }

                // Connection status indicator
                Rectangle {
                    width: 180
                    height: 40
                    color: droneModel && droneModel.isConnected ? "#27ae60" : "#e74c3c"
                    radius: 20

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Label {
                            text: droneModel && droneModel.isConnected ? "●" : "○"
                            color: "white"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Label {
                            text: droneModel && droneModel.isConnected ? "Connected" : "Disconnected"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }
            }
        }

        // Main content area
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#2c3e50"
            radius: 10

            GridLayout {
                anchors.centerIn: parent
                columns: 2
                columnSpacing: 40
                rowSpacing: 30

                // Connection controls
                GroupBox {
                    title: "Connection"
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 200

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15

                        TextField {
                            id: connectionUri
                            placeholderText: "Connection URI (e.g., udp:127.0.0.1:14550)"
                            text: "udp:127.0.0.1:14550"
                            Layout.fillWidth: true
                        }

                        TextField {
                            id: baudRate
                            placeholderText: "Baud Rate"
                            text: "57600"
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            Layout.fillWidth: true

                            Button {
                                text: droneModel && droneModel.isConnected ? "Disconnect" : "Connect"
                                Layout.fillWidth: true
                                enabled: droneModel !== null

                                background: Rectangle {
                                    color: {
                                        if (!parent.enabled) return "#95a5a6"
                                        if (droneModel && droneModel.isConnected) {
                                            return parent.pressed ? "#c0392b" : "#e74c3c"
                                        } else {
                                            return parent.pressed ? "#27ae60" : "#2ecc71"
                                        }
                                    }
                                    radius: 6
                                }

                                contentItem: Label {
                                    text: parent.text
                                    color: "white"
                                    font.bold: true
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    if (droneModel.isConnected) {
                                        droneModel.disconnectDrone()
                                    } else {
                                        droneModel.connectToDrone("main_drone", connectionUri.text, parseInt(baudRate.text))
                                    }
                                }
                            }

                            Button {
                                text: "2nd Conn"
                                Layout.preferredWidth: 80
                                enabled: droneModel && droneModel.isConnected

                                background: Rectangle {
                                    color: {
                                        if (!parent.enabled) return "#95a5a6"
                                        if (droneModel && droneModel.isSecondConnectionActive) {
                                            return parent.pressed ? "#c0392b" : "#e74c3c"
                                        } else {
                                            return parent.pressed ? "#2980b9" : "#3498db"
                                        }
                                    }
                                    radius: 6
                                }

                                contentItem: Label {
                                    text: parent.text
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 10
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                onClicked: {
                                    if (droneModel.isSecondConnectionActive) {
                                        droneModel.deactivateSecondConnection()
                                    } else {
                                        droneModel.activateSecondConnection()
                                    }
                                }
                            }
                        }
                    }
                }

                // Calibration controls
                GroupBox {
                    title: "Calibration"
                    Layout.preferredWidth: 300
                    Layout.preferredHeight: 200

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 15

                        Label {
                            text: "Drone sensor calibration tools"
                            color: "#bdc3c7"
                            wrapMode: Text.WordWrap
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "🔧 Open Calibration Center"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 50
                            enabled: droneModel !== null

                            background: Rectangle {
                                color: parent.pressed ? "#2980b9" : (parent.enabled ? "#3498db" : "#95a5a6")
                                radius: 8
                            }

                            contentItem: Label {
                                text: parent.text
                                color: "white"
                                font.bold: true
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: openCalibrationWindow()
                        }

                        Label {
                            text: droneModel && droneModel.isConnected ? 
                                  "✅ Ready for calibration" : 
                                  "⚠️ Connect drone first"
                            color: droneModel && droneModel.isConnected ? "#2ecc71" : "#e67e22"
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }

                // Telemetry display
                GroupBox {
                    title: "Telemetry"
                    Layout.columnSpan: 2
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200

                    ScrollView {
                        anchors.fill: parent
                        
                        ColumnLayout {
                            width: parent.width
                            spacing: 10

                            Label {
                                text: droneModel && droneModel.telemetry ? 
                                      "Mode: " + droneModel.telemetry.mode + 
                                      " | Armed: " + (droneModel.telemetry.armed ? "YES" : "NO") +
                                      " | Alt: " + droneModel.telemetry.alt.toFixed(1) + "m" +
                                      " | Battery: " + droneModel.telemetry.battery_remaining.toFixed(0) + "%" : 
                                      "No telemetry data"
                                color: "white"
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }

                            Label {
                                text: droneModel && droneModel.statusTexts && droneModel.statusTexts.length > 0 ? 
                                      "Last Status: " + droneModel.statusTexts[droneModel.statusTexts.length - 1] : 
                                      "No status messages"
                                color: "#bdc3c7"
                                font.pixelSize: 10
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }

    // Property to hold the calibration window instance
    property var calibrationWindow: null

    function openCalibrationWindow() {
        if (!droneModel) {
            console.error("[MainWindow] Cannot open calibration - droneModel is null")
            return
        }

        // Close existing window if open
        if (calibrationWindow) {
            calibrationWindow.close()
            calibrationWindow.destroy()
        }

        // Create new calibration window
        calibrationWindow = calibrationWindowComponent.createObject(null, {
            "droneModel": droneModel,
            "calibrationModel": null
        })

        if (calibrationWindow) {
            calibrationWindow.show()
            console.log("[MainWindow] Calibration window opened")
        } else {
            console.error("[MainWindow] Failed to create calibration window")
        }
    }

    // Clean up on close
    onClosing: {
        if (calibrationWindow) {
            calibrationWindow.close()
            calibrationWindow.destroy()
        }
    }

    Component.onCompleted: {
        console.log("[MainWindow] Main window completed")
        console.log("[MainWindow] droneModel:", droneModel)
    }
}