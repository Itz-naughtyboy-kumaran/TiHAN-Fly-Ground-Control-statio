import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Dialog {
    id: feedbackDialog
    title: ""
    width: 500
    height: 580
    modal: true
    
    // Center on screen
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    
    property color accentColor: "#3b82f6"
    property color accentHover: "#2563eb"
    property color accentPressed: "#1d4ed8"
    property color borderColor: "#374151"
    property color successColor: "#10b981"
    property color errorColor: "#ef4444"
    property color textPrimary: "#f9fafb"
    property color textSecondary: "#d1d5db"
    property color bgPrimary: "#1f2937"
    property color bgSecondary: "#111827"
    property color bgInput: "#374151"
    
    // Remove default padding
    padding: 0
    
    background: Rectangle {
        color: "transparent"
        
        // Main card background
        Rectangle {
            anchors.fill: parent
            color: bgPrimary
            radius: 12
            border.color: borderColor
            border.width: 1
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 20
                radius: 60
                samples: 61
                color: "#60000000"
                transparentBorder: true
            }
        }
    }
    
    contentItem: ColumnLayout {
        spacing: 0
        
        // Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            radius: 12
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#2563eb" }
                GradientStop { position: 1.0; color: "#1d4ed8" }
            }
            
            ColumnLayout {
                anchors.centerIn: parent
                spacing: 2
                
                Text {
                    text: "Send Feedback"
                    font.family: "Segoe UI"
                    font.pixelSize: 22
                    font.weight: Font.Bold
                    color: "#ffffff"
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: "Help us improve your experience"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    color: "#e0e7ff"
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
        
        // Form Content
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 14
                
                // Name Field
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Text {
                        text: "Your Name *"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: textPrimary
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        color: bgInput
                        border.color: nameField.activeFocus ? accentColor : borderColor
                        border.width: nameField.activeFocus ? 2 : 1
                        radius: 8
                        
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on border.width { NumberAnimation { duration: 200 } }
                        
                        TextField {
                            id: nameField
                            anchors.fill: parent
                            anchors.margins: 1
                            placeholderText: "Enter your full name"
                            placeholderTextColor: "#9ca3af"
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                            color: textPrimary
                            verticalAlignment: TextInput.AlignVCenter
                            leftPadding: 14
                            rightPadding: 14
                            
                            background: Rectangle {
                                color: "transparent"
                            }
                        }
                    }
                }
                
                // Email Field
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Text {
                        text: "Your Email *"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: textPrimary
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        color: bgInput
                        border.color: emailField.activeFocus ? accentColor : borderColor
                        border.width: emailField.activeFocus ? 2 : 1
                        radius: 8
                        
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on border.width { NumberAnimation { duration: 200 } }
                        
                        TextField {
                            id: emailField
                            anchors.fill: parent
                            anchors.margins: 1
                            placeholderText: "your.email@example.com"
                            placeholderTextColor: "#9ca3af"
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                            color: textPrimary
                            verticalAlignment: TextInput.AlignVCenter
                            leftPadding: 14
                            rightPadding: 14
                            
                            background: Rectangle {
                                color: "transparent"
                            }
                        }
                    }
                }
                
                // Feedback Field
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 6
                    
                    Text {
                        text: "Your Feedback *"
                        font.family: "Segoe UI"
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        color: textPrimary
                    }
                    
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 100
                        color: bgInput
                        border.color: feedbackText.activeFocus ? accentColor : borderColor
                        border.width: feedbackText.activeFocus ? 2 : 1
                        radius: 8
                        
                        Behavior on border.color { ColorAnimation { duration: 200 } }
                        Behavior on border.width { NumberAnimation { duration: 200 } }
                        
                        ScrollView {
                            anchors.fill: parent
                            anchors.margins: 1
                            clip: true
                            
                            ScrollBar.vertical: ScrollBar {
                                width: 6
                                policy: ScrollBar.AsNeeded
                                
                                contentItem: Rectangle {
                                    color: accentColor
                                    radius: 3
                                    opacity: 0.5
                                }
                            }
                            
                            TextArea {
                                id: feedbackText
                                placeholderText: "Share your thoughts, suggestions, or report issues..."
                                wrapMode: TextArea.Wrap
                                font.family: "Segoe UI"
                                font.pixelSize: 13
                                color: textPrimary
                                padding: 12
                                selectByMouse: true
                                
                                background: Rectangle {
                                    color: "transparent"
                                }
                            }
                        }
                    }
                    
                    Text {
                        text: feedbackText.length + " / 2000 characters"
                        font.family: "Segoe UI"
                        font.pixelSize: 11
                        color: textSecondary
                        Layout.alignment: Qt.AlignRight
                    }
                }
                
                // Status Message
                Rectangle {
                    id: statusMessageContainer
                    Layout.fillWidth: true
                    Layout.preferredHeight: 42
                    color: statusMessage.color === successColor ? "#064e3b" : "#7f1d1d"
                    border.color: statusMessage.color === successColor ? "#059669" : "#dc2626"
                    border.width: 1
                    radius: 8
                    visible: statusMessage.text.length > 0
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            text: statusMessage.color === successColor ? "✓" : "⚠"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            id: statusMessage
                            font.family: "Segoe UI"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }
            }
        }
        
        // Footer with Buttons
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            color: bgSecondary
            radius: 12
            
            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: borderColor
            }
            
            RowLayout {
                anchors.centerIn: parent
                spacing: 12
                
                Button {
                    id: cancelButton
                    text: "Cancel"
                    font.family: "Segoe UI"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    implicitWidth: 110
                    implicitHeight: 42
                    
                    contentItem: Text {
                        text: cancelButton.text
                        font: cancelButton.font
                        color: textSecondary
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: cancelButton.pressed ? "#374151" : (cancelButton.hovered ? "#1f2937" : "transparent")
                        border.color: borderColor
                        border.width: 1.5
                        radius: 8
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    onClicked: {
                        feedbackDialog.close()
                    }
                }
                
                Button {
                    id: sendButton
                    text: "✉  Send Feedback"
                    font.family: "Segoe UI"
                    font.pixelSize: 14
                    font.weight: Font.Bold
                    implicitWidth: 170
                    implicitHeight: 42
                    enabled: nameField.text.length > 0 && 
                             emailField.text.length > 0 && 
                             feedbackText.text.length > 0
                    
                    contentItem: Text {
                        text: sendButton.text
                        font: sendButton.font
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    background: Rectangle {
                        color: {
                            if (!sendButton.enabled) return "#6b7280"
                            if (sendButton.pressed) return accentPressed
                            if (sendButton.hovered) return accentHover
                            return accentColor
                        }
                        radius: 8
                        
                        Behavior on color { ColorAnimation { duration: 150 } }
                        
                        layer.enabled: sendButton.enabled
                        layer.effect: DropShadow {
                            horizontalOffset: 0
                            verticalOffset: 4
                            radius: 12
                            samples: 25
                            color: sendButton.pressed ? "#00000000" : "#40000000"
                            transparentBorder: true
                        }
                    }
                    
                    onClicked: {
                        statusMessage.text = "Sending feedback..."
                        statusMessage.color = accentColor
                        sendButton.enabled = false
                        
                        emailSender.sendFeedback(
                            nameField.text,
                            emailField.text,
                            feedbackText.text
                        )
                    }
                }
            }
        }
    }
    
    Connections {
        target: emailSender
        
        function onEmailSent(success, message) {
            statusMessage.text = message
            statusMessage.color = success ? successColor : errorColor
            sendButton.enabled = true
            
            if (success) {
                closeTimer.start()
            }
        }
    }
    
    Timer {
        id: closeTimer
        interval: 2000
        onTriggered: {
            feedbackDialog.close()
            nameField.text = ""
            emailField.text = ""
            feedbackText.text = ""
            statusMessage.text = ""
        }
    }
    
    onOpened: {
        nameField.text = ""
        emailField.text = ""
        feedbackText.text = ""
        statusMessage.text = ""
        sendButton.enabled = true
        nameField.forceActiveFocus()
    }
}