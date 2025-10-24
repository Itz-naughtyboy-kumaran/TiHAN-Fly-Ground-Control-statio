import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15 // Added for Dialog's parent: ApplicationWindow.overlay

// Simple Row with buttons - no background containers
Row {
    id: controlsPanelRoot
    spacing: 10
    anchors.centerIn: parent
    
    // Properties
    property var mainWindowRef: null
    
    clip: false

    Button {
        id: takeoffButton
        property bool isClicked: false
        text: languageManager ? languageManager.getText("TAKEOFF") : "TAKEOFF"
        width: 70
        height: 30
        flat: true  // Remove default button styling
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
            altitudeDialog.open()
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
    flat: true  // Remove default button styling
    
    // Match takeoff button background styling
    background: Rectangle {
        color: settingsButton.isClicked ? "green" : "#ADD8E6"
        radius: 4
        border.width: 0
    }
    
    // Match takeoff button text styling
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
        y: settingsButton.height + 2  // Match language selector popup positioning
        width: settingsButton.width  // Match parent width
        padding: 4  // Match language selector popup padding
        
        // Match language selector popup background
        background: Rectangle {
            color: "#ffffff"  // White background like language selector
            border.color: Qt.rgba(0.4, 0.4, 0.4, 0.8)  // Gray border like language selector
            border.width: 1
            radius: 6  // Match language selector popup radius
        }

        MenuItem {
            id: waypointsMenuItem
            property bool isClicked: false
            text: languageManager ? languageManager.getText("Waypoints") : "Waypoints"
            width: settingsButton.width  // Match parent width
            height: 35  // Match language selector delegate height

            // Match language selector delegate background styling
            background: Rectangle {
                color: parent.hovered ? "#4CAF50" : "#ffffff"  // Green on hover, white otherwise
                radius: 4
            }

            // Match language selector delegate text styling
            contentItem: Text {
                text: waypointsMenuItem.text
                color: parent.hovered ? "#ffffff" : "#000000"  // White text on green hover, black text on white background
                font.family: "Consolas"
                font.pixelSize: 16
                font.bold: waypointsMenuItem.isClicked
                horizontalAlignment: Text.AlignHCenter  // Center align like language selector
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering  // Match language selector render type
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
            width: settingsButton.width  // Match parent width
            height: 35  // Match language selector delegate height

            // Match language selector delegate background styling
            background: Rectangle {
                color: parent.hovered ? "#4CAF50" : "#ffffff"  // Green on hover, white otherwise
                radius: 4
            }

            // Match language selector delegate text styling
            contentItem: Text {
                text: parametersMenuItem.text
                color: parent.hovered ? "#ffffff" : "#000000"  // White text on green hover, black text on white background
                font.family: "Consolas"
                font.pixelSize: 16
                font.bold: parametersMenuItem.isClicked || parent.hovered
                horizontalAlignment: Text.AlignHCenter  // Center align like language selector
                verticalAlignment: Text.AlignVCenter
                renderType: Text.NativeRendering  // Match language selector render type
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
    
    // Store window reference locally
    property var tinariWindowInstance: null
    
    onClicked: {
        tinariButton.isClicked = true
        takeoffButton.isClicked = false
        landButton.isClicked = false
        rtlButton.isClicked = false
        settingsButton.isClicked = false
        
        // Open Ti-NARI window
        if (!tinariWindowInstance || !tinariWindowInstance.visible) {
            var component = Qt.createComponent("TinariWindow.qml")
            if (component.status === Component.Ready) {
                tinariWindowInstance = component.createObject(null, {
                    "portManager": mainWindowRef ? mainWindowRef.portManager : null,
                    "firmwareFlasher": mainWindowRef ? mainWindowRef.firmwareFlasher : null
                })
                if (tinariWindowInstance) {
                    // Store reference in main window if property exists
                    if (mainWindowRef && mainWindowRef.hasOwnProperty("tinariWindowInstance")) {
                        mainWindowRef.tinariWindowInstance = tinariWindowInstance
                    }
                    
                    // Use visible property instead of show()
                    tinariWindowInstance.visible = true
                    
                    // Connect close handler to reset button state
                    tinariWindowInstance.closing.connect(function() {
                        tinariButton.isClicked = false
                    })
                    
                    console.log("✅ Ti-NARI window created successfully")
                } else {
                    console.log("❌ Failed to create Ti-NARI window object")
                }
            } else if (component.status === Component.Error) {
                console.log("❌ Error loading TinariWindow.qml:", component.errorString())
            } else {
                console.log("⏳ Component still loading...")
            }
        } else {
            // Show existing window
            tinariWindowInstance.visible = true
            tinariWindowInstance.raise()
            tinariWindowInstance.requestActivate()
            console.log("✅ Ti-NARI window shown")
        }
    }
    
    // Reset button state when window is closed
    Connections {
        target: tinariWindowInstance
        function onVisibleChanged() {
            if (tinariWindowInstance && !tinariWindowInstance.visible) {
                tinariButton.isClicked = false
            }
        }
    }
}
    // Professional Altitude Input Dialog
    Dialog {
        id: altitudeDialog
        width: 400
        height: 280
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
                        text: languageManager ? languageManager.getText("Takeoff Configuration") : "Takeoff Configuration"
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
                    spacing: 20
                    width: parent.width - 60

                    Text {
                        text: languageManager ? languageManager.getText("Set the altitude for drone takeoff") : "Set the altitude for drone takeoff"
                        font.family: "Consolas"
                        font.pixelSize: 16
                        color: "#5a6c7d"
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                    }

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Text {
                            text: languageManager ? languageManager.getText("Altitude (meters)") : "Altitude (meters)"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            color: "#34495e"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }

                        Rectangle {
                            width: 180
                            height: 45
                            color: "#ffffff"
                            border.color: altitudeInput.activeFocus ? "#4A90E2" : "#e1e8ed"
                            border.width: 2
                            radius: 8

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

                                Keys.onReturnPressed: {
                                    if (acceptButton.enabled) {
                                        acceptButton.clicked()
                                    }
                                }

                                Component.onCompleted: forceActiveFocus()
                            }
                        }

                        Text {
                            text: languageManager ? languageManager.getText("Range: 1.0 - 500.0 meters") : "Range: 1.0 - 500.0 meters"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            color: "#95a5a6"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }

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
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        hoverEnabled: true

                        onClicked: {
                            altitudeDialog.close()
                        }
                    }

                    Button {
                        id: acceptButton
                        text: languageManager ? languageManager.getText("Start Takeoff") : "Start Takeoff"
                        width: 130
                        height: 40
                        enabled: altitudeInput.text !== "" && altitudeInput.acceptableInput

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
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        hoverEnabled: true

                        onClicked: {
                            var altitude = parseFloat(altitudeInput.text)
                            if (altitude > 0) {
                                if (droneCommander) droneCommander.takeoff(altitude)
                                else console.log("DroneCommander not set for takeoff.");
                                altitudeDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }
}