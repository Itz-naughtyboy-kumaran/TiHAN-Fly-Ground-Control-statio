import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3

Row {
    id: droneControlRow
    spacing: 10
    property bool isArmed: droneModel.telemetry.armed
    
    // Add reference to language manager - UPDATE THIS PATH TO MATCH YOUR SETUP
    property var languageManager: root.languageManager // Make sure this path is correct in your app
    
    // Debug: Check if languageManager is accessible
    Component.onCompleted: {
        console.log("LanguageManager available:", languageManager !== null)
        console.log("Current language:", languageManager ? languageManager.currentLanguage : "N/A")
    }
    
    // Signal to notify when language changes so UI can update
    Connections {
        target: languageManager
        function onCurrentLanguageChanged() {
            // Force update of all text elements
            modeComboBox.modelChanged()
        }
    }
    
    MessageDialog { 
        id: modeChangeDialog
        title: languageManager ? languageManager.getText("Mode Changed") : "Mode Changed"
        standardButtons: StandardButton.Ok 
    }
    MessageDialog{ 
        id: armError
        title: languageManager ? languageManager.getText("ERROR") : "ERROR"
    }
    MessageDialog {
        id: armSuccess
        title: languageManager ? languageManager.getText("Message") : "Message"
    }
    
    // Status check timer
    Timer {
        id: statusCheckTimer
        interval: 2000 // Wait for 2 seconds
        // onTriggered: {
        //     isArmed = droneModel.telemetry.armed // Update armed status after delay
        // }
    }
    
    // ARM/DISARM Button
    Button {
        id: armDisarmButton
        width: 150; height: 40
        
        background: Rectangle { 
            color: parent.parent.isArmed ? "#4CAF50" : "#F44336"
            radius: 8 
        }
        
        Label { 
            anchors.centerIn: parent
            text: {
                if (parent.parent.isArmed) {
                    return languageManager ? languageManager.getText("ARMED") : "ARMED"
                } else {
                    return languageManager ? languageManager.getText("DISARMED") : "DISARMED"
                }
            }
            color: "white"
            font.bold: true 
        }
        
        onClicked: {
            if(droneControlRow.isArmed) {
                // Disarm the drone
                if(droneCommander.disarm()){
                    statusCheckTimer.start()
                    if(!droneModel.telemetry.armed){
                        armError.open()
                        armError.text = droneModel.statusTexts.length > 0 ? droneModel.statusTexts[droneModel.statusTexts.length - 1] : "Disarm failed"
                        droneControlRow.isArmed = droneModel.telemetry.armed
                    }
                } else {
                    armSuccess.open()
                    armSuccess.text = languageManager ? 
                        languageManager.getText("Drone Disarmed Successfully") : 
                        "Drone Disarmed Successfully"
                    droneControlRow.isArmed = droneModel.telemetry.armed
                }
            } else {
                // Arm the drone
                if(droneCommander.arm()){
                    statusCheckTimer.start()
                    if(droneModel.telemetry.armed){
                        armSuccess.open()
                        armSuccess.text = languageManager ? 
                            languageManager.getText("Drone Armed Successfully") : 
                            "Drone Armed Successfully"
                        droneControlRow.isArmed = droneModel.telemetry.armed
                    } else {
                        armError.open()
                        armError.text = droneModel.statusTexts.length > 0 ? droneModel.statusTexts[droneModel.statusTexts.length - 1] : "Arm failed"
                        droneControlRow.isArmed = droneModel.telemetry.armed
                    }
                }
            }
        }
    }

    // Flight Mode ComboBox
    ComboBox {
        id: modeComboBox
        width: 200
        height: 40
        
        // Original English mode keys for drone commander
        property var modeKeys: [
            "STABILIZE", "ACRO", "ALT_HOLD", "AUTO", "GUIDED", "LOITER", "RTL", "CIRCLE", 
            "POSITION", "LAND", "OF_LOITER", "DRIFT", "SPORT", "FLIP", "AUTOTUNE", 
            "POSHOLD", "BRAKE", "THROW", "AVOID_ADSB", "GUIDED_NOGPS", "SMART_RTL", 
            "FLOWHOLD", "FOLLOW", "ZIGZAG", "SYSTEMID", "AUTOROTATE", "AUTO_RTL"
        ]
        
        // Create display model with translations - with forced update
        model: {
            if (!languageManager) {
                return modeKeys
            }
            // Force dependency on current language to trigger updates
            var currentLang = languageManager.currentLanguage
            var translatedModes = []
            for (var i = 0; i < modeKeys.length; i++) {
                translatedModes.push(languageManager.getText(modeKeys[i]))
            }
            return translatedModes
        }
        
        displayText: {
            var modeLabel = languageManager ? languageManager.getText("Flightmode") : "Mode"
            return modeLabel + ": " + currentText
        }
        
        enabled: root.isConnected  // Assuming same enable condition as calibration selector

        // Background styling
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

        // Content text styling
        contentItem: Text {
            text: modeComboBox.displayText
            font.pixelSize: root.standardFontSize || 12
            font.family: root.standardFontFamily || "Arial"
            font.weight: root.standardFontWeight || Font.Normal
            color: enabled ? "#2c5282" : "#6c757d"
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.leftMargin: 10
            anchors.rightMargin: 30 // Leave space for dropdown arrow
            anchors.topMargin: 5
            anchors.bottomMargin: 5
            elide: Text.ElideRight
        }

        // Dropdown arrow
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

        // Popup styling
        popup: Popup {
            y: modeComboBox.height + 2
            width: modeComboBox.width
            height: Math.min(contentItem.implicitHeight, 300) // Limit max height
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

        // Delegate styling
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
                font.pixelSize: root.standardFontSize || 12
                font.family: root.standardFontFamily || "Arial"
                font.weight: root.standardFontWeight || Font.Normal
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignHCenter
                renderType: Text.NativeRendering
            }
        }

        onActivated: {
            var selectedModeKey = modeKeys[currentIndex] // Get the original mode key
            var translatedModeName = languageManager ? 
                languageManager.getText(selectedModeKey) : selectedModeKey
            
            var changeText = languageManager ? languageManager.getText("Mode changed to") : "Mode changed to"
            modeChangeDialog.text = changeText + ": " + translatedModeName
            modeChangeDialog.open()
            
            // Send the original English mode key to the drone commander
            droneCommander.setMode(selectedModeKey)
        }

        // Tooltip
        ToolTip.visible: hovered
        ToolTip.text: {
            if (root.isConnected) {
                return languageManager ? languageManager.getText("Select flight mode") : "Select flight mode"
            } else {
                return languageManager ? languageManager.getText("Connect to drone first") : "Connect to drone first"
            }
        }
        ToolTip.delay: 1000
        
        // Update display text when language changes
        Connections {
            target: languageManager
            function onCurrentLanguageChanged() {
                modeComboBox.displayTextChanged()
            }
        }
    }
}