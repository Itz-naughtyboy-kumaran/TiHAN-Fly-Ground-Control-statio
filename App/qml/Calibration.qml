// CalibrationPage.qml - Main calibration page with left panel
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Page {
    id: calibrationPage
    title: "Drone Calibration"
    
    property var calibrationModel
    property var droneModel
    
    // References to calibration windows
    property var accelWindow: null
    property var compassWindow: null
    
    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20
        
        // Left Panel - Calibration Type Selection
        GroupBox {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            title: "Calibration Types"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 15
                
                Label {
                    text: "Select Calibration Type"
                    font.pixelSize: 18
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                }
                
                // Accelerometer Calibration Button
                Button {
                    id: accelButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    enabled: droneModel.isConnected
                    
                    Rectangle {
                        anchors.fill: parent
                        color: parent.pressed ? "#3498db" : "#2980b9"
                        radius: 8
                        border.width: 2
                        border.color: parent.enabled ? "#2c3e50" : "#95a5a6"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            
                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                source: "qrc:/icons/accelerometer.png" // Add your icon
                                width: 32
                                height: 32
                                fillMode: Image.PreserveAspectFit
                            }
                            
                            Label {
                                text: "Accelerometer"
                                font.pixelSize: 14
                                font.bold: true
                                color: "white"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: "Calibrate IMU"
                                font.pixelSize: 10
                                color: "#ecf0f1"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    onClicked: {
                        openAccelCalibration()
                    }
                }
                
                // Compass Calibration Button
                Button {
                    id: compassButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    enabled: droneModel.isConnected
                    
                    Rectangle {
                        anchors.fill: parent
                        color: parent.pressed ? "#e67e22" : "#d35400"
                        radius: 8
                        border.width: 2
                        border.color: parent.enabled ? "#2c3e50" : "#95a5a6"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            
                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                source: "qrc:/icons/compass.png" // Add your icon
                                width: 32
                                height: 32
                                fillMode: Image.PreserveAspectFit
                            }
                            
                            Label {
                                text: "Compass"
                                font.pixelSize: 14
                                font.bold: true
                                color: "white"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: "Calibrate Magnetometer"
                                font.pixelSize: 10
                                color: "#ecf0f1"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    onClicked: {
                        openCompassCalibration()
                    }
                }
                
                // ESC Calibration Button
                Button {
                    id: escButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    enabled: droneModel.isConnected
                    
                    Rectangle {
                        anchors.fill: parent
                        color: parent.pressed ? "#27ae60" : "#229954"
                        radius: 8
                        border.width: 2
                        border.color: parent.enabled ? "#2c3e50" : "#95a5a6"
                        
                        ColumnLayout {
                            anchors.centerIn: parent
                            spacing: 5
                            
                            Image {
                                Layout.alignment: Qt.AlignHCenter
                                source: "qrc:/icons/esc.png" // Add your icon
                                width: 32
                                height: 32
                                fillMode: Image.PreserveAspectFit
                            }
                            
                            Label {
                                text: "ESC"
                                font.pixelSize: 14
                                font.bold: true
                                color: "white"
                                Layout.alignment: Qt.AlignHCenter
                            }
                            
                            Label {
                                text: "Calibrate Motors"
                                font.pixelSize: 10
                                color: "#ecf0f1"
                                Layout.alignment: Qt.AlignHCenter
                            }
                        }
                    }
                    
                    onClicked: {
                        // Add ESC calibration logic here
                        calibrationModel.startESCCalibration()
                    }
                }
                
                // Connection Status
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    color: droneModel.isConnected ? "#2ecc71" : "#e74c3c"
                    radius: 5
                    
                    Label {
                        anchors.centerIn: parent
                        text: droneModel.isConnected ? "✓ Drone Connected" : "✗ Drone Disconnected"
                        color: "white"
                        font.bold: true
                    }
                }
                
                Item {
                    Layout.fillHeight: true
                }
            }
        }
        
        // Right Panel - Information and Status
        GroupBox {
            Layout.fillWidth: true
            Layout.fillHeight: true
            title: "Calibration Information"
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 20
                
                Label {
                    text: "Calibration Instructions"
                    font.pixelSize: 18
                    font.bold: true
                }
                
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    ColumnLayout {
                        width: parent.width
                        spacing: 15
                        
                        GroupBox {
                            Layout.fillWidth: true
                            title: "Accelerometer Calibration"
                            
                            Label {
                                text: "• Place the drone on a flat, level surface\n" +
                                      "• Follow the on-screen instructions\n" +
                                      "• Orient the drone in 6 different positions\n" +
                                      "• Keep the drone steady during each position\n" +
                                      "• Complete all positions for accurate calibration"
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                        
                        GroupBox {
                            Layout.fillWidth: true
                            title: "Compass Calibration"
                            
                            Label {
                                text: "• Move away from metal objects and electronics\n" +
                                      "• Hold the drone and rotate it slowly\n" +
                                      "• Complete full rotations in all axes\n" +
                                      "• Follow the 3D visualization guide\n" +
                                      "• Ensure smooth, continuous movements"
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                        
                        GroupBox {
                            Layout.fillWidth: true
                            title: "ESC Calibration"
                            
                            Label {
                                text: "• Remove propellers before calibration\n" +
                                      "• Ensure battery is fully charged\n" +
                                      "• Follow the throttle sequence carefully\n" +
                                      "• Listen for ESC confirmation beeps\n" +
                                      "• Do not interrupt the calibration process"
                                wrapMode: Text.WordWrap
                                width: parent.width
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Functions to open calibration windows
    function openAccelCalibration() {
        if (accelWindow) {
            accelWindow.raise()
            accelWindow.requestActivate()
            return
        }
        
        var component = Qt.createComponent("AccelCalibration.qml")
        if (component.status === Component.Ready) {
            accelWindow = component.createObject(null, {
                "calibrationModel": calibrationModel,
                "droneModel": droneModel
            })
            
            accelWindow.onClosing.connect(function() {
                accelWindow = null
            })
            
            accelWindow.show()
        } else {
            console.error("Failed to load AccelCalibration.qml:", component.errorString())
        }
    }
    
    function openCompassCalibration() {
        if (compassWindow) {
            compassWindow.raise()
            compassWindow.requestActivate()
            return
        }
        
        var component = Qt.createComponent("compass.qml")
        if (component.status === Component.Ready) {
            compassWindow = component.createObject(null, {
                "calibrationModel": calibrationModel,
                "droneModel": droneModel
            })
            
            compassWindow.onClosing.connect(function() {
                compassWindow = null
            })
            
            compassWindow.show()
        } else {
            console.error("Failed to load CompassCalibration.qml:", component.errorString())
        }
    }
}