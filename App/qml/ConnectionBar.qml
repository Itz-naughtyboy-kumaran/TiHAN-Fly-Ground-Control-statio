import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.10

Rectangle {
    id: root
    height: 60
    color: "#ffffff" // White background
    border.color: "#dee2e6" // Light gray border
    border.width: 2

    property bool showConnectButton: true
    property var calibrationWindow: null  // Store reference to calibration window

    // Enhanced connection state properties
    property bool isConnected: droneModel ? droneModel.isConnected : false
    property bool isReconnecting: calibrationModel ? (calibrationModel.reconnectionAttempts > 0 && !calibrationModel.isDroneConnected) : false
    property bool autoReconnectEnabled: calibrationModel ? calibrationModel.autoReconnectEnabled : true
    property int reconnectionAttempts: calibrationModel ? calibrationModel.reconnectionAttempts : 0
    property var languageManager: null

    // ✅ UPDATED FONT PROPERTIES - Apply these to ALL text elements
    readonly property string standardFontFamily: "Consolas" // Changed to Times New Roman
    readonly property int standardFontSize: 16
    readonly property int standardFontWeight: Font.Bold

    // Signal to notify when connection state changes
    signal connectionStateChanged(bool connected)
    signal parametersRequested()
    signal parametersReceived(var parameters)

    // MOVED FUNCTIONS TO ROOT LEVEL - THIS FIXES THE SCOPE ISSUE
    function openAccelCalibration() {
        console.log("Opening AccelCalibration.qml...");
        
        // Close existing calibration window if it exists
        if (root.calibrationWindow) {
            root.calibrationWindow.close();
            root.calibrationWindow = null;
        }
        
        var component = Qt.createComponent("AccelCalibration.qml");
        if (component.status === Component.Ready) {
            root.calibrationWindow = component.createObject(null, {
                "calibrationModel": calibrationModel
            });
            if (root.calibrationWindow) {
                root.calibrationWindow.closing.connect(function() {
                    console.log("Accel calibration window closing");
                    root.calibrationWindow = null;
                });
                root.calibrationWindow.show();
                console.log("Accel calibration window created and shown");
            } else {
                console.log("Error creating accel calibration window object");
            }
        } else if (component.status === Component.Error) {
            console.log("AccelCalibration component error:", component.errorString());
        } else {
            console.log("AccelCalibration component not ready, status:", component.status);
        }
    }

    // Updated openESCCalibration function for connection_bar.qml
// Replace the existing openESCCalibration function with this one:
function openESCCalibration() {
    console.log("Opening esc_calibration.qml...");
    // Check if drone is connected first
    if (!root.isConnected) {
        console.log("Cannot open ESC calibration - drone not connected");
        // Show connection warning dialog
        var warningComponent = Qt.createComponent("qrc:/qml/ConnectionWarningDialog.qml");
        if (warningComponent.status === Component.Ready) {
            var warningDialog = warningComponent.createObject(null, {
                "title": "Connection Required",
                "message": "Please connect to the drone before opening ESC calibration."
            });
            if (warningDialog) {
                warningDialog.show();
            }
        }
        return;
    }
    
    // Close existing calibration window if it exists
    if (root.calibrationWindow) {
        root.calibrationWindow.close();
        root.calibrationWindow = null;
    }
    
    var component = Qt.createComponent("esc_calibration.qml");
    if (component.status === Component.Ready) {
        root.calibrationWindow = component.createObject(null, {
            // Pass the connected drone model and commander
            "droneModel": droneModel,
            "droneCommander": droneCommander,
            "escCalibrationModel": escCalibrationModel
        });
        if (root.calibrationWindow) {
            // Check if the closing signal exists before connecting
            if (root.calibrationWindow.closing) {
                root.calibrationWindow.closing.connect(function() {
                    console.log("ESC calibration window closing");
                    root.calibrationWindow = null;
                });
            } else {
                console.log("Warning: ESC calibration window does not have closing signal");
                // Alternative: use Component.onDestruction in the window itself
            }
            
            root.calibrationWindow.show();
            console.log("ESC calibration window created and shown with drone connection");
        } else {
            console.log("Error creating ESC calibration window object");
        }
    } else if (component.status === Component.Error) {
        console.log("ESC component error:", component.errorString());
    } else {
        console.log("ESC component not ready, status:", component.status);
        component.statusChanged.connect(function() {
            if (component.status === Component.Ready) {
                root.calibrationWindow = component.createObject(null, {
                    "droneModel": droneModel,
                    "droneCommander": droneCommander,
                    "escCalibrationModel": escCalibrationModel
                });
                
                if (root.calibrationWindow) {
                    // Check if the closing signal exists before connecting
                    if (root.calibrationWindow.closing) {
                        root.calibrationWindow.closing.connect(function() {
                            console.log("ESC calibration window closing");
                            root.calibrationWindow = null;
                        });
                    }
                    
                    root.calibrationWindow.show();
                    console.log("ESC calibration window created and shown (delayed)");
                }
            } else if (component.status === Component.Error) {
                console.log("ESC component error (delayed):", component.errorString());
            }
        });
    }
}
  function openServoCalibration() {
        console.log("Opening servo_calibration.qml...");
        // Check if drone is connected first
        if (!root.isConnected) {
            console.log("Cannot open servo calibration - drone not connected");
            return;
        }
        
        // Close existing calibration window if it exists
        if (root.calibrationWindow) {
            root.calibrationWindow.close();
            root.calibrationWindow = null;
        }
        
        var component = Qt.createComponent("servo_calibration.qml");
        if (component.status === Component.Ready) {
            root.calibrationWindow = component.createObject(null, {
                "servoCalibrationModel": servoCalibrationModel
            });
            if (root.calibrationWindow) {
                root.calibrationWindow.closing.connect(function() {
                    console.log("Servo calibration window closing");
                    root.calibrationWindow = null;
                });
                root.calibrationWindow.show();
                console.log("Servo calibration window created and shown with shared connection");
            } else {
                console.log("Error creating servo calibration window object");
            }
        } else if (component.status === Component.Error) {
            console.log("Servo component error:", component.errorString());
        } else {
            console.log("Servo component not ready, status:", component.status);
            component.statusChanged.connect(function() {
                if (component.status === Component.Ready) {
                    root.calibrationWindow = component.createObject(null, {
                        "servoCalibrationModel": servoCalibrationModel
                    });
           
                    if (root.calibrationWindow) {
                        root.calibrationWindow.closing.connect(function() {
                            console.log("Servo calibration window closing");
                            root.calibrationWindow = null;
                        });
                        
                        root.calibrationWindow.show();
                        console.log("Servo calibration window created and shown (delayed)");
                    }
                } else if (component.status === Component.Error) {
                    console.log("Servo component error (delayed):", component.errorString());
                }
            });
        }
    }
    function openRadioCalibration() {
        console.log("Opening radio.qml...");
        // Check if drone is connected first
        if (!root.isConnected) {
            console.log("Cannot open radio calibration - drone not connected");
            return;
        }
        
        // Close existing calibration window if it exists
        if (root.calibrationWindow) {
            root.calibrationWindow.close();
            root.calibrationWindow = null;
        }
        
        var component = Qt.createComponent("radio.qml");
        if (component.status === Component.Ready) {
            root.calibrationWindow = component.createObject(null, {
                "radioCalibrationModel": radioCalibrationModel
            });
            if (root.calibrationWindow) {
                root.calibrationWindow.closing.connect(function() {
                    console.log("Radio calibration window closing");
                    root.calibrationWindow = null;
                });
                root.calibrationWindow.show();
                console.log("Radio calibration window created and shown with shared connection");
            } else {
                console.log("Error creating radio calibration window object");
            }
        } else if (component.status === Component.Error) {
            console.log("Radio component error:", component.errorString());
        } else {
            console.log("Radio component not ready, status:", component.status);
            component.statusChanged.connect(function() {
                if (component.status === Component.Ready) {
                    root.calibrationWindow = component.createObject(null, {
                        "radioCalibrationModel": radioCalibrationModel
                    });
           
                    if (root.calibrationWindow) {
                        root.calibrationWindow.closing.connect(function() {
                            console.log("Radio calibration window closing");
                            root.calibrationWindow = null;
                        });
                        
                        root.calibrationWindow.show();
                        console.log("Radio calibration window created and shown (delayed)");
                    }
                } else if (component.status === Component.Error) {
                    console.log("Radio component error (delayed):", component.errorString());
                }
            });
        }
    }

    // Replace the existing openCompassCalibration function in ConnectionBar.qml with this:

function openCompassCalibration() {
    console.log("Opening compass_shared.qml with shared connection...");
    // Check if drone is connected first
    if (!root.isConnected) {
        console.log("Cannot open compass calibration - drone not connected");
        // Show connection warning dialog
        var warningComponent = Qt.createComponent("qrc:/qml/ConnectionWarningDialog.qml");
        if (warningComponent.status === Component.Ready) {
            var warningDialog = warningComponent.createObject(null, {
                "title": "Connection Required",
                "message": "Please connect to the drone before opening compass calibration."
            });
            if (warningDialog) {
                warningDialog.show();
            }
        }
        return;
    }
    
    // Close existing calibration window if it exists
    if (root.calibrationWindow) {
        root.calibrationWindow.close();
        root.calibrationWindow = null;
    }
    
    // Load the shared compass calibration component
    var component = Qt.createComponent("compass.qml");
    if (component.status === Component.Ready) {
        root.calibrationWindow = component.createObject(null, {
            // Pass the shared connection models
            "compassCalibrationModel": compassCalibrationModel,
            "droneModel": droneModel,
            "droneCommander": droneCommander
        });
        if (root.calibrationWindow) {
            // Check if the closing signal exists before connecting
            if (root.calibrationWindow.closing) {
                root.calibrationWindow.closing.connect(function() {
                    console.log("Shared compass calibration window closing");
                    root.calibrationWindow = null;
                });
            }
            
            root.calibrationWindow.show();
            console.log("Shared compass calibration window created and shown with PyMAVLink backend");
            // Test buzzer when window opens (optional)
            if (compassCalibrationModel && compassCalibrationModel.testBuzzer) {
                // Wait a bit for window to stabilize
                var testTimer = Qt.createQmlObject(
                    "import QtQuick 2.15; Timer { interval: 1500; running: true; repeat: false }",
                    root, "testTimer"
                );
                testTimer.triggered.connect(function() {
                    compassCalibrationModel.testBuzzer();
                    testTimer.destroy();
                });
            }
            
        } else {
            console.log("Error creating shared compass calibration window object");
        }
    } else if (component.status === Component.Error) {
        console.log("Shared compass component error:", component.errorString());
    } else {
        console.log("Shared compass component not ready, status:", component.status);
        component.statusChanged.connect(function() {
            if (component.status === Component.Ready) {
                root.calibrationWindow = component.createObject(null, {
                    "compassCalibrationModel": compassCalibrationModel,
                    "droneModel": droneModel,
                    "droneCommander": droneCommander
                });
                
                if (root.calibrationWindow) {
                    if (root.calibrationWindow.closing) {
                        root.calibrationWindow.closing.connect(function() {
                            console.log("Shared compass calibration window closing (delayed)");
                            root.calibrationWindow = null;
                        });
                    }
                    
                    root.calibrationWindow.show();
                    console.log("Shared compass calibration window created and shown (delayed)");
                }
            } else if (component.status === Component.Error) {
                console.log("Shared compass component error (delayed):", component.errorString());
            }
        });
    }
}

    // Function to add custom connection to the combo box
    function addCustomConnection(connectionString) {
        // Check if connection string already exists
        for (let i = 0; i < portModel.count; i++) {
            if (portModel.get(i).port === connectionString) {
                portSelector.currentIndex = i;
                connectionStringInput.text = "";
                return;
            }
        }
        
        // Add new custom connection
        const customId = "custom-" + Math.random().toString(36).substring(2, 8);
        portModel.append({ 
            id: customId, 
            port: connectionString, 
            display: "Custom (" + connectionString + ")" 
        });
        // Select the newly added connection
        portSelector.currentIndex = portModel.count - 1;
        // Clear the text input
        connectionStringInput.text = "";
    }

    // Watch for connection state changes
    Connections {
        target: droneModel
        function onIsConnectedChanged() {
            root.isConnected = droneModel.isConnected;
            root.connectionStateChanged(root.isConnected);
            
            // Store connection info when connected
            if (root.isConnected && calibrationModel) {
                if (droneModel.current_connection_string) {
                    console.log("Storing connection info for auto-reconnection:", droneModel.current_connection_string);
                }
            }
            
           
        }
    }

    // Watch for calibration model changes (reconnection status)
    Connections {
        target: calibrationModel
        function onCalibrationStatusChanged() {
            root.isReconnecting = (calibrationModel.reconnectionAttempts > 0 && !calibrationModel.isDroneConnected);
            root.reconnectionAttempts = calibrationModel.reconnectionAttempts;
            root.autoReconnectEnabled = calibrationModel.autoReconnectEnabled;
        }
    }

    // Listen for parameter updates from droneCommander
    Connections {
        target: droneCommander
        function onParametersUpdated(parameters) {
            console.log("Parameters received from drone:", Object.keys(parameters).length, "parameters");
            root.parametersReceived(parameters);
        }
        
        function onParameterReceived(name, value, type) {
            console.log("Individual parameter received:", name, "=", value, "type:", type);
        }
        
        function onParameterUpdateResult(name, success, error) {
            console.log("Parameter update result:", name, success ? "SUCCESS" : "FAILED", error || "");
        }
    }

    // Accent line at bottom - Light theme colors
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 3
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#0066cc" }
            GradientStop { position: 0.5; color: "#28a745" }
            GradientStop { position: 1.0; color: "#17a2b8" }
        }
        opacity: 0.8
    }

