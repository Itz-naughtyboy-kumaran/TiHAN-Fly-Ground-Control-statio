import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.10

Rectangle {
    id: root
    height: 70
    color: "#2c3e50" // Match calibration theme
    border.color: "#34495e"
    border.width: 2
    radius: 10

    // Connection state property - now directly linked to droneModel
    property bool isConnected: droneModel ? droneModel.isConnected : false
    property string connectionType: "Auto-Sync"
    property var calibrationModel: null

    // Signal to notify when connection state changes
    signal connectionStateChanged(bool connected)
    signal parametersRequested()
    signal parametersReceived(var parameters)

    // Watch for connection state changes from main droneModel
    Connections {
        target: droneModel
        function onIsConnectedChanged() {
            root.isConnected = droneModel.isConnected;
            console.log("CalibrationConnectionBar: Connection state changed to", root.isConnected);
            root.connectionStateChanged(root.isConnected);
            
            // If connected, request parameters for calibration
            if (root.isConnected) {
                console.log("CalibrationConnectionBar: Drone connected - requesting parameters...");
                root.parametersRequested();
                // Request all parameters from the drone
                if (droneCommander) {
                    droneCommander.requestAllParameters();
                }
            } else {
                console.log("CalibrationConnectionBar: Drone disconnected");
            }
        }
    }

    // Listen for parameter updates from droneCommander
    Connections {
        target: droneCommander
        function onParametersUpdated(parameters) {
            console.log("CalibrationConnectionBar: Parameters received from drone:", Object.keys(parameters).length, "parameters");
            root.parametersReceived(parameters);
        }
        
        function onParameterReceived(name, value, type) {
            console.log("CalibrationConnectionBar: Individual parameter received:", name, "=", value, "type:", type);
        }
        
        function onParameterUpdateResult(name, success, error) {
            console.log("CalibrationConnectionBar: Parameter update result:", name, success ? "SUCCESS" : "FAILED", error || "");
        }
    }

    // Accent line at bottom with calibration theme colors
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 3
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#3498db" }
            GradientStop { position: 0.5; color: "#2ecc71" }
            GradientStop { position: 1.0; color: "#f39c12" }
        }
        opacity: 0.8
        radius: 1
    }

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 25
        spacing: 20

        // Connection Type Display (Read-only)
        Rectangle {
            width: 180
            height: 45
            radius: 10
            color: "#34495e"
            border.color: "#4a5568"
            border.width: 2

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#34495e" }
                GradientStop { position: 1.0; color: "#2c3e50" }
            }

            Text {
                anchors.centerIn: parent
                text: "Auto-Sync Mode"
                font.pixelSize: 13
                font.family: "Segoe UI"
                font.weight: Font.Medium
                color: "#ecf0f1"
            }
        }

        // Connection String Display (Read-only, shows current drone connection)
        Rectangle {
            id: connectionStringContainer
            width: 240
            height: 45
            radius: 10
            color: "#34495e"
            border.color: root.isConnected ? "#2ecc71" : "#4a5568"
            border.width: 2

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#34495e" }
                GradientStop { position: 1.0; color: "#2c3e50" }
            }

            Behavior on border.color {
                ColorAnimation { duration: 300 }
            }

            Text {
                anchors.centerIn: parent
                text: root.isConnected ? "Synced with Main Connection" : "Waiting for Connection..."
                font.pixelSize: 12
                font.family: "Segoe UI"
                font.weight: Font.Medium
                color: root.isConnected ? "#2ecc71" : "#7f8c8d"
                
                SequentialAnimation on opacity {
                    running: !root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.5; duration: 1000 }
                    NumberAnimation { to: 1.0; duration: 1000 }
                }
            }
        }

        // Connection Status Indicator (Enhanced)
        Item {
            width: 60
            height: 45
            anchors.verticalCenter: parent.verticalCenter

            // Outer pulse ring
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: "transparent"
                border.color: root.isConnected ? "#2ecc71" : "#7f8c8d"
                border.width: 2
                anchors.centerIn: parent
                opacity: root.isConnected ? 0.4 : 0.2

                SequentialAnimation on scale {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.6; duration: 2000 }
                    NumberAnimation { to: 1.0; duration: 2000 }
                }

                SequentialAnimation on opacity {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.1; duration: 2000 }
                    NumberAnimation { to: 0.4; duration: 2000 }
                }
            }

            // Main indicator
            Rectangle {
                width: 18
                height: 18
                radius: 9
                anchors.centerIn: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.isConnected ? "#2ecc71" : "#7f8c8d" }
                    GradientStop { position: 1.0; color: root.isConnected ? "#27ae60" : "#5d6d7e" }
                }
                border.color: "#ffffff"
                border.width: 2

                SequentialAnimation on scale {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.3; duration: 1500 }
                    NumberAnimation { to: 1.0; duration: 1500 }
                }
            }

            // Connection sync icon
            Text {
                anchors.centerIn: parent
                text: root.isConnected ? "⚡" : "⏸"
                font.pixelSize: 10
                color: "white"
                
                SequentialAnimation on rotation {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 360; duration: 3000 }
                    NumberAnimation { to: 0; duration: 0 }
                }
            }
        }

        // Status Text (Enhanced with sync info)
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                text: root.isConnected ? "SYNCHRONIZED" : "DISCONNECTED"
                color: root.isConnected ? "#2ecc71" : "#7f8c8d"
                font.pixelSize: 12
                font.family: "Segoe UI"
                font.weight: Font.Bold

                SequentialAnimation on opacity {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.7; duration: 2000 }
                    NumberAnimation { to: 1.0; duration: 2000 }
                }
            }

            Text {
                text: root.isConnected ? "Ready for Calibration" : "Connect via Main Interface"
                color: root.isConnected ? "#3498db" : "#95a5a6"
                font.pixelSize: 9
                font.family: "Segoe UI"
                font.weight: Font.Normal
            }
        }

        // Refresh Parameters Button (only visible when connected)
        Button {
            id: refreshParametersBtn
            text: "🔄 Refresh"
            width: 100
            height: 35
            visible: root.isConnected
            anchors.verticalCenter: parent.verticalCenter

            onClicked: {
                console.log("CalibrationConnectionBar: Manually requesting parameter refresh...");
                root.parametersRequested();
                if (droneCommander) {
                    droneCommander.requestAllParameters();
                }
            }

            background: Rectangle {
                radius: 8
                border.width: 1
                border.color: refreshParametersBtn.pressed ? "#2980b9" : "#3498db"
                
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: refreshParametersBtn.pressed ? "#2980b9" : (refreshParametersBtn.hovered ? "#3498db" : "#3498db")
                    }
                    GradientStop {
                        position: 1.0
                        color: refreshParametersBtn.pressed ? "#21618c" : (refreshParametersBtn.hovered ? "#2e86c1" : "#2874a6")
                    }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            contentItem: Text {
                text: refreshParametersBtn.text
                font.pixelSize: 10
                font.family: "Segoe UI"
                font.weight: Font.Bold
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // Calibration Status Display (Right side) - Enhanced
    Item {
        id: calibrationStatusContainer
        width: 220
        height: 50
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 25

        Rectangle {
            anchors.fill: parent
            color: "#34495e"
            radius: 8
            border.color: root.isConnected ? "#2ecc71" : "#4a5568"
            border.width: 2

            Behavior on border.color {
                ColorAnimation { duration: 300 }
            }

            Column {
                anchors.centerIn: parent
                spacing: 3

                Text {
                    text: "CALIBRATION SYSTEM"
                    color: "#3498db"
                    font.pixelSize: 10
                    font.family: "Segoe UI"
                    font.weight: Font.Bold
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: root.isConnected ? "✅ Ready for Calibration" : "⏳ Connect to Start"
                    color: root.isConnected ? "#2ecc71" : "#bdc3c7"
                    font.pixelSize: 9
                    font.family: "Segoe UI"
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 8
                    
                    Text {
                        text: "● Level"
                        color: root.isConnected ? "#f39c12" : "#7f8c8d"
                        font.pixelSize: 8
                        font.family: "Segoe UI"
                    }
                    
                    Text {
                        text: "● Accelerometer"
                        color: root.isConnected ? "#f39c12" : "#7f8c8d"
                        font.pixelSize: 8
                        font.family: "Segoe UI"
                    }
                }
            }

            // Connection sync indicator on the right
            Rectangle {
                width: 6
                height: parent.height - 4
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                radius: 3
                color: root.isConnected ? "#2ecc71" : "#7f8c8d"
                
                SequentialAnimation on opacity {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.3; duration: 1500 }
                    NumberAnimation { to: 1.0; duration: 1500 }
                }
            }
        }
    }

    Component.onCompleted: {
        console.log("CalibrationConnectionBar initialized in auto-sync mode");
        // Set initial connection state
        if (droneModel) {
            root.isConnected = droneModel.isConnected;
            console.log("CalibrationConnectionBar: Initial connection state:", root.isConnected);
        }
    }
}