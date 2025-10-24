import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15
import QtQuick.Controls.Material 2.15
import Qt.labs.qmlmodels 1.0

ApplicationWindow {
    id: parametersWindowRoot
    visible: true
    visibility: "Maximized"
    color: "#ffffff"
    title: "Drone Parameters Configuration"

    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2

    Material.theme: Material.Light
    Material.primary: Material.Blue
    Material.accent: Material.Teal

    property var allParameters: droneCommander.parameters
    property bool isDroneConnected: true
    property string connectionStatus: isDroneConnected ? "CONNECTED" : "DISCONNECTED"
    property string lastError: ""
    property bool isUpdatingParameter: false

    // Mock data for demonstration
    property var mockParameters: [
        { "name": "SERVO1_FUNCTION", "value": "1", "type": "INT32", "description": "RC servo function", "range": "0-100", "units": "", "default": "0", "synced": true },
        { "name": "ACRO_BAL_PITCH", "value": "1", "type": "FLOAT", "description": "Acro balance pitch", "range": "0-1", "units": "", "default": "0", "synced": true },
        { "name": "ACRO_BAL_ROLL", "value": "1", "type": "FLOAT", "description": "Acro balance roll", "range": "0-1", "units": "", "default": "0", "synced": true }
    ]

    // Status notification
    Rectangle {
        id: statusNotification
        anchors.top: parametersWindowRoot.top
        anchors.horizontalCenter: parametersWindowRoot.horizontalCenter
        anchors.topMargin: 100
        width: 300
        height: 50
        color: "#10B981"
        radius: 8
        opacity: 0
        z: 1000
        
        Label {
            anchors.centerIn: parent
            text: "Parameter updated successfully!"
            color: "white"
            font.pixelSize: 12
            font.bold: true
        }
        
        Behavior on opacity {
            NumberAnimation { duration: 300 }
        }
        
        Timer {
            id: hideNotificationTimer
            interval: 2000
            onTriggered: statusNotification.opacity = 0
        }
    }

    // Main layout
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Top toolbar with search and filters
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: "#f5f5f5"
            border.color: "#cccccc"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Label {
                    text: "Filter:"
                    color: "#333333"
                    font.pixelSize: 12
                }

                TextField {
                    id: searchBar
                    placeholderText: "Search parameters..."
                    Layout.preferredWidth: 200
                    Layout.preferredHeight: 25
                    color: "#333333"
                    font.pixelSize: 11
                    onTextChanged: filterParameters()
                    
                    background: Rectangle {
                        color: "#ffffff"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                }

                Button {
                    text: "Clear"
                    Layout.preferredHeight: 25
                    Layout.preferredWidth: 60
                    font.pixelSize: 10
                    
                    background: Rectangle {
                        color: parent.pressed ? "#e0e0e0" : (parent.hovered ? "#f0f0f0" : "#ffffff")
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                    
                    onClicked: {
                        searchBar.text = ""
                        filterParameters()
                    }
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: paramModel.count + " parameters"
                    color: "#666666"
                    font.pixelSize: 11
                }

            }
        }

        // Parameters table
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            border.color: "#cccccc"
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                // Table header
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 30
                    color: "#f8f9fa"
                    border.color: "#dee2e6"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        spacing: 0

                        // Parameter Name column
                        Rectangle {
                            Layout.preferredWidth: 280
                            Layout.fillHeight: true
                            color: "transparent"
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Parameter"
                                color: "#333333"
                                font.bold: true
                                font.pixelSize: 11
                            }
                        }

                        // Value column
                        Rectangle {
                            Layout.preferredWidth: 120
                            Layout.fillHeight: true
                            color: "transparent"
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Value"
                                color: "#333333"
                                font.bold: true
                                font.pixelSize: 11
                            }
                        }

                        // Default column
                        Rectangle {
                            Layout.preferredWidth: 120
                            Layout.fillHeight: true
                            color: "transparent"
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Default"
                                color: "#333333"
                                font.bold: true
                                font.pixelSize: 11
                            }
                        }

                        // Units column
                        Rectangle {
                            Layout.preferredWidth: 80
                            Layout.fillHeight: true
                            color: "transparent"
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Units"
                                color: "#333333"
                                font.bold: true
                                font.pixelSize: 11
                            }
                        }

                        // Range column
                        Rectangle {
                            Layout.preferredWidth: 150
                            Layout.fillHeight: true
                            color: "transparent"
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Range"
                                color: "#333333"
                                font.bold: true
                                font.pixelSize: 11
                            }
                        }

                        // Description column
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "transparent"
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            Label {
                                anchors.left: parent.left
                                anchors.leftMargin: 8
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Description"
                                color: "#333333"
                                font.bold: true
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                // Table content with scrollable list
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    
                    ListView {
                        id: tableView
                        model: ListModel {
                            id: paramModel
                        }
                        spacing: 0

                        delegate: Rectangle {
                            width: tableView.width
                            height: 25
                            color: index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                            border.color: "#e9ecef"
                            border.width: 0.5
                            
                            property bool isUpdating: false

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                
                                onEntered: parent.color = "#e3f2fd"
                                onExited: parent.color = index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 5
                                anchors.rightMargin: 5
                                spacing: 0

                                // Parameter Name
                                Rectangle {
                                    Layout.preferredWidth: 280
                                    Layout.fillHeight: true
                                    color: "transparent"
                                    border.color: "#e9ecef"
                                    border.width: 1
                                    
                                    Label {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.name || ""
                                        color: "#1976d2"
                                        font.pixelSize: 10
                                        font.family: "Consolas, Monaco, monospace"
                                        elide: Text.ElideRight
                                    }
                                }

                                // Value (editable)
                                Rectangle {
                                    Layout.preferredWidth: 120
                                    Layout.fillHeight: true
                                    color: "transparent"
                                    border.color: "#e9ecef"
                                    border.width: 1
                                    
                                    TextField {
                                        id: valueField
                                        anchors.fill: parent
                                        anchors.margins: 1
                                        text: model.value || ""
                                        color: "#333333"
                                        font.pixelSize: 10
                                        selectByMouse: true
                                        enabled: !isUpdating
                                        horizontalAlignment: Text.AlignLeft
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 6
                                        rightPadding: 6
                                        topPadding: 2
                                        bottomPadding: 2
                                        
                                        background: Rectangle {
                                            color: parent.enabled ? "#ffffff" : "#f8f9fa"
                                            border.color: parent.activeFocus ? "#1976d2" : "#e9ecef"
                                            border.width: 1
                                            radius: 2
                                        }
                                        
                                        onEditingFinished: {
                                            if (text !== model.value) {
                                                parametersWindowRoot.updateParameterUI(model.name, text, index);
                                            }
                                        }
                                    }
                                }

                                // Default value
                                Rectangle {
                                    Layout.preferredWidth: 120
                                    Layout.fillHeight: true
                                    color: "transparent"
                                    border.color: "#e9ecef"
                                    border.width: 1
                                    
                                    Label {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.default || "0"
                                        color: "#666666"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                // Units
                                Rectangle {
                                    Layout.preferredWidth: 80
                                    Layout.fillHeight: true
                                    color: "transparent"
                                    border.color: "#e9ecef"
                                    border.width: 1
                                    
                                    Label {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.units || ""
                                        color: "#666666"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                // Range
                                Rectangle {
                                    Layout.preferredWidth: 150
                                    Layout.fillHeight: true
                                    color: "transparent"
                                    border.color: "#e9ecef"
                                    border.width: 1
                                    
                                    Label {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.range || ""
                                        color: "#666666"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }

                                // Description
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: "transparent"
                                    border.color: "#e9ecef"
                                    border.width: 1
                                    
                                    Label {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: model.description || ""
                                        color: "#666666"
                                        font.pixelSize: 10
                                        elide: Text.ElideRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Bottom action bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#f5f5f5"
            border.color: "#cccccc"
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 10

                Button {
                    text: "Refresh Params"
                    Layout.preferredHeight: 25
                    Layout.preferredWidth: 120
                    font.pixelSize: 10
                    enabled: !parametersWindowRoot.isUpdatingParameter
                    onClicked: parametersWindowRoot.loadParameters()
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#e0e0e0" : (parent.hovered ? "#f0f0f0" : "#ffffff")) : "#f5f5f5"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                }

                Button {
                    text: "Load from File"
                    Layout.preferredHeight: 25
                    Layout.preferredWidth: 120
                    font.pixelSize: 10
                    enabled: !parametersWindowRoot.isUpdatingParameter
                    onClicked: parametersWindowRoot.saveParameters()
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#e0e0e0" : (parent.hovered ? "#f0f0f0" : "#ffffff")) : "#f5f5f5"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                }

                Button {
                    text: "Save to File"
                    Layout.preferredHeight: 25
                    Layout.preferredWidth: 120
                    font.pixelSize: 10
                    enabled: parametersWindowRoot.isDroneConnected && !parametersWindowRoot.isUpdatingParameter
                    onClicked: parametersWindowRoot.exportParameters()
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#e0e0e0" : (parent.hovered ? "#f0f0f0" : "#ffffff")) : "#f5f5f5"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                }

                Button {
                    text: "Write Params"
                    Layout.preferredHeight: 25
                    Layout.preferredWidth: 120
                    font.pixelSize: 10
                    enabled: parametersWindowRoot.isDroneConnected && !parametersWindowRoot.isUpdatingParameter
                    onClicked: parametersWindowRoot.sendAllParametersUI()
                    
                    background: Rectangle {
                        color: parent.enabled ? (parent.pressed ? "#e0e0e0" : (parent.hovered ? "#f0f0f0" : "#ffffff")) : "#f5f5f5"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 2
                    }
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: parametersWindowRoot.isUpdatingParameter ? "Updating..." : "Ready"
                    color: parametersWindowRoot.isUpdatingParameter ? "#ff8c00" : "#10B981"
                    font.pixelSize: 10
                }
            }
        }
    }

    // Keep all your existing functions unchanged
    function loadParameters() {
        console.log("Loading mock parameters for UI demo...");
        
        allParameters = droneCommander.parameters;
        
        updateModel(allParameters);

        isUpdatingParameter = true;

        var loadTimer = Qt.createQmlObject(
            'import QtQuick 2.15; Timer { 
                    interval: 1000; 
                    repeat: false; 
                    onTriggered: { 
                        isUpdatingParameter = false;
                        statusNotification.color = "#10B981";
                        statusNotification.children[0].text = "Parameters loaded successfully!";
                        statusNotification.opacity = 1;
                        hideNotificationTimer.restart();
                        destroy();
                    }
                }', parametersWindowRoot
            );

            loadTimer.start();
    }

    function updateModel(params) {
        if (!params || typeof params !== "object") {
            console.error("Error: params is invalid or undefined.", params);
            // Load mock data if no real parameters available
            params = {};
            for (var i = 0; i < mockParameters.length; i++) {
                params[mockParameters[i].name] = mockParameters[i];
            }
        }

        var paramArray = Object.values(params); 
        console.log("Updating model with params:", paramArray);
        paramModel.clear();

        for (var i = 0; i < paramArray.length; i++) {
            var param = paramArray[i];
            if(param.type === 9 || param.type === 10) {
                param.type = "FLOAT";
            } else if (param.type === "FLOAT") {
                param.type = "FLOAT";
            } else {
                param.type = "INT32";
            }
            
            // Add realistic parameter descriptions and ranges based on parameter names
            param.default = param.default || "0";
            param.units = param.units || getUnitsForParameter(param.name);
            param.range = param.range || getRangeForParameter(param.name);
            param.description = param.description || getDescriptionForParameter(param.name);
            param.synced = param.synced !== undefined ? param.synced : true;
            
            paramModel.append(param);
        }
    }

    function getDescriptionForParameter(paramName) {
        // Extract parameter group and generate description
        var parts = paramName.split('_');
        var group = parts[0];
        
        // Comprehensive parameter descriptions based on groups
        var groupDescriptions = {
            // Flight modes and control
            "ACRO": "Acrobatic flight mode",
            "STAB": "Stabilize mode",
            "ALT": "Altitude hold mode",
            "AUTO": "Autonomous flight mode",
            "GUIDED": "Guided flight mode",
            "LOITER": "Loiter mode",
            "RTL": "Return to launch mode",
            "CIRCLE": "Circle flight mode",
            "LAND": "Landing mode",
            "DRIFT": "Drift flight mode",
            "SPORT": "Sport flight mode",
            "FLIP": "Flip mode",
            "BRAKE": "Brake mode",
            "THROW": "Throw mode",
            "AVOID": "Avoidance system",
            "FOLLOW": "Follow me mode",
            "ZIGZAG": "Zigzag mode",
            "SYSID": "System identification mode",
            "HELI": "Helicopter specific",
            "AUTOTUNE": "Auto-tuning mode",
            
            // Control systems
            "ATC": "Attitude controller",
            "PSC": "Position controller", 
            "VEL": "Velocity controller",
            "WPNAV": "Waypoint navigation",
            "CIRCLE": "Circle navigation",
            "FENCE": "Geofencing system",
            "RALLY": "Rally point system",
            
            // Sensors and estimation
            "AHRS": "Attitude heading reference system",
            "INS": "Inertial navigation system",
            "EK2": "Extended Kalman Filter 2",
            "EK3": "Extended Kalman Filter 3", 
            "COMPASS": "Magnetometer/compass",
            "GPS": "Global positioning system",
            "BARO": "Barometric pressure sensor",
            "RNGFND": "Range finder/sonar",
            "FLOW": "Optical flow sensor",
            "VISO": "Visual odometry",
            "BCN": "Beacon positioning system",
            "ARSPD": "Airspeed sensor",
            
            // Motors and servos
            "MOT": "Motor control",
            "SERVO": "Servo output",
            "ESC": "Electronic speed controller",
            
            // Radio and telemetry
            "RC": "Radio control input",
            "RSSI": "Received signal strength",
            "TELEM": "Telemetry system",
            "SR0": "Serial port 0 stream rate",
            "SR1": "Serial port 1 stream rate", 
            "SR2": "Serial port 2 stream rate",
            "SR3": "Serial port 3 stream rate",
            
            // Power and battery
            "BATT": "Battery monitoring",
            "VOLT": "Voltage monitoring",
            "CURR": "Current monitoring",
            
            // Logging and diagnostics
            "LOG": "Data logging system",
            "NTF": "Notification system",
            "STAT": "Status reporting",
            
            // Safety and arming
            "ARMING": "Arming safety checks",
            "FS": "Failsafe system",
            
            // Camera and gimbal
            "CAM": "Camera control",
            "MNT": "Mount/gimbal control",
            "GIMBAL": "Gimbal control",
            
            // Navigation aids
            "TERRAIN": "Terrain following",
            "RALLY": "Rally points",
            "MIS": "Mission planning",
            
            // Advanced features
            "ADSB": "ADS-B traffic system",
            "AVOID": "Object avoidance",
            "PRX": "Proximity sensors",
            "GRIP": "Gripper control",
            "WINCH": "Winch control",
            "SPRAY": "Crop spraying",
            "TEMP": "Temperature monitoring",
            "RCON": "Remote control",
            "CAN": "CAN bus communication",
            "SERIAL": "Serial communication",
            "NET": "Network settings",
            "SCHED": "Scheduler settings",
            "SIM": "Simulation parameters"
        };
        
        // Get specific descriptions for common parameters
        var specificDescriptions = {
            // Common specific parameters
            "_ENABLE": "Enable/disable this feature",
            "_TYPE": "Type selection for this feature", 
            "_OPTIONS": "Option flags bitmask",
            "_RATE": "Update rate or maximum rate",
            "_FILT": "Filter cutoff frequency",
            "_TC": "Time constant",
            "_P": "Proportional gain",
            "_I": "Integral gain", 
            "_D": "Derivative gain",
            "_IMAX": "Integral maximum",
            "_FF": "Feed forward gain",
            "_FLTT": "Target filter frequency",
            "_FLTE": "Error filter frequency",
            "_FLTD": "Derivative filter frequency",
            "_MIN": "Minimum value",
            "_MAX": "Maximum value",
            "_TRIM": "Trim/offset value",
            "_EXPO": "Exponential curve",
            "_THR": "Throttle related",
            "_PWM": "PWM output value",
            "_REVERSED": "Reverse direction flag",
            "_OFFSET": "Offset/calibration value",
            "_SCALE": "Scaling factor",
            "_ORIENT": "Orientation/rotation",
            "_X": "X-axis parameter",
            "_Y": "Y-axis parameter", 
            "_Z": "Z-axis parameter",
            "_ROLL": "Roll axis parameter",
            "_PITCH": "Pitch axis parameter",
            "_YAW": "Yaw axis parameter",
            "_LAT": "Latitude coordinate",
            "_LNG": "Longitude coordinate", 
            "_ALT": "Altitude parameter",
            "_RADIUS": "Radius parameter",
            "_SPEED": "Speed parameter",
            "_ACCEL": "Acceleration parameter",
            "_JERK": "Jerk parameter"
        };
        
        // Try to get group description
        var description = groupDescriptions[group] || "";
        
        // Add specific parameter type description
        for (var suffix in specificDescriptions) {
            if (paramName.includes(suffix)) {
                description += (description ? " - " : "") + specificDescriptions[suffix];
                break;
            }
        }
        
        // If no description found, create a generic one
        if (!description) {
            description = group + " system parameter";
        }
        
        return description;
    }

    function getRangeForParameter(paramName) {
        // Determine range based on parameter patterns
        var parts = paramName.split('_');
        var group = parts[0];
        var suffix = parts[parts.length - 1];
        
        // Common range patterns
        var rangePatterns = {
            // Boolean/enable parameters
            "_ENABLE": "0-1",
            "_REVERSED": "0-1", 
            "_USE": "0-1",
            
            // Gain parameters
            "_P": "0.001-10.0",
            "_I": "0-1.0",
            "_D": "0-0.1",
            "_FF": "0-1.0",
            "_IMAX": "0-1000",
            
            // Filter frequencies
            "_FILT": "0-100",
            "_FLTT": "0-100",
            "_FLTE": "0-100", 
            "_FLTD": "0-100",
            
            // Percentage/ratio parameters
            "_EXPO": "0-1",
            "_SCALE": "0.1-5.0",
            "_TC": "0-1",
            
            // Angle parameters
            "_TRIM": "-10-10",
            "_OFFSET": "-180-180",
            "_ROLL": "-180-180",
            "_PITCH": "-90-90",
            "_YAW": "-180-180",
            
            // Rate parameters (deg/s)
            "_RATE": "0-1080",
            "_SPEED": "0-2000",
            "_ACCEL": "0-18000",
            "_JERK": "0-60000",
            
            // PWM parameters
            "_PWM": "800-2200",
            "_MIN": "800-2200", 
            "_MAX": "800-2200",
            "_TRIM": "800-2200",
            
            // Type selection parameters
            "_TYPE": "0-10",
            "_ORIENT": "0-47",
            "_OPTIONS": "0-65535",
            
            // Coordinate parameters
            "_LAT": "-90-90",
            "_LNG": "-180-180",
            "_ALT": "-1000-10000",
            "_RADIUS": "0-32767"
        };
        
        // Group-specific ranges
        var groupRanges = {
            "RC": function(param) {
                if (param.includes("_MIN") || param.includes("_MAX") || param.includes("_TRIM")) return "800-2200";
                if (param.includes("_DZ")) return "0-200";
                if (param.includes("_REVERSED")) return "0-1";
                return "800-2200";
            },
            
            "SERVO": function(param) {
                if (param.includes("_MIN") || param.includes("_MAX") || param.includes("_TRIM")) return "800-2200";
                if (param.includes("_REVERSED")) return "0-1";
                if (param.includes("_FUNCTION")) return "0-109";
                return "800-2200";
            },
            
            "MOT": function(param) {
                if (param.includes("_PWM_")) return "800-2200";
                if (param.includes("_SPIN_")) return "0-1";
                if (param.includes("_YAW_")) return "0-1000";
                if (param.includes("_THST_")) return "0.2-0.8";
                return "0-1000";
            },
            
            "BATT": function(param) {
                if (param.includes("_VOLT_")) return "0-100";
                if (param.includes("_AMP_")) return "0-1000";
                if (param.includes("_CAPACITY")) return "0-100000";
                if (param.includes("_LOW_VOLT")) return "0-20";
                return "0-100";
            },
            
            "GPS": function(param) {
                if (param.includes("_TYPE")) return "0-14";
                if (param.includes("_RATE")) return "1-20";
                if (param.includes("_HDOP")) return "0-1000";
                return "0-1000";
            },
            
            "COMPASS": function(param) {
                if (param.includes("_USE")) return "0-1";
                if (param.includes("_AUTODEC")) return "0-1";
                if (param.includes("_OFS")) return "-1000-1000";
                if (param.includes("_DIA")) return "0.8-1.2";
                if (param.includes("_ODI")) return "-1.0-1.0";
                return "-1000-1000";
            },
            
            "RNGFND": function(param) {
                if (param.includes("_TYPE")) return "0-16";
                if (param.includes("_MIN_CM")) return "1-1000";
                if (param.includes("_MAX_CM")) return "10-30000";
                if (param.includes("_SCALING")) return "0.001-10";
                return "0-1000";
            },
            
            "FENCE": function(param) {
                if (param.includes("_ENABLE")) return "0-1";
                if (param.includes("_TYPE")) return "0-11";
                if (param.includes("_ALT_MAX")) return "10-1000";
                if (param.includes("_ALT_MIN")) return "-100-100";
                if (param.includes("_RADIUS")) return "30-10000";
                return "0-10000";
            }
        };
        
        // Check for suffix-based range first
        for (var pattern in rangePatterns) {
            if (paramName.includes(pattern)) {
                return rangePatterns[pattern];
            }
        }
        
        // Check for group-specific range
        if (groupRanges[group]) {
            return groupRanges[group](paramName);
        }
        
        // Default ranges based on common patterns
        if (paramName.includes("ANGLE") || paramName.includes("DEG")) return "0-360";
        if (paramName.includes("VOLT")) return "0-100";
        if (paramName.includes("AMP") || paramName.includes("CURR")) return "0-1000"; 
        if (paramName.includes("TEMP")) return "-50-150";
        if (paramName.includes("PRESS")) return "0-2000";
        if (paramName.includes("FLOW")) return "0-1000";
        if (paramName.includes("DIST") || paramName.includes("CM")) return "0-10000";
        if (paramName.includes("TIME") || paramName.includes("MS")) return "0-30000";
        if (paramName.includes("FREQ") || paramName.includes("HZ")) return "0-100";
        
        return ""; // No range if pattern not recognized
    }

    function getUnitsForParameter(paramName) {
        // Determine units based on parameter patterns
        var parts = paramName.split('_');
        var group = parts[0];
        
        // Unit patterns based on parameter suffix/content
        var unitPatterns = {
            // Angles and rotation
            "_DEG": "deg",
            "_ANGLE": "cdeg", 
            "_TRIM": "cdeg",
            "_YAW": "cdeg",
            "_ROLL": "cdeg", 
            "_PITCH": "cdeg",
            
            // Rates and speeds
            "_RATE": "deg/s",
            "_SPEED": "cm/s",
            "_VEL": "cm/s",
            "_ACCEL": "cm/s/s",
            "_JERK": "cm/s/s/s",
            
            // Time and frequency
            "_TIME": "s",
            "_MS": "ms",
            "_FREQ": "Hz",
            "_HZ": "Hz",
            "_FILT": "Hz",
            "_FLTT": "Hz",
            "_FLTE": "Hz",
            "_FLTD": "Hz",
            
            // Distance and position
            "_ALT": "m",
            "_RADIUS": "m", 
            "_DIST": "m",
            "_CM": "cm",
            "_MM": "mm",
            "_LAT": "deg",
            "_LNG": "deg",
            
            // Electrical
            "_VOLT": "V",
            "_AMP": "A",
            "_CURR": "A",
            "_CAPACITY": "mAh",
            "_WATT": "W",
            "_OHM": "ohm",
            
            // Physical quantities
            "_TEMP": "degC",
            "_PRESS": "Pa",
            "_FLOW": "l/min",
            "_MASS": "kg",
            "_FORCE": "N",
            
            // PWM and servo
            "_PWM": "PWM",
            "_MIN": "PWM",
            "_MAX": "PWM"
        };
        
        // Group-specific unit rules
        var groupUnits = {
            "RC": function(param) {
                if (param.includes("_MIN") || param.includes("_MAX") || param.includes("_TRIM")) return "PWM";
                if (param.includes("_DZ")) return "PWM";
                return "";
            },
            
            "SERVO": function(param) {
                if (param.includes("_MIN") || param.includes("_MAX") || param.includes("_TRIM")) return "PWM";
                return "";
            },
            
            "MOT": function(param) {
                if (param.includes("_PWM_")) return "PWM";
                if (param.includes("_THST_")) return "";
                if (param.includes("_SPIN_")) return "";
                if (param.includes("_YAW_")) return "";
                return "";
            },
            
            "BATT": function(param) {
                if (param.includes("_VOLT_")) return "V";
                if (param.includes("_AMP_")) return "A"; 
                if (param.includes("_CURR_")) return "A";
                if (param.includes("_CAPACITY")) return "mAh";
                if (param.includes("_LOW_VOLT")) return "V";
                if (param.includes("_FS_VOLT")) return "V";
                return "";
            },
            
            "COMPASS": function(param) {
                if (param.includes("_OFS")) return "mGauss";
                if (param.includes("_DIA")) return "";
                if (param.includes("_ODI")) return "";
                return "";
            },
            
            "RNGFND": function(param) {
                if (param.includes("_MIN_CM") || param.includes("_MAX_CM")) return "cm";
                if (param.includes("_OFFSET")) return "cm";
                return "";
            },
            
            "FENCE": function(param) {
                if (param.includes("_ALT_")) return "m";
                if (param.includes("_RADIUS")) return "m";
                if (param.includes("_MARGIN")) return "m";
                return "";
            },
            
            "WPNAV": function(param) {
                if (param.includes("_SPEED")) return "cm/s";
                if (param.includes("_RADIUS")) return "cm";
                if (param.includes("_ACCEL")) return "cm/s/s";
                if (param.includes("_JERK")) return "cm/s/s/s";
                return "";
            },
            
            "ARSPD": function(param) {
                if (param.includes("_SPEED")) return "m/s";
                if (param.includes("_RATIO")) return "";
                if (param.includes("_OFFSET")) return "Pa";
                return "";
            },
            
            "BARO": function(param) {
                if (param.includes("_ALT_")) return "m";
                if (param.includes("_PRESS_")) return "Pa";
                if (param.includes("_TEMP_")) return "degC";
                return "";
            }
        };
        
        // Check for pattern-based units first
        for (var pattern in unitPatterns) {
            if (paramName.includes(pattern)) {
                return unitPatterns[pattern];
            }
        }
        
        // Check for group-specific units
        if (groupUnits[group]) {
            return groupUnits[group](paramName);
        }
        
        // Common parameter name patterns
        if (paramName.includes("ANGLE") && !paramName.includes("MAX")) return "cdeg";
        if (paramName.includes("RATE") && !paramName.includes("BAUD")) return "deg/s";
        if (paramName.includes("SPEED")) return "cm/s";
        if (paramName.includes("ACCEL")) return "cm/s/s";
        if (paramName.includes("ALT")) return "m";
        if (paramName.includes("VOLT")) return "V";
        if (paramName.includes("CURR") || paramName.includes("AMP")) return "A";
        if (paramName.includes("TEMP")) return "degC";
        if (paramName.includes("PRESS")) return "Pa";
        if (paramName.includes("FREQ")) return "Hz";
        if (paramName.includes("TIME") && !paramName.includes("TIMEOUT")) return "s";
        
        return ""; // No units if pattern not recognized
    }

    function filterParameters() {
        var searchText = searchBar.text.toLowerCase();

        if (searchText.trim() === "") {
            updateModel(allParameters);
            return;
        }
        var parametersArray = Object.values(allParameters);
        
        var filtered = parametersArray.filter(function(p) {
            return p.name && p.name.toLowerCase().includes(searchText);
        });
        
        updateModel(filtered);
    }

    function updateParameterUI(paramName, newValue, modelIndex) {
        console.log("UI Demo: Updating parameter " + paramName + " to " + newValue);
        
        isUpdatingParameter = true;
        
        var currentItem = paramModel.get(modelIndex);
        paramModel.set(modelIndex, {
            "name": currentItem.name,
            "value": newValue,
            "type": currentItem.type,
            "description": currentItem.description,
            "synced": false,
            "default": currentItem.default,
            "units": currentItem.units,
            "range": currentItem.range
        });

        var updateTimer = Qt.createQmlObject('import QtQuick 2.15; Timer {}', parametersWindowRoot);
        updateTimer.interval = 1500;
        updateTimer.repeat = false;
        updateTimer.triggered.connect(function() {
            isUpdatingParameter = false;
            
            var currentItem = paramModel.get(modelIndex);
            paramModel.set(modelIndex, {
                "name": currentItem.name,
                "value": currentItem.value,
                "type": currentItem.type,
                "description": currentItem.description,
                "synced": true,
                "default": currentItem.default,
                "units": currentItem.units,
                "range": currentItem.range
            });
            
            statusNotification.color = "#10B981";
            statusNotification.children[0].text = "Parameter '" + paramName + "' updated successfully!";
            statusNotification.opacity = 1;
            hideNotificationTimer.restart();
            
            updateTimer.destroy();
        });
        updateTimer.start();
    }

    function sendAllParametersUI() {
        console.log("UI Demo: Sending all parameters to drone...");
        
        isUpdatingParameter = true;
        
        var sendTimer = Qt.createQmlObject('import QtQuick 2.15; Timer {}', parametersWindowRoot);
        sendTimer.interval = 2000;
        sendTimer.repeat = false;
        sendTimer.triggered.connect(function() {
            isUpdatingParameter = false;
            
            for (let i = 0; i < paramModel.count; i++) {
                let currentItem = paramModel.get(i);
                paramModel.set(i, {
                    "name": currentItem.name,
                    "value": currentItem.value,
                    "type": currentItem.type,
                    "description": currentItem.description,
                    "synced": true,
                    "default": currentItem.default,
                    "units": currentItem.units,
                    "range": currentItem.range
                });
            }
            
            statusNotification.color = "#10B981";
            statusNotification.children[0].text = "All parameters sent to drone successfully!";
            statusNotification.opacity = 1;
            hideNotificationTimer.restart();
            
            sendTimer.destroy();
        });
        sendTimer.start();
    }

    function saveParameters() {
        console.log("UI Demo: Saving parameters to file...");
        
        var paramData = "";
        var timestamp = new Date().toISOString().replace(/[:.]/g, '-').split('T')[0];
        
        paramData += "# Drone Parameters Configuration\n";
        paramData += "# Generated on: " + new Date().toLocaleString() + "\n";
        paramData += "# Total parameters: " + paramModel.count + "\n\n";
        
        for (let i = 0; i < paramModel.count; i++) {
            let p = paramModel.get(i);
            paramData += p.name + "," + p.value + "\n";
        }

        statusNotification.color = "#10B981";
        statusNotification.children[0].text = "Parameters saved to file (UI Demo)";
        statusNotification.opacity = 1;
        hideNotificationTimer.restart();
        
        console.log("Parameters data:\n" + paramData);
    }

    function exportParameters() {
        console.log("UI Demo: Exporting parameters...");
        
        var data = {};
        for (let i = 0; i < paramModel.count; i++) {
            let p = paramModel.get(i);
            data[p.name] = parseFloat(p.value);
        }
        
        statusNotification.color = "#10B981";
        statusNotification.children[0].text = "Parameters exported successfully (UI Demo)";
        statusNotification.opacity = 1;
        hideNotificationTimer.restart();
        
        console.log("Exported data:", JSON.stringify(data, null, 2));
    }

    onClosing: {
        console.log("Parameters window closing...");
    }

    Component.onCompleted: {
        visibility = Window.Maximized
        // var savedLang = loadLanguagePreference()
        // languageManager.changeLanguage(savedLang)
        console.log("Drone Parameters UI Demo - Ready");
        // droneCommander.requestAllParameters();
        
        // Load mock data for demonstration
        allParameters = {};
        for (var i = 0; i < mockParameters.length; i++) {
            allParameters[mockParameters[i].name] = mockParameters[i];
        }
        
        loadParameters();
    }

    onVisibilityChanged: {
        if (visibility === Window.Windowed || visibility === Window.AutomaticVisibility) {
            width = Screen.width
            height = Screen.height
            visibility = Window.Maximized
        }
    }

    onWindowStateChanged: {
        if (windowState === Qt.WindowNoState) {
            width = Screen.width
            height = Screen.height
            visibility = Window.Maximized
        }
    }
}
