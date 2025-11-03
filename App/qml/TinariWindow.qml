import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs 1.3
import QtGraphicalEffects 1.15

ApplicationWindow {
    id: root
    visible: true; visibility: "Maximized"; title: "⚙️ Ti-NARI Firmware Flasher"; color: "#f5f5f5"
    property string selectedFile: ""; property string selectedPort: ""
    property int baudBoot: 115200; property int baudFlash: 115200; property string selectedDrone: ""
    
    // Define base path for resources - going up from qml/ folder to App/ folder
    property string resourcePath: Qt.resolvedUrl("../resources/firmware/")

    Rectangle { anchors.fill: parent; color: "#f0f4f8" }

    RowLayout {
        anchors.fill: parent; anchors.margins: 25; spacing: 25

        // LEFT PANEL
        Item {
            Layout.fillHeight: true; Layout.preferredWidth: parent.width * 0.62
            DropShadow { anchors.fill: contentFrame; radius: 12; samples: 20; color: "#40000000"; source: contentFrame }
            Rectangle {
                id: contentFrame
                anchors.fill: parent; radius: 16; color: "#ffffff"; border.color: "#00BCD4"; border.width: 2
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 16
                    Text { text: "🛠️ Ti-NARI Firmware Flasher"; font.pixelSize: 32; color: "#00838F"; font.bold: true; horizontalAlignment: Text.AlignHCenter; Layout.alignment: Qt.AlignHCenter }
                    Rectangle { height: 2; color: "#00BCD4"; opacity: 0.3; Layout.fillWidth: true }
                    Text { text: "Select Serial Port:"; color: "#34495e"; font.pixelSize: 16; font.bold: true }
                    
                    Rectangle {
                        Layout.fillWidth: true; Layout.preferredHeight: 200; color: "#ffffff"; border.color: "#cbd5e0"; border.width: 2; radius: 10
                        ColumnLayout {
                            anchors.fill: parent; anchors.margins: 0; spacing: 0
                            Rectangle {
                                Layout.fillWidth: true; height: 40; color: "#34495e"; radius: 8
                                RowLayout {
                                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 0
                                    Text { text: "Port"; color: "#ffffff"; font.pixelSize: 13; font.bold: true; Layout.preferredWidth: 100 }
                                    Text { text: "Board ID"; color: "#ffffff"; font.pixelSize: 13; font.bold: true; Layout.preferredWidth: 120 }
                                    Text { text: "Manufacturer"; color: "#ffffff"; font.pixelSize: 13; font.bold: true; Layout.preferredWidth: 130 }
                                    Text { text: "Brand"; color: "#ffffff"; font.pixelSize: 13; font.bold: true; Layout.preferredWidth: 100 }
                                    Text { text: "FW-Type"; color: "#ffffff"; font.pixelSize: 13; font.bold: true; Layout.preferredWidth: 100 }
                                    Text { text: "Filename"; color: "#ffffff"; font.pixelSize: 13; font.bold: true; Layout.fillWidth: true }
                                }
                            }
                            ScrollView {
                                Layout.fillWidth: true; Layout.fillHeight: true; clip: true; ScrollBar.vertical.policy: ScrollBar.AsNeeded
                                ListView { id: portListView; anchors.fill: parent; model: portModel; delegate: portDelegate }
                            }
                        }
                    }

                    ListModel {
                        id: portModel
                        ListElement { port: "ttyACM0"; boardId: "0x2dae"; manufacturer: "CubePilot"; brand: "CubeOrange+"; fwType: ""; filename: "" }
                        ListElement { port: "ttyACM1"; boardId: "0x2dae"; manufacturer: "CubePilot"; brand: "CubeOrange+"; fwType: ""; filename: "" }
                        ListElement { port: "tty50"; boardId: ""; manufacturer: ""; brand: ""; fwType: ""; filename: "" }
                        ListElement { port: "tty51"; boardId: ""; manufacturer: ""; brand: ""; fwType: ""; filename: "" }
                        ListElement { port: "ttyS10"; boardId: ""; manufacturer: ""; brand: ""; fwType: ""; filename: "" }
                        ListElement { port: "ttyS11"; boardId: ""; manufacturer: ""; brand: ""; fwType: ""; filename: "" }
                    }

                    Component {
                        id: portDelegate
                        Rectangle {
                            width: portListView.width; height: 45
                            color: portMouseArea.containsMouse ? "#e3f2fd" : (index % 2 === 0 ? "#ffffff" : "#f8f9fa")
                            border.color: selectedPort === "/dev/" + model.port ? "#00BCD4" : "transparent"; border.width: 2
                            MouseArea {
                                id: portMouseArea; anchors.fill: parent; hoverEnabled: true
                                onClicked: { selectedPort = "/dev/" + model.port; logArea.append("📍 Selected port: " + selectedPort + "\n") }
                            }
                            RowLayout {
                                anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 0
                                Text { text: model.port; color: "#2c3e50"; font.pixelSize: 12; font.family: "Consolas"; Layout.preferredWidth: 100 }
                                Text { text: model.boardId; color: "#2c3e50"; font.pixelSize: 12; font.family: "Consolas"; Layout.preferredWidth: 120 }
                                Text { text: model.manufacturer; color: "#2c3e50"; font.pixelSize: 12; Layout.preferredWidth: 130 }
                                Text { text: model.brand; color: "#2c3e50"; font.pixelSize: 12; Layout.preferredWidth: 100 }
                                Text { text: model.fwType; color: "#2c3e50"; font.pixelSize: 12; Layout.preferredWidth: 100 }
                                Text { text: model.filename; color: "#2c3e50"; font.pixelSize: 11; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }
                    }

                    FileDialog { 
                        id: droneFileDialog; 
                        title: "Select Firmware File for " + selectedDrone; 
                        nameFilters: ["Firmware Files (*.apj)", "All Files (*)"]
                        onAccepted: { 
                            selectedFile = droneFileDialog.fileUrl.toString().replace("file://", ""); 
                            logArea.append("📦 Selected firmware for " + selectedDrone + ": " + selectedFile + "\n");
                            startFlashProcess();
                        }
                    }

                    GridLayout {
                        columns: 2; Layout.fillWidth: true; columnSpacing: 20; rowSpacing: 12
                        Label { text: "Bootloader Baud:"; color: "#34495e"; font.pixelSize: 15; font.bold: true }
                        ComboBox {
                            id: baudBootCombo; Layout.fillWidth: true; font.pixelSize: 14; font.family: "Consolas"; model: [115200, 230400, 460800, 921600]
                            background: Rectangle { color: "#f8f9fa"; radius: 10; border.color: baudBootCombo.activeFocus ? "#00BCD4" : "#cbd5e0"; border.width: 2 }
                            contentItem: Text { text: baudBootCombo.displayText; font: baudBootCombo.font; color: "#2c3e50"; verticalAlignment: Text.AlignVCenter; leftPadding: 12 }
                            onCurrentTextChanged: baudBoot = parseInt(currentText)
                        }
                        Label { text: "Flash Baud:"; color: "#34495e"; font.pixelSize: 15; font.bold: true }
                        ComboBox {
                            id: baudFlashCombo; Layout.fillWidth: true; font.pixelSize: 14; font.family: "Consolas"; model: [115200, 230400, 460800, 921600]
                            background: Rectangle { color: "#f8f9fa"; radius: 10; border.color: baudFlashCombo.activeFocus ? "#00BCD4" : "#cbd5e0"; border.width: 2 }
                            contentItem: Text { text: baudFlashCombo.displayText; font: baudFlashCombo.font; color: "#2c3e50"; verticalAlignment: Text.AlignVCenter; leftPadding: 12 }
                            onCurrentTextChanged: baudFlash = parseInt(currentText)
                        }
                    }

                    Text { text: "Flashing Log:"; color: "#34495e"; font.pixelSize: 16; font.bold: true }
                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true; ScrollBar.vertical.policy: ScrollBar.AlwaysOn
                        TextArea {
                            id: logArea; readOnly: true; wrapMode: TextArea.WrapAnywhere; font.family: "Consolas"; font.pixelSize: 14; color: "#2ecc71"; textFormat: TextEdit.PlainText
                            background: Rectangle { color: "#1a1a1a"; border.color: "#00BCD4"; border.width: 2; radius: 10 }
                            onTextChanged: contentY = contentHeight - height
                        }
                    }

                    Text { text: "Erase Progress:"; color: "#34495e"; font.pixelSize: 16; font.bold: true }
                    ProgressBar {
                        id: eraseProgress; Layout.fillWidth: true; from: 0; to: 100; height: 14
                        background: Rectangle { color: "#e0e0e0"; radius: 7; border.color: "#bdbdbd"; border.width: 1 }
                        contentItem: Rectangle { color: "#FF9800"; radius: 7; width: eraseProgress.visualPosition * eraseProgress.width; height: eraseProgress.height; Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } } }
                    }
                    Text { text: "Write Progress:"; color: "#34495e"; font.pixelSize: 16; font.bold: true }
                    ProgressBar {
                        id: writeProgress; Layout.fillWidth: true; from: 0; to: 100; height: 14
                        background: Rectangle { color: "#e0e0e0"; radius: 7; border.color: "#bdbdbd"; border.width: 1 }
                        contentItem: Rectangle { color: "#00BCD4"; radius: 7; width: writeProgress.visualPosition * writeProgress.width; height: writeProgress.height; Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } } }
                    }
                }
            }
        }

        // RIGHT PANEL
        Item {
            Layout.fillHeight: true; Layout.fillWidth: true
            DropShadow { anchors.fill: dronePanel; radius: 20; samples: 25; color: "#80000000"; source: dronePanel }
            Rectangle {
                id: dronePanel
                anchors.fill: parent; radius: 16; color: "#ffffff"; border.color: "#00BCD4"; border.width: 2
                ColumnLayout {
                    anchors.fill: parent; anchors.margins: 24; spacing: 16
                    Text { text: "Select Drone Type"; font.pixelSize: 24; color: "#00838F"; font.bold: true; Layout.alignment: Qt.AlignLeft }
                    Rectangle { height: 2; color: "#00BCD4"; opacity: 0.3; Layout.fillWidth: true }
                    ScrollView {
                        Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                        ColumnLayout {
                            id: droneList; width: parent.width; spacing: 14
                            Repeater {
                                id: droneRepeater
                                model: [
                                    {name: "Ti-Shadow", desc: "Surveillance Drone", icon: "ti-shadow.png", subdesc: ""},
                                    {name: "Spider Drone", desc: "Hexacopter Drone", icon: "spider.png", subdesc: ""},
                                    {name: "Kala Drone", desc: "Payload Dropping Drone", icon: "Kala.png", subdesc: ""},
                                    {name: "Palyanka Drone", desc: "Air Taxi", icon: "palyanka.png", subdesc: ""},
                                    {name: "Chakrayukhan Drone", desc: "Heavy Payload Cargo Drone", icon: "Chakravyuh.png", subdesc: "Industrial-grade heavy lifting"}
                                ]
                                DroneCard {
                                    Layout.fillWidth: true; droneName: modelData.name; droneDesc: modelData.desc; droneIcon: root.resourcePath + modelData.icon; droneSubDesc: modelData.subdesc; isLocked: true
                                    onInstallClicked: { 
                                        selectedDrone = modelData.name;
                                        if (selectedPort === "") {
                                            logArea.append("⚠️ Please select a port first before installing " + modelData.name + " firmware!\n");
                                            return;
                                        }
                                        logArea.append("📦 Installing " + modelData.name + " firmware...\n");
                                        logArea.append("📍 Using port: " + selectedPort + "\n");
                                        droneFileDialog.open();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    function startFlashProcess() {
        eraseProgress.value = 0; 
        writeProgress.value = 0; 
        logArea.append("🚀 Starting flash on " + selectedPort + "\n");
        if (selectedDrone !== "") {
            logArea.append("📡 Flashing firmware for: " + selectedDrone + "\n");
        }
        firmwareFlasher.startFlash(selectedPort, baudBoot, baudFlash, selectedFile);
    }

    Connections {
        target: firmwareFlasher
        function onLogMessage(msg) { logArea.append(msg + "\n") }
        function onEraseValue(v) { eraseProgress.value = v }
        function onWriteValue(v) { writeProgress.value = v }
        function onFlashFinished(success) { eraseProgress.value = 100; writeProgress.value = 100; logArea.append(success ? "✅ Flash completed successfully!\n" : "❌ Flash failed!\n") }
    }

    Rectangle {
        id: passwordDialog; visible: false; anchors.centerIn: parent; width: 350; height: 180; radius: 12; color: "#ffffff"; border.color: "#00BCD4"; border.width: 2; z: 1000
        property string targetDrone: ""
        function open() { visible = true; passwordField.focus = true }
        function close() { visible = false; passwordField.text = "" }
        Rectangle { anchors.fill: parent; color: "#40000000"; z: -1; anchors.margins: -10000; visible: passwordDialog.visible }
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 20; spacing: 15
            Text { text: "🔒 Enter Password"; font.pixelSize: 18; font.bold: true; color: "#00838F"; Layout.alignment: Qt.AlignHCenter }
            Text { text: "Unlock: " + passwordDialog.targetDrone; font.pixelSize: 14; color: "#2c3e50"; Layout.alignment: Qt.AlignHCenter }
            TextField {
                id: passwordField; placeholderText: "Enter password"; echoMode: TextInput.Password; Layout.fillWidth: true; Layout.preferredHeight: 40; font.pixelSize: 14
                background: Rectangle { color: "#f8f9fa"; radius: 8; border.color: passwordField.activeFocus ? "#00BCD4" : "#cbd5e0"; border.width: 2 }
                Keys.onReturnPressed: okButton.clicked()
            }
            RowLayout {
                Layout.fillWidth: true; spacing: 10
                Button {
                    id: okButton; text: "OK"; Layout.fillWidth: true; font.pixelSize: 14; font.bold: true
                    contentItem: Text { text: parent.text; font: parent.font; color: "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 8; color: parent.hovered ? "#00BCD4" : "#00ACC1"; border.color: "#00838F"; border.width: 2; Behavior on color { ColorAnimation { duration: 150 } } }
                    onClicked: {
                        var passwords = {"Ti-Shadow": "tishadow@123", "Spider Drone": "spider@123", "Kala Drone": "kala@123", "Palyanka Drone": "palyanka@123", "Chakrayukhan Drone": "chakravyuh@123"}
                        if (passwordField.text === passwords[passwordDialog.targetDrone]) {
                            logArea.append("✅ " + passwordDialog.targetDrone + " unlocked successfully!\n")
                            for (var i = 0; i < droneRepeater.count; i++) {
                                var item = droneRepeater.itemAt(i)
                                if (item.droneName === passwordDialog.targetDrone) { item.isLocked = false; break }
                            }
                        } else logArea.append("❌ Incorrect password for " + passwordDialog.targetDrone + "!\n")
                        passwordDialog.close()
                    }
                }
                Button {
                    text: "Cancel"; Layout.fillWidth: true; font.pixelSize: 14; font.bold: true; onClicked: passwordDialog.close()
                    contentItem: Text { text: parent.text; font: parent.font; color: "#ffffff"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 8; color: parent.hovered ? "#95a5a6" : "#7f8c8d"; border.color: "#34495e"; border.width: 2; Behavior on color { ColorAnimation { duration: 150 } } }
                }
            }
        }
    }

    component DroneCard: Rectangle {
        id: card
        property string droneName: ""; property string droneDesc: ""; property string droneSubDesc: ""; property string droneIcon: ""; property bool isLocked: true
        signal unlockClicked(); signal installClicked()
        height: droneSubDesc !== "" ? 140 : 125; radius: 12; color: "#f8f9fa"; border.color: mouseArea.containsMouse ? "#00BCD4" : "#cbd5e0"; border.width: 2
        Behavior on border.color { ColorAnimation { duration: 200 } }
        MouseArea { id: mouseArea; anchors.fill: parent; hoverEnabled: true }
        RowLayout {
            anchors.fill: parent; anchors.margins: 14; spacing: 14
            Rectangle { 
                Layout.preferredWidth: 110; Layout.preferredHeight: 110; radius: 10; color: "#ffffff"; border.color: "#00BCD4"; border.width: 2; Layout.alignment: Qt.AlignVCenter
                Image { 
                    anchors.fill: parent; 
                    anchors.margins: 5
                    source: card.droneIcon
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    antialiasing: true
                    mipmap: true
                    // Fallback to emoji if image fails to load
                    onStatusChanged: {
                        if (status === Image.Error) {
                            console.log("Failed to load image: " + card.droneIcon)
                        }
                    }
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; Layout.fillHeight: true; spacing: 6; Layout.alignment: Qt.AlignVCenter
                Text { text: card.droneName; font.pixelSize: 17; font.bold: true; color: "#2c3e50" }
                Text { text: card.droneDesc; font.pixelSize: 14; color: "#7f8c8d" }
                Text { visible: card.droneSubDesc !== ""; text: card.droneSubDesc; font.pixelSize: 12; color: "#00838F"; font.italic: true }
            }
            Item { Layout.fillWidth: true }
            RowLayout {
                spacing: 12; Layout.alignment: Qt.AlignVCenter
                Button {
                    text: card.isLocked ? "🔒 UNLOCK" : "🔓 UNLOCKED"; font.pixelSize: 12; font.bold: true; implicitWidth: 100; implicitHeight: 38; enabled: card.isLocked
                    contentItem: Text { text: parent.text; font: parent.font; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 6; implicitWidth: 100; implicitHeight: 38; color: parent.enabled ? (parent.hovered ? "#e53935" : "#f44336") : "#9E9E9E"; Behavior on color { ColorAnimation { duration: 150 } } }
                    onClicked: { passwordDialog.targetDrone = card.droneName; passwordDialog.open() }
                }
                Button {
                    text: "🔧 INSTALL"; font.pixelSize: 12; font.bold: true; implicitWidth: 100; implicitHeight: 38; enabled: !card.isLocked
                    contentItem: Text { text: parent.text; font: parent.font; color: "#FFFFFF"; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                    background: Rectangle { radius: 6; implicitWidth: 100; implicitHeight: 38; color: parent.enabled ? (parent.hovered ? "#1976D2" : "#2196F3") : "#9E9E9E"; Behavior on color { ColorAnimation { duration: 150 } } }
                    onClicked: { if (!card.isLocked) card.installClicked() }
                }
            }
        }
    }
}
