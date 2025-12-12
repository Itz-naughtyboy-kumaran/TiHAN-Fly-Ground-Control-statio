import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3

Row {
    id: statusBarRoot
    spacing: 10
    property bool isArmed: droneModel.telemetry.armed
    
    // Add properties that were referenced as root.xxx
    property bool isConnected: droneModel.isConnected
    property int standardFontSize: 14
    property string standardFontFamily: "Arial"
    property int standardFontWeight: Font.Normal
    
    MessageDialog { id: modeChangeDialog; title: "Mode Changed"; standardButtons: StandardButton.Ok }
    MessageDialog{ id: armError; title: "ERROR"}
    MessageDialog {id: armSuccess; title: "Message" }
    
    // Track if we're currently changing mode to prevent loops
    property bool isChangingMode: false
    
    //status time
    Timer {
        id: statusCheckTimer
        interval: 2000 // Wait for 2 seconds
    }
    
    Button {
        width: 150; height: 40
        background: Rectangle { color: parent.parent.isArmed ? "#4CAF50" : "#F44336"; radius: 8 }
        Label { anchors.centerIn: parent; text: parent.parent.isArmed ? "ARMED" : "DISARMED"; color: "white"; font.bold: true }
        onClicked: {
            if(parent.isArmed){
                if(droneCommander.disarm()){
                    statusCheckTimer.start()
                    if(!droneModel.telemetry.armed){
                        armError.open()
                        armError.text = droneModel.statusTexts[-1]
                        parent.isArmed = droneModel.telemetry.armed
                    }
                }else{
                    armSuccess.open()
                    armSuccess.text = "Drone Disarmed Successfully"
                    parent.isArmed = droneModel.telemetry.armed
                }

            } else {
                if(droneCommander.arm()){
                    statusCheckTimer.start()
                    if(droneModel.telemetry.armed){
                        armError.open()
                        armError.text = "Drone Armed Successfully"
                        parent.isArmed = droneModel.telemetry.armed
                    }else{
                        armSuccess.open()
                        armSuccess.text = droneModel.statusTexts[-1]
                        parent.isArmed = droneModel.telemetry.armed
                    }
                }
            }
        }
    }

    ComboBox {
        id: modeComboBox
        width: 200
        height: 40
        model: [
            "STABILIZE", "ACRO", "ALT_HOLD", "AUTO", "GUIDED", "LOITER", "RTL", "CIRCLE", "POSITION", "LAND",
            "OF_LOITER", "DRIFT", "SPORT", "FLIP", "AUTOTUNE", "POSHOLD", "BRAKE", "THROW", "AVOID_ADSB",
            "GUIDED_NOGPS", "SMART_RTL", "FLOWHOLD", "FOLLOW", "ZIGZAG", "SYSTEMID", "AUTOROTATE", "AUTO_RTL"
        ]
        displayText: "Mode: " + currentText
        enabled: statusBarRoot.isConnected
        
        // Track last user selection to prevent loops
        property string lastUserSelectedMode: ""
        property bool updatingFromDrone: false

        // Update the ComboBox when drone mode changes (but don't trigger command)
        Connections {
            target: droneModel
            function onTelemetryChanged() {
                var droneMode = droneModel.telemetry.mode
                var index = modeComboBox.model.indexOf(droneMode)
                
                if (index !== -1 && index !== modeComboBox.currentIndex) {
                    console.log("QML: Drone mode changed to:", droneMode, "- Updating ComboBox")
                    modeComboBox.updatingFromDrone = true
                    modeComboBox.currentIndex = index
                    modeComboBox.updatingFromDrone = false
                }
            }
        }
        
        // Initialize ComboBox with current drone mode on connection
        Component.onCompleted: {
            if (statusBarRoot.isConnected) {
                var droneMode = droneModel.telemetry.mode
                var index = modeComboBox.model.indexOf(droneMode)
                if (index !== -1) {
                    modeComboBox.currentIndex = index
                }
            }
        }

        background: Rectangle {
            radius: 10
            border.width: 2
            border.color: enabled ? (modeComboBox.pressed ? "#4a90e2" : "#87ceeb") : "#adb5bd"
            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: enabled ? (modeComboBox.pressed ? "#4a90e2" : (modeComboBox.hovered ? "#7bb3e0" : "#87ceeb")) : "#adb5bd"
                }
                GradientStop {
                    position: 1.0
                    color: enabled ? (modeComboBox.pressed ? "#357abd" : (modeComboBox.hovered ? "#4a90e2" : "#7bb3e0")) : "#868e96"
                }
            }

            Behavior on border.color {
                ColorAnimation { duration: 200 }
            }
        }

        contentItem: Text {
            text: modeComboBox.displayText
            font.pixelSize: statusBarRoot.standardFontSize
            font.family: statusBarRoot.standardFontFamily
            font.weight: statusBarRoot.standardFontWeight
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

        indicator: Canvas {
            x: modeComboBox.width - 18
            y: (modeComboBox.height - height) / 2
            width: 12
            height: 8
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.moveTo(0, 0);
                ctx.lineTo(width, 0);
                ctx.lineTo(width / 2, height);
                ctx.closePath();
                ctx.fillStyle = enabled ? "#2c5282" : "#6c757d";
                ctx.fill();
            }
        }

        popup: Popup {
            y: modeComboBox.height + 2
            width: modeComboBox.width
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
                clip: true
                implicitHeight: contentHeight
                model: modeComboBox.delegateModel
                currentIndex: modeComboBox.highlightedIndex
                spacing: 1
                ScrollIndicator.vertical: ScrollIndicator { }
            }
        }

        delegate: ItemDelegate {
            width: modeComboBox.width
            height: 35

            background: Rectangle {
                color: parent.hovered ? "#4CAF50" : "#ffffff"
                radius: 4
            }

            contentItem: Text {
                text: modelData
                color: parent.hovered ? "#ffffff" : "#000000"
                font.pixelSize: statusBarRoot.standardFontSize
                font.family: statusBarRoot.standardFontFamily
                font.weight: statusBarRoot.standardFontWeight
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
            }
        }

        onActivated: {
            // CRITICAL: Only send command when user manually selects AND it's different from current
            if (modeComboBox.updatingFromDrone) {
                console.log("QML: Ignoring mode change - updating from drone telemetry")
                return
            }
            
            var selectedMode = model[currentIndex]
            var currentDroneMode = droneModel.telemetry.mode
            
            // Don't send if already in this mode
            if (selectedMode === currentDroneMode) {
                console.log("QML: Already in mode", selectedMode, "- not sending command")
                return
            }
            
            // Don't send if this was the last mode we tried to set
            if (selectedMode === modeComboBox.lastUserSelectedMode) {
                console.log("QML: This mode was already requested recently - not sending again")
                return
            }
            
            console.log("QML: User manually selected mode:", selectedMode)
            modeComboBox.lastUserSelectedMode = selectedMode
            
            // Send the mode change command
            if (droneCommander.setMode(selectedMode)) {
                modeChangeDialog.text = "Mode change command sent: " + selectedMode + "\n\nNote: If mode reverts, your RC transmitter may be overriding it."
                modeChangeDialog.open()
            } else {
                modeChangeDialog.text = "Failed to send mode change to: " + selectedMode
                modeChangeDialog.open()
            }
        }
        
        // Clear the last user selection after 5 seconds to allow retry
        Timer {
            id: modeRetryTimer
            interval: 5000
            onTriggered: {
                console.log("QML: Clearing last mode selection - user can retry")
                modeComboBox.lastUserSelectedMode = ""
            }
        }

        ToolTip.visible: hovered
        ToolTip.text: statusBarRoot.isConnected ? "Select flight mode" : "Connect to drone first"
        ToolTip.delay: 1000
    }

}
