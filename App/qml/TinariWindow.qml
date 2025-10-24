//Ti-Nari Firmware Installation 
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Window 2.15

Window {
    id: tinariWindow
    width: 1400
    height: 800
    minimumWidth: 1200
    minimumHeight: 700
    title: "Ti-Nari - Firmware Installer"
    color: "#f5f5f5"
    
    property var portManager: null
    property var firmwareFlasher: null
    
    // Selected device port
    property string selectedPort: ""
    property var selectedPortInfo: null
    
    // Selected drone for flashing
    property string selectedDrone: ""
    property string selectedCubeType: "CubeOrange"
    
    // Drone unlock states
    property var unlockedDrones: ({})
    
    // Flash progress dialog
    Dialog {
        id: flashProgressDialog
        title: "Flashing Firmware"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 600
        height: 400
        closePolicy: Popup.NoAutoClose
        
        property bool isFlashing: false
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 15
            
            Label {
                text: "Flashing firmware to device..."
                font.family: "Consolas"
                font.pixelSize: 16
                font.bold: true
            }
            
            ProgressBar {
                id: flashProgressBar
                Layout.fillWidth: true
                from: 0
                to: 100
                value: 0
                
                background: Rectangle {
                    color: "#ecf0f1"
                    radius: 3
                }
                contentItem: Rectangle {
                    width: flashProgressBar.visualPosition * parent.width
                    color: "#3498db"
                    radius: 3
                }
            }
            
            Label {
                id: flashProgressText
                text: "0%"
                font.family: "Consolas"
                font.pixelSize: 14
                Layout.alignment: Qt.AlignHCenter
            }
            
            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                color: "#2c3e50"
                radius: 3
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    
                    TextArea {
                        id: flashStatusText
                        readOnly: true
                        wrapMode: Text.Wrap
                        font.family: "Consolas"
                        font.pixelSize: 11
                        color: "#ecf0f1"
                        background: Rectangle {
                            color: "transparent"
                        }
                    }
                }
            }
            
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                
                Item { Layout.fillWidth: true }
                
                Button {
                    text: "Cancel"
                    visible: flashProgressDialog.isFlashing
                    background: Rectangle {
                        color: parent.hovered ? "#c0392b" : "#e74c3c"
                        radius: 3
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 14
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        if (firmwareFlasher) {
                            firmwareFlasher.cancelFlash()
                        }
                    }
                }
                
                Button {
                    text: "Close"
                    visible: !flashProgressDialog.isFlashing
                    background: Rectangle {
                        color: parent.hovered ? "#2980b9" : "#3498db"
                        radius: 3
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        font.pixelSize: 14
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: {
                        flashProgressDialog.close()
                        flashProgressBar.value = 0
                        flashStatusText.text = ""
                    }
                }
            }
        }
        
        onVisibleChanged: {
            if (!visible) {
                isFlashing = false
            }
        }
    }
    
    // Cube Type Selection Dialog
    Dialog {
        id: cubeTypeDialog
        title: "Select Cube Type"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 400
        
        property string selectedDroneName: ""
        
        footer: DialogButtonBox {
            Button {
                text: "OK"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
            Button {
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
        }
        
        onAccepted: {
            startFlashing(selectedDroneName)
        }
        
        ColumnLayout {
            spacing: 15
            width: parent.width
            
            Label {
                text: "Select the flight controller type for " + cubeTypeDialog.selectedDroneName
                font.family: "Consolas"
                font.pixelSize: 14
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }
            
            ButtonGroup {
                id: cubeTypeGroup
            }
            
            RadioButton {
                text: "Cube Orange"
                font.family: "Consolas"
                font.pixelSize: 13
                checked: true
                ButtonGroup.group: cubeTypeGroup
                onClicked: selectedCubeType = "CubeOrange"
            }
            
            RadioButton {
                text: "Cube Orange+"
                font.family: "Consolas"
                font.pixelSize: 13
                ButtonGroup.group: cubeTypeGroup
                onClicked: selectedCubeType = "CubeOrangePlus"
            }
        }
    }
    
    // Password dialog
    Dialog {
        id: passwordDialog
        title: "Enter Password"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 400
        
        property string droneName: ""
        property string correctPassword: ""
        property int droneIndex: -1
        
        footer: DialogButtonBox {
            Button {
                text: "OK"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
            Button {
                text: "Cancel"
                DialogButtonBox.buttonRole: DialogButtonBox.RejectRole
            }
        }
        
        onAccepted: {
            if (passwordField.text === correctPassword) {
                unlockedDrones[droneName] = true
                droneRepeater.itemAt(droneIndex).updateUnlockState()
                passwordField.text = ""
            } else {
                errorDialog.open()
                passwordField.text = ""
            }
        }
        
        onRejected: {
            passwordField.text = ""
        }
        
        ColumnLayout {
            spacing: 15
            width: parent.width
            Label {
                text: "Enter password to unlock " + passwordDialog.droneName
                font.family: "Consolas"
                font.pixelSize: 14
            }
            TextField {
                id: passwordField
                echoMode: TextInput.Password
                placeholderText: "Password"
                font.family: "Consolas"
                font.pixelSize: 14
                Layout.fillWidth: true
                onAccepted: passwordDialog.accept()
            }
        }
    }
    
    // Error dialog
    Dialog {
        id: errorDialog
        title: "Error"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        footer: DialogButtonBox {
            Button {
                text: "OK"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
        
        Label {
            text: "Incorrect password!"
            font.family: "Consolas"
            font.pixelSize: 14
            color: "#e74c3c"
        }
    }
    
    // Success dialog
    Dialog {
        id: successDialog
        title: "Success"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        footer: DialogButtonBox {
            Button {
                text: "OK"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
        
        onAccepted: {
            selectedPort = ""
            selectedDrone = ""
        }
        
        Label {
            text: "Firmware flashed successfully!"
            font.family: "Consolas"
            font.pixelSize: 14
            color: "#27ae60"
        }
    }
    
    // Validation error dialog
    Dialog {
        id: validationDialog
        title: "Validation Error"
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        
        property string message: ""
        
        footer: DialogButtonBox {
            Button {
                text: "OK"
                DialogButtonBox.buttonRole: DialogButtonBox.AcceptRole
            }
        }
        
        Label {
            text: validationDialog.message
            font.family: "Consolas"
            font.pixelSize: 14
            color: "#e67e22"
        }
    }
    
    onVisibleChanged: { 
        if (visible) {
            refreshPorts()
        }
    }
    
    Component.onCompleted: {
        console.log("🚀 Ti-Nari Firmware Installer started")
        
        // Connect to port detector signals
        if (typeof portDetector !== 'undefined') {
            console.log("✅ Port detector available")
            portDetector.portsChanged.connect(function() { 
                console.log("✅ Ports changed:", portDetector.portCount) 
            })
            portDetector.scanCompleted.connect(function() { 
                console.log("✅ Scan completed!") 
            })
        } else {
            console.log("❌ Port detector not available!")
        }
        
        // Connect to firmware flasher signals
        if (typeof firmwareFlasher !== 'undefined') {
            console.log("✅ Firmware flasher available")
            firmwareFlasher.flashProgress.connect(onFlashProgress)
            firmwareFlasher.flashStatus.connect(onFlashStatus)
            firmwareFlasher.flashCompleted.connect(onFlashCompleted)
            firmwareFlasher.flashError.connect(onFlashError)
        } else {
            console.log("❌ Firmware flasher not available!")
        }
        
        refreshPorts()
    }
    
    function refreshPorts() {
        if (typeof portDetector !== 'undefined') {
            console.log("🔄 Refreshing ports...")
            portDetector.refreshPorts()
        } else {
            console.log("❌ Cannot refresh ports - portDetector not available")
        }
    }
    
    function startFlashing(droneName) {
        console.log("\n" + "=".repeat(60))
        console.log("🚀 STARTING FIRMWARE FLASH")
        console.log("=".repeat(60))
        
        // Validation 1: Check if port is selected
        if (!selectedPort) {
            console.log("❌ Validation failed: No port selected")
            validationDialog.message = "Please select a device from Available Devices"
            validationDialog.open()
            return
        }
        console.log("✅ Port selected:", selectedPort)
        
        // Validation 2: Check if drone is selected
        if (!droneName) {
            console.log("❌ Validation failed: No drone selected")
            validationDialog.message = "Please select a drone type"
            validationDialog.open()
            return
        }
        console.log("✅ Drone selected:", droneName)
        
        // Validation 3: Check if drone is unlocked
        if (!unlockedDrones[droneName]) {
            console.log("❌ Validation failed: Drone not unlocked")
            validationDialog.message = "Please unlock the drone first by entering password"
            validationDialog.open()
            return
        }
        console.log("✅ Drone unlocked:", droneName)
        
        // Validation 4: Check if firmware flasher is available
        if (typeof firmwareFlasher === 'undefined' || !firmwareFlasher) {
            console.log("❌ CRITICAL: Firmware flasher backend not available!")
            validationDialog.message = "Firmware flasher backend not initialized.\nPlease restart the application."
            validationDialog.open()
            return
        }
        console.log("✅ Firmware flasher backend available")
        
        console.log("\n📋 Flash Configuration:")
        console.log("   Port:", selectedPort)
        console.log("   Drone:", droneName)
        console.log("   Cube Type:", selectedCubeType)
        
        // Map full drone names to short names for firmware file lookup
        var droneNameMap = {
            "Ti-Shadow": "Shadow",
            "Spider Drone": "Spider",
            "Kala Drone": "Kala",
            "Palyanka Drone": "Palyanka",
            "Chakrayukhan Drone": "Chakrayukhan"
        }
        
        var shortDroneName = droneNameMap[droneName] || droneName
        console.log("   Mapped name:", shortDroneName)
        
        // Open flash progress dialog
        flashProgressDialog.isFlashing = true
        flashProgressBar.value = 0
        flashStatusText.text = "Initializing flash process...\n"
        flashProgressText.text = "0%"
        flashProgressDialog.open()
        
        console.log("\n🔄 Calling firmwareFlasher.flashFirmware()...")
        console.log("   Parameters:")
        console.log("      - port:", selectedPort)
        console.log("      - drone:", shortDroneName)
        console.log("      - cubeType:", selectedCubeType)
        
        try {
            // Call the backend flash function
            firmwareFlasher.flashFirmware(selectedPort, shortDroneName, selectedCubeType)
            console.log("✅ Flash process initiated successfully")
        } catch (error) {
            console.log("❌ ERROR calling flashFirmware:", error)
            flashStatusText.text += "\n❌ ERROR: " + error + "\n"
            flashProgressDialog.isFlashing = false
        }
    }
    
    function onFlashProgress(progress) {
        console.log("📊 Progress:", progress + "%")
        flashProgressBar.value = progress
        flashProgressText.text = progress + "%"
    }
    
    function onFlashStatus(status) {
        console.log("📝 Status:", status)
        flashStatusText.text += status + "\n"
        // Auto-scroll to bottom
        flashStatusText.cursorPosition = flashStatusText.length
    }
    
    function onFlashCompleted(success, message) {
        console.log("\n" + "=".repeat(60))
        if (success) {
            console.log("✅ FLASH COMPLETED SUCCESSFULLY")
        } else {
            console.log("❌ FLASH FAILED")
        }
        console.log("=".repeat(60))
        console.log("Message:", message)
        
        flashProgressDialog.isFlashing = false
        
        if (success) {
            flashStatusText.text += "\n✅ " + message + "\n"
            flashStatusText.text += "\n🔄 Device will reboot with new firmware...\n"
            successTimer.start()
        } else {
            flashStatusText.text += "\n❌ " + message + "\n"
        }
    }
    
    function onFlashError(error) {
        console.log("❌ FLASH ERROR:", error)
        flashStatusText.text += "\n❌ ERROR: " + error + "\n"
        flashProgressDialog.isFlashing = false
    }
    
    Timer {
        id: successTimer
        interval: 2000
        onTriggered: {
            flashProgressDialog.close()
            successDialog.open()
        }
    }
    
    RowLayout {
        anchors.fill: parent
        spacing: 0
        
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#ffffff"
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 20
                
                // Left panel - Device Selection
                Rectangle {
                    Layout.preferredWidth: 700
                    Layout.fillHeight: true
                    color: "#ffffff"
                    border.color: "#bdc3c7"
                    border.width: 1
                    radius: 5
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15
                        
                        Label {
                            text: "Flash Firmware"
                            font.pixelSize: 18
                            font.family: "Consolas"
                            font.bold: true
                            color: "#2c3e50"
                        }
                        
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            Repeater {
                                model: [{lbl: "Category", opts: ["All Categories"]}, 
                                        {lbl: "Platform", opts: ["All Platforms"]}, 
                                        {lbl: "Mav Type", opts: ["All Types"]}, 
                                        {lbl: "Version", opts: ["Latest"]}]
                                delegate: ColumnLayout {
                                    Layout.preferredWidth: index < 3 ? 140 : -1
                                    Layout.fillWidth: index === 3
                                    spacing: 5
                                    Label {
                                        text: modelData.lbl
                                        font.pixelSize: 12
                                        font.family: "Consolas"
                                        color: "#7f8c8d"
                                    }
                                    ComboBox {
                                        Layout.fillWidth: true
                                        model: modelData.opts
                                        font.family: "Consolas"
                                        font.pixelSize: 11
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 180
                            color: "#ffffff"
                            border.color: "#bdc3c7"
                            border.width: 1
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 35
                                    color: "#34495e"
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10
                                        Repeater {
                                            model: [{txt: "Board-ID", w: 80}, {txt: "Manufacturer", w: 100}, 
                                                    {txt: "Brand", w: 80}, {txt: "FW-Type", w: 80}, {txt: "FileName", w: -1}]
                                            delegate: Label {
                                                text: modelData.txt
                                                color: "white"
                                                font.pixelSize: 11
                                                font.family: "Consolas"
                                                font.bold: true
                                                Layout.preferredWidth: modelData.w > 0 ? modelData.w : undefined
                                                Layout.fillWidth: modelData.w < 0
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    color: "#f8f9fa"
                                }
                            }
                        }
                        
                        RowLayout {
                            spacing: 10
                            Button {
                                text: "Download"
                                enabled: false
                                background: Rectangle {
                                    color: "#95a5a6"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    font.family: "Consolas"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            Button {
                                text: "Flash Local Firmware"
                                enabled: false
                                background: Rectangle {
                                    color: "#95a5a6"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 14
                                    font.family: "Consolas"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            Item { Layout.fillWidth: true }
                        }
                        
                        Label {
                            text: "Available Devices"
                            font.pixelSize: 18
                            font.family: "Consolas"
                            font.bold: true
                            color: "#2c3e50"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: selectedPort ? "#d5f4e6" : "#fff3cd"
                            border.color: selectedPort ? "#27ae60" : "#f39c12"
                            border.width: 2
                            radius: 4
                            visible: true
                            
                            Label {
                                anchors.centerIn: parent
                                text: selectedPort ? "✓ Selected: " + selectedPort : "⚠ No device selected"
                                font.pixelSize: 13
                                font.family: "Consolas"
                                font.bold: true
                                color: selectedPort ? "#27ae60" : "#f39c12"
                            }
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: "#ffffff"
                            border.color: "#bdc3c7"
                            border.width: 1
                            
                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0
                                
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 35
                                    color: "#34495e"
                                    
                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10
                                        Repeater {
                                            model: [{txt: "Select", w: 60}, {txt: "Port", w: 70}, {txt: "Description", w: -1}, 
                                                    {txt: "Manufacturer", w: 90}, {txt: "Location", w: 90}, 
                                                    {txt: "Vendor-ID", w: 70}, {txt: "Product-ID", w: 70}]
                                            delegate: Label {
                                                text: modelData.txt
                                                color: "white"
                                                font.pixelSize: 11
                                                font.family: "Consolas"
                                                font.bold: true
                                                Layout.preferredWidth: modelData.w > 0 ? modelData.w : undefined
                                                Layout.fillWidth: modelData.w < 0
                                            }
                                        }
                                    }
                                }
                                
                                ScrollView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true
                                    
                                    ListView {
                                        id: portListView
                                        model: portDetector ? portDetector.availablePorts : []
                                        spacing: 0
                                        delegate: Rectangle {
                                            width: portListView.width
                                            height: 40
                                            color: {
                                                if (modelData && modelData.portName === selectedPort) return "#b3e5fc"
                                                return index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                                            }
                                            
                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                onEntered: {
                                                    if (modelData && modelData.portName !== selectedPort) {
                                                        parent.color = "#e3f2fd"
                                                    }
                                                }
                                                onExited: {
                                                    if (modelData && modelData.portName === selectedPort) {
                                                        parent.color = "#b3e5fc"
                                                    } else {
                                                        parent.color = index % 2 === 0 ? "#ffffff" : "#f8f9fa"
                                                    }
                                                }
                                            }
                                            
                                            RowLayout {
                                                anchors.fill: parent
                                                anchors.leftMargin: 10
                                                anchors.rightMargin: 10
                                                spacing: 10
                                                
                                                RadioButton {
                                                    Layout.preferredWidth: 60
                                                    checked: modelData && modelData.portName === selectedPort
                                                    onClicked: {
                                                        if (modelData) {
                                                            selectedPort = modelData.portName
                                                            selectedPortInfo = modelData
                                                            console.log("✅ Selected port:", selectedPort)
                                                        }
                                                    }
                                                }
                                                
                                                Label {
                                                    text: modelData && modelData.portName ? modelData.portName : "N/A"
                                                    font.pixelSize: 11
                                                    font.family: "Consolas"
                                                    color: "#2c3e50"
                                                    Layout.preferredWidth: 70
                                                    elide: Text.ElideRight
                                                }
                                                Label {
                                                    text: modelData && modelData.description ? modelData.description : "Unknown Device"
                                                    font.pixelSize: 11
                                                    font.family: "Consolas"
                                                    color: "#34495e"
                                                    Layout.fillWidth: true
                                                    elide: Text.ElideRight
                                                }
                                                Label {
                                                    text: modelData && modelData.manufacturer ? modelData.manufacturer : "-"
                                                    font.pixelSize: 11
                                                    font.family: "Consolas"
                                                    color: "#7f8c8d"
                                                    Layout.preferredWidth: 90
                                                    elide: Text.ElideRight
                                                }
                                                Label {
                                                    text: modelData && modelData.systemLocation ? modelData.systemLocation : "N/A"
                                                    font.pixelSize: 10
                                                    font.family: "Consolas"
                                                    color: "#95a5a6"
                                                    Layout.preferredWidth: 90
                                                    elide: Text.ElideRight
                                                }
                                                Label {
                                                    text: (modelData && modelData.vendorIdentifier && modelData.vendorIdentifier !== 0) ? "0x" + modelData.vendorIdentifier.toString(16).toUpperCase().padStart(4, '0') : "-"
                                                    font.pixelSize: 10
                                                    font.family: "Consolas"
                                                    color: "#95a5a6"
                                                    Layout.preferredWidth: 70
                                                }
                                                Label {
                                                    text: (modelData && modelData.productIdentifier && modelData.productIdentifier !== 0) ? "0x" + modelData.productIdentifier.toString(16).toUpperCase().padStart(4, '0') : "-"
                                                    font.pixelSize: 10
                                                    font.family: "Consolas"
                                                    color: "#95a5a6"
                                                    Layout.preferredWidth: 70
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        RowLayout {
                            spacing: 10
                            Button {
                                text: "Download BRD Files"
                                enabled: false
                                background: Rectangle {
                                    color: "#95a5a6"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 11
                                    font.family: "Consolas"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            Button {
                                text: "Flash Local Firmware"
                                enabled: false
                                background: Rectangle {
                                    color: "#95a5a6"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 11
                                    font.family: "Consolas"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                            Button {
                                text: "Refresh"
                                background: Rectangle {
                                    color: parent.hovered ? "#27ae60" : "#2ecc71"
                                    radius: 3
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: 11
                                    font.family: "Consolas"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: refreshPorts()
                            }
                            Item { Layout.fillWidth: true }
                        }
                    }
                }
                
                // Right panel - Drone Selection
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#ffffff"
                    border.color: "#bdc3c7"
                    border.width: 1
                    radius: 5
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 15
                        spacing: 15
                        
                        Label {
                            text: "Select Drone Type"
                            font.pixelSize: 18
                            font.family: "Consolas"
                            font.bold: true
                            color: "#2c3e50"
                        }
                        
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 40
                            color: selectedDrone ? "#d5f4e6" : "#fff3cd"
                            border.color: selectedDrone ? "#27ae60" : "#f39c12"
                            border.width: 2
                            radius: 4
                            
                            Label {
                                anchors.centerIn: parent
                                text: selectedDrone ? "✓ Selected: " + selectedDrone : "⚠ No drone selected"
                                font.pixelSize: 13
                                font.family: "Consolas"
                                font.bold: true
                                color: selectedDrone ? "#27ae60" : "#f39c12"
                            }
                        }
                        
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            
                            ColumnLayout {
                                width: parent.width - 20
                                spacing: 15
                                
                                Repeater {
                                    id: droneRepeater
                                    model: [
                                        {name: "Ti-Shadow", subtitle: "Surveillance Drone", image: "ti-shadow.png", password: "tishadow@123"}, 
                                        {name: "Spider Drone", subtitle: "Hexacopter Drone", image: "spider.png", password: "spider@123"}, 
                                        {name: "Kala Drone", subtitle: "Payload Dropping Drone", image: "Kala.png", password: "kala@123"}, 
                                        {name: "Palyanka Drone", subtitle: "Air Taxi", image: "Palyanak.png", password: "palyanka@123"}, 
                                        {name: "Chakrayukhan Drone", subtitle: "Heavy Payload Cargo Drone", image: "Chakravyuh.png", password: "chakravyuh@123"}
                                    ]
                                    
                                    delegate: Rectangle {
                                        id: droneCard
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 130
                                        color: {
                                            if (modelData.name === selectedDrone) return "#b3e5fc"
                                            return "#f8f9fa"
                                        }
                                        border.color: modelData.name === selectedDrone ? "#2196F3" : "#dee2e6"
                                        border.width: modelData.name === selectedDrone ? 3 : 1
                                        radius: 5
                                        
                                        property bool isUnlocked: unlockedDrones[modelData.name] || false
                                        
                                        function updateUnlockState() {
                                            isUnlocked = unlockedDrones[modelData.name] || false
                                        }
                                        
                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.margins: 12
                                            spacing: 15
                                            
                                            Image {
                                                source: "file:///home/tihan_012/Videos/Tfly_V1.0.1/App/resources/firmware/" + modelData.image
                                                Layout.preferredWidth: 100
                                                Layout.preferredHeight: 100
                                                fillMode: Image.PreserveAspectFit
                                                
                                                Rectangle {
                                                    anchors.fill: parent
                                                    color: "transparent"
                                                    border.color: "#bdc3c7"
                                                    border.width: 1
                                                    radius: 3
                                                    visible: parent.status === Image.Error
                                                    
                                                    Label {
                                                        anchors.centerIn: parent
                                                        text: "No Image"
                                                        font.family: "Consolas"
                                                        font.pixelSize: 10
                                                        color: "#95a5a6"
                                                    }
                                                }
                                            }
                                            
                                            ColumnLayout {
                                                Layout.fillWidth: true
                                                spacing: 3
                                                Label {
                                                    text: modelData.name
                                                    font.pixelSize: 13
                                                    font.family: "Consolas"
                                                    font.bold: true
                                                    color: "#2980b9"
                                                }
                                                Label {
                                                    text: modelData.subtitle
                                                    font.pixelSize: 11
                                                    font.family: "Consolas"
                                                    color: "#7f8c8d"
                                                    wrapMode: Text.WordWrap
                                                    Layout.fillWidth: true
                                                }
                                            }
                                            
                                            Button {
                                                id: unlockBtn
                                                text: droneCard.isUnlocked ? "✓ UNLOCKED" : "🔒 UNLOCK"
                                                Layout.preferredWidth: 110
                                                Layout.preferredHeight: 35
                                                background: Rectangle {
                                                    color: droneCard.isUnlocked ? "#27ae60" : (parent.hovered ? "#c0392b" : "#e74c3c")
                                                    radius: 4
                                                }
                                                contentItem: Text {
                                                    text: parent.text
                                                    color: "white"
                                                    font.pixelSize: 11
                                                    font.family: "Consolas"
                                                    font.bold: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                onClicked: {
                                                    if (!droneCard.isUnlocked) {
                                                        passwordDialog.droneName = modelData.name
                                                        passwordDialog.correctPassword = modelData.password
                                                        passwordDialog.droneIndex = index
                                                        passwordDialog.open()
                                                    }
                                                }
                                            }
                                            
                                            Button {
                                                text: "✓ INSTALL"
                                                Layout.preferredWidth: 110
                                                Layout.preferredHeight: 35
                                                enabled: droneCard.isUnlocked
                                                background: Rectangle {
                                                    color: droneCard.isUnlocked ? (parent.hovered ? "#2980b9" : "#3498db") : "#95a5a6"
                                                    radius: 4
                                                }
                                                contentItem: Text {
                                                    text: parent.text
                                                    color: "white"
                                                    font.pixelSize: 11
                                                    font.family: "Consolas"
                                                    font.bold: true
                                                    horizontalAlignment: Text.AlignHCenter
                                                    verticalAlignment: Text.AlignVCenter
                                                }
                                                onClicked: {
                                                    console.log("🔘 INSTALL button clicked for: " + modelData.name)
                                                    selectedDrone = modelData.name
                                                    cubeTypeDialog.selectedDroneName = modelData.name
                                                    cubeTypeDialog.open()
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