Row {
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    anchors.leftMargin: 25
    spacing: 15
    
    // Add import for DropShadow effect
    // Note: You may need to add "import QtGraphicalEffects 1.15" at the top of your QML file
    
    ComboBox {
        id: portSelector
        width: 140
        height: 40
        model: ListModel { id: portModel }
        
        property var selectedPort: portModel.get(currentIndex)
        
        // Updated background with light blue color
        background: Rectangle {
            radius: 8
            border.color: portSelector.activeFocus ? "#4a90e2" : "#e0e0e0"
            border.width: portSelector.activeFocus ? 2 : 1
            color: (portSelector.currentIndex >= 0) ? "#add8e6" : "#f8fbff"
            
            // Add subtle gradient for better visual appeal
            gradient: Gradient {
                GradientStop { position: 0.0; color: (portSelector.currentIndex >= 0) ? "#b8dff0" : "#ffffff" }
                GradientStop { position: 1.0; color: (portSelector.currentIndex >= 0) ? "#9dd0e6" : "#f0f8ff" }
            }
        }
        
        // Fixed contentItem with proper text clipping and alignment
        contentItem: Text {
            text: {
                if (portSelector.currentIndex >= 0 && portSelector.currentIndex < portModel.count) {
                    return portModel.get(portSelector.currentIndex).display
                }
                return "Select Port"
            }
            font.pixelSize: root.standardFontSize
            font.family: root.standardFontFamily
            font.weight: Font.Medium
            color: (portSelector.currentIndex >= 0) ? "#2c3e50" : "#7f8c8d"
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignLeft
            renderType: Text.NativeRendering
            elide: Text.ElideRight
            clip: true
            leftPadding: 12
            rightPadding: 35
            topPadding: 0
            bottomPadding: 0
            width: parent.width - 35
        }
        
        // Improved delegate with better styling and hover effects
        delegate: ItemDelegate {
            width: portSelector.width
            height: 38
            
            background: Rectangle {
                color: {
                    if (parent.pressed) return "#5a9fd4"
                    if (parent.hovered) return "#87ceeb"
                    return "transparent"
                }
                radius: 4
                
                // Add subtle border for better definition
                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.color: parent.hovered ? "#70b8e0" : "transparent"
                    border.width: 1
                    radius: 4
                }
            }
            
            contentItem: Text {
                text: model.display
                color: {
                    if (parent.pressed) return "#ffffff"
                    if (parent.hovered) return "#ffffff"
                    return "#2c3e50"
                }
                font.pixelSize: root.standardFontSize
                font.family: root.standardFontFamily
                font.weight: Font.Normal
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignLeft
                renderType: Text.NativeRendering
                elide: Text.ElideRight
                clip: true
                leftPadding: 12
                rightPadding: 12
                topPadding: 6
                bottomPadding: 6
            }
            
            onClicked: {
                portSelector.currentIndex = index
                portSelector.popup.close()
                console.log("Selected port:", model.display)
            }
        }
        
        // Significantly improved popup styling with shadow and better appearance
        popup: Popup {
            y: portSelector.height + 4
            width: portSelector.width
            height: Math.min(contentItem.implicitHeight + 8, 240)
            padding: 4
            
            // Add drop shadow effect (requires QtGraphicalEffects import)
            background: Rectangle {
                color: "#ffffff"
                border.color: "#c0c0c0"
                border.width: 1
                radius: 8
                
                // Add shadow using a Rectangle behind
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 2
                    anchors.leftMargin: 2
                    color: "#20000000"
                    radius: 8
                    z: -1
                }
                
                // Inner border for polish
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    color: "transparent"
                    border.color: "#f0f0f0"
                    border.width: 1
                    radius: 7
                }
            }
            
            contentItem: ListView {
                implicitHeight: contentHeight
                model: portSelector.popup.visible ? portSelector.delegateModel : null
                currentIndex: portSelector.highlightedIndex
                clip: true
                spacing: 1
                
                // Add subtle separator lines between items
                delegate: Column {
                    width: ListView.view.width
                    
                    ItemDelegate {
                        width: portSelector.width - 8
                        height: 38
                        
                        background: Rectangle {
                            color: {
                                if (parent.pressed) return "#5a9fd4"
                                if (parent.hovered) return "#e8f4fd"
                                return "transparent"
                            }
                            radius: 4
                            
                            // Subtle hover border
                            border.color: parent.hovered ? "#205c08ff" : "transparent"
                            border.width: parent.hovered ? 1 : 0
                        }
                        
                        contentItem: Text {
                            text: model.display
                            color: {
                                if (parent.pressed) return "#ffffff"
                                if (parent.hovered) return "#2980b9"
                                return "#2c3e50"
                            }
                            font.pixelSize: root.standardFontSize
                            font.family: root.standardFontFamily
                            font.weight: parent.hovered ? Font.Medium : Font.Normal
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignLeft
                            renderType: Text.NativeRendering
                            elide: Text.ElideRight
                            clip: true
                            leftPadding: 12
                            rightPadding: 12
                            topPadding: 6
                            bottomPadding: 6
                        }
                        
                        onClicked: {
                            portSelector.currentIndex = index
                            portSelector.popup.close()
                            console.log("Selected port:", model.display)
                        }
                    }
                    
                    // Separator line (except for last item)
                    Rectangle {
                        width: parent.width - 24
                        height: index < portModel.count - 1 ? 1 : 0
                        color: "#f0f0f0"
                        anchors.horizontalCenter: parent.horizontalCenter
                        visible: index < portModel.count - 1
                    }
                }
            }
        }
        
        // Improved custom indicator (dropdown arrow)
        indicator: Rectangle {
            x: portSelector.width - width - 10
            y: portSelector.height / 2 - height / 2
            width: 16
            height: 16
            color: "transparent"
            
            Canvas {
                id: canvas
                anchors.centerIn: parent
                width: 10
                height: 6
                contextType: "2d"

                Connections {
                    target: portSelector
                    function onPressedChanged() { canvas.requestPaint() }
                    function onHoveredChanged() { canvas.requestPaint() }
                }

                onPaint: {
                    context.reset()
                    context.moveTo(0, 0)
                    context.lineTo(width, 0)
                    context.lineTo(width / 2, height)
                    context.closePath()
                    if (portSelector.pressed) {
                        context.fillStyle = "#07883dff"
                    } else if (portSelector.hovered) {
                        context.fillStyle = "#14d845ff"
                    } else {
                        context.fillStyle = "#666666"
                    }
                    context.fill()
                }
            }
        }
        
        // Handle selection changes
        onCurrentIndexChanged: {
            if (currentIndex >= 0 && currentIndex < portModel.count) {
                console.log("Port changed to:", portModel.get(currentIndex).display)
            }
        }
        
        // Enhanced methods for better functionality
        
        // Method to add ports to the model
        function addPort(portName) {
            portModel.append({"display": portName})
        }
        
        // Method to clear all ports
        function clearPorts() {
            portModel.clear()
            currentIndex = -1
        }
        
        // Method to select port by name
        function selectPort(portName) {
            for (var i = 0; i < portModel.count; i++) {
                if (portModel.get(i).display === portName) {
                    currentIndex = i
                    return true
                }
            }
            return false
        }
        
        // Method to clear selection
        function clearSelection() {
            currentIndex = -1
        }
        
        // Method to get current selection
        function getCurrentSelection() {
            if (currentIndex >= 0 && currentIndex < portModel.count) {
                return portModel.get(currentIndex).display
            }
            return ""
        }
        
        // Method to check if port exists
        function hasPort(portName) {
            for (var i = 0; i < portModel.count; i++) {
                if (portModel.get(i).display === portName) {
                    return true
                }
            }
            return false
        }
    }



        // Custom Connection String Text Box
        Rectangle {
            id: connectionStringContainer
            width: 200
            height: 40
            radius: 10
            color: "#f8f9fa"
            border.color: connectionStringInput.activeFocus ? "#0066cc" : "#dee2e6"
            border.width: 2

            gradient: Gradient {
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 1.0; color: "#f8f9fa" }
            }

            Behavior on border.color {
                ColorAnimation { duration: 300 }
            }

            // ✅ STANDARDIZED FONT: Apply to TextInput
            TextInput {
                id: connectionStringInput
                anchors.fill: parent
                anchors.leftMargin: 15
                anchors.rightMargin: 15
                
                font.pixelSize: root.standardFontSize
                font.family: root.standardFontFamily
                font.weight: root.standardFontWeight
                color: "#212529"
                verticalAlignment: Text.AlignVCenter
                
                selectByMouse: true
                clip: true
                
                // ✅ STANDARDIZED FONT: Apply to placeholder text
                Text {
                    id: placeholderText
                    anchors.fill: parent
                    text: "Enter connection string..."
                    font.pixelSize: root.standardFontSize
                    font.family: root.standardFontFamily
                    font.weight: root.standardFontWeight
                    color: "#6c757d"
                    verticalAlignment: Text.AlignVCenter
                    visible: !connectionStringInput.text && !connectionStringInput.activeFocus
                }
            }
        }

        Button {
            id: toggleConnectBtn
            visible: showConnectButton
            text: {
                if (isReconnecting) {
                    return "Reconnecting..."
                } else {
                    return languageManager ? languageManager.getText(root.isConnected ? "DISCONNECT" : "CONNECT") : 
                        (root.isConnected ? "DISCONNECT" : "CONNECT")
                }
            }
            width: 130
            height: 40
            enabled: !isReconnecting

            onClicked: {
                let connectionString = "";
                let connectionId = "";
                
                if (connectionStringInput.text.trim() !== "") {
                    connectionString = connectionStringInput.text.trim();
                    connectionId = "custom-" + Math.random().toString(36).substring(2, 8);
                } else {
                    const selectedPort = portSelector.selectedPort;
                    if (selectedPort) {
                        connectionString = selectedPort.port;
                        connectionId = selectedPort.id;
                    }
                }
                
                if (!root.isConnected && connectionString) {
                    console.log("Connecting to:", connectionId, connectionString);
                    droneModel.current_connection_string = connectionString;
                    droneModel.current_connection_id = connectionId;
                    
                    droneModel.connectToDrone(connectionId, connectionString, 57600);
                    
                } else if (root.isConnected) {
                    console.log("Disconnecting from drone...");
                    if (calibrationModel) {
                        calibrationModel.disableAutoReconnect();
                    }
                    
                    droneModel.disconnectDrone();
                    root.isConnected = false;
                    root.connectionStateChanged(false);
                }
            }

            // ✅ Button background (Green = Connect, Red = Disconnect)
            background: Rectangle {
                radius: 10
                border.width: 2
                border.color: {
                    if (isReconnecting) return "#ffc107"
                    else if (root.isConnected) {
                        return toggleConnectBtn.pressed ? "#a71d2a" : "#dc3545"   // Red for DISCONNECT
                    } else {
                        return toggleConnectBtn.pressed ? "#1e7e34" : "#28a745"   // Green for CONNECT
                    }
                }

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: {
                            if (isReconnecting) return "#ffc107"
                            else if (root.isConnected) {
                                return toggleConnectBtn.pressed ? "#a71d2a" : (toggleConnectBtn.hovered ? "#bd2130" : "#dc3545")
                            } else {
                                return toggleConnectBtn.pressed ? "#1e7e34" : (toggleConnectBtn.hovered ? "#218838" : "#28a745")
                            }
                        }
                    }
                    GradientStop {
                        position: 1.0
                        color: {
                            if (isReconnecting) return "#e0a800"
                            else if (root.isConnected) {
                                return toggleConnectBtn.pressed ? "#7f1d1d" : (toggleConnectBtn.hovered ? "#a71d2a" : "#bd2130")
                            } else {
                                return toggleConnectBtn.pressed ? "#155d27" : (toggleConnectBtn.hovered ? "#1e7e34" : "#218838")
                            }
                        }
                    }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            // ✅ UPDATED FONT: Apply to button text
            contentItem: Text {
                text: toggleConnectBtn.text
                font.pixelSize: root.standardFontSize
                font.family: root.standardFontFamily
                font.weight: root.standardFontWeight
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                anchors.centerIn: parent
            }
        }

        // Force Reconnect Button
        Button {
            id: forceReconnectBtn
            text: "⟲"
            width: 40
            height: 40
            visible: !root.isConnected && calibrationModel && calibrationModel.lastConnectionString !== ""
            
            onClicked: {
                if (calibrationModel) {
                    calibrationModel.forceReconnect();
                }
            }

            background: Rectangle {
                radius: 10
                border.width: 2
                border.color: forceReconnectBtn.pressed ? "#215f88ff" : "#287fa7ff"
                
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: forceReconnectBtn.pressed ? "#217888ff" : (forceReconnectBtn.hovered ? "#218838" : "#28a745")
                    }
                    GradientStop {
                        position: 1.0
                        color: forceReconnectBtn.pressed ? "#1e7e34" : (forceReconnectBtn.hovered ? "#1e7e34" : "#218838")
                    }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            // ✅ UPDATED FONT: Apply to force reconnect button text
            contentItem: Text {
                text: forceReconnectBtn.text
                font.pixelSize: root.standardFontSize
                font.family: root.standardFontFamily
                font.weight: root.standardFontWeight
                color: "#ffffff"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            ToolTip.visible: hovered
            ToolTip.text: "Force reconnection attempt"
            ToolTip.delay: 1000
        }

        // Calibration ComboBox - Light theme
// Replace the calibrationSelector ComboBox in connection_bar.qml with this fixed version:

ComboBox {
    id: calibrationSelector
    width: 120
    height: 40
    enabled: root.isConnected

    model: ListModel {
        ListElement { text: "🔧 Accel"; value: 1 }
        ListElement { text: "🧭 Compass"; value: 2 }
        ListElement { text: "📻 Radio"; value: 3 }
        ListElement { text: "⚡ ESC"; value: 4 }
        ListElement { text: "🎛️ Servo"; value: 5 }
    }

    textRole: "text"
    currentIndex: -1
    displayText: "Calibrate"

    // ✅ FIX: Use proper function calls without index manipulation
    onActivated: function(index) {
        console.log("Calibration selector activated with index:", index);
        var selectedValue = model.get(index).value;
        console.log("Selected value:", selectedValue);
        
        // Reset to default display immediately
        Qt.callLater(function() {
            calibrationSelector.currentIndex = -1;
        });
        
        // Open appropriate calibration window
        if (selectedValue === 1) {
            console.log("Opening Accel Calibration...");
            root.openAccelCalibration();
        } else if (selectedValue === 2) {
            console.log("Opening Compass Calibration...");
            root.openCompassCalibration();
        } else if (selectedValue === 3) {
            console.log("Opening Radio Calibration...");
            root.openRadioCalibration();
        } else if (selectedValue === 4) {
            console.log("Opening ESC Calibration...");
            root.openESCCalibration();
        } else if (selectedValue === 5) {
            console.log("Opening Servo Calibration...");
            root.openServoCalibration();
        }
    }

    background: Rectangle {
        radius: 10
        border.width: 2
        border.color: enabled ? (calibrationSelector.pressed ? "#4a90e2" : "#87ceeb") : "#adb5bd"
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: enabled ? (calibrationSelector.pressed ? "#4a90e2" : (calibrationSelector.hovered ? "#7bb3e0" : "#87ceeb")) : "#adb5bd"
            }
            GradientStop {
                position: 1.0
                color: enabled ? (calibrationSelector.pressed ? "#357abd" : (calibrationSelector.hovered ? "#4a90e2" : "#7bb3e0")) : "#868e96"
            }
        }

        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }

    contentItem: Text {
        text: calibrationSelector.displayText
        font.pixelSize: root.standardFontSize
        font.family: root.standardFontFamily
        font.weight: root.standardFontWeight
        color: enabled ? "#2c5282" : "#6c757d"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.leftMargin: 10
        anchors.rightMargin: 30
        anchors.topMargin: 5
        anchors.bottomMargin: 5
        elide: Text.ElideRight
    }

    popup: Popup {
        y: calibrationSelector.height + 2
        width: calibrationSelector.width
        height: contentItem.implicitHeight
        padding: 2
        margins: 0
        
        background: Rectangle {
            color: "#ffffff"
            border.color: Qt.rgba(0.4, 0.4, 0.4, 0.8)
            border.width: 1
            radius: 6
        }
        
        contentItem: ListView {
            implicitHeight: contentHeight
            model: calibrationSelector.popup.visible ? calibrationSelector.delegateModel : null
            currentIndex: calibrationSelector.highlightedIndex
            clip: true
            spacing: 1
        }
    }

    delegate: ItemDelegate {
        width: calibrationSelector.width
        height: 35

        background: Rectangle {
            color: parent.hovered ? "#4CAF50" : "#ffffff"
            radius: 4
        }

        contentItem: Text {
            text: model.text
            color: parent.hovered ? "#ffffff" : "#000000"
            font.pixelSize: root.standardFontSize
            font.family: root.standardFontFamily
            font.weight: root.standardFontWeight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            renderType: Text.NativeRendering
        }

        // ✅ FIX: Properly handle click and close popup
        onClicked: {
            console.log("Delegate clicked, index:", index);
            calibrationSelector.activated(index);
            calibrationSelector.popup.close();
        }
    }

    ToolTip.visible: hovered
    ToolTip.text: root.isConnected ? "Choose calibration type" : "Connect to drone first"
    ToolTip.delay: 1000
}

