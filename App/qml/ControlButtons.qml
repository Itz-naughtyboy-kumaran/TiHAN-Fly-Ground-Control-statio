import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Row {
    id: controlsPanelRoot
    spacing: 10
    anchors.centerIn: parent
    
    property var mainWindowRef: null
    property var parametersWindowInstance: null
    property var navigationControlsWindowInstance: null
    clip: false

    Button {
        id: takeoffButton
        property bool isClicked: false
        text: languageManager ? languageManager.getText("TAKEOFF") : "TAKEOFF"
        width: 70
        height: 30
        flat: true
        background: Rectangle {
            color: takeoffButton.isClicked ? "green" : "#ADD8E6"
            radius: 4
            border.width: 0
        }
        contentItem: Text {
            text: parent.text
            color: takeoffButton.isClicked ? "white" : "black"
            font.family: "Consolas"
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        hoverEnabled: false
        focusPolicy: Qt.NoFocus
        onClicked: {
            takeoffButton.isClicked = true
            landButton.isClicked = false
            rtlButton.isClicked = false
            settingsButton.isClicked = false
            tinariButton.isClicked = false
            altitudeSpeedDialog.open()
        }
    }

    Button {
        id: landButton
        property bool isClicked: false
        text: languageManager ? languageManager.getText("LAND") : "LAND"
        width: 60
        height: 30
        flat: true
        background: Rectangle {
            color: landButton.isClicked ? "green" : "#ADD8E6"
            radius: 4
            border.width: 0
        }
        contentItem: Text {
            text: parent.text
            color: landButton.isClicked ? "white" : "black"
            font.family: "Consolas"
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        hoverEnabled: false
        focusPolicy: Qt.NoFocus
        onClicked: {
            landButton.isClicked = true
            takeoffButton.isClicked = false
            rtlButton.isClicked = false
            settingsButton.isClicked = false
            tinariButton.isClicked = false
            if (droneCommander) droneCommander.land()
            else console.log("DroneCommander not set.");
        }
    }

    Button {
        id: rtlButton
        property bool isClicked: false
        text: languageManager ? languageManager.getText("RTL") : "RTL"
        width: 120
        height: 30
        flat: true
        background: Rectangle {
            color: rtlButton.isClicked ? "green" : "#ADD8E6"
            radius: 4
            border.width: 0
        }
        contentItem: Text {
            text: parent.text
            color: rtlButton.isClicked ? "white" : "black"
            font.family: "Consolas"
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        hoverEnabled: false
        focusPolicy: Qt.NoFocus
        onClicked: {
            rtlButton.isClicked = true
            takeoffButton.isClicked = false
            landButton.isClicked = false
            settingsButton.isClicked = false
            tinariButton.isClicked = false
            if (droneCommander) droneCommander.setMode("RTL")
            else console.log("DroneCommander not set.");
        }
    }

    Button {
        id: settingsButton
        property bool isClicked: false
        text: languageManager ? languageManager.getText("SETTINGS") + " ▼" : "SETTINGS ▼"
        width: 120
        height: 30
        flat: true
        
        background: Rectangle {
            color: settingsButton.isClicked ? "green" : "#ADD8E6"
            radius: 4
            border.width: 0
        }
        
        contentItem: Text {
            text: parent.text
            color: settingsButton.isClicked ? "white" : "black"
            font.family: "Consolas"
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        
        hoverEnabled: false
        focusPolicy: Qt.NoFocus
        onClicked: {
            settingsButton.isClicked = true
            takeoffButton.isClicked = false
            landButton.isClicked = false
            rtlButton.isClicked = false
            tinariButton.isClicked = false
            settingsMenu.open()
        }

        Menu {
            id: settingsMenu
            y: settingsButton.height + 2
            width: settingsButton.width
            padding: 4
            
            background: Rectangle {
                color: "#ffffff"
                border.color: Qt.rgba(0.4, 0.4, 0.4, 0.8)
                border.width: 1
                radius: 6
            }

            MenuItem {
                id: waypointsMenuItem
                property bool isClicked: false
                text: languageManager ? languageManager.getText("Waypoints") : "Waypoints"
                width: settingsButton.width
                height: 35

                background: Rectangle {
                    color: parent.hovered ? "#4CAF50" : "#ffffff"
                    radius: 4
                }

                contentItem: Text {
                    text: waypointsMenuItem.text
                    color: parent.hovered ? "#ffffff" : "#000000"
                    font.family: "Consolas"
                    font.pixelSize: 16
                    font.bold: waypointsMenuItem.isClicked
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                onTriggered: {
                    waypointsMenuItem.isClicked = true
                    parametersMenuItem.isClicked = false
                    
                    if (mainWindowRef) {
                        if (!mainWindowRef.navigationControlsWindowInstance) {
                            var c = Qt.createComponent("NavigationControls.qml")
                            if (c.status === Component.Ready) {
                                var w = c.createObject(mainWindowRef, {
                                    droneCommander: droneCommander,
                                    droneModel: droneModel
                                })

                                if (w) {
                                    mainWindowRef.navigationControlsWindowInstance = w
                                    w.show()
                                } else {
                                    console.log("❌ Failed to create Waypoints window object.")
                                }

                            } else {
                                console.log("❌ Error loading NavigationControls.qml:", c.errorString())
                            }
                        } else {
                            if (mainWindowRef.navigationControlsWindowInstance) {
                                mainWindowRef.navigationControlsWindowInstance.show()
                                mainWindowRef.navigationControlsWindowInstance.raise()
                            } else {
                                console.log("⚠️ Waypoints window exists but is not valid.")
                            }
                        }
                    } else {
                        console.log("❌ mainWindowRef is undefined.")
                    }
                }
            }

            MenuItem {
                id: parametersMenuItem
                property bool isClicked: false
                text: languageManager ? languageManager.getText("Parameters") : "Parameters"
                width: settingsButton.width
                height: 35

                background: Rectangle {
                    color: parent.hovered ? "#4CAF50" : "#ffffff"
                    radius: 4
                }

                contentItem: Text {
                    text: parametersMenuItem.text
                    color: parent.hovered ? "#ffffff" : "#000000"
                    font.family: "Consolas"
                    font.pixelSize: 16
                    font.bold: parametersMenuItem.isClicked || parent.hovered
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    renderType: Text.NativeRendering
                }

                onTriggered: {
                    if (mainWindowRef && !mainWindowRef.parametersWindowInstance) {
                        var c = Qt.createComponent("Parameters.qml")
                        if (c.status === Component.Ready) {
                            var w = c.createObject(mainWindowRef, {
                                "droneCommander": droneCommander
                            })
                            if (w) {
                                w.show()
                                mainWindowRef.parametersWindowInstance = w
                            } else {
                                console.log("❌ Failed to create Parameters window.")
                            }
                        } else {
                            console.log("❌ Error loading Parameters.qml:", c.errorString())
                        }
                    } else if (mainWindowRef && mainWindowRef.parametersWindowInstance) {
                        mainWindowRef.parametersWindowInstance.visible = true
                        mainWindowRef.parametersWindowInstance.raise()
                    } else {
                        console.log("❌ mainWindowRef not set.")
                    }
                }
            }
        }
    }

    Button {
        id: tinariButton
        property bool isClicked: false
        text: languageManager ? languageManager.getText("Ti-NARI") : "Ti-NARI"
        width: 80
        height: 30
        flat: true
        background: Rectangle {
            color: tinariButton.isClicked ? "green" : "#ADD8E6"
            radius: 4
            border.width: 0
        }
        contentItem: Text {
            text: parent.text
            color: tinariButton.isClicked ? "white" : "black"
            font.family: "Consolas"
            font.pixelSize: 16
            font.bold: true
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        hoverEnabled: false
        focusPolicy: Qt.NoFocus
        
        property var tinariWindowInstance: null
        
        onClicked: {
            if (!tinariWindowInstance) {
                var component = Qt.createComponent("TiNariWindow.qml")
                
                if (component.status === Component.Ready) {
                    tinariWindowInstance = component.createObject(null, {
                        "portDetector": portDetector,
                        "messageLogger": messageLogger
                    })
                    
                    if (tinariWindowInstance) {
                        isClicked = true
                        console.log("✅ Ti-NARI window opened successfully")
                        
                        tinariWindowInstance.closing.connect(function() {
                            isClicked = false
                            tinariWindowInstance.destroy()
                            tinariWindowInstance = null
                            console.log("🔒 Ti-NARI window closed")
                        })
                    } else {
                        console.error("❌ Failed to create Ti-NARI window instance")
                    }
                } else if (component.status === Component.Error) {
                    console.error("❌ Error loading Ti-NARI window:", component.errorString())
                } else {
                    console.log("⏳ Ti-NARI window loading...")
                }
            } else {
                tinariWindowInstance.raise()
                tinariWindowInstance.requestActivate()
            }
        }
        
        Connections {
            target: tinariWindowInstance
            function onVisibleChanged() {
                if (tinariWindowInstance && !tinariWindowInstance.visible) {
                    tinariButton.isClicked = false
                }
            }
        }
    }

    // Enhanced Altitude & Speed Dialog
    Dialog {
        id: altitudeSpeedDialog
        width: 450
        height: 380
        parent: ApplicationWindow.overlay
        anchors.centerIn: parent
        modal: true
        closePolicy: Popup.CloseOnEscape

        Overlay.modal: Rectangle {
            color: "#80000000"
        }

        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.width: 0

            Rectangle {
                anchors.fill: parent
                anchors.margins: -2
                color: "transparent"
                border.color: "#20000000"
                border.width: 1
                radius: parent.radius + 2
                z: -1
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                color: "transparent"
                border.color: "#10000000"
                border.width: 1
                radius: parent.radius + 4
                z: -2
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 0
            spacing: 0

            // Header section
            Rectangle {
                width: parent.width
                height: 60
                color: "#f8f9fa"
                radius: 12

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: parent.radius
                    color: parent.color
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 12

                    Rectangle {
                        width: 32
                        height: 32
                        color: "#4A90E2"
                        radius: 16

                        Text {
                            anchors.centerIn: parent
                            text: "✈"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            color: "white"
                        }
                    }

                    Text {
                        text: languageManager ? languageManager.getText("Automated Takeoff") : "Automated Takeoff"
                        font.family: "Consolas"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                        color: "#2c3e50"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // Content section
            Item {
                width: parent.width
                height: parent.height - 60 - 80

                Column {
                    anchors.centerIn: parent
                    spacing: 25
                    width: parent.width - 60

                    Text {
                        text: languageManager ? languageManager.getText("Configure takeoff parameters") : "Configure takeoff parameters"
                        font.family: "Consolas"
                        font.pixelSize: 14
                        color: "#5a6c7d"
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    // Altitude Input
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: languageManager ? languageManager.getText("Target Altitude (meters)") : "Target Altitude (meters)"
                            font.family: "Consolas"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#34495e"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Rectangle {
                            width: 200
                            height: 45
                            color: "#ffffff"
                            border.color: altitudeInput.activeFocus ? "#4A90E2" : "#e1e8ed"
                            border.width: 2
                            radius: 8
                            anchors.horizontalCenter: parent.horizontalCenter

                            TextField {
                                id: altitudeInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: "10"
                                placeholderText: "Enter altitude..."
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                horizontalAlignment: TextInput.AlignHCenter
                                color: "#2c3e50"

                                validator: DoubleValidator {
                                    bottom: 1.0
                                    top: 500.0
                                    decimals: 1
                                }

                                background: Rectangle {
                                    color: "transparent"
                                }
                            }
                        }

                        Text {
                            text: languageManager ? languageManager.getText("Range: 1.0 - 500.0 m") : "Range: 1.0 - 500.0 m"
                            font.family: "Consolas"
                            font.pixelSize: 11
                            color: "#95a5a6"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // Speed Input
                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: languageManager ? languageManager.getText("Climb Speed (m/s)") : "Climb Speed (m/s)"
                            font.family: "Consolas"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            color: "#34495e"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Rectangle {
                            width: 200
                            height: 45
                            color: "#ffffff"
                            border.color: speedInput.activeFocus ? "#4A90E2" : "#e1e8ed"
                            border.width: 2
                            radius: 8
                            anchors.horizontalCenter: parent.horizontalCenter

                            TextField {
                                id: speedInput
                                anchors.fill: parent
                                anchors.margins: 2
                                text: "2.5"
                                placeholderText: "Enter speed..."
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Medium
                                horizontalAlignment: TextInput.AlignHCenter
                                color: "#2c3e50"

                                validator: DoubleValidator {
                                    bottom: 0.5
                                    top: 10.0
                                    decimals: 1
                                }

                                background: Rectangle {
                                    color: "transparent"
                                }

                                Keys.onReturnPressed: {
                                    if (startTakeoffButton.enabled) {
                                        startTakeoffButton.clicked()
                                    }
                                }
                            }
                        }

                        Text {
                            text: languageManager ? languageManager.getText("Range: 0.5 - 10.0 m/s") : "Range: 0.5 - 10.0 m/s"
                            font.family: "Consolas"
                            font.pixelSize: 11
                            color: "#95a5a6"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }

                    // Info message
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "#e8f5e9"
                        radius: 6
                        border.color: "#4CAF50"
                        border.width: 1

                        Text {
                            anchors.centerIn: parent
                            text: "🤖 Auto: ARM → GUIDED → TAKEOFF"
                            font.family: "Consolas"
                            font.pixelSize: 12
                            color: "#2e7d32"
                            font.weight: Font.Medium
                        }
                    }
                }
            }

            // Footer with buttons
            Rectangle {
                width: parent.width
                height: 80
                color: "#ffffff"

                Rectangle {
                    width: parent.width - 40
                    height: 1
                    color: "#ecf0f1"
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 15

                    Button {
                        text: languageManager ? languageManager.getText("Cancel") : "Cancel"
                        width: 100
                        height: 40

                        background: Rectangle {
                            color: parent.hovered ? "#e74c3c" : "#ecf0f1"
                            radius: 8
                            border.width: 0
                        }

                        contentItem: Text {
                            text: parent.text
                            color: parent.hovered ? "white" : "#7f8c8d"
                            font.family: "Consolas"
                            font.pixelSize: 14
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        hoverEnabled: true

                        onClicked: {
                            altitudeSpeedDialog.close()
                        }
                    }

                    Button {
                        id: startTakeoffButton
                        text: languageManager ? languageManager.getText("Start Takeoff") : "Start Takeoff"
                        width: 140
                        height: 40
                        enabled: altitudeInput.text !== "" && altitudeInput.acceptableInput &&
                                speedInput.text !== "" && speedInput.acceptableInput

                        background: Rectangle {
                            color: {
                                if (!parent.enabled) return "#bdc3c7"
                                return parent.hovered ? "#27ae60" : "#2ecc71"
                            }
                            radius: 8
                            border.width: 0
                        }

                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? "white" : "#95a5a6"
                            font.family: "Consolas"
                            font.pixelSize: 14
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        hoverEnabled: true

                        onClicked: {
                            var altitude = parseFloat(altitudeInput.text)
                            var speed = parseFloat(speedInput.text)
                            
                            console.log("🚁 Starting automated takeoff:")
                            console.log("  - Altitude:", altitude, "m")
                            console.log("  - Speed:", speed, "m/s")
                            console.log("  - altitude type:", typeof altitude)
                            console.log("  - speed type:", typeof speed)
                            console.log("  - altitude isNaN:", isNaN(altitude))
                            console.log("  - speed isNaN:", isNaN(speed))
                            console.log("  - droneCommander exists:", droneCommander !== undefined && droneCommander !== null)
                            
                            if (!isNaN(altitude) && !isNaN(speed) && altitude > 0 && speed > 0) {
                                if (droneCommander) {
                                    try {
                                        console.log("📞 Calling droneCommander.takeoff(" + altitude + ", " + speed + ")")
                                        var result = droneCommander.takeoff(altitude, speed)
                                        console.log("✅ Takeoff command result:", result)
                                    } catch (error) {
                                        console.log("❌ Error calling takeoff:", error)
                                        console.log("❌ Error details:", JSON.stringify(error))
                                    }
                                } else {
                                    console.log("❌ DroneCommander not set for takeoff.")
                                }
                                
                                altitudeSpeedDialog.close()
                            } else {
                                console.log("❌ Invalid input values:")
                                console.log("  - altitude:", altitude, "valid:", !isNaN(altitude) && altitude > 0)
                                console.log("  - speed:", speed, "valid:", !isNaN(speed) && speed > 0)
                            }
                        }
                    }
                }
            }
        }

        // Reset inputs when dialog opens
        onOpened: {
            altitudeInput.forceActiveFocus()
            altitudeInput.selectAll()
        }
    }
}
