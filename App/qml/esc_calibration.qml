import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: escCalibrationWindow
    title: "ESC Calibration (AC3.3+)"
    width: 600
    height: 400
    flags: Qt.Window | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    modality: Qt.ApplicationModal
    
    property var droneModel: null
    property var droneCommander: null  
    property var escCalibrationModel: null
    
    // Sound feedback properties
    property bool soundFeedbackEnabled: true
    property string lastDetectedSound: ""
    property bool powerCycleRequired: false
    
    Rectangle {
        id: mainBackground
        anchors.fill: parent
        color: "#f0f0f0"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 10
            
            // Title Bar
            Rectangle {
                Layout.fillWidth: true
                height: 35
                color: "#4a90e2"
                border.color: "#3a7bc8"
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: "ESC Calibration (AC3.3+)"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                }
            }
            
            // Main Content Area
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "white"
                border.color: "#d0d0d0"
                border.width: 1
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15
                    
                    // Instructions Section
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        
                        // Calibrate ESCs Button
                        Button {
                            id: calibrateButton
                            Layout.fillWidth: true
                            height: 40
                            
                            text: {
                                if (!escCalibrationModel) return "Calibrate ESCs"
                                if (escCalibrationModel.isCalibrating) {
                                    return "Calibrating ESCs..."
                                }
                                if (escCalibrationModel.currentStatus.includes("COMPLETED")) return "ESCs Calibrated"
                                if (escCalibrationModel.currentStatus.includes("FAILED")) return "Retry Calibration"
                                return "Calibrate ESCs"
                            }
                            
                            enabled: {
                                if (!droneModel || !escCalibrationModel) return false
                                return droneModel.isConnected && !escCalibrationModel.isCalibrating
                            }
                            
                            onClicked: {
                                if (escCalibrationModel) {
                                    if (escCalibrationModel.currentStatus.includes("FAILED") || 
                                        escCalibrationModel.currentStatus.includes("COMPLETED")) {
                                        escCalibrationModel.resetCalibrationStatus()
                                    }
                                    escCalibrationModel.startCalibration()
                                }
                            }
                            
                            background: Rectangle {
                                color: {
                                    if (!parent.enabled) return "#cccccc"
                                    if (parent.pressed) return "#357abd"
                                    if (escCalibrationModel && escCalibrationModel.currentStatus.includes("COMPLETED")) return "#5cb85c"
                                    return "#4a90e2"
                                }
                                border.color: {
                                    if (!parent.enabled) return "#aaaaaa"
                                    if (escCalibrationModel && escCalibrationModel.currentStatus.includes("COMPLETED")) return "#449d44"
                                    return "#357abd"
                                }
                                border.width: 1
                                radius: 3
                            }
                            
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? "white" : "#666666"
                                font.pixelSize: 12
                                font.bold: true
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                        
                        // Instructions Text
                        Rectangle {
                            Layout.fillWidth: true
                            height: 120
                            color: "#fafafa"
                            border.color: "#e0e0e0"
                            border.width: 1
                            
                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 8
                                clip: true
                                
                                Text {
                                    width: parent.width
                                    text: "Remove Props\n" +
                                          "After pushing ESC button:\n" +
                                          "-Unplug battery and USB\n" +
                                          "-Plug in battery\n" +
                                          "-When ESCs beep, Switch (if present)\n" +
                                          "-ESCs should beep as they are calibrated\n" +
                                          "-Restart flight control firmware"
                                    color: "#333333"
                                    font.pixelSize: 11
                                    wrapMode: Text.Wrap
                                    lineHeight: 1.2
                                }
                            }
                        }
                    }
                    
                    // ESC Type and Output PWM Min Section
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 20
                        
                        // ESC Type
                        ColumnLayout {
                            Layout.preferredWidth: 150
                            spacing: 5
                            
                            Text {
                                text: "ESC Type:"
                                color: "#333333"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            
                            ComboBox {
                                Layout.fillWidth: true
                                height: 25
                                
                                model: ["Normal", "BLHeli", "DShot"]
                                currentIndex: 0
                                
                                background: Rectangle {
                                    color: "white"
                                    border.color: "#cccccc"
                                    border.width: 1
                                    radius: 2
                                }
                                
                                contentItem: Text {
                                    text: parent.displayText
                                    color: "#333333"
                                    font.pixelSize: 10
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                            }
                        }
                        
                        // Output PWM Min
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5
                            
                            Text {
                                text: "Output PWM Min"
                                color: "#333333"
                                font.pixelSize: 11
                                font.bold: true
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                
                                SpinBox {
                                    Layout.preferredWidth: 80
                                    height: 25
                                    from: 900
                                    to: 2000
                                    value: 1100
                                    stepSize: 1
                                    
                                    background: Rectangle {
                                        color: "white"
                                        border.color: "#cccccc"
                                        border.width: 1
                                        radius: 2
                                    }
                                    
                                    contentItem: TextInput {
                                        text: parent.textFromValue(parent.value, parent.locale)
                                        font.pixelSize: 10
                                        color: "#333333"
                                        horizontalAlignment: Qt.AlignHCenter
                                        verticalAlignment: Qt.AlignVCenter
                                        readOnly: !parent.editable
                                        validator: parent.validator
                                        inputMethodHints: Qt.ImhFormattedNumbersOnly
                                    }
                                }
                                
                                Text {
                                    text: "Leave as 0 to use RX min range"
                                    color: "#666666"
                                    font.pixelSize: 9
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                    
                    // Status Display Area
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        color: "#fafafa"
                        border.color: "#e0e0e0"
                        border.width: 1
                        
                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 8
                            clip: true
                            
                            Text {
                                id: statusText
                                width: parent.width
                                text: escCalibrationModel ? escCalibrationModel.currentStatus : "Ready - Remove propellers before starting!"
                                color: {
                                    if (!escCalibrationModel) return "#333333"
                                    if (escCalibrationModel.currentStatus.includes("COMPLETED")) return "#5cb85c"
                                    if (escCalibrationModel.currentStatus.includes("FAILED")) return "#d9534f"
                                    if (escCalibrationModel.currentStatus.includes("POWER CYCLE")) return "#f0ad4e"
                                    if (escCalibrationModel.isCalibrating) return "#5bc0de"
                                    return "#333333"
                                }
                                wrapMode: Text.Wrap
                                font.pixelSize: 10
                                lineHeight: 1.3
                                font.family: "Courier New, monospace"
                            }
                        }
                    }
                }
            }
            
            // Bottom Button Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Button {
                    text: "Reset"
                    Layout.preferredWidth: 80
                    height: 30
                    enabled: escCalibrationModel ? !escCalibrationModel.isCalibrating : false
                    onClicked: {
                        if (escCalibrationModel) {
                            escCalibrationModel.resetCalibrationStatus()
                        }
                    }
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#d0d0d0" : "#e6e6e6") : "#f5f5f5"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 3
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#333333" : "#999999"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                Item { Layout.fillWidth: true }
                
                // Connection Status Indicator
                Rectangle {
                    Layout.preferredWidth: 100
                    height: 20
                    color: droneModel && droneModel.isConnected ? "#d4edda" : "#f8d7da"
                    border.color: droneModel && droneModel.isConnected ? "#c3e6cb" : "#f5c6cb"
                    border.width: 1
                    radius: 10
                    
                    Text {
                        anchors.centerIn: parent
                        text: droneModel && droneModel.isConnected ? "Connected" : "Disconnected"
                        color: droneModel && droneModel.isConnected ? "#155724" : "#721c24"
                        font.pixelSize: 9
                        font.bold: true
                    }
                }
                
                Button {
                    text: "Close"
                    Layout.preferredWidth: 80
                    height: 30
                    enabled: escCalibrationModel ? !escCalibrationModel.isCalibrating : true
                    onClicked: escCalibrationWindow.close()
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#d0d0d0" : "#e6e6e6") : "#f5f5f5"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 3
                    }
                    
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "#333333" : "#999999"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }
    }
    
    // Power cycle notification overlay
    Rectangle {
        id: powerCycleOverlay
        anchors.centerIn: parent
        width: 400
        height: 200
        color: "#fff3cd"
        border.color: "#ffeaa7"
        border.width: 2
        radius: 5
        opacity: 0
        visible: opacity > 0
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 10
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Power Cycle Required"
                color: "#856404"
                font.pixelSize: 14
                font.bold: true
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "1. Disconnect Battery\n2. Disconnect USB\n3. Connect Battery Only\n4. Press Safety Button (if applicable)"
                color: "#856404"
                font.pixelSize: 11
                horizontalAlignment: Text.AlignHCenter
                lineHeight: 1.2
            }
            
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "All ESCs will calibrate automatically"
                color: "#856404"
                font.pixelSize: 10
                font.bold: true
            }
        }
        
        // Show/hide animations
        PropertyAnimation {
            id: showPowerCycleOverlay
            target: powerCycleOverlay
            property: "opacity"
            to: 0.95
            duration: 300
        }
        
        PropertyAnimation {
            id: hidePowerCycleOverlay
            target: powerCycleOverlay
            property: "opacity"
            to: 0
            duration: 300
        }
    }
    
    // Connect to backend model signals
    Connections {
        target: escCalibrationModel
        function onSoundDetected(soundDescription) {
            if (soundFeedbackEnabled) {
                console.log("Sound Detected:", soundDescription)
                lastDetectedSound = soundDescription
            }
        }
        
        function onCalibrationCompleted(success, message) {
            if (success) {
                console.log("ESC calibration completed successfully")
            } else {
                console.log("ESC calibration failed:", message)
            }
        }
        
        function onCalibrationStatusChanged() {
            if (escCalibrationModel && escCalibrationModel.currentStatus.includes("POWER CYCLE")) {
                showPowerCycleOverlay.start()
                powerCycleRequired = true
            } else if (powerCycleRequired) {
                hidePowerCycleOverlay.start()
                powerCycleRequired = false
            }
        }
    }
    
    Component.onDestruction: {
        console.log("ESC calibration window destroyed")
        if (escCalibrationModel) {
            escCalibrationModel.cleanup()
        }
    }
}