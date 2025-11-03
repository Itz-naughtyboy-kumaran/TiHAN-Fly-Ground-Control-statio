import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3

ApplicationWindow {
    id: root
    visible: true
    visibility: "Maximized"
    title: "Compass Calibration System"
    color: "#f0f2f5"

    property bool isDroneConnected: droneModel ? (droneModel.isConnected || false) : false
    property var compassCalibrationModel: null
    property var droneModel: null
    property var droneCommander: null
    property bool isCalibrationCompleted: false

    // Custom colors
    readonly property color primaryColor: "#2563eb"
    readonly property color successColor: "#10b981"
    readonly property color dangerColor: "#ef4444"
    readonly property color warningColor: "#f59e0b"
    readonly property color backgroundColor: "#f0f2f5"
    readonly property color cardColor: "#ffffff"
    readonly property color textPrimary: "#1f2937"
    readonly property color textSecondary: "#6b7280"
    readonly property color borderColor: "#e5e7eb"

    Connections {
        target: droneModel
        enabled: droneModel !== null
        function onIsConnectedChanged() {
            if (droneModel && !droneModel.isConnected && compassCalibrationModel && compassCalibrationModel.calibrationStarted) {
                compassCalibrationModel.stopCalibration();
            }
        }
    }

    Connections {
        target: compassCalibrationModel
        enabled: compassCalibrationModel !== null
        function onCalibrationStartedChanged() { isCalibrationCompleted = false }
        function onCalibrationComplete() { isCalibrationCompleted = true }
        function onCalibrationFailed() { isCalibrationCompleted = false }
    }

    MessageDialog {
        id: rebootDialog
        title: "Reboot Required"
        text: "Calibration completed successfully!\n\nReboot required to apply settings. Reboot now?"
        standardButtons: StandardButton.Yes | StandardButton.No
        onYes: {
            if (isDroneConnected && compassCalibrationModel) {
                compassCalibrationModel.rebootAutopilot();
                isCalibrationCompleted = false;
            }
        }
    }

    // Header Bar
    Rectangle {
        id: headerBar
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 70
        color: cardColor
        z: 10

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: borderColor
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20

            // Logo/Icon
            Rectangle {
                width: 40
                height: 40
                radius: 8
                color: primaryColor
                Text {
                    anchors.centerIn: parent
                    text: "⚙"
                    color: "white"
                    font.pixelSize: 24
                }
            }

            ColumnLayout {
                spacing: 2
                Text {
                    text: "Compass Calibration System"
                    color: textPrimary
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "Advanced Configuration & Diagnostics"
                    color: textSecondary
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            // Connection Status Badge
            Rectangle {
                Layout.preferredWidth: 140
                Layout.preferredHeight: 36
                radius: 18
                color: isDroneConnected ? "#ecfdf5" : "#fef2f2"
                border.color: isDroneConnected ? "#a7f3d0" : "#fecaca"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 8
                    Rectangle {
                        width: 8
                        height: 8
                        radius: 4
                        color: isDroneConnected ? successColor : dangerColor
                        SequentialAnimation on opacity {
                            running: isDroneConnected
                            loops: Animation.Infinite
                            NumberAnimation { from: 1.0; to: 0.3; duration: 800 }
                            NumberAnimation { from: 0.3; to: 1.0; duration: 800 }
                        }
                    }
                    Text {
                        text: isDroneConnected ? "Connected" : "Disconnected"
                        color: isDroneConnected ? "#065f46" : "#991b1b"
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    ScrollView {
        anchors.top: headerBar.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        clip: true

        ColumnLayout {
            width: root.width - 48
            spacing: 20

            // System Diagnostics Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 90
                color: cardColor
                radius: 12
                border.color: borderColor
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 20
                    spacing: 12

                    Text {
                        text: "System Diagnostics"
                        color: textPrimary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    GridLayout {
                        columns: 6
                        columnSpacing: 24
                        rowSpacing: 8

                        Repeater {
                            model: [
                                {label: "Model Status", value: compassCalibrationModel ? "Active" : "Inactive", status: compassCalibrationModel},
                                {label: "Calibration", value: (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? "Running" : "Idle", status: compassCalibrationModel && compassCalibrationModel.calibrationStarted},
                                {label: "Mag 1", value: Math.round(compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0) + "%", status: true},
                                {label: "Mag 2", value: Math.round(compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0) + "%", status: true},
                                {label: "Mag 3", value: Math.round(compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0) + "%", status: true}
                            ]

                            ColumnLayout {
                                spacing: 4
                                Text {
                                    text: modelData.label
                                    color: textSecondary
                                    font.pixelSize: 10
                                    font.weight: Font.Medium
                                }
                                RowLayout {
                                    spacing: 6
                                    Rectangle {
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: modelData.status ? successColor : textSecondary
                                    }
                                    Text {
                                        text: modelData.value
                                        color: textPrimary
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Compass Priority Configuration Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 340
                color: cardColor
                radius: 12
                border.color: borderColor
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 4
                            height: 20
                            color: primaryColor
                            radius: 2
                        }
                        Text {
                            text: "Compass Priority Configuration"
                            color: textPrimary
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                    }

                    Text {
                        text: "Configure compass priority order (highest priority at top)"
                        color: textSecondary
                        font.pixelSize: 12
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 140
                        color: "#f9fafb"
                        border.color: borderColor
                        border.width: 1
                        radius: 8

                        GridLayout {
                            anchors.fill: parent
                            columns: 9
                            rows: 3
                            rowSpacing: 0
                            columnSpacing: 0

                            // Headers
                            Repeater {
                                model: ["Priority", "DevID", "BusType", "Bus", "Address", "DevType", "Missing", "External", "Actions"]
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 40
                                    color: "#f3f4f6"
                                    border.color: borderColor
                                    border.width: 1
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                        color: textPrimary
                                    }
                                }
                            }

                            // Data Rows
                            Repeater {
                                model: [
                                    ["1", "97539", "UAVCAN", "0", "125", "SENSOR_ID#1"],
                                    ["2", "590114", "SPI", "4", "AK09916", ""]
                                ]
                                Repeater {
                                    model: modelData
                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 50
                                        color: index === 0 ? "#eff6ff" : cardColor
                                        border.color: borderColor
                                        border.width: 1
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData
                                            font.pixelSize: 11
                                            color: textPrimary
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    color: index === 0 ? "#eff6ff" : cardColor
                                    border.color: borderColor
                                    border.width: 1
                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 8
                                        CheckBox { enabled: isDroneConnected; scale: 0.75 }
                                        CheckBox { enabled: isDroneConnected; scale: 0.75 }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 50
                                    color: index === 0 ? "#eff6ff" : cardColor
                                    border.color: borderColor
                                    border.width: 1
                                    RowLayout {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        Button {
                                            text: "↑"
                                            width: 28
                                            height: 28
                                            enabled: isDroneConnected
                                            background: Rectangle {
                                                color: parent.enabled ? (parent.hovered ? "#f3f4f6" : "transparent") : "#f9fafb"
                                                border.color: borderColor
                                                border.width: 1
                                                radius: 4
                                            }
                                            contentItem: Text {
                                                text: parent.text
                                                color: parent.enabled ? textPrimary : textSecondary
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                font.pixelSize: 12
                                            }
                                        }
                                        Button {
                                            text: "↓"
                                            width: 28
                                            height: 28
                                            enabled: isDroneConnected
                                            background: Rectangle {
                                                color: parent.enabled ? (parent.hovered ? "#f3f4f6" : "transparent") : "#f9fafb"
                                                border.color: borderColor
                                                border.width: 1
                                                radius: 4
                                            }
                                            contentItem: Text {
                                                text: parent.text
                                                color: parent.enabled ? textPrimary : textSecondary
                                                horizontalAlignment: Text.AlignHCenter
                                                verticalAlignment: Text.AlignVCenter
                                                font.pixelSize: 12
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 20
                        CheckBox {
                            checked: true
                            enabled: isDroneConnected
                            scale: 0.85
                        }
                        Text {
                            text: "Use Compass 1"
                            color: textPrimary
                            font.pixelSize: 12
                        }
                        CheckBox {
                            checked: true
                            enabled: isDroneConnected
                            scale: 0.85
                        }
                        Text {
                            text: "Use Compass 2"
                            color: textPrimary
                            font.pixelSize: 12
                        }
                        CheckBox {
                            checked: false
                            enabled: isDroneConnected
                            scale: 0.85
                        }
                        Text {
                            text: "Use Compass 3"
                            color: textPrimary
                            font.pixelSize: 12
                        }
                        Item { Layout.fillWidth: true }
                        Button {
                            text: "Remove Missing"
                            enabled: isDroneConnected
                            Layout.preferredHeight: 36
                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#f3f4f6" : cardColor) : "#f9fafb"
                                border.color: borderColor
                                border.width: 1
                                radius: 6
                            }
                            contentItem: Text {
                                text: parent.text
                                color: parent.enabled ? textPrimary : textSecondary
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                                font.weight: Font.Medium
                            }
                        }
                    }
                }
            }

            // Calibration Progress Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 480
                color: cardColor
                radius: 12
                border.color: borderColor
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 20

                    RowLayout {
                        spacing: 12
                        Rectangle {
                            width: 4
                            height: 20
                            color: primaryColor
                            radius: 2
                        }
                        Text {
                            text: "Calibration Process"
                            color: textPrimary
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                        Item { Layout.fillWidth: true }
                        
                        // Status Badge
                        Rectangle {
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 32
                            radius: 16
                            color: isCalibrationCompleted ? "#ecfdf5" : (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? "#fef3c7" : "#f3f4f6"
                            border.color: isCalibrationCompleted ? "#a7f3d0" : (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? "#fde68a" : borderColor
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: isCalibrationCompleted ? "✓ COMPLETED" : (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? "Step " + (compassCalibrationModel.currentOrientation || 1) + " of 6" : "Ready"
                                color: isCalibrationCompleted ? "#065f46" : (compassCalibrationModel && compassCalibrationModel.calibrationStarted) ? "#92400e" : textSecondary
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    // Action Buttons
                    RowLayout {
                        spacing: 12
                        Button {
                            text: isCalibrationCompleted ? "✓ Reboot & Apply" : "Start Calibration"
                            enabled: isDroneConnected && compassCalibrationModel && (!compassCalibrationModel.calibrationStarted || isCalibrationCompleted)
                            Layout.preferredHeight: 44
                            Layout.preferredWidth: 180
                            onClicked: {
                                if (isCalibrationCompleted) rebootDialog.open()
                                else if (compassCalibrationModel && isDroneConnected) compassCalibrationModel.startCalibration()
                            }
                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#1d4ed8" : primaryColor) : "#9ca3af"
                                radius: 8
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }
                        Button {
                            text: "Accept Calibration"
                            enabled: isDroneConnected && compassCalibrationModel && compassCalibrationModel.calibrationStarted && !isCalibrationCompleted
                            Layout.preferredHeight: 44
                            Layout.preferredWidth: 180
                            onClicked: { if (compassCalibrationModel && isDroneConnected) compassCalibrationModel.acceptCalibration() }
                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#059669" : successColor) : "#9ca3af"
                                radius: 8
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }
                        Button {
                            text: "Cancel"
                            enabled: isDroneConnected && compassCalibrationModel && compassCalibrationModel.calibrationStarted && !isCalibrationCompleted
                            Layout.preferredHeight: 44
                            Layout.preferredWidth: 120
                            onClicked: { if (compassCalibrationModel && isDroneConnected) { compassCalibrationModel.stopCalibration(); isCalibrationCompleted = false } }
                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#dc2626" : dangerColor) : "#9ca3af"
                                radius: 8
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: borderColor
                    }

                    // Progress Indicators
                    Text {
                        text: "Magnetometer Progress"
                        color: textPrimary
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                    }

                    Repeater {
                        model: [
                            {name: "Magnetometer 1", progress: compassCalibrationModel ? compassCalibrationModel.mag1Progress : 0, color: successColor, lightColor: "#d1fae5"},
                            {name: "Magnetometer 2", progress: compassCalibrationModel ? compassCalibrationModel.mag2Progress : 0, color: primaryColor, lightColor: "#dbeafe"},
                            {name: "Magnetometer 3", progress: compassCalibrationModel ? compassCalibrationModel.mag3Progress : 0, color: warningColor, lightColor: "#fef3c7"}
                        ]

                        ColumnLayout {
                            spacing: 8
                            Layout.fillWidth: true

                            RowLayout {
                                spacing: 12
                                Layout.fillWidth: true

                                Text {
                                    text: modelData.name
                                    color: textPrimary
                                    Layout.preferredWidth: 130
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    color: "#f3f4f6"
                                    border.color: borderColor
                                    border.width: 1
                                    radius: 8

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, modelData.progress / 100.0))
                                        height: parent.height
                                        color: modelData.color
                                        radius: 8
                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 300
                                                easing.type: Easing.OutCubic
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(modelData.progress) + "%"
                                        color: modelData.progress > 50 ? "white" : textPrimary
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }
                                }

                                Rectangle {
                                    width: 32
                                    height: 32
                                    radius: 16
                                    color: modelData.progress >= 100 ? modelData.lightColor : (modelData.progress > 0 ? "#fef3c7" : "#f3f4f6")
                                    border.color: modelData.progress >= 100 ? modelData.color : (modelData.progress > 0 ? warningColor : borderColor)
                                    border.width: 2

                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.progress >= 100 ? "✓" : modelData.progress > 0 ? "●" : "○"
                                        color: modelData.progress >= 100 ? modelData.color : (modelData.progress > 0 ? warningColor : textSecondary)
                                        font.pixelSize: 14
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: borderColor
                    }

                    // Configuration Options
                    RowLayout {
                        spacing: 16
                        Text {
                            text: "Fitness Level:"
                            color: textPrimary
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                        ComboBox {
                            model: ["Strict", "Default", "Relaxed", "Very Relaxed"]
                            currentIndex: 1
                            enabled: isDroneConnected && (!compassCalibrationModel || !compassCalibrationModel.calibrationStarted)
                            Layout.preferredWidth: 160
                            Layout.preferredHeight: 36
                            background: Rectangle {
                                color: parent.enabled ? cardColor : "#f9fafb"
                                border.color: borderColor
                                border.width: 1
                                radius: 6
                            }
                        }
                        Item { Layout.fillWidth: true }
                        CheckBox {
                            checked: true
                            enabled: isDroneConnected
                            scale: 0.85
                        }
                        Text {
                            text: "Auto-retry on failure"
                            color: textPrimary
                            font.pixelSize: 12
                        }
                    }

                    // Status Message
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        color: isCalibrationCompleted ? "#f0fdf4" : "#f9fafb"
                        border.color: isCalibrationCompleted ? "#bbf7d0" : borderColor
                        border.width: 1
                        radius: 8

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Rectangle {
                                width: 6
                                height: parent.height
                                color: isCalibrationCompleted ? successColor : primaryColor
                                radius: 3
                            }

                            Text {
                                Layout.fillWidth: true
                                text: isCalibrationCompleted ? "✓ Calibration completed successfully! Click 'Reboot & Apply' to finalize changes." : compassCalibrationModel ? (compassCalibrationModel.statusText || "Ready to begin calibration process") : "Ready to begin calibration process"
                                color: isCalibrationCompleted ? "#166534" : textSecondary
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                verticalAlignment: Text.AlignVCenter
                            }
                        }
                    }
                }
            }

            // System Actions Card
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                color: cardColor
                radius: 12
                border.color: borderColor
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 24
                    spacing: 16

                    Text {
                        text: "System Actions"
                        color: textPrimary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                    }

                    RowLayout {
                        spacing: 12
                        Button {
                            text: "Reboot Autopilot"
                            enabled: isDroneConnected
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: 160
                            onClicked: { if (droneCommander && typeof droneCommander.rebootAutopilot === 'function') droneCommander.rebootAutopilot() }
                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#0891b2" : "#06b6d4") : "#9ca3af"
                                radius: 8
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                        Button {
                            text: "Large Vehicle MagCal"
                            enabled: isDroneConnected
                            Layout.preferredHeight: 40
                            Layout.preferredWidth: 180
                            onClicked: { if (compassCalibrationModel && isDroneConnected) compassCalibrationModel.startCalibration() }
                            background: Rectangle {
                                color: parent.enabled ? (parent.hovered ? "#ea580c" : "#f97316") : "#9ca3af"
                                radius: 8
                            }
                            contentItem: Text {
                                text: parent.text
                                color: "white"
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
            }

            Item { height: 20 }
        }
    }

    Component.onDestruction: {
        if (compassCalibrationModel && compassCalibrationModel.calibrationStarted) compassCalibrationModel.stopCalibration()
    }
}