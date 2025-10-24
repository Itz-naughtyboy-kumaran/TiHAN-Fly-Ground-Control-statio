// Enhanced AccelCalibration.qml - Light Theme Version
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

ApplicationWindow {
    id: accelWindow
    width: 1400
    height: 900
    title: "Enhanced Drone Calibration with GPS/Altitude Support"
    modality: Qt.NonModal
    color: "#FFFFFF"

    // Properties bound to calibrationModel
    property bool levelCalibrationActive: calibrationModel ? calibrationModel.levelCalibrationActive : false
    property bool levelCalibrationComplete: calibrationModel ? calibrationModel.levelCalibrationComplete : false
    property int currentStep: calibrationModel ? calibrationModel.currentStep : 0
    property bool accelCalibrationActive: calibrationModel ? calibrationModel.accelCalibrationActive : false
    property var completedSteps: calibrationModel ? calibrationModel.completedSteps : [false, false, false, false, false, false]
    property bool accelCalibrationComplete: calibrationModel ? calibrationModel.accelCalibrationComplete : false
    property bool allPositionsCompleted: calibrationModel ? calibrationModel.allPositionsCompleted : false
    property bool allCalibrationsComplete: calibrationModel ? calibrationModel.allCalibrationsComplete : false
    property bool isDroneConnected: calibrationModel ? calibrationModel.isDroneConnected : false
    property string feedbackMessage: calibrationModel ? calibrationModel.feedbackMessage : ""

    // Position checking properties
    property real currentRoll: calibrationModel ? calibrationModel.currentRoll : 0.0
    property real currentPitch: calibrationModel ? calibrationModel.currentPitch : 0.0
    property real currentYaw: calibrationModel ? calibrationModel.currentYaw : 0.0
    property bool isPositionCorrect: calibrationModel ? calibrationModel.isPositionCorrect : false
    property string positionCheckMessage: calibrationModel ? calibrationModel.positionCheckMessage : ""
    property bool positionCheckActive: calibrationModel ? calibrationModel.positionCheckActive : false

    // GPS and Altitude properties
    property real currentAltitude: calibrationModel ? calibrationModel.currentAltitude : 0.0
    property real correctAltitude: calibrationModel ? calibrationModel.correctAltitude : 0.0
    property real gpsLatitude: calibrationModel ? calibrationModel.gpsLatitude : 0.0
    property real gpsLongitude: calibrationModel ? calibrationModel.gpsLongitude : 0.0
    property int gpsFixType: calibrationModel ? calibrationModel.gpsFixType : 0
    property int satellitesVisible: calibrationModel ? calibrationModel.satellitesVisible : 0
    property real hdop: calibrationModel ? calibrationModel.hdop : 99.99
    property real vdop: calibrationModel ? calibrationModel.vdop : 99.99

    // Additional calibration properties
    property bool compassCalibrationActive: calibrationModel ? calibrationModel.compassCalibrationActive : false
    property bool compassCalibrationComplete: calibrationModel ? calibrationModel.compassCalibrationComplete : false
    property bool radioCalibrationActive: calibrationModel ? calibrationModel.radioCalibrationActive : false
    property bool radioCalibrationComplete: calibrationModel ? calibrationModel.radioCalibrationComplete : false
    property bool escCalibrationActive: calibrationModel ? calibrationModel.escCalibrationActive : false
    property bool escCalibrationComplete: calibrationModel ? calibrationModel.escCalibrationComplete : false
    property bool servoCalibrationActive: calibrationModel ? calibrationModel.servoCalibrationActive : false
    property bool servoCalibrationComplete: calibrationModel ? calibrationModel.servoCalibrationComplete : false

    // CORRECTED orientation sequence with GPS-based nose directions
    property var orientations: [
        { name: "Level", description: "Place drone level (flat on surface)", image: "qrc:/icons/orientation_level.png" },
        { name: "Left", description: "Place drone on left side", image: "qrc:/icons/orientation_left.png" },
        { name: "Right", description: "Place drone on right side", image: "qrc:/icons/orientation_right.png" },
        { name: "Nose Down", description: "Place drone nose down (towards GPS direction)", image: "qrc:/icons/orientation_nose_down.png" },
        { name: "Nose Up", description: "Place drone nose up (away from GPS direction)", image: "qrc:/icons/orientation_nose_up.png" },
        { name: "Back", description: "Place drone upside down (back)", image: "qrc:/icons/orientation_back.png" }
    ]

    // Calibration window properties
    property var compassWindow: null
    property var radioWindow: null
    property var escWindow: null
    property var servoWindow: null
    
    // Connections to calibrationModel signals
    Connections {
        target: calibrationModel
        function onCalibrationStatusChanged() {
            console.log("Calibration status changed")
        }
        
        function onFeedbackMessageChanged() {
            if (calibrationModel.feedbackMessage !== "") {
                showFeedback(calibrationModel.feedbackMessage)
            }
        }
        
        function onPositionCheckChanged() {
            console.log("Position check changed:", positionCheckMessage)
        }

        function onAltitudeDataChanged() {
            console.log("Altitude data updated:", currentAltitude)
        }

        function onGpsDataChanged() {
            console.log("GPS data updated:", gpsLatitude, gpsLongitude)
        }
    }

    // Connection Status Bar - Light Theme
    Rectangle {
        id: connectionStatusBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: rightPanel.left
        height: 40
        color: isDroneConnected ? "#D4F6D4" : "#FFE6E6"
        border.color: "#DDDDDD"
        z: 100

        Row {
            anchors.centerIn: parent
            spacing: 10

            Text {
                text: isDroneConnected ? "✅ Drone Connected" : "❌ Drone Disconnected"
                color: isDroneConnected ? "#0F5132" : "#842029"
                font.bold: true
                font.pixelSize: 14
            }
        }
    }

    // Position Status Bar - Light Theme
    Rectangle {
        id: positionStatusBar
        anchors.top: connectionStatusBar.bottom
        anchors.left: parent.left
        anchors.right: rightPanel.left
        height: 50
        color: "#F8F9FA"
        border.color: "#E9ECEF"
        border.width: 1
        visible: positionCheckActive
        z: 99

        RowLayout {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 15

            // Current Attitude Display
            Rectangle {
                Layout.preferredWidth: 200
                Layout.fillHeight: true
                color: "#FFFFFF"
                radius: 8
                border.width: 1
                border.color: "#DEE2E6"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 5
                    spacing: 2

                    Label {
                        text: "Current Attitude"
                        font.pixelSize: 10
                        font.bold: true
                        color: "#212529"
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Row {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 8
                        Label {
                            text: "R:" + currentRoll.toFixed(1) + "°"
                            font.pixelSize: 9
                            color: "#6C757D"
                        }
                        Label {
                            text: "P:" + currentPitch.toFixed(1) + "°"
                            font.pixelSize: 9
                            color: "#6C757D"
                        }
                        Label {
                            text: "Y:" + currentYaw.toFixed(1) + "°"
                            font.pixelSize: 9
                            color: "#6C757D"
                        }
                    }
                }
            }

            // Position Status
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: isPositionCorrect ? "#D1E7DD" : "#F8D7DA"
                radius: 8
                border.width: 1
                border.color: isPositionCorrect ? "#A3CFBB" : "#F1AEB5"

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10

                    Label {
                        text: isPositionCorrect ? "✅" : "⚠️"
                        font.pixelSize: 16
                    }

                    Label {
                        text: positionCheckMessage
                        font.pixelSize: 12
                        font.bold: true
                        color: isPositionCorrect ? "#0F5132" : "#842029"
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // Live Drone Orientation Indicator
            Rectangle {
                Layout.preferredWidth: 80
                Layout.fillHeight: true
                color: "#FFFFFF"
                radius: 8
                border.width: 2
                border.color: isPositionCorrect ? "#198754" : "#DC3545"

                Label {
                    anchors.centerIn: parent
                    text: "✈️"
                    font.pixelSize: 24
                    rotation: currentRoll
                    transform: [
                        Rotation {
                            origin.x: parent.width / 2
                            origin.y: parent.height / 2
                            axis { x: 1; y: 0; z: 0 }
                            angle: currentPitch
                        }
                    ]

                    Behavior on rotation { NumberAnimation { duration: 100 } }
                }
            }
        }
    }

    // RIGHT PANEL - Light Theme
    Rectangle {
        id: rightPanel
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: 350
        color: "#F8F9FA"
        border.width: 2
        border.color: "#E9ECEF"
        z: 95

        ScrollView {
            anchors.fill: parent
            anchors.margins: 15
            contentWidth: rightPanel.width - 30

            ColumnLayout {
                width: rightPanel.width - 30
                spacing: 20

                // GPS Status Panel - Light Theme
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 200
                    color: "#FFFFFF"
                    radius: 10
                    border.width: 2
                    border.color: gpsFixType >= 3 ? "#198754" : "#DC3545"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10

                        Label {
                            text: "🛰️ GPS Status"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#007BFF"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 5

                            Label { text: "Fix Type:"; color: "#6C757D"; font.pixelSize: 12 }
                            Label { 
                                text: {
                                    switch(gpsFixType) {
                                        case 0: return "No Fix"
                                        case 1: return "No Fix"
                                        case 2: return "2D Fix"
                                        case 3: return "3D Fix"
                                        case 4: return "DGPS"
                                        case 5: return "RTK Float"
                                        case 6: return "RTK Fixed"
                                        default: return "Unknown"
                                    }
                                }
                                color: gpsFixType >= 3 ? "#198754" : "#DC3545"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Label { text: "Satellites:"; color: "#6C757D"; font.pixelSize: 12 }
                            Label { 
                                text: satellitesVisible.toString()
                                color: satellitesVisible >= 6 ? "#198754" : "#FFC107"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Label { text: "HDOP:"; color: "#6C757D"; font.pixelSize: 12 }
                            Label { 
                                text: hdop.toFixed(2)
                                color: hdop < 2.0 ? "#198754" : hdop < 5.0 ? "#FFC107" : "#DC3545"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Label { text: "Latitude:"; color: "#6C757D"; font.pixelSize: 12 }
                            Label { 
                                text: gpsLatitude.toFixed(6)
                                color: "#212529"
                                font.pixelSize: 12
                                font.family: "monospace"
                            }

                            Label { text: "Longitude:"; color: "#6C757D"; font.pixelSize: 12 }
                            Label { 
                                text: gpsLongitude.toFixed(6)
                                color: "#212529"
                                font.pixelSize: 12
                                font.family: "monospace"
                            }
                        }
                    }
                }

                // Altitude Panel - Light Theme
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    color: "#FFFFFF"
                    radius: 10
                    border.width: 2
                    border.color: "#DEE2E6"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 10

                        Label {
                            text: "📏 Altitude Status"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#007BFF"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: 10
                            rowSpacing: 8

                            Label { text: "Current:"; color: "#6C757D"; font.pixelSize: 12 }
                            Label { 
                                text: currentAltitude.toFixed(2) + " m"
                                color: "#212529"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "monospace"
                            }

                            Label { text: "Reference:"; color: "#6C757D"; font.pixelSize: 12 }
                            Label { 
                                text: correctAltitude.toFixed(2) + " m"
                                color: "#198754"
                                font.pixelSize: 14
                                font.bold: true
                                font.family: "monospace"
                            }

                            Label { text: "Difference:"; color: "#6C757D"; font.pixelSize: 12 }
                            Label { 
                                text: Math.abs(currentAltitude - correctAltitude).toFixed(2) + " m"
                                color: Math.abs(currentAltitude - correctAltitude) < 1.0 ? "#198754" : "#FFC107"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }

                        Button {
                            text: "Set Reference Altitude"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 35
                            enabled: isDroneConnected

                            background: Rectangle {
                                color: parent.pressed ? "#0056B3" : (parent.enabled ? "#007BFF" : "#ADB5BD")
                                radius: 6
                            }

                            contentItem: Label {
                                text: parent.text
                                color: "white"
                                font.bold: true
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (calibrationModel) {
                                    calibrationModel.setCorrectAltitude()
                                }
                            }
                        }
                    }
                }

                // Drone Level Panel - Light Theme
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    color: "#FFFFFF"
                    radius: 10
                    border.width: 2
                    border.color: {
                        if (levelCalibrationComplete) return "#198754"
                        else if (levelCalibrationActive) return "#FFC107"
                        else return "#DEE2E6"
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 12

                        Label {
                            text: "📏 Level Status"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#007BFF"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        // Live attitude display
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 80
                            color: "#F8F9FA"
                            radius: 8
                            border.width: 2
                            border.color: isPositionCorrect && levelCalibrationActive ? "#198754" : "#DEE2E6"

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 15

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 5

                                    Label {
                                        text: "Roll: " + currentRoll.toFixed(1) + "°"
                                        color: Math.abs(currentRoll) < 5 ? "#198754" : "#DC3545"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                    Label {
                                        text: "Pitch: " + currentPitch.toFixed(1) + "°"
                                        color: Math.abs(currentPitch) < 5 ? "#198754" : "#DC3545"
                                        font.pixelSize: 12
                                        font.bold: true
                                    }
                                    Label {
                                        text: "Yaw: " + currentYaw.toFixed(1) + "°"
                                        color: "#6C757D"
                                        font.pixelSize: 12
                                    }
                                }

                                Rectangle {
                                    Layout.preferredWidth: 50
                                    Layout.preferredHeight: 50
                                    color: "#FFFFFF"
                                    radius: 25
                                    border.width: 2
                                    border.color: (Math.abs(currentRoll) < 5 && Math.abs(currentPitch) < 5) ? "#198754" : "#DC3545"

                                    Label {
                                        anchors.centerIn: parent
                                        text: "✈️"
                                        font.pixelSize: 20
                                        rotation: currentRoll
                                        Behavior on rotation { NumberAnimation { duration: 100 } }
                                    }
                                }
                            }
                        }

                        Label {
                            text: {
                                if (levelCalibrationComplete) return "✅ Level Complete"
                                else if (levelCalibrationActive) return "🔄 Calibrating..."
                                else return "⏳ Level Pending"
                            }
                            font.pixelSize: 12
                            font.bold: true
                            color: {
                                if (levelCalibrationComplete) return "#198754"
                                else if (levelCalibrationActive) return "#FFC107"
                                else return "#DC3545"
                            }
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Button {
                            text: levelCalibrationActive ? "Cancel Level" : "Start Level Calibration"
                            Layout.fillWidth: true
                            Layout.preferredHeight: 35
                            enabled: !accelCalibrationActive && !levelCalibrationComplete && isDroneConnected

                            background: Rectangle {
                                color: {
                                    if (!parent.enabled) return "#ADB5BD"
                                    if (levelCalibrationActive) {
                                        return parent.pressed ? "#BB2D3B" : "#DC3545"
                                    } else {
                                        return parent.pressed ? "#0056B3" : "#007BFF"
                                    }
                                }
                                radius: 6
                            }

                            contentItem: Label {
                                text: parent.text
                                color: "white"
                                font.bold: true
                                font.pixelSize: 11
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (levelCalibrationActive) {
                                    if (calibrationModel) calibrationModel.stopLevelCalibration()
                                } else {
                                    if (calibrationModel) {
                                        let canStart = calibrationModel.canStartLevelCalibration()
                                        if (canStart) {
                                            calibrationModel.startLevelCalibration()
                                        } else {
                                            showFeedback("⚠️ Drone must be level to start calibration!")
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                            }                }
            }
    // Reusable Dialog Component - Light Theme
    component CustomDialog: Dialog {
        property alias dialogTitle: titleLabel.text
        property alias dialogText: contentLabel.text
        property alias buttonText: okButton.text
        property alias buttonColor: buttonRect.color
        property bool showCancelButton: false
        property bool showRebootButton: false
        signal accepted()
        signal rebootRequested()

        modal: true
        anchors.centerIn: parent
        width: 450
        height: showRebootButton ? 250 : 200

        background: Rectangle {
            color: "#FFFFFF"
            radius: 10
            border.width: 2
            border.color: showRebootButton ? "#FFC107" : "#DC3545"
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20

            Label {
                id: titleLabel
                font.pixelSize: 20
                font.bold: true
                color: showRebootButton ? "#FFC107" : "#DC3545"
                Layout.alignment: Qt.AlignHCenter
            }

            Label {
                id: contentLabel
                font.pixelSize: 14
                color: "#6C757D"
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignHCenter
            }

            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 15

                Button {
                    text: "Cancel"
                    Layout.preferredWidth: 100
                    Layout.preferredHeight: 40
                    visible: showCancelButton || showRebootButton

                    background: Rectangle {
                        color: parent.pressed ? "#E0E0E0" : "#F5F5F5"
                        radius: 8
                        border.width: 1
                        border.color: "#CED4DA"
                    }

                    contentItem: Label {
                        text: parent.text
                        color: "#000000"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: close()
                }

                Button {
                    id: okButton
                    text: "OK"
                    Layout.preferredWidth: showRebootButton ? 130 : 120
                    Layout.preferredHeight: 40

                    background: Rectangle {
                        id: buttonRect
                        color: parent.pressed ? (showRebootButton ? "#FFCA2C" : "#157347") : (showRebootButton ? "#FFC107" : "#198754")
                        radius: 8
                    }

                    contentItem: Label {
                        text: parent.text
                        color: "white"
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: showRebootButton ? rebootRequested() : accepted()
                }
            }
        }
    }

    // Dialog instances
    CustomDialog {
        id: warningDialog
        onAccepted: close()
    }

    CustomDialog {
        id: positionWarningDialog
        dialogTitle: "⚠️ Position Check Required"
        showCancelButton: true
        onAccepted: close()
    }

    CustomDialog {
        id: rebootDialog
        dialogTitle: "🔄 Reboot Required"
        dialogText: "All calibrations completed successfully! The drone needs to be rebooted to apply calibration settings.\n\nAfter reboot, the drone will automatically reconnect.\n\nAre you sure you want to reboot now?"
        buttonText: "Reboot Drone"
        showRebootButton: true
        onRebootRequested: {
            if (calibrationModel) {
                calibrationModel.rebootDrone()
                startReconnectionProcess()
            }
            close()
        }
    }

    CustomDialog {
        id: levelSuccessDialog
        dialogTitle: "🎉 Level Calibration Completed!"
        dialogText: "The drone's level orientation has been successfully calibrated with position verification. Trim values have been calculated and stored in the flight controller.\n\n" + 
                   (allCalibrationsComplete ? "All calibrations are now complete! You can reboot the drone to apply all settings." : "You can now proceed with accelerometer calibration if needed.")
        onAccepted: close()
    }

    CustomDialog {
        id: accelSuccessDialog
        dialogTitle: "🎉 Accelerometer Calibration Completed!"
        dialogText: "All six orientations have been successfully captured and verified with GPS-corrected nose directions. Sensor offsets and scale factors have been calculated and applied to the flight controller.\n\n" +
                   (allCalibrationsComplete ? "🎯 All calibrations are now complete! Your drone needs to be rebooted to apply all calibration settings." : "Your drone is now ready for accurate flight operations!")
        showCancelButton: allCalibrationsComplete
        buttonText: allCalibrationsComplete ? "Reboot Now" : "OK"
        onAccepted: allCalibrationsComplete ? rebootDialog.open() : close()
    }

    // Feedback message display - Light Theme
    Rectangle {
        id: feedbackBar
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: rightPanel.left
        height: 60
        color: "#F8F9FA"
        border.width: 1
        border.color: "#DEE2E6"
        visible: feedbackText.text !== ""
        z: 99

        Label {
            id: feedbackText
            anchors.centerIn: parent
            color: "#212529"
            font.pixelSize: 14
            wrapMode: Text.WordWrap
            width: parent.width - 40
            horizontalAlignment: Text.AlignHCenter
        }

        Timer {
            id: feedbackTimer
            interval: 5000
            onTriggered: feedbackText.text = ""
        }
    }

    // Calibration Complete Banner - Light Theme
    Rectangle {
        id: completeBanner
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: rightPanel.left
        anchors.topMargin: positionCheckActive ? 90 : 40
        height: 80
        color: "#D1E7DD"
        border.width: 1
        border.color: "#A3CFBB"
        visible: allCalibrationsComplete
        z: 98

        RowLayout {
            anchors.centerIn: parent
            spacing: 20

            Label {
                text: "🎉"
                font.pixelSize: 30
            }

            ColumnLayout {
                spacing: 5
                Label {
                    text: "All Calibrations Complete!"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#0F5132"
                }
                Label {
                    text: "Reboot the drone to apply all settings"
                    font.pixelSize: 12
                    color: "#0F5132"
                }
            }

            Button {
                text: "Reboot Drone"
                Layout.preferredWidth: 120
                Layout.preferredHeight: 35

                background: Rectangle {
                    color: parent.pressed ? "#FFCA2C" : "#FFC107"
                    radius: 8
                }

                contentItem: Label {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                onClicked: rebootDialog.open()
            }
        }
    }

    // Main Content Area - Light Theme
    Rectangle {
        anchors.fill: parent
        anchors.rightMargin: rightPanel.width
        color: "#FFFFFF"

        ScrollView {
            anchors.fill: parent
            anchors.margins: 20
            anchors.topMargin: {
                let topMargin = 60
                if (positionCheckActive) topMargin += 50
                if (allCalibrationsComplete) topMargin += 80
                return topMargin
            }
            anchors.bottomMargin: feedbackBar.visible ? feedbackBar.height + 20 : 20

            ColumnLayout {
                width: accelWindow.width - rightPanel.width - 40
                spacing: 40

                Label {
                    text: "Enhanced Drone Calibration Center"
                    font.pixelSize: 36
                    font.bold: true
                    color: "#212529"
                    Layout.alignment: Qt.AlignHCenter
                }

                // ACCELEROMETER CALIBRATION SECTION
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 30

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        Label {
                            text: "📱 Accelerometer Calibration with GPS-Corrected Orientation"
                            font.pixelSize: 28
                            font.bold: true
                            color: "#212529"
                            Layout.alignment: Qt.AlignHCenter
                        }

                        Label {
                            text: accelCalibrationActive ? "Step " + (currentStep + 1) + " of 6: " + orientations[currentStep].description :
                                  "Six-position accelerometer calibration with GPS-based nose direction correction.\nSequence: Level → Left → Right → Nose Down (GPS) → Nose Up (GPS) → Back"
                            font.pixelSize: 16
                            color: "#6C757D"
                            Layout.alignment: Qt.AlignHCenter
                            wrapMode: Text.WordWrap
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 100
                            Layout.maximumWidth: 800
                            Layout.alignment: Qt.AlignHCenter
                            color: "#F8F9FA"
                            radius: 8
                            border.width: 1
                            border.color: "#DEE2E6"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 15
                                spacing: 8

                                Label {
                                    text: "GPS-Enhanced Accelerometer Calibration Process:"
                                    font.pixelSize: 14
                                    font.bold: true
                                    color: "#212529"
                                }

                                Label {
                                    text: "• Real-time position verification with GPS heading correction • Nose Down/Up positions adjusted based on GPS direction • System verifies correct positioning before proceeding • Captures acceleration data only when position is confirmed • Calculates sensor offsets and scale factors • Applies corrections for accurate flight data"
                                    font.pixelSize: 12
                                    color: "#6C757D"
                                    wrapMode: Text.WordWrap
                                    Layout.fillWidth: true
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 12
                            Layout.maximumWidth: 600
                            Layout.alignment: Qt.AlignHCenter
                            color: "#E9ECEF"
                            radius: 6

                            Rectangle {
                                width: parent.width * (completedSteps.filter(Boolean).length / 6)
                                height: parent.height
                                color: "#198754"
                                radius: 6
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }

                            Label {
                                anchors.centerIn: parent
                                text: completedSteps.filter(Boolean).length + "/6 positions complete"
                                font.pixelSize: 10
                                font.bold: true
                                color: "#212529"
                            }
                        }
                    }

                    // Current Step Display with GPS-Corrected Position Verification - Light Theme
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 320
                        Layout.maximumWidth: 800
                        Layout.alignment: Qt.AlignHCenter
                        color: "#FFFFFF"
                        radius: 12
                        visible: accelCalibrationActive
                        border.width: 2
                        border.color: positionCheckActive && isPositionCorrect ? "#198754" : "#FFC107"

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 25
                            spacing: 15

                            Label {
                                text: "Current Position: " + (accelCalibrationActive ? orientations[currentStep].name : "")
                                font.pixelSize: 22
                                font.bold: true
                                color: "#212529"
                                Layout.alignment: Qt.AlignHCenter
                            }

                            // GPS Direction Info for Nose positions
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                color: "#E3F2FD"
                                radius: 6
                                visible: accelCalibrationActive && (currentStep === 3 || currentStep === 4) // Nose Down or Nose Up
                                border.width: 1
                                border.color: "#007BFF"

                                Label {
                                    anchors.centerIn: parent
                                    text: "GPS Heading: " + currentYaw.toFixed(1) + "° | " + 
                                         (gpsFixType >= 3 ? "GPS Lock ✅" : "No GPS Lock ❌")
                                    font.pixelSize: 12
                                    color: gpsFixType >= 3 ? "#198754" : "#DC3545"
                                    font.bold: true
                                }
                            }

                            // Position verification status
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                color: positionCheckActive && isPositionCorrect ? "#D1E7DD" : "#F8D7DA"
                                radius: 8
                                visible: positionCheckActive
                                border.width: 1
                                border.color: positionCheckActive && isPositionCorrect ? "#A3CFBB" : "#F1AEB5"

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 10

                                    Label {
                                        text: positionCheckActive && isPositionCorrect ? "✅" : "⚠️"
                                        font.pixelSize: 16
                                    }

                                    Label {
                                        text: positionCheckMessage
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: positionCheckActive && isPositionCorrect ? "#0F5132" : "#842029"
                                        Layout.fillWidth: true
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }

                            Row {
                                Layout.alignment: Qt.AlignHCenter
                                spacing: 30

                                // Required Position Indicator with GPS correction
                                Rectangle {
                                    width: 120
                                    height: 80
                                    color: "#F8F9FA"
                                    radius: 10
                                    border.width: 2
                                    border.color: "#FFC107"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 5

                                        Label {
                                            text: "Required"
                                            font.pixelSize: 10
                                            color: "#6C757D"
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        Label {
                                            text: "✈️"
                                            font.pixelSize: 40
                                            Layout.alignment: Qt.AlignHCenter
                                            rotation: {
                                                if (!accelCalibrationActive) return 0
                                                switch(currentStep) {
                                                    case 0: return 0      // Level
                                                    case 1: return -90    // Left
                                                    case 2: return 90     // Right
                                                    case 3: return -45    // Nose Down (CORRECTED)
                                                    case 4: return 45     // Nose Up (CORRECTED)
                                                    case 5: return 180    // Back
                                                    default: return 0
                                                }
                                            }
                                            Behavior on rotation { NumberAnimation { duration: 500 } }
                                        }
                                    }
                                }

                                // Current Position Indicator
                                Rectangle {
                                    width: 120
                                    height: 80
                                    color: "#F8F9FA"
                                    radius: 10
                                    border.width: 2
                                    border.color: positionCheckActive && isPositionCorrect ? "#198754" : "#DC3545"

                                    ColumnLayout {
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        spacing: 5

                                        Label {
                                            text: "Current"
                                            font.pixelSize: 10
                                            color: "#6C757D"
                                            Layout.alignment: Qt.AlignHCenter
                                        }

                                        Label {
                                            text: "✈️"
                                            font.pixelSize: 40
                                            Layout.alignment: Qt.AlignHCenter
                                            rotation: currentRoll
                                            transform: [
                                                Rotation {
                                                    origin.x: 20
                                                    origin.y: 20
                                                    axis { x: 1; y: 0; z: 0 }
                                                    angle: currentPitch
                                                }
                                            ]
                                            Behavior on rotation { NumberAnimation { duration: 100 } }
                                        }
                                    }
                                }
                            }

                            Label {
                                text: accelCalibrationActive ? orientations[currentStep].description : ""
                                font.pixelSize: 16
                                color: "#212529"
                                Layout.alignment: Qt.AlignHCenter
                                wrapMode: Text.WordWrap
                            }

                            // Position match indicator
                            Rectangle {
                                Layout.preferredWidth: 250
                                Layout.preferredHeight: 40
                                Layout.alignment: Qt.AlignHCenter
                                color: "transparent"
                                visible: positionCheckActive

                                ColumnLayout {
                                    anchors.fill: parent
                                    spacing: 5

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: isPositionCorrect ? "🎯 Position Verified!" : "📍 Adjust Position"
                                        font.pixelSize: 14
                                        font.bold: true
                                        color: isPositionCorrect ? "#198754" : "#FFC107"
                                    }

                                    Label {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "R:" + currentRoll.toFixed(1) + "° P:" + currentPitch.toFixed(1) + "° Y:" + currentYaw.toFixed(1) + "°"
                                        font.pixelSize: 10
                                        color: "#6C757D"
                                        visible: positionCheckActive
                                    }
                                }
                            }
                        }
                    }

                    // Orientation Grid with GPS-Corrected Position Status - Light Theme
                    GridLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        columns: 3
                        rows: 2
                        columnSpacing: 20
                        rowSpacing: 20

                        Repeater {
                            model: orientations

                            Rectangle {
                                Layout.preferredWidth: 180
                                Layout.preferredHeight: 160
                                color: "#FFFFFF"
                                radius: 10
                                border.width: 3
                                border.color: {
                                    if (accelCalibrationActive && currentStep === index) {
                                        if (positionCheckActive && isPositionCorrect) return "#198754"
                                        else if (positionCheckActive) return "#DC3545"
                                        else return "#FFC107"
                                    }
                                    else if (completedSteps[index]) return "#198754"
                                    else return "#DEE2E6"
                                }

                                ColumnLayout {
                                    anchors.fill: parent
                                    anchors.margins: 10
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        color: "#F8F9FA"
                                        radius: 6

                                        Label {
                                            anchors.centerIn: parent
                                            text: "✈️"
                                            font.pixelSize: 35
                                            rotation: {
                                                switch(index) {
                                                    case 0: return 0      // Level
                                                    case 1: return -90    // Left
                                                    case 2: return 90     // Right
                                                    case 3: return -45    // Nose Down (CORRECTED)
                                                    case 4: return 45     // Nose Up (CORRECTED)
                                                    case 5: return 180    // Back
                                                    default: return 0
                                                }
                                            }
                                        }
                                    }

                                    Label {
                                        text: {
                                            if (accelCalibrationActive && currentStep === index) {
                                                if (positionCheckActive && isPositionCorrect) return "🎯 Ready"
                                                else if (positionCheckActive) return "⚠️ Adjust" 
                                                else return "◉ Current"
                                            }
                                            else if (completedSteps[index]) return "✓ Complete"
                                            else return "○ Pending"
                                        }
                                        color: {
                                            if (accelCalibrationActive && currentStep === index) {
                                                if (positionCheckActive && isPositionCorrect) return "#198754"
                                                else if (positionCheckActive) return "#DC3545"
                                                else return "#FFC107"
                                            }
                                            else if (completedSteps[index]) return "#198754"
                                            else return "#ADB5BD"
                                        }
                                        font.pixelSize: 11
                                        font.bold: true
                                        Layout.alignment: Qt.AlignHCenter
                                    }

                                    Label {
                                        text: modelData.name + (index === 3 || index === 4 ? " (GPS)" : "")
                                        color: "#212529"
                                        font.pixelSize: 11
                                        Layout.alignment: Qt.AlignHCenter
                                        wrapMode: Text.WordWrap
                                    }
                                }
                            }
                        }
                    }

                    // Control Buttons with NEW LIGHT THEME COLORS
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 15

                        // Cancel Button - Neutral Action
                        Button {
                            text: "Cancel"
                            Layout.preferredWidth: 120
                            Layout.preferredHeight: 50
                            enabled: accelCalibrationActive

                            background: Rectangle {
                                color: parent.pressed ? "#E0E0E0" : (parent.enabled ? "#F5F5F5" : "#F8F9FA")
                                radius: 8
                                border.width: 1
                                border.color: "#CED4DA"
                            }

                            contentItem: Label {
                                text: parent.text
                                color: "#000000"
                                font.bold: true
                                font.pixelSize: 14
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            onClicked: {
                                if (calibrationModel) calibrationModel.stopAccelCalibration()
                            }
                        }

                        // Start Accel Calibration - Primary Action
                        Button {
                            text: "Start Accel Calibration"
                            Layout.preferredWidth: 180
                            Layout.preferredHeight: 50
                            enabled: !accelCalibrationActive && !levelCalibrationActive && !allCalibrationsComplete && isDroneConnected

                            background: Rectangle {
                                color: parent.pressed ? "#0056B3" : (parent.enabled ? "#007BFF" : "#ADB5BD")
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

                            onClicked: {
                                if (calibrationModel) calibrationModel.startAccelCalibration()
                            }
                        }

                        // Next Position - Secondary Action
                        Button {
                            text: allPositionsCompleted ? "Done" : "Next Position"
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 50
                            enabled: accelCalibrationActive && (!positionCheckActive || isPositionCorrect)

                            background: Rectangle {
                                color: {
                                    if (!parent.enabled) return "#ADB5BD"
                                    if (allPositionsCompleted) {
                                        return parent.pressed ? "#157347" : "#198754"
                                    } else {
                                        return parent.pressed ? "#5A6268" : "#6C757D"
                                    }
                                }
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

                            onClicked: {
                                if (calibrationModel) {
                                    if (allPositionsCompleted) {
                                        calibrationModel.completeAccelCalibration()
                                    } else {
                                        // Check position before proceeding
                                        let canProceed = calibrationModel.canProceedToNextPosition()
                                        if (canProceed) {
                                            calibrationModel.nextPosition()
                                        } else {
                                            let requiredPosition = orientations[currentStep].name
                                            let gpsNote = (currentStep === 3 || currentStep === 4) ? "\n\nNote: This position uses GPS heading correction." : ""
                                            positionWarningDialog.dialogText = "The drone must be in the correct position before proceeding.\n\nRequired position: " + requiredPosition + gpsNote + "\n\nCurrent position status: " + positionCheckMessage + "\n\nAdjust the drone position and try again."
                                            positionWarningDialog.open()
                                        }
                                    }
                                }
                            }
                        }

                        // Exit Calibration - Danger Action
                        Button {
                            text: allCalibrationsComplete ? "Reboot Drone" : "Exit Calibration"
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 50
                            enabled: !accelCalibrationActive && !levelCalibrationActive

                            background: Rectangle {
                                color: {
                                    if (!parent.enabled) return "#ADB5BD"
                                    if (allCalibrationsComplete) {
                                        return parent.pressed ? "#FFCA2C" : "#FFC107"
                                    } else {
                                        return parent.pressed ? "#BB2D3B" : "#DC3545"
                                    }
                                }
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

                            onClicked: {
                                if (allCalibrationsComplete) {
                                    rebootDialog.open()
                                } else {
                                    accelWindow.close()
                                }
                            }
                        }
                    }

                    // GPS-Enhanced Position Checking Help - Light Theme
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 120
                        Layout.maximumWidth: 800
                        Layout.alignment: Qt.AlignHCenter
                        color: "#F8F9FA"
                        radius: 8
                        border.width: 1
                        border.color: "#DEE2E6"
                        visible: positionCheckActive

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            spacing: 8

                            Label {
                                text: "📍 GPS-Enhanced Position Checking Active"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#007BFF"
                            }

                            Label {
                                text: "• The system continuously monitors drone orientation using real-time telemetry\n• Green indicators show correct positioning, red indicates adjustments needed\n• Nose Down/Up positions are automatically corrected based on GPS heading\n• GPS Fix Status: " + (gpsFixType >= 3 ? "✅ 3D Lock" : "❌ No Lock") + " | Satellites: " + satellitesVisible + "\n• Calibration steps only proceed when the drone is verified to be in the correct position\n• Tolerance: ±15° for all orientations"
                                font.pixelSize: 12
                                color: "#6C757D"
                                wrapMode: Text.WordWrap
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }

    // Functions for opening calibration windows
    function openCompassCalibration() {
        console.log("Opening Compass Calibration window...")
        if (!compassWindow) {
            let component = Qt.createComponent("compass.qml")
            if (component.status === Component.Ready) {
                compassWindow = component.createObject(accelWindow, {
                    "calibrationModel": calibrationModel
                })
                if (compassWindow) {
                    compassWindow.show()
                    compassWindow.closing.connect(function() {
                        compassWindow = null
                    })
                }
            } else {
                console.error("Failed to load CompassCalibration.qml:", component.errorString())
                showFeedback("❌ Could not load CompassCalibration.qml")
            }
        } else {
            compassWindow.show()
            compassWindow.raise()
            compassWindow.requestActivate()
        }
    }

    function openRadioCalibration() {
        console.log("Opening Radio Calibration window...")
        if (!radioWindow) {
            let component = Qt.createComponent("RadioCalibration.qml")
            if (component.status === Component.Ready) {
                radioWindow = component.createObject(accelWindow, {
                    "calibrationModel": calibrationModel
                })
                if (radioWindow) {
                    radioWindow.show()
                    radioWindow.closing.connect(function() {
                        radioWindow = null
                    })
                }
            } else {
                console.error("Failed to load RadioCalibration.qml:", component.errorString())
                showFeedback("❌ Could not load RadioCalibration.qml")
            }
        } else {
            radioWindow.show()
            radioWindow.raise()
            radioWindow.requestActivate()
        }
    }

    function openEscCalibration() {
        console.log("Opening ESC Calibration window...")
        if (!escWindow) {
            let component = Qt.createComponent("EscCalibration.qml")
            if (component.status === Component.Ready) {
                escWindow = component.createObject(accelWindow, {
                    "calibrationModel": calibrationModel
                })
                if (escWindow) {
                    escWindow.show()
                    escWindow.closing.connect(function() {
                        escWindow = null
                    })
                }
            } else {
                console.error("Failed to load EscCalibration.qml:", component.errorString())
                showFeedback("❌ Could not load EscCalibration.qml")
            }
        } else {
            escWindow.show()
            escWindow.raise()
            escWindow.requestActivate()
        }
    }

    function openServoCalibration() {
        console.log("Opening Servo Calibration window...")
        if (!servoWindow) {
            let component = Qt.createComponent("ServoCalibration.qml")
            if (component.status === Component.Ready) {
                servoWindow = component.createObject(accelWindow, {
                    "calibrationModel": calibrationModel
                })
                if (servoWindow) {
                    servoWindow.show()
                    servoWindow.closing.connect(function() {
                        servoWindow = null
                    })
                }
            } else {
                console.error("Failed to load ServoCalibration.qml:", component.errorString())
                showFeedback("❌ Could not load ServoCalibration.qml")
            }
        } else {
            servoWindow.show()
            servoWindow.raise()
            servoWindow.requestActivate()
        }
    }

    // Functions
    function showFeedback(message) {
        feedbackText.text = message
        feedbackTimer.restart()
    }

    function startReconnectionProcess() {
        showFeedback("🔄 Drone rebooting... Will attempt to reconnect automatically in 10 seconds...")
        reconnectionTimer.start()
    }

    // Reconnection Timer
    Timer {
        id: reconnectionTimer
        interval: 10000
        onTriggered: {
            if (droneModel && !droneModel.isConnected) {
                showFeedback("🔄 Attempting to reconnect to drone...")
                Qt.callLater(function() {
                    if (droneModel.lastConnectionString !== "") {
                        droneModel.connectToDrone(droneModel.lastConnectionId, droneModel.lastConnectionString, 57600)
                        showFeedback("📡 Reconnecting to: " + droneModel.lastConnectionString)
                    }
                })
            }
        }
    }

    // Keyboard handling with GPS-enhanced position checking
    Keys.onReturnPressed: {
        if (accelCalibrationActive && calibrationModel) {
            if (allPositionsCompleted) {
                calibrationModel.completeAccelCalibration()
            } else if (!positionCheckActive || isPositionCorrect) {
                calibrationModel.nextPosition()
            } else {
                let gpsInfo = (currentStep === 3 || currentStep === 4) ? " (GPS-corrected)" : ""
                showFeedback("⚠️ Adjust drone position before proceeding" + gpsInfo + " - " + positionCheckMessage)
            }
        } else if (allCalibrationsComplete) {
            rebootDialog.open()
        } else {
            showFeedback("Use the 'Start Calibration' buttons to begin a new calibration.")
        }
    }

    Keys.onEscapePressed: {
        if (levelCalibrationActive && calibrationModel) {
            calibrationModel.stopLevelCalibration()
        } else if (accelCalibrationActive && calibrationModel) {
            calibrationModel.stopAccelCalibration()
        } else {
            accelWindow.close()
        }
    }

    Component.onCompleted: {
        console.log("Enhanced AccelCalibration: Component completed with GPS/altitude support and separate calibration windows")
        console.log("calibrationModel at startup:", calibrationModel)
        console.log("isDroneConnected:", isDroneConnected)
        accelWindow.requestActivate()
    }

    Component.onDestruction: {
        // Clean up any open calibration windows
        if (compassWindow) compassWindow.close()
        if (radioWindow) radioWindow.close()
        if (escWindow) escWindow.close()
        if (servoWindow) servoWindow.close()
    }

    // Watch for calibration completion to show dialogs
    onLevelCalibrationCompleteChanged: {
        if (levelCalibrationComplete && !levelCalibrationActive) {
            levelSuccessDialog.open()
        }
    }

    onAccelCalibrationCompleteChanged: {
        if (accelCalibrationComplete && !accelCalibrationActive) {
            accelSuccessDialog.open()
        }
    }

    // Position check status monitoring with GPS info
    onIsPositionCorrectChanged: {
        if (positionCheckActive) {
            if (isPositionCorrect) {
                let gpsInfo = (accelCalibrationActive && (currentStep === 3 || currentStep === 4)) ? " (GPS-corrected)" : ""
                console.log("Position verified" + gpsInfo + ":", positionCheckMessage)
            } else {
                console.log("Position adjustment needed:", positionCheckMessage)
            }
        }
    }

    // GPS status monitoring
    onGpsFixTypeChanged: {
        if (gpsFixType >= 3) {
            console.log("GPS 3D lock acquired - Enhanced nose position accuracy available")
        }
    }
}
