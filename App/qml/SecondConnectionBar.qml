import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.10

Rectangle {
    id: root
    height: 60
    color: "#1a1a1a" // Darker background to differentiate
    border.color: "#4a5568"
    border.width: 2

    // Properties
    property bool isConnected: droneModel ? droneModel.isSecondConnectionActive : false
    property var languageManager: null
    property string connectionName: "Secondary Connection"

    // Signal to notify when connection state changes
    signal connectionStateChanged(bool connected)

    // Watch for second connection state changes
    Connections {
        target: droneModel
        function onSecondConnectionChanged() {
            root.isConnected = droneModel.isSecondConnectionActive;
            root.connectionStateChanged(root.isConnected);
        }
    }

    // Accent line at bottom (different color for second connection)
    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 3
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#ff6b35" }
            GradientStop { position: 0.5; color: "#f7931e" }
            GradientStop { position: 1.0; color: "#ffcd3c" }
        }
        opacity: 0.6
    }

    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 25
        spacing: 20

        // Connection Name Display
        Rectangle {
            width: 180
            height: 40
            radius: 10
            color: "#2d3748"
            border.color: "#4a5568"
            border.width: 2

            Text {
                anchors.centerIn: parent
                text: root.connectionName
                font.pixelSize: 13
                font.family: "Segoe UI"
                font.weight: Font.Medium
                color: "#ffffff"
            }
        }

        // Status Display
        Rectangle {
            width: 120
            height: 40
            radius: 10
            color: "#2d3748"
            border.color: root.isConnected ? "#ff6b35" : "#4a5568"
            border.width: 2

            Behavior on border.color {
                ColorAnimation { duration: 300 }
            }

            Text {
                anchors.centerIn: parent
                text: languageManager ? 
                      languageManager.getText(root.isConnected ? "ACTIVE" : "INACTIVE") : 
                      (root.isConnected ? "ACTIVE" : "INACTIVE")
                font.pixelSize: 12
                font.family: "Segoe UI"
                font.weight: Font.Bold
                color: root.isConnected ? "#ff6b35" : "#9ca3af"

                SequentialAnimation on opacity {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.7; duration: 2000 }
                    NumberAnimation { to: 1.0; duration: 2000 }
                }
            }
        }

        // Toggle Connection Button
        Button {
            id: toggleSecondConnectionBtn
            text: languageManager ? 
                  languageManager.getText(root.isConnected ? "DISCONNECT" : "CONNECT") : 
                  (root.isConnected ? "DISCONNECT" : "CONNECT")
            width: 130
            height: 40

            enabled: droneModel ? droneModel.isConnected : false // Only enabled when main connection is active

            onClicked: {
                if (!root.isConnected && droneModel.isConnected) {
                    console.log("Activating second connection...");
                    droneModel.activateSecondConnection();
                } else if (root.isConnected) {
                    console.log("Deactivating second connection...");
                    droneModel.deactivateSecondConnection();
                }
            }

            background: Rectangle {
                radius: 10
                border.width: 2
                border.color: !toggleSecondConnectionBtn.enabled ? "#4a5568" :
                             root.isConnected ?
                             (toggleSecondConnectionBtn.pressed ? "#d53f00" : "#ff6b35") :
                             (toggleSecondConnectionBtn.pressed ? "#cc7a00" : "#f7931e")

                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: !toggleSecondConnectionBtn.enabled ? "#2d3748" :
                               root.isConnected ?
                               (toggleSecondConnectionBtn.pressed ? "#d53f00" : (toggleSecondConnectionBtn.hovered ? "#ff8555" : "#ff6b35")) :
                               (toggleSecondConnectionBtn.pressed ? "#cc7a00" : (toggleSecondConnectionBtn.hovered ? "#ffb84d" : "#f7931e"))
                    }
                    GradientStop {
                        position: 1.0
                        color: !toggleSecondConnectionBtn.enabled ? "#1a202c" :
                               root.isConnected ?
                               (toggleSecondConnectionBtn.pressed ? "#c53030" : (toggleSecondConnectionBtn.hovered ? "#fd7f28" : "#e53e3e")) :
                               (toggleSecondConnectionBtn.pressed ? "#b86c00" : (toggleSecondConnectionBtn.hovered ? "#ed8936" : "#dd6b20"))
                    }
                }

                Behavior on border.color {
                    ColorAnimation { duration: 200 }
                }
            }

            contentItem: Text {
                text: toggleSecondConnectionBtn.text
                font.pixelSize: 12
                font.family: "Segoe UI"
                font.weight: Font.Bold
                color: toggleSecondConnectionBtn.enabled ? "#ffffff" : "#9ca3af"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        // Connection Status Indicator
        Item {
            width: 40
            height: 40
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                width: 20
                height: 20
                radius: 10
                color: "transparent"
                border.color: root.isConnected ? "#ff6b35" : "#666666"
                border.width: 2
                anchors.centerIn: parent
                opacity: root.isConnected ? 0.4 : 0.2

                SequentialAnimation on scale {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.8; duration: 2000 }
                    NumberAnimation { to: 1.0; duration: 2000 }
                }

                SequentialAnimation on opacity {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.1; duration: 2000 }
                    NumberAnimation { to: 0.4; duration: 2000 }
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                anchors.centerIn: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.isConnected ? "#ff6b35" : "#666666" }
                    GradientStop { position: 1.0; color: root.isConnected ? "#f7931e" : "#444444" }
                }
                border.color: "#ffffff"
                border.width: 2

                SequentialAnimation on scale {
                    running: root.isConnected
                    loops: Animation.Infinite
                    NumberAnimation { to: 1.2; duration: 1500 }
                    NumberAnimation { to: 1.0; duration: 1500 }
                }
            }
        }

        Text {
            text: languageManager ? 
                  languageManager.getText(root.isConnected ? "SECONDARY ACTIVE" : "SECONDARY INACTIVE") : 
                  (root.isConnected ? "SECONDARY ACTIVE" : "SECONDARY INACTIVE")
            color: root.isConnected ? "#ff6b35" : "#666666"
            font.pixelSize: 12
            font.family: "Segoe UI"
            font.weight: Font.Bold
            anchors.verticalCenter: parent.verticalCenter

            SequentialAnimation on opacity {
                running: root.isConnected
                loops: Animation.Infinite
                NumberAnimation { to: 0.7; duration: 2000 }
                NumberAnimation { to: 1.0; duration: 2000 }
            }
        }
    }

    // Connection Info Display (Right side)
    Item {
        id: infoContainer
        width: 200
        height: 50
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.rightMargin: 25

        Column {
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: "SECONDARY CONNECTION"
                color: "#ff6b35"
                font.pixelSize: 10
                font.family: "Segoe UI"
                font.weight: Font.Bold
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Text {
                text: root.isConnected ? "Data Mirroring Active" : "Standby Mode"
                color: root.isConnected ? "#ffffff" : "#9ca3af"
                font.pixelSize: 9
                font.family: "Segoe UI"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }
}