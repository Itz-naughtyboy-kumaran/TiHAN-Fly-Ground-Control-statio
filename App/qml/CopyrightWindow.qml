import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtGraphicalEffects 1.10

Window {
    id: creditsWindow
    width: 2000
    height: 1500
    title: "TiHAN - Credits"
    modality: Qt.WindowModal
    flags: Qt.Window | Qt.WindowCloseButtonHint | Qt.WindowTitleHint
    color: "#000000"
    
    Rectangle {
        id: mainBackground
        anchors.fill: parent
        color: "#000000"  // Pure black background
        
        // Animated star field
        Repeater {
            model: 200
            Rectangle {
                width: Math.random() * 3 + 1
                height: width
                radius: width / 2
                color: Math.random() > 0.7 ? "#4f8fff" : "#ffffff"
                opacity: Math.random() * 0.8 + 0.2
                x: Math.random() * parent.width
                y: Math.random() * parent.height
                
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    PauseAnimation { duration: Math.random() * 2000 }
                    NumberAnimation { 
                        to: opacity * 0.3
                        duration: 1000 + Math.random() * 2000 
                    }
                    NumberAnimation { 
                        to: opacity * 1.2
                        duration: 1000 + Math.random() * 2000 
                    }
                }
            }
        }
        
        // Floating orbs/light effects
        Repeater {
            model: 5
            Rectangle {
                width: 150 + Math.random() * 100
                height: width
                radius: width / 2
                color: "transparent"
                opacity: 0.1
                x: Math.random() * (parent.width - width)
                y: Math.random() * (parent.height - height)
                
                border.width: 1
                border.color: index % 2 === 0 ? "#4f8fff" : "#ffffff"
                
                // Subtle glow effect
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 20
                    height: parent.height + 20
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: parent.border.color
                    opacity: 0.3
                }
                
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite
                    NumberAnimation { 
                        to: 0.25
                        duration: 4000 + Math.random() * 3000
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation { 
                        to: 0.05
                        duration: 4000 + Math.random() * 3000
                        easing.type: Easing.InOutQuad
                    }
                }
                
                RotationAnimation on rotation {
                    running: true
                    loops: Animation.Infinite
                    from: 0
                    to: 360
                    duration: 30000 + Math.random() * 20000
                }
            }
        }
        
        // Subtle particle system
        Repeater {
            model: 50
            Rectangle {
                width: 1
                height: 1
                color: "#ffffff"
                opacity: Math.random() * 0.6 + 0.2
                x: Math.random() * parent.width
                y: Math.random() * parent.height
                
                NumberAnimation on y {
                    running: true
                    loops: Animation.Infinite
                    from: y
                    to: parent.height + 10
                    duration: 10000 + Math.random() * 15000
                    onFinished: {
                        y = -10
                        x = Math.random() * parent.width
                        restart()
                    }
                }
            }
        }
        
        ScrollView {
            anchors.fill: parent
            anchors.margins: 30
            contentWidth: -1 // Use implicit width
            
            // Main content column
            Column {
                width: parent.parent.width - 60 // Full width minus margins
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 25
                
                // Header Section
                Item {
                    width: parent.width
                    height: headerColumn.height
                    
                    Column {
                        id: headerColumn
                        spacing: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            text: "DEVELOPMENT TEAM"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Normal
                            color: "#888888"
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "CREDITS"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        // Blue accent line
                        Rectangle {
                            width: 80
                            height: 3
                            color: "#4f8fff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 1.5
                        }
                    }
                }
                
                // Core Development Team
                Item {
                    width: parent.width
                    height: teamColumn.height
                    
                    Column {
                        id: teamColumn
                        spacing: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            text: "CORE DEVELOPMENT TEAM"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Medium
                            color: "#cccccc"
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        // Blue accent line
                        Rectangle {
                            width: 60
                            height: 2
                            color: "#4f8fff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 1
                        }
                        
                        // Team Members - All centered
                        Column {
                            spacing: 18
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            Text {
                                text: "Prof P.Rajalakshmi"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Santhosh Reddy"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Syam Narayanan S"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Sanju Kumar Tari"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Raju Santhani"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "B.Tarun Kumar"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Pavan Sai Kumar Reddy"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Jani Basha Shaik"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Vijay Kumar Gudimetla"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Boopalan"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Saravana Kumar K"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Arun Kumar K"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Mohan Kumar J"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "M Sandeep"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#ffffff"
                                horizontalAlignment: Text.AlignHCenter
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                    }
                }
                
                // Separator line
                Rectangle {
                    width: 200
                    height: 1
                    color: "#333333"
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                
                // Proudly Presented By Section
                Item {
                    width: parent.width
                    height: presentedColumn.height
                    
                    Column {
                        id: presentedColumn
                        spacing: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            text: "PROUDLY PRESENTED BY"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Normal
                            color: "#888888"
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "TEAM TiHAN"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "Technology Innovation Hub"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Normal
                            color: "#cccccc"
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        // Blue accent line
                        Rectangle {
                            width: 60
                            height: 2
                            color: "#4f8fff"
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 1
                        }
                    }
                }
                
                // Thank You Section
                Item {
                    width: parent.width
                    height: thankYouColumn.height
                    
                    Column {
                        id: thankYouColumn
                        spacing: 15
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Text {
                            text: "THANK YOU"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "For using our application and supporting innovation"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Normal
                            color: "#cccccc"
                            horizontalAlignment: Text.AlignHCenter
                            anchors.horizontalCenter: parent.horizontalCenter
                            wrapMode: Text.WordWrap
                            width: 300
                        }
                    }
                }
                
                // Close Button
                Item {
                    width: parent.width
                    height: 50
                    
                    Button {
                        id: closeButton
                        width: 200
                        height: 40
                        anchors.centerIn: parent
                        
                        background: Rectangle {
                            color: "transparent"
                            border.color: "#4f8fff"
                            border.width: 2
                            radius: 20
                            
                            Rectangle {
                                anchors.fill: parent
                                color: "#4f8fff"
                                opacity: parent.parent.pressed ? 0.3 : parent.parent.hovered ? 0.2 : 0
                                radius: parent.radius
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 200 }
                                }
                            }
                        }
                        
                        contentItem: Text {
                            text: "CLOSE"
                            font.family: "Consolas"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            color: "#ffffff"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        
                        onClicked: creditsWindow.close()
                    }
                }
                
                // Built with love section
                Item {
                    width: parent.width
                    height: loveColumn.height
                    
                    Column {
                        id: loveColumn
                        spacing: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Row {
                            spacing: 5
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            Text {
                                text: "BUILT WITH"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#666666"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "❤"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                color: "#ff4757"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "FOR THE FUTURE"
                                font.family: "Consolas"
                                font.pixelSize: 16
                                font.weight: Font.Normal
                                color: "#666666"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        Rectangle {
                            width: 150
                            height: 1
                            color: "#333333"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                }
            }
        }
    }
    
    // Fade in animation
    NumberAnimation {
        id: showAnimation
        target: creditsWindow
        property: "opacity"
        from: 0
        to: 1
        duration: 500
        easing.type: Easing.OutQuart
    }
    
    // Center the window on screen when shown
    Component.onCompleted: {
        x = (Screen.width - width) / 2
        y = (Screen.height - height) / 2
        showAnimation.start()
    }
}