// Language Selector - Dark theme (hover green + button light blue on selection)
// Language Selector - Blue theme (same as calibration button)
ComboBox {
    id: languageSelector
    width: 120
    height: 40
    model: ["English", "हिंदी", "தமிழ்", "తెలుగు"]
    currentIndex: 0
    property var languageCodes: ["en", "hi", "ta", "te"]

    onCurrentIndexChanged: {
        if (languageManager) {
            languageManager.changeLanguage(languageCodes[currentIndex]);
        }
    }

    // ✅ Same background style as calibrationSelector
    background: Rectangle {
        radius: 10
        border.width: 2
        border.color: enabled ? (languageSelector.pressed ? "#4a90e2" : "#87ceeb") : "#adb5bd"
        gradient: Gradient {
            GradientStop {
                position: 0.0
                color: enabled ? (languageSelector.pressed ? "#4a90e2" : (languageSelector.hovered ? "#7bb3e0" : "#87ceeb")) : "#adb5bd"
            }
            GradientStop {
                position: 1.0
                color: enabled ? (languageSelector.pressed ? "#357abd" : (languageSelector.hovered ? "#4a90e2" : "#7bb3e0")) : "#868e96"
            }
        }

        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }

    // ✅ Standardized text style
    contentItem: Text {
        text: languageSelector.displayText
        font.pixelSize: root.standardFontSize
        font.family: root.standardFontFamily
        font.weight: root.standardFontWeight
        color: enabled ? "#2c5282" : "#6c757d"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        anchors.fill: parent
        anchors.margins: 5
        elide: Text.ElideRight
    }

    // ✅ Dropdown delegate styling (green hover like before)
    delegate: ItemDelegate {
        width: languageSelector.width
        height: 35

        background: Rectangle {
            color: parent.hovered ? "#4CAF50" : "#ffffff" // Green on hover, white otherwise
            radius: 4
        }

        contentItem: Text {
            text: modelData
            color: parent.hovered ? "#ffffff" : "#000000"
            font.pixelSize: root.standardFontSize
            font.family: root.standardFontFamily
            font.weight: root.standardFontWeight
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }

        onClicked: {
            languageSelector.currentIndex = index
            languageSelector.popup.close()
        }
    }

    // ✅ Popup styling same as calibrationSelector
    popup: Popup {
        y: languageSelector.height + 2
        width: languageSelector.width
        height: contentItem.implicitHeight
        padding: 4

        background: Rectangle {
            color: "#ffffff"
            border.color: Qt.rgba(0.4, 0.4, 0.4, 0.8)
            border.width: 1
            radius: 6
        }

        contentItem: ListView {
            implicitHeight: contentHeight
            model: languageSelector.popup.visible ? languageSelector.delegateModel : null
            currentIndex: languageSelector.highlightedIndex
            clip: true
        }
    }
}
}

    
    // Logo container - Light theme
  Item {
    id: logoContainer
    width: 120
    height: 50
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.rightMargin: 25

    Image {
        id: logoImage
        anchors.centerIn: parent
        width: 100
        height: 40
        source: "../images/tihan.png"
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true

        onStatusChanged: {
            if (status === Image.Error) {
                console.log("Failed to load image from:", source)
            } else if (status === Image.Ready) {
                console.log("Successfully loaded image from:", source)
            }
        }

        // ✅ STANDARDIZED FONT: Apply to logo fallback text
        Text {
            anchors.centerIn: parent
            text: "TIHAN FLY"
            color: "#0066cc"
            font.pixelSize: root.standardFontSize
            font.family: root.standardFontFamily
            font.weight: root.standardFontWeight
            visible: logoImage.status !== Image.Ready
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true

            onEntered: { logoImage.scale = 1.05 }
            onExited: { logoImage.scale = 1.0 }

            onClicked: {
                var component = Qt.createComponent("AboutTihan.qml");
                if (component.status === Component.Ready) {
                    var window = component.createObject(null);
                    window.show();
                } else if (component.status === Component.Error) {
                    console.log("Error loading AboutTihan.qml:", component.errorString());
                }
            }
        }

        Behavior on scale {
            NumberAnimation { duration: 200 }
        }
    }
}

    Component.onCompleted: {
        portModel.clear();
        const sitlPort = "udp:127.0.0.1:14550";
        const randomId = "sitl-" + Math.random().toString(36).substring(2, 8);
        portModel.append({ id: randomId, port: sitlPort, display: "SITL (" + sitlPort + ")" });

        const availablePorts = portManager.getAvailablePorts();
        for (let i = 0; i < availablePorts.length; ++i) {
            const port = availablePorts[i];
            if (port !== sitlPort) {
                portModel.append({ id: "port-" + i, port: port, display: port });
            }
        }

        portSelector.currentIndex = 0;
        // Enable auto-reconnection by default
        if (calibrationModel) {
            calibrationModel.enableAutoReconnect();
        }
    }

    // Clean up calibration window reference when this component is destroyed
    Component.onDestruction: {
        if (root.calibrationWindow) {
            root.calibrationWindow.close();
            root.calibrationWindow = null;
        }
    }
}