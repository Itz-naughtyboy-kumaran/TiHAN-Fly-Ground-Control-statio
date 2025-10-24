import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

ApplicationWindow {
    id: compassWindow
    width: 850
    height: 700
    visible: true
    title: "Mission Planner Style Compass Calibration - Hardware Integration"
    color: "#2b2b2b"

    // Connection properties with null safety
    property bool isDroneConnected: droneModel ? (droneModel.isConnected || false) : false
    property var compassCalibrationModel: null
    property var droneModel: null
    property var droneCommander: null
    property bool isCalibrationCompleted: false

    // Mission Planner style connection monitoring with null checks
    Connections {
        target: droneModel
        enabled: droneModel !== null
        function onIsConnectedChanged() {
            if (droneModel && !droneModel.isConnected) {
                console.log("[Compass] Mission Planner: Shared connection lost - stopping calibration");
                if (compassCalibrationModel && compassCalibrationModel.calibrationStarted) {
                    compassCalibrationModel.stopCalibration();
                }
            } else if (droneModel && droneModel.isConnected) {
                console.log("[Compass] Mission Planner: Shared connection established - ready");
            }
        }
    }

    // Enhanced Mission Planner calibration model connections with null checks
    Connections {
        target: compassCalibrationModel
        enabled: compassCalibrationModel !== null
        
        function onCalibrationStartedChanged() {
            if (compassCalibrationModel) {
                console.log("[Compass] Mission Planner: Calibration state changed -", 
                           compassCalibrationModel.calibrationStarted ? "STARTED" : "STOPPED");
                isCalibrationCompleted = false;
            }
        }
        
        function onCalibrationProgressChanged() {
            if (compassCalibrationModel) {
                console.log("[Compass] Mission Planner: General progress signal received");
            }
        }
        
        function onCalibrationComplete() {
            console.log("[Compass] Mission Planner: Calibration COMPLETED successfully");
            isCalibrationCompleted = true;
        }
        
        function onCalibrationFailed() {
            console.log("[Compass] Mission Planner: Calibration FAILED - automatic retry initiated");
            isCalibrationCompleted = false;
        }
        
        function onOrientationChanged() {
            if (compassCalibrationModel) {
                console.log("[Compass] Mission Planner: Now on orientation", 
                           compassCalibrationModel.currentOrientation + "/6");
            }
        }
        
        function onRetryAttemptChanged() {
            if (compassCalibrationModel) {
                console.log("[Compass] Mission Planner: Retry attempt", 
                           compassCalibrationModel.retryAttempt);
            }
        }

        // CRITICAL FIX: Enhanced progress signal handlers with debugging
        function onMag1ProgressChanged() {
            if (compassCalibrationModel) {
                console.log("[Compass] QML: Mag1 progress signal received:", 
                           compassCalibrationModel.mag1Progress);
            }
        }
        
        function onMag2ProgressChanged() {
            if (compassCalibrationModel) {
                console.log("[Compass] QML: Mag2 progress signal received:", 
                           compassCalibrationModel.mag2Progress);
            }
        }
        
        function onMag3ProgressChanged() {
            if (compassCalibrationModel) {
                console.log("[Compass] QML: Mag3 progress signal received:", 
                           compassCalibrationModel.mag3Progress);
            }
        }
    }

    // CRITICAL FIX: Progress monitoring timer
    Timer {
        id: progressCheckTimer
        interval: 1000  // Check every second
        running: compassCalibrationModel && compassCalibrationModel.calibrationStarted
        repeat: true
        
        onTriggered: {
            if (compassCalibrationModel) {
                console.log("[Compass] QML: Progress check - Mag1:", 
                           compassCalibrationModel.mag1Progress,
                           "Mag2:", compassCalibrationModel.mag2Progress,
                           "Mag3:", compassCalibrationModel.mag3Progress);
            }
        }
    }

    // Reboot confirmation dialog
    MessageDialog {
        id: rebootDialog
        title: "Reboot Required"
        text: "Calibration completed successfully!\n\nA reboot is required to apply the new compass calibration settings. Would you like to reboot the autopilot now?"
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: {
            if (isDroneConnected && droneCommander) {
                console.log("[Compass] Mission Planner: Rebooting autopilot after calibration completion");
               compassCalibrationModel.rebootAutopilot();
                isCalibrationCompleted = false;
            }
        }
        onNo: {
            console.log("[Compass] User chose not to reboot immediately");
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#2b2b2b"

        ScrollView {
            anchors.fill: parent
            contentHeight: mainColumn.height + 40

            Column {
                id: mainColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 10
                spacing: 10

                // Mission Planner style connection status
                Rectangle {
                    width: parent.width
                    height: 35
                    color: isDroneConnected ? "#28a745" : "#dc3545"
                    radius: 5
                    border.color: "#555"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: isDroneConnected ? "🔗" : "❌"
                            color: "white"
                            font.pixelSize: 16
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        }
                        
                        Text {
                            text: isDroneConnected ? 
                                  "Mission Planner Compatible - PyMAVLink Hardware Connection Ready" : 
                                  "No Drone Connection - Mission Planner Calibration Unavailable"
                            color: "white"
                            font.pixelSize: 12
                            font.bold: true
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        }
                        
                        Text {
                            text: isDroneConnected ? "🔊 HW Audio Ready" : "🔇 No Audio"
                            color: "white"
                            font.pixelSize: 10
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        }
                    }
                }

                // CRITICAL FIX: Debug information panel
                Rectangle {
                    width: parent.width
                    height: 40
                    color: "#333"
                    border.color: "#555"
                    border.width: 1
                    radius: 3
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 2
                        
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 15
                            
                            Text {
                                text: "Debug Info:"
                                color: "white"
                                font.pixelSize: 10
                                font.bold: true
                            }
                            
                            Text {
                                text: "Model: " + (compassCalibrationModel ? "✓" : "✗")
                                color: compassCalibrationModel ? "#28a745" : "#dc3545"
                                font.pixelSize: 10
                            }
                            
                            Text {
                                text: "Connected: " + (isDroneConnected ? "✓" : "✗")
                                color: isDroneConnected ? "#28a745" : "#dc3545"
                                font.pixelSize: 10
                            }
                            
                            Text {
                                text: "Calibrating: " + (compassCalibrationModel && compassCalibrationModel.calibrationStarted ? "✓" : "✗")
                                color: (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? "#ffc107" : "#666"
                                font.pixelSize: 10
                            }

                            Text {
                                text: "Completed: " + (isCalibrationCompleted ? "✓" : "✗")
                                color: isCalibrationCompleted ? "#28a745" : "#666"
                                font.pixelSize: 10
                            }
                        }
                        
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 15
                            
                            Text {
                                text: "M1: " + Math.round(compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) + "%"
                                color: "#17a2b8"
                                font.pixelSize: 10
                            }
                            
                            Text {
                                text: "M2: " + Math.round(compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) + "%"
                                color: "#17a2b8"
                                font.pixelSize: 10
                            }
                            
                            Text {
                                text: "M3: " + Math.round(compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) + "%"
                                color: "#17a2b8"
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                // Title
                Text {
                    text: "Compass Priority Configuration"
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                }

                Text {
                    text: "Set the Compass Priority by reordering the compasses in the table below (Highest at the top)"
                    color: "white"
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    width: parent.width
                }

                // Compass priority table
                Rectangle {
                    width: parent.width
                    height: 120
                    color: "#3a3a3a"
                    border.color: "#555"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        
                        // Header
                        Rectangle {
                            width: parent.width
                            height: 25
                            color: "#4a4a4a"
                            
                            Row {
                                anchors.fill: parent
                                
                                HeaderCell { text: "Priority"; cellWidth: 60 }
                                HeaderCell { text: "DevID"; cellWidth: 80 }
                                HeaderCell { text: "BusType"; cellWidth: 80 }
                                HeaderCell { text: "Bus"; cellWidth: 50 }
                                HeaderCell { text: "Address"; cellWidth: 70 }
                                HeaderCell { text: "DevType"; cellWidth: 100 }
                                HeaderCell { text: "Missing"; cellWidth: 70 }
                                HeaderCell { text: "External"; cellWidth: 70 }
                                HeaderCell { text: "Orientation"; cellWidth: 100 }
                                HeaderCell { text: "Up"; cellWidth: 50 }
                                HeaderCell { text: "Down"; cellWidth: 50 }
                            }
                        }

                        // Data Row 1
                        Rectangle {
                            width: parent.width
                            height: 25
                            color: "#4a6fa5"
                            
                            Row {
                                anchors.fill: parent
                                
                                DataCell { text: "1"; cellWidth: 60; textColor: "white" }
                                DataCell { text: "97539"; cellWidth: 80; textColor: "white" }
                                DataCell { text: "UAVCAN"; cellWidth: 80; textColor: "white" }
                                DataCell { text: "0"; cellWidth: 50; textColor: "white" }
                                DataCell { text: "125"; cellWidth: 70; textColor: "white" }
                                DataCell { text: "SENSOR_ID#1"; cellWidth: 100; textColor: "white" }
                                
                                Rectangle {
                                    width: 70
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    CheckBox {
                                        anchors.centerIn: parent
                                        checked: false
                                        enabled: isDroneConnected
                                    }
                                }
                                
                                Rectangle {
                                    width: 70
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    CheckBox {
                                        anchors.centerIn: parent
                                        checked: true
                                        enabled: isDroneConnected
                                    }
                                }
                                
                                Rectangle {
                                    width: 100
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    ComboBox {
                                        anchors.centerIn: parent
                                        width: 90
                                        height: 20
                                        model: ["0", "1", "2", "3"]
                                        currentIndex: 0
                                        enabled: isDroneConnected
                                    }
                                }
                                
                                Rectangle {
                                    width: 50
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    Button {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        text: "↑"
                                        font.pixelSize: 12
                                        enabled: isDroneConnected
                                    }
                                }
                                
                                Rectangle {
                                    width: 50
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    Button {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        text: "↓"
                                        font.pixelSize: 12
                                        enabled: isDroneConnected
                                    }
                                }
                            }
                        }

                        // Data Row 2
                        Rectangle {
                            width: parent.width
                            height: 25
                            color: "#3a3a3a"
                            
                            Row {
                                anchors.fill: parent
                                
                                DataCell { text: "2"; cellWidth: 60 }
                                DataCell { text: "590114"; cellWidth: 80 }
                                DataCell { text: "SPI"; cellWidth: 80 }
                                DataCell { text: "4"; cellWidth: 50 }
                                DataCell { text: "AK09916"; cellWidth: 70 }
                                DataCell { text: ""; cellWidth: 100 }
                                
                                Rectangle {
                                    width: 70
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    CheckBox {
                                        anchors.centerIn: parent
                                        checked: false
                                        enabled: isDroneConnected
                                    }
                                }
                                
                                Rectangle {
                                    width: 70
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    CheckBox {
                                        anchors.centerIn: parent
                                        checked: false
                                        enabled: isDroneConnected
                                    }
                                }
                                
                                Rectangle {
                                    width: 100
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    ComboBox {
                                        anchors.centerIn: parent
                                        width: 90
                                        height: 20
                                        model: ["0", "1", "2", "3"]
                                        currentIndex: 0
                                        enabled: isDroneConnected
                                    }
                                }
                                
                                Rectangle {
                                    width: 50
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    Button {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        text: "↑"
                                        font.pixelSize: 12
                                        enabled: isDroneConnected
                                    }
                                }
                                
                                Rectangle {
                                    width: 50
                                    height: parent ? parent.height : 25
                                    color: "transparent"
                                    Button {
                                        anchors.centerIn: parent
                                        width: 20
                                        height: 20
                                        text: "↓"
                                        font.pixelSize: 12
                                        enabled: isDroneConnected
                                    }
                                }
                            }
                        }
                    }
                }

                // Compass options with null safety
                Row {
                    spacing: 20
                    
                    Column {
                        spacing: 5
                        
                        Text {
                            text: "Do you want to disable any of the first 3 compasses?"
                            color: "white"
                            font.pixelSize: 12
                        }
                        
                        Row {
                            spacing: 15
                            
                            Row {
                                spacing: 5
                                CheckBox {
                                    checked: true
                                    enabled: isDroneConnected
                                }
                                Text {
                                    text: "Use Compass 1"
                                    color: "white"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                            }
                            
                            Row {
                                spacing: 5
                                CheckBox {
                                    checked: true
                                    enabled: isDroneConnected
                                }
                                Text {
                                    text: "Use Compass 2"
                                    color: "white"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                            }
                            
                            Row {
                                spacing: 5
                                CheckBox {
                                    checked: false
                                    enabled: isDroneConnected
                                }
                                Text {
                                    text: "Use Compass 3"
                                    color: "white"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                            }
                        }
                    }
                    
                    Button {
                        text: "Remove\nMissing"
                        width: 80
                        height: 40
                        enabled: isDroneConnected
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        background: Rectangle {
                            color: parent.enabled ? "#8bc34a" : "#666"
                            radius: 3
                        }
                    }
                    
                    Row {
                        spacing: 5
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        
                        CheckBox {
                            checked: false
                            enabled: isDroneConnected
                        }
                        Text {
                            text: "Automatically learn offsets"
                            color: "white"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                        }
                    }
                }

                Text {
                    text: "A reboot is required to adjust the ordering."
                    color: "white"
                    font.pixelSize: 12
                }

                // Reboot button with improved styling and completion state
                Button {
                    text: isCalibrationCompleted ? "Completed - Reboot Required" : "Reboot Autopilot"
                    width: isCalibrationCompleted ? 240 : 180
                    height: 40
                    enabled: isDroneConnected
                    onClicked: {
    console.log("DroneCommander methods:", Object.getOwnPropertyNames(droneCommander));
    if (typeof droneCommander.rebootAutopilot === 'function') {
        droneCommander.rebootAutopilot();
    } else {
        console.log("rebootAutopilot is not a function");
    }
}
                    background: Rectangle {
                        color: parent.enabled ? (isCalibrationCompleted ? "#28a745" : "#8bc34a") : "#666"
                        radius: 8
                        border.color: isCalibrationCompleted ? "#1e7e34" : (parent.enabled ? "#689f38" : "#555")
                        border.width: 2
                        
                        gradient: Gradient {
                            GradientStop { 
                                position: 0.0; 
                                color: isCalibrationCompleted ? "#32cd32" : (parent.parent.enabled ? "#a3d977" : "#777")
                            }
                            GradientStop { 
                                position: 1.0; 
                                color: isCalibrationCompleted ? "#228b22" : (parent.parent.enabled ? "#689f38" : "#555")
                            }
                        }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: parent.text
                        color: "white"
                        font.pixelSize: isCalibrationCompleted ? 12 : 13
                        font.bold: true
                        font.weight: Font.Bold
                    }
                }

                Text {
                    text: "A mag calibration is required to remap the above changes."
                    color: "white"
                    font.pixelSize: 12
                }

                // Mission Planner Style Compass Calibration Section with null safety
                Rectangle {
                    width: parent.width
                    height: 350
                    color: "#3a3a3a"
                    border.color: "#555"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 8

                        // Mission Planner style header with completion status
                        Row {
                            spacing: 10
                            width: parent ? parent.width : 100
                            
                            Text {
                                text: "Mission Planner Style Compass Calibration"
                                color: "white"
                                font.pixelSize: 14
                                font.bold: true
                            }
                            
                            Rectangle {
                                width: 120
                                height: 20
                                color: isCalibrationCompleted ? "#28a745" :
                                       (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? "#ffc107" : "#666"
                                radius: 3
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: isCalibrationCompleted ? "COMPLETED" :
                                          (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? 
                                          "Orientation " + (compassCalibrationModel.currentOrientation || 1) + "/6" : 
                                          "Ready"
                                    color: "white"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                            
                            Rectangle {
                                width: 80
                                height: 20
                                color: (compassCalibrationModel && compassCalibrationModel.retryAttempt > 0) ? "#dc3545" : "transparent"
                                radius: 3
                                visible: compassCalibrationModel && compassCalibrationModel.retryAttempt > 0
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: "Retry " + (compassCalibrationModel ? (compassCalibrationModel.retryAttempt || 0) : 0)
                                    color: "white"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }

// Mission Planner control buttons with improved styling
Row {
    spacing: 15
    anchors.horizontalCenter: parent.horizontalCenter
    
    Button {
        text: isCalibrationCompleted ? "Completed" : "Start Calibration"
        width: 140
        height: 45
        enabled: isDroneConnected && compassCalibrationModel && 
                (!compassCalibrationModel.calibrationStarted || isCalibrationCompleted)
        
        // Style the button's built-in text
        font.pixelSize: 14
        font.bold: true
        font.family: "Arial"
        
        // Set text color using palette
        palette.buttonText: "#000000"
        
        onClicked: {
            if (isCalibrationCompleted) {
                rebootDialog.open();
            } else if (compassCalibrationModel && isDroneConnected) {
                console.log("[Compass] Mission Planner: Starting hardware calibration");
                compassCalibrationModel.startCalibration();
            }
        }
        background: Rectangle {
            color: parent.enabled ? "#87CEEB" : "#666"
            radius: 8
            border.color: parent.enabled ? "#6BB6E6" : "#555"
            border.width: 2
        }
    }
    
    Button {
        text: "Accept Results"
        width: 140
        height: 45
        enabled: isDroneConnected && compassCalibrationModel && 
                compassCalibrationModel.calibrationStarted && !isCalibrationCompleted
        
        // Style the button's built-in text
        font.pixelSize: 14
        font.bold: true
        font.family: "Arial"
        
        // Set text color using palette
        palette.buttonText: "#000000"
        
        onClicked: {
            if (compassCalibrationModel && isDroneConnected) {
                console.log("[Compass] Mission Planner: Accepting calibration results");
                compassCalibrationModel.acceptCalibration();
            }
        }
        background: Rectangle {
            color: parent.enabled ? "#87CEEB" : "#666"
            radius: 8
            border.color: parent.enabled ? "#6BB6E6" : "#555"
            border.width: 2
        }
    }
    
    Button {
        text: "Cancel"
        width: 100
        height: 45
        enabled: isDroneConnected && compassCalibrationModel && 
                compassCalibrationModel.calibrationStarted && !isCalibrationCompleted
        
        // Style the button's built-in text
        font.pixelSize: 14
        font.bold: true
        font.family: "Arial"
        
        // Set text color using palette
        palette.buttonText: "#000000"
        
        onClicked: {
            if (compassCalibrationModel && isDroneConnected) {
                console.log("[Compass] Mission Planner: Canceling calibration");
                compassCalibrationModel.stopCalibration();
                isCalibrationCompleted = false;
            }
        }
        background: Rectangle {
            color: parent.enabled ? "#87CEEB" : "#666"
            radius: 8
            border.color: parent.enabled ? "#6BB6E6" : "#555"
            border.width: 2
        }
    }
}

                        // CRITICAL FIX: Enhanced progress bars with debug information
                        Column {
                            spacing: 8
                            width: parent ? parent.width : 100
                            
                            // Compass 1 Progress Bar - FIXED with enhanced binding and debug
                            Row {
                                spacing: 10
                                width: parent ? parent.width : 400
                                
                                Text {
                                    text: "Compass 1"
                                    color: "white"
                                    width: 80
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                                
                                Rectangle {
                                    width: 300
                                    height: 24
                                    color: "#555"
                                    border.color: "#777"
                                    border.width: 1
                                    radius: 3
                                    
                                    Rectangle {
                                        id: mag1ProgressBar
                                        // CRITICAL FIX: Enhanced property binding with bounds checking
                                        width: parent.width * Math.max(0, Math.min(1, 
                                            (compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) / 100.0))
                                        height: parent.height - 2
                                        x: 1
                                        y: 1
                                        color: "#28a745"
                                        radius: 2
                                        
                                        // DEBUG: Log width changes
                                        onWidthChanged: {
                                            if (compassCalibrationModel) {
                                                console.log("[Compass] QML: Mag1 bar width changed:", width, 
                                                           "Progress:", compassCalibrationModel.mag1Progress);
                                            }
                                        }
                                        
                                        Behavior on width {
                                            NumberAnimation { duration: 200 }
                                        }
                                    }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) + "%"
                                        color: (compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) > 50 ? "white" : "#ccc"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                
                                // DEBUG: Show raw progress value
                                Text {
                                    text: "(" + (compassCalibrationModel ? compassCalibrationModel.mag1Progress.toFixed(1) : "0.0") + ")"
                                    color: "#999"
                                    font.pixelSize: 9
                                    width: 45
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                                
                                Text {
                                    text: (compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) >= 100 ? "✓" : 
                                          (compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) > 0 ? "●" : "○"
                                    color: (compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) >= 100 ? "#28a745" : 
                                           (compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) > 0 ? "#ffc107" : "#666"
                                    font.pixelSize: 16
                                    font.bold: true
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                            }

                            // Compass 2 Progress Bar - FIXED with enhanced binding and debug
                            Row {
                                spacing: 10
                                width: parent ? parent.width : 400
                                
                                Text {
                                    text: "Compass 2"
                                    color: "white"
                                    width: 80
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                                
                                Rectangle {
                                    width: 300
                                    height: 24
                                    color: "#555"
                                    border.color: "#777"
                                    border.width: 1
                                    radius: 3
                                    
                                    Rectangle {
                                        id: mag2ProgressBar
                                        // CRITICAL FIX: Enhanced property binding with bounds checking
                                        width: parent.width * Math.max(0, Math.min(1, 
                                            (compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) / 100.0))
                                        height: parent.height - 2
                                        x: 1
                                        y: 1
                                        color: "#17a2b8"
                                        radius: 2
                                        
                                        // DEBUG: Log width changes
                                        onWidthChanged: {
                                            if (compassCalibrationModel) {
                                                console.log("[Compass] QML: Mag2 bar width changed:", width, 
                                                           "Progress:", compassCalibrationModel.mag2Progress);
                                            }
                                        }
                                        
                                        Behavior on width {
                                            NumberAnimation { duration: 200 }
                                        }
                                    }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) + "%"
                                        color: (compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) > 50 ? "white" : "#ccc"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                
                                // DEBUG: Show raw progress value
                                Text {
                                    text: "(" + (compassCalibrationModel ? compassCalibrationModel.mag2Progress.toFixed(1) : "0.0") + ")"
                                    color: "#999"
                                    font.pixelSize: 9
                                    width: 45
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                                
                                Text {
                                    text: (compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) >= 100 ? "✓" : 
                                          (compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) > 0 ? "●" : "○"
                                    color: (compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) >= 100 ? "#28a745" : 
                                           (compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) > 0 ? "#ffc107" : "#666"
                                    font.pixelSize: 16
                                    font.bold: true
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                            }

                            // Compass 3 Progress Bar - FIXED with enhanced binding and debug
                            Row {
                                spacing: 10
                                width: parent ? parent.width : 400
                                
                                Text {
                                    text: "Compass 3"
                                    color: "white"
                                    width: 80
                                    font.pixelSize: 12
                                    font.bold: true
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                                
                                Rectangle {
                                    width: 300
                                    height: 24
                                    color: "#555"
                                    border.color: "#777"
                                    border.width: 1
                                    radius: 3
                                    
                                    Rectangle {
                                        id: mag3ProgressBar
                                        // CRITICAL FIX: Enhanced property binding with bounds checking
                                        width: parent.width * Math.max(0, Math.min(1, 
                                            (compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) / 100.0))
                                        height: parent.height - 2
                                        x: 1
                                        y: 1
                                        color: "#ffc107"
                                        radius: 2
                                        
                                        // DEBUG: Log width changes
                                        onWidthChanged: {
                                            if (compassCalibrationModel) {
                                                console.log("[Compass] QML: Mag3 bar width changed:", width, 
                                                           "Progress:", compassCalibrationModel.mag3Progress);
                                            }
                                        }
                                        
                                        Behavior on width {
                                            NumberAnimation { duration: 200 }
                                        }
                                    }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) + "%"
                                        color: (compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) > 50 ? "white" : "#ccc"
                                        font.pixelSize: 11
                                        font.bold: true
                                    }
                                }
                                
                                // DEBUG: Show raw progress value
                                Text {
                                    text: "(" + (compassCalibrationModel ? compassCalibrationModel.mag3Progress.toFixed(1) : "0.0") + ")"
                                    color: "#999"
                                    font.pixelSize: 9
                                    width: 45
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                                
                                Text {
                                    text: (compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) >= 100 ? "✓" : 
                                          (compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) > 0 ? "●" : "○"
                                    color: (compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) >= 100 ? "#28a745" : 
                                           (compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) > 0 ? "#ffc107" : "#666"
                                    font.pixelSize: 16
                                    font.bold: true
                                    anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                                }
                            }
                        }

                        // Mission Planner fitness settings with null safety
                        Row {
                            spacing: 15
                            
                            Text {
                                text: "Fitness Level:"
                                color: "white"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            }
                            
                            ComboBox {
                                width: 120
                                height: 25
                                model: ["Strict", "Default", "Relaxed", "Very Relaxed"]
                                currentIndex: 1
                                enabled: isDroneConnected && (!compassCalibrationModel || !compassCalibrationModel.calibrationStarted)
                                
                                background: Rectangle {
                                    color: parent.enabled ? "#4a4a4a" : "#666"
                                    border.color: "#777"
                                    border.width: 1
                                    radius: 3
                                }
                            }
                            
                            CheckBox {
                                checked: true
                                enabled: isDroneConnected
                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            }
                            
                            Text {
                                text: "Auto-retry on failure (Mission Planner behavior)"
                                color: "white"
                                font.pixelSize: 11
                                anchors.verticalCenter: parent ? parent.verticalCenter : undefined
                            }
                        }

                        // Mission Planner status display with completion message
                        Rectangle {
                            width: parent ? (parent.width - 20) : 400
                            height: 45
                            color: "#4a4a4a"
                            border.color: "#666"
                            border.width: 1
                            radius: 3
                            
                            ScrollView {
                                anchors.fill: parent
                                anchors.margins: 5
                                
                                Text {
                                    text: isCalibrationCompleted ? "Calibration completed successfully! Click 'Completed' button to reboot autopilot." :
                                          compassCalibrationModel ? (compassCalibrationModel.statusText || "Ready") : 
                                          "Mission Planner compatible compass calibration ready"
                                    color: isCalibrationCompleted ? "#28a745" :
                                           (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? "#ffc107" : "white"
                                    font.pixelSize: 11
                                    font.bold: isCalibrationCompleted || (compassCalibrationModel && compassCalibrationModel.calibrationStarted)
                                    wrapMode: Text.WordWrap
                                    width: parent ? parent.width : 400
                                }
                            }
                        }

                        Text {
                            text: "Instructions: Start calibration, then rotate vehicle so each side points down (6 orientations). Listen for audio feedback."
                            color: "#ccc"
                            font.pixelSize: 10
                            wrapMode: Text.WordWrap
                            width: parent ? parent.width : 400
                            opacity: 0.8
                        }
                    }
                }

                // Large Vehicle button with improved styling and completion state
                Button {
                    text: isCalibrationCompleted ? "Completed - Large Vehicle" : "Large Vehicle\nMagCal"
                    width: isCalibrationCompleted ? 220 : 180
                    height: 50
                    enabled: isDroneConnected
                    onClicked: {
                        if (isCalibrationCompleted) {
                            rebootDialog.open();
                        } else if (compassCalibrationModel && isDroneConnected) {
                            console.log("[Compass] Mission Planner: Starting large vehicle calibration");
                            compassCalibrationModel.startCalibration();
                        }
                    }
                    background: Rectangle {
                        color: parent.enabled ? (isCalibrationCompleted ? "#28a745" : "#fd7e14") : "#666"
                        radius: 8
                        border.color: isCalibrationCompleted ? "#1e7e34" : (parent.enabled ? "#e67e22" : "#555")
                        border.width: 2
                        
                        gradient: Gradient {
                            GradientStop { 
                                position: 0.0; 
                                color: isCalibrationCompleted ? "#32cd32" : (parent.parent.enabled ? "#ff922b" : "#777")
                            }
                            GradientStop { 
                                position: 1.0; 
                                color: isCalibrationCompleted ? "#228b22" : (parent.parent.enabled ? "#e67e22" : "#555")
                            }
                        }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: parent.text
                        color: "white"
                        font.pixelSize: isCalibrationCompleted ? 12 : 13
                        font.bold: true
                        font.weight: Font.Bold
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    // Custom components with null safety
    component HeaderCell: Rectangle {
        property string text: ""
        property real cellWidth: 100
        
        width: cellWidth
        height: parent ? parent.height : 25
        color: "transparent"
        border.color: "#666"
        border.width: 1
        
        Text {
            anchors.centerIn: parent
            text: parent.text
            color: "white"
            font.pixelSize: 11
            font.bold: true
        }
    }

    component DataCell: Rectangle {
        property string text: ""
        property real cellWidth: 100
        property color textColor: "#ccc"
        
        width: cellWidth
        height: parent ? parent.height : 25
        color: "transparent"
        border.color: "#666"
        border.width: 1
        
        Text {
            anchors.centerIn: parent
            text: parent.text
            color: parent.textColor
            font.pixelSize: 11
        }
    }

    // Window lifecycle management with null safety
    Component.onDestruction: {
        console.log("[Compass] Mission Planner: Window closing - cleanup");
        if (compassCalibrationModel && compassCalibrationModel.calibrationStarted) {
            compassCalibrationModel.stopCalibration();
        }
    }

    Component.onCompleted: {
        console.log("[Compass] Mission Planner: UI initialized");
        console.log("[Compass] Connection state:", isDroneConnected);
        console.log("[Compass] Calibration model:", compassCalibrationModel !== null);
    }
}