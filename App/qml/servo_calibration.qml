import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    width: 650
    height: 500
    visible: true
    title: "Servo/Motor Control Panel - Mission Planner Style"
    color: "#2b2b2b"

    // Properties to receive the drone connection objects from ConnectionBar.qml
    property var droneModel: null
    property var droneCommander: null
    property var servoCalibrationModel: null

    // Connection status properties (internal monitoring only)
    property bool isConnected: servoCalibrationModel ? servoCalibrationModel.isDroneConnected : false

    // Monitor connection status changes
    Connections {
        target: servoCalibrationModel
        function onConnectionStatusChanged(connected) {
            window.isConnected = connected;
            if (!connected) {
                console.log("[ServoCalibration] Drone disconnected - servo control disabled");
                // Reset all displays to neutral when disconnected
                resetAllServoDisplays();
            } else {
                console.log("[ServoCalibration] Drone connected - loading configuration");
                // Configuration will be loaded automatically by the model
            }
        }
        
        function onCalibrationStatusChanged(status) {
            console.log("[ServoCalibration] Status:", status);
        }
        
        function onRealTimeServoUpdate(servoNum, value) {
            console.log("[ServoCalibration] Real-time Servo", servoNum, "value:", value + "us");
            // Update the corresponding row's position display
            updateServoDisplay(servoNum, value);
        }
        
        function onServoConfigurationLoaded() {
            console.log("[ServoCalibration] Configuration loaded - updating UI");
            // Refresh all servo displays with actual configuration
            refreshServoConfiguration();
        }
        
        function onErrorOccurred(error) {
            console.log("[ServoCalibration] Error:", error);
            errorDialog.text = error;
            errorDialog.open();
        }
    }

    // Function to refresh servo configuration from drone
    function refreshServoConfiguration() {
        for (var i = 0; i < listView.count; i++) {
            var item = listView.itemAtIndex(i);
            if (item && servoCalibrationModel) {
                // Update with actual values from drone
                item.updateFromDrone();
            }
        }
    }
    

    // Function to reset all servo displays
    function resetAllServoDisplays() {
        for (var i = 0; i < listView.count; i++) {
            var item = listView.itemAtIndex(i);
            if (item) {
                item.currentPosition = 1000; // Set to minimum/disarmed position
            }
        }
    }

    // Error dialog
    Dialog {
        id: errorDialog
        title: "Servo Control Error"
        property alias text: errorText.text
        standardButtons: Dialog.Ok
        
        Text {
            id: errorText
            color: "#ff6b6b"
            wrapMode: Text.Wrap
            width: 300
        }
    }

    // Control buttons at top (simplified)
    Rectangle {
        id: controlBar
        width: parent.width
        height: 45
        color: "#404040"
        border.color: "#555"
        border.width: 1
        
        Row {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 10
            spacing: 10
            
            Button {
                id: saveBtn
                text: "Save to EEPROM"
                width: 120
                height: 35
                enabled: window.isConnected
                
                onClicked: {
                    if (servoCalibrationModel) {
                        servoCalibrationModel.saveParameters();
                    }
                }
                
                background: Rectangle {
                    color: saveBtn.enabled ? (saveBtn.pressed ? "#e67e22" : "#f39c12") : "#666666"
                    border.color: "#333"
                    border.width: 1
                    radius: 4
                }
                
                contentItem: Text {
                    text: saveBtn.text
                    color: saveBtn.enabled ? "white" : "#999"
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
            
            // Status indicator
            Rectangle {
                width: 200
                height: 35
                color: "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: window.isConnected ? 
                          (servoCalibrationModel ? servoCalibrationModel.calibrationStatus : "Real-time Monitoring") : 
                          "Disconnected"
                    color: window.isConnected ? "#2ecc71" : "#e74c3c"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }
    }

    // Header with better styling to match the image
    Rectangle {
        id: header
        anchors.top: controlBar.bottom
        width: parent.width
        height: 30
        color: "#3a3a3a"
        border.color: "#555"
        border.width: 1
        
        Row {
            anchors.fill: parent
            anchors.leftMargin: 5
            spacing: 0
            
            // # column
            Rectangle {
                width: 30
                height: parent.height
                color: "transparent"
                border.color: "#555"
                border.width: 0.5
                Text {
                    anchors.centerIn: parent
                    text: "#"
                    color: "#ddd"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
            
            // Position column
            Rectangle {
                width: 120
                height: parent.height
                color: "transparent"
                border.color: "#555"
                border.width: 0.5
                Text {
                    anchors.centerIn: parent
                    text: "Position"
                    color: "#ddd"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
            
            // Reverse column
            Rectangle {
                width: 70
                height: parent.height
                color: "transparent"
                border.color: "#555"
                border.width: 0.5
                Text {
                    anchors.centerIn: parent
                    text: "Reverse"
                    color: "#ddd"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
            
            // Function column
            Rectangle {
                width: 140
                height: parent.height
                color: "transparent"
                border.color: "#555"
                border.width: 0.5
                Text {
                    anchors.centerIn: parent
                    text: "Function"
                    color: "#ddd"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
            
            // Min column
            Rectangle {
                width: 70
                height: parent.height
                color: "transparent"
                border.color: "#555"
                border.width: 0.5
                Text {
                    anchors.centerIn: parent
                    text: "Min"
                    color: "#ddd"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
            
            // Trim column
            Rectangle {
                width: 70
                height: parent.height
                color: "transparent"
                border.color: "#555"
                border.width: 0.5
                Text {
                    anchors.centerIn: parent
                    text: "Trim"
                    color: "#ddd"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
            
            // Max column
            Rectangle {
                width: 70
                height: parent.height
                color: "transparent"
                border.color: "#555"
                border.width: 0.5
                Text {
                    anchors.centerIn: parent
                    text: "Max"
                    color: "#ddd"
                    font.bold: true
                    font.pixelSize: 11
                }
            }
        }
    }

    // Content area with improved styling
    ScrollView {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 0
        clip: true

        ListView {
            id: listView
            model: 16
            delegate: motorRowDelegate
            spacing: 0
        }
    }

    // Function to update servo display (called from Connections)
    function updateServoDisplay(servoNum, value) {
        // Find the corresponding row and update its position
        for (var i = 0; i < listView.count; i++) {
            var item = listView.itemAtIndex(i);
            if (item && item.servoNumber === servoNum) {
                item.currentPosition = value;
                break;
            }
        }
    }

    Component {
        id: motorRowDelegate
        
        Rectangle {
            id: rowRect
            width: listView.width
            height: 28
            color: index % 2 === 0 ? "#2b2b2b" : "#323232"
            border.color: "#555"
            border.width: 0.5
            
            property int servoNumber: index + 1
            property int currentPosition: 1000  // Start at disarmed position, will be updated by real data
            
            // Get initial position from model when item is created
            Component.onCompleted: {
                updateFromDrone();
            }
            
            // Function to update this row with actual drone configuration
            function updateFromDrone() {
                if (window.servoCalibrationModel && window.isConnected) {
                    // Get real values from drone with fallback defaults
                    var currentValue = servoCalibrationModel.getCurrentServoValue(servoNumber);
                    if (currentValue !== undefined && currentValue > 0) {
                        currentPosition = currentValue;
                    }
                    
                    // Update function dropdown
                    var actualFunction = servoCalibrationModel.getServoFunction(servoNumber);
                    if (actualFunction !== undefined && actualFunction !== "") {
                        for (var i = 0; i < functionComboBox.model.length; i++) {
                            if (functionComboBox.model[i] === actualFunction) {
                                functionComboBox.currentIndex = i;
                                break;
                            }
                        }
                    }
                    
                    // Update parameter fields with safety checks
                    var minVal = servoCalibrationModel.getServoMin(servoNumber);
                    var trimVal = servoCalibrationModel.getServoTrim(servoNumber);
                    var maxVal = servoCalibrationModel.getServoMax(servoNumber);
                    var reverseVal = servoCalibrationModel.getServoReversed(servoNumber);
                    
                    if (minVal !== undefined && minVal > 0) {
                        minInput.text = minVal.toString();
                    }
                    if (trimVal !== undefined && trimVal > 0) {
                        trimInput.text = trimVal.toString();
                    }
                    if (maxVal !== undefined && maxVal > 0) {
                        maxInput.text = maxVal.toString();
                    }
                    if (reverseVal !== undefined) {
                        reverseCheckBox.checked = reverseVal;
                    }
                }
            }
            
            Row {
                anchors.fill: parent
                anchors.leftMargin: 5
                spacing: 0
                
                // Row number
                Rectangle {
                    width: 30
                    height: parent.height
                    color: "transparent"
                    border.color: "#555"
                    border.width: 0.5
                    Text {
                        anchors.centerIn: parent
                        text: rowRect.servoNumber.toString()
                        color: "#ddd"
                        font.pixelSize: 10
                        font.bold: index < 4
                    }
                }
                
                // Position with progress bar style (read-only, reflects real values)
                Rectangle {
                    width: 120
                    height: parent.height
                    color: "transparent"
                    border.color: "#555"
                    border.width: 0.5
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 100
                        height: 18
                        color: "#1a1a1a"
                        border.color: "#444"
                        border.width: 1
                        radius: 2
                        
                        // Progress bar background
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            color: "#2a2a2a"
                            radius: 1
                            
                            // Progress bar fill - automatically reflects real servo values
                            Rectangle {
                                id: progressFill
                                width: {
                                    var normalizedValue = Math.max(800, Math.min(2200, rowRect.currentPosition));
                                    return parent.width * ((normalizedValue - 800) / (2200 - 800));
                                }
                                height: parent.height
                                color: {
                                    // Color based on actual servo function and current position
                                    var isMotor = (rowRect.servoNumber <= 8 && 
                                                  rowRect.currentPosition > 1000 && 
                                                  rowRect.currentPosition !== 1500);
                                    
                                    if (isMotor && rowRect.currentPosition > 1100) {
                                        return "#4a90e2";  // Motors with throttle - blue
                                    } else if (rowRect.currentPosition > 1520 || rowRect.currentPosition < 1480) {
                                        return "#2ecc71";  // Active servos - green  
                                    } else {
                                        return "#666";  // Inactive/neutral/disarmed - gray
                                    }
                                }
                                radius: 1
                                
                                Behavior on width {
                                    NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
                                }
                                
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                        }
                        
                        // Value text overlay
                        Text {
                            anchors.centerIn: parent
                            text: rowRect.currentPosition.toString()
                            color: "#ddd"
                            font.pixelSize: 9
                            font.bold: true
                        }
                    }
                }
                
                // Reverse checkbox
                Rectangle {
                    width: 70
                    height: parent.height
                    color: "transparent"
                    border.color: "#555"
                    border.width: 0.5
                    
                    CheckBox {
                        id: reverseCheckBox
                        anchors.centerIn: parent
                        enabled: window.isConnected
                        
                        onCheckedChanged: {
                            if (enabled && servoCalibrationModel) {
                                servoCalibrationModel.setServoReverse(rowRect.servoNumber, checked);
                            }
                        }
                        
                        indicator: Rectangle {
                            implicitWidth: 14
                            implicitHeight: 14
                            x: reverseCheckBox.leftPadding
                            y: parent.height / 2 - height / 2
                            radius: 2
                            color: "#444"
                            border.color: "#666"
                            border.width: 1
                            
                            Rectangle {
                                width: 6
                                height: 6
                                x: 4
                                y: 4
                                radius: 1
                                color: "#4a90e2"
                                visible: reverseCheckBox.checked
                            }
                        }
                    }
                }
                
                // Function dropdown
                Rectangle {
                    width: 140
                    height: parent.height
                    color: "transparent"
                    border.color: "#555"
                    border.width: 0.5
                    
                    ComboBox {
                        id: functionComboBox
                        anchors.centerIn: parent
                        width: 130
                        height: 22
                        enabled: window.isConnected
                        
                        model: [
                            "Disabled", "RCPassThru", "Motor1", "Motor2", "Motor3", "Motor4",
                            "Motor5", "Motor6", "Motor7", "Motor8", "Flap", "FlapAuto",
                            "Aileron", "Mount1Yaw", "Mount1Pitch", "Mount1Roll",
                            "CameraTrigger", "CameraShutter"
                        ]
                        
                        // Set default based on servo number (motors 1-4 for first 4 servos)
                        Component.onCompleted: {
                            if (index < 4) {
                                currentIndex = model.indexOf("Motor" + (index + 1));
                            } else {
                                currentIndex = 0; // Disabled
                            }
                        }
                        
                        onCurrentTextChanged: {
                            if (enabled && servoCalibrationModel && currentText) {
                                servoCalibrationModel.setServoFunction(rowRect.servoNumber, currentText);
                            }
                        }
                        
                        background: Rectangle {
                            color: "#444"
                            border.color: "#666"
                            border.width: 1
                            radius: 2
                        }
                        
                        contentItem: Text {
                            text: functionComboBox.displayText
                            color: "#ddd"
                            font.pixelSize: 9
                            verticalAlignment: Text.AlignVCenter
                            leftPadding: 5
                        }
                        
                        popup: Popup {
                            y: functionComboBox.height
                            width: functionComboBox.width
                            height: Math.min(contentItem.implicitHeight, 200)
                            padding: 1
                            
                            contentItem: ListView {
                                implicitHeight: contentHeight
                                model: functionComboBox.popup.visible ? functionComboBox.delegateModel : null
                                delegate: ItemDelegate {
                                    width: functionComboBox.width
                                    height: 20
                                    
                                    background: Rectangle {
                                        color: parent.hovered ? "#555" : "#444"
                                    }
                                    
                                    contentItem: Text {
                                        text: modelData
                                        color: "#ddd"
                                        font.pixelSize: 9
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 5
                                    }
                                }
                            }
                            
                            background: Rectangle {
                                color: "#444"
                                border.color: "#666"
                                border.width: 1
                                radius: 2
                            }
                        }
                    }
                }
                
                // Min value
                Rectangle {
                    width: 70
                    height: parent.height
                    color: "transparent"
                    border.color: "#555"
                    border.width: 0.5
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 55
                        height: 18
                        color: "#444"
                        border.color: "#666"
                        border.width: 1
                        radius: 2
                        
                        TextInput {
                            id: minInput
                            anchors.centerIn: parent
                            text: "1100"
                            color: "#ddd"
                            font.pixelSize: 9
                            horizontalAlignment: TextInput.AlignHCenter
                            selectByMouse: true
                            enabled: window.isConnected
                            validator: IntValidator { bottom: 800; top: 2200 }
                            
                            onEditingFinished: {
                                if (enabled && servoCalibrationModel && text) {
                                    var value = parseInt(text);
                                    if (!isNaN(value)) {
                                        servoCalibrationModel.setServoMin(rowRect.servoNumber, value);
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Trim value
                Rectangle {
                    width: 70
                    height: parent.height
                    color: "transparent"
                    border.color: "#555"
                    border.width: 0.5
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 55
                        height: 18
                        color: "#444"
                        border.color: "#666"
                        border.width: 1
                        radius: 2
                        
                        TextInput {
                            id: trimInput
                            anchors.centerIn: parent
                            text: "1500"
                            color: "#ddd"
                            font.pixelSize: 9
                            horizontalAlignment: TextInput.AlignHCenter
                            selectByMouse: true
                            enabled: window.isConnected
                            validator: IntValidator { bottom: 800; top: 2200 }
                            
                            onEditingFinished: {
                                if (enabled && servoCalibrationModel && text) {
                                    var value = parseInt(text);
                                    if (!isNaN(value)) {
                                        servoCalibrationModel.setServoTrim(rowRect.servoNumber, value);
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Max value
                Rectangle {
                    width: 70
                    height: parent.height
                    color: "transparent"
                    border.color: "#555"
                    border.width: 0.5
                    
                    Rectangle {
                        anchors.centerIn: parent
                        width: 55
                        height: 18
                        color: "#444"
                        border.color: "#666"
                        border.width: 1
                        radius: 2
                        
                        TextInput {
                            id: maxInput
                            anchors.centerIn: parent
                            text: "1900"
                            color: "#ddd"
                            font.pixelSize: 9
                            horizontalAlignment: TextInput.AlignHCenter
                            selectByMouse: true
                            enabled: window.isConnected
                            validator: IntValidator { bottom: 800; top: 2200 }
                            
                            onEditingFinished: {
                                if (enabled && servoCalibrationModel && text) {
                                    var value = parseInt(text);
                                    if (!isNaN(value)) {
                                        servoCalibrationModel.setServoMax(rowRect.servoNumber, value);
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // Handle window closing
    onClosing: {
        if (servoCalibrationModel) {
            console.log("[ServoCalibration] Window closing - cleaning up");
        }
    }

    // Initialize when component is complete
    Component.onCompleted: {
        console.log("[ServoCalibration] Window initialized with drone connection");
        console.log("  - DroneModel:", droneModel ? "Available" : "Not Available");
        console.log("  - DroneCommander:", droneCommander ? "Available" : "Not Available");
        console.log("  - ServoCalibrationModel:", servoCalibrationModel ? "Available" : "Not Available");
        console.log("  - Connection Status:", isConnected ? "Connected" : "Disconnected");
        
        if (servoCalibrationModel) {
            console.log("  - Real-time monitoring:", servoCalibrationModel.calibrationStatus);
        }
    }
}