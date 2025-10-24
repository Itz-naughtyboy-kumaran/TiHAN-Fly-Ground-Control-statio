
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 400
    height: 500
    title: "Drone Telemetry - Login"
    
    property bool isLoginMode: true
    
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#2c3e50" }
            GradientStop { position: 1.0; color: "#34495e" }
        }
        
        ColumnLayout {
            anchors.centerIn: parent
            spacing: 20
            width: parent.width * 0.8
            
            Text {
                text: "DRONE TELEMETRY SYSTEM"
                color: "white"
                font.pixelSize: 24
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            Text {
                text: isLoginMode ? "LOGIN" : "SIGN UP"
                color: "#3498db"
                font.pixelSize: 20
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
            
            TextField {
                id: usernameField
                placeholderText: "Username"
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: "white"
                    radius: 5
                }
            }
            
            TextField {
                id: passwordField
                placeholderText: "Password"
                echoMode: TextInput.Password
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                background: Rectangle {
                    color: "white"
                    radius: 5
                }
            }
            
            Button {
                text: isLoginMode ? "LOGIN" : "SIGN UP"
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                background: Rectangle {
                    color: parent.pressed ? "#2980b9" : "#3498db"
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (isLoginMode) {
                        userManager.login_user(usernameField.text, passwordField.text)
                    } else {
                        userManager.signup_user(usernameField.text, passwordField.text)
                    }
                }
            }
            
            Button {
                text: isLoginMode ? "Don't have an account? Sign Up" : "Already have an account? Login"
                Layout.fillWidth: true
                Layout.preferredHeight: 35
                background: Rectangle {
                    color: "transparent"
                    border.color: "#3498db"
                    border.width: 1
                    radius: 5
                }
                contentItem: Text {
                    text: parent.text
                    color: "#3498db"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    isLoginMode = !isLoginMode
                    usernameField.text = ""
                    passwordField.text = ""
                    statusText.text = ""
                }
            }
            
            Text {
                id: statusText
                color: "#e74c3c"
                Layout.alignment: Qt.AlignHCenter
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
    
    Connections {
        target: userManager
        function onLoginSuccess() {
            statusText.color = "#27ae60"
            statusText.text = "Login successful! Starting application..."
        }
        function onLoginFailed(error) {
            statusText.color = "#e74c3c"
            statusText.text = error
        }
        function onSignupSuccess() {
            statusText.color = "#27ae60"
            statusText.text = "Account created successfully! Starting application..."
        }
        function onSignupFailed(error) {
            statusText.color = "#e74c3c"
            statusText.text = error
        }
    }
}
