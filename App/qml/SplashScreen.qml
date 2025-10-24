import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Window {
    id: splashWindow
    visible: true
    width: 1400
    height: 900
    flags: Qt.SplashScreen | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
    modality: Qt.ApplicationModal
    color: "transparent"
    
    x: (Screen.width - width) / 2
    y: (Screen.height - height) / 2
    
    property bool splashComplete: false
    property string logoPath: {
        var qmlDir = Qt.resolvedUrl(".")
        return qmlDir.substring(0, qmlDir.lastIndexOf("/")) + "/images/tihan.png"
    }
    
    Component.onCompleted: {
        console.log("✅ Splash screen component completed")
        show()
        raise()
        requestActivate()
        splashWindow.modality = Qt.ApplicationModal
    }
    
    Timer {
        id: closeTimer
        interval: 5500
        running: true
        repeat: false
        onTriggered: {
            console.log("⏱️ Splash timer triggered, starting fade out")
            fadeOut.start()
        }
    }
    
    PropertyAnimation {
        id: fadeOut
        target: splashWindow
        property: "opacity"
        from: 1.0
        to: 0
        duration: 1500
        easing.type: Easing.InOutQuad
        onStopped: {
            console.log("✅ Splash screen fade complete")
            splashWindow.splashComplete = true
            splashWindow.hide()
            closeDelayTimer.start()
        }
    }
    
    Timer {
        id: closeDelayTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: {
            console.log("✅ Closing splash screen - main window should now load")
            splashWindow.close()
        }
    }
    
    // Premium light gradient background
    Rectangle {
        anchors.fill: parent
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#f5f5f5" }
            GradientStop { position: 0.25; color: "#fafafa" }
            GradientStop { position: 0.5; color: "#ffffff" }
            GradientStop { position: 0.75; color: "#f8f8f8" }
            GradientStop { position: 1.0; color: "#f0f0f0" }
        }
    }
    
    // Animated accent overlay - Orange
    Rectangle {
        anchors.fill: parent
        color: "#ff6600"
        opacity: 0.01
        
        SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            PropertyAnimation { to: 0.03; duration: 6000; easing.type: Easing.InOutQuad }
            PropertyAnimation { to: 0.01; duration: 6000; easing.type: Easing.InOutQuad }
        }
    }
    
    // Top-left accent glow - Orange
    Rectangle {
        width: 500
        height: 500
        x: -150
        y: -150
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#ff6600" }
            GradientStop { position: 1.0; color: "transparent" }
        }
        radius: 250
        opacity: 0.04
        
        SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            PropertyAnimation { to: 0.08; duration: 5000; easing.type: Easing.InOutQuad }
            PropertyAnimation { to: 0.04; duration: 5000; easing.type: Easing.InOutQuad }
        }
    }
    
    // Bottom-right accent glow - Navy
    Rectangle {
        width: 600
        height: 600
        x: parent.width - 200
        y: parent.height - 200
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 1.0; color: "#003d6b" }
        }
        radius: 300
        opacity: 0.03
        
        SequentialAnimation on opacity {
            running: true
            loops: Animation.Infinite
            PropertyAnimation { to: 0.07; duration: 5500; easing.type: Easing.InOutQuad }
            PropertyAnimation { to: 0.03; duration: 5500; easing.type: Easing.InOutQuad }
        }
    }
    
    // Main content layout
    Column {
        anchors.fill: parent
        spacing: 0
        
        // Premium top border with gradient
        Rectangle {
            width: parent.width
            height: 3
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.25; color: "#ff6600" }
                GradientStop { position: 0.5; color: "#003d6b" }
                GradientStop { position: 0.75; color: "#ff6600" }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
        
        // Main content area
        Rectangle {
            width: parent.width
            height: parent.height - 3 - 100
            color: "transparent"
            
            Column {
                anchors.centerIn: parent
                spacing: 65
                width: parent.width - 160
                
                // Logo and branding section
                Item {
                    width: parent.width
                    height: 240
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 32
                        width: parent.width
                        
                        // Main logo and title
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 40
                            
                            // Premium animated logo container with image
                            Rectangle {
                                width: 110
                                height: 110
                                color: "#f0f0f0"
                                radius: 16
                                border.color: "#ff6600"
                                border.width: 2
                                opacity: 0
                                
                                SequentialAnimation on opacity {
                                    running: true
                                    PropertyAnimation { to: 0.95; duration: 1000; easing.type: Easing.OutQuad }
                                }
                                
                                Item {
                                    anchors.fill: parent
                                    
                                    // Inner glow effect
                                    Rectangle {
                                        anchors.fill: parent
                                        color: "#ff6600"
                                        opacity: 0.03
                                        radius: 16
                                    }
                                    
                                    // Logo image
                                    Image {
                                        anchors.centerIn: parent
                                        width: 90
                                        height: 90
                                        source: splashWindow.logoPath
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }
                                    
                                    // Pulsing ring
                                    Rectangle {
                                        width: 85
                                        height: 85
                                        radius: 42.5
                                        color: "transparent"
                                        border.color: "#ff6600"
                                        border.width: 2
                                        opacity: 0
                                        anchors.centerIn: parent
                                        
                                        SequentialAnimation on opacity {
                                            running: true
                                            loops: Animation.Infinite
                                            PropertyAnimation { to: 0.4; duration: 2000; easing.type: Easing.InOutQuad }
                                            PropertyAnimation { to: 0; duration: 2000; easing.type: Easing.InOutQuad }
                                        }
                                    }
                                }
                            }
                            
                            // Title section with premium styling
                            Column {
                                spacing: 14
                                
                                Row {
                                    spacing: 2
                                    
                                    Text {
                                        text: "TiHAN"
                                        font.pixelSize: 72
                                        font.bold: true
                                        font.family: "Segoe UI, Arial"
                                        color: "#003d6b"
                                        font.weight: Font.ExtraBold
                                        
                                        SequentialAnimation on opacity {
                                            running: true
                                            PropertyAnimation { from: 0; to: 1.0; duration: 1200; easing.type: Easing.OutQuad }
                                        }
                                    }
                                    
                                    Text {
                                        text: "FLY"
                                        font.pixelSize: 72
                                        font.bold: true
                                        font.family: "Segoe UI, Arial"
                                        color: "#ff6600"
                                        font.weight: Font.ExtraBold
                                        
                                        SequentialAnimation on opacity {
                                            running: true
                                            PropertyAnimation { from: 0; to: 1.0; duration: 1300; easing.type: Easing.OutQuad }
                                        }
                                    }
                                }
                                
                                Row {
                                    spacing: 10
                                    
                                    Rectangle {
                                        width: 8
                                        height: 8
                                        radius: 4
                                        color: "#ff6600"
                                        anchors.verticalCenter: parent.verticalCenter
                                        
                                        SequentialAnimation on opacity {
                                            running: true
                                            loops: Animation.Infinite
                                            PropertyAnimation { to: 0.3; duration: 900 }
                                            PropertyAnimation { to: 1.0; duration: 900 }
                                        }
                                    }
                                    
                                    Text {
                                        text: "Ground Control Station"
                                        font.pixelSize: 15
                                        color: "#4a5a6a"
                                        font.family: "Segoe UI, Arial"
                                        font.weight: Font.Light
                                    }
                                }
                                
                                Text {
                                    text: "Enterprise Autonomous Systems"
                                    font.pixelSize: 12
                                    color: "#6a7a8a"
                                    font.family: "Segoe UI, Arial"
                                    font.weight: Font.ExtraLight
                                    opacity: 0.8
                                }
                            }
                        }
                        
                        // Institution branding
                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8
                            
                            Rectangle {
                                width: 3
                                height: 20
                                color: "#ff6600"
                                opacity: 0.4
                            }
                            
                            Column {
                                spacing: 2
                                
                                Text {
                                    text: "Developed by"
                                    font.pixelSize: 10
                                    color: "#8a9aaa"
                                    font.family: "Segoe UI, Arial"
                                    font.weight: Font.Light
                                }
                                
                                Text {
                                    text: "TiHAN Foundation • IIT Hyderabad"
                                    font.pixelSize: 12
                                    color: "#ff6600"
                                    font.family: "Segoe UI, Arial"
                                    font.weight: Font.DemiBold
                                }
                            }
                            
                            Rectangle {
                                width: 3
                                height: 20
                                color: "#ff6600"
                                opacity: 0.4
                            }
                        }
                    }
                }
                
                // Premium divider with glow
                Rectangle {
                    width: 380
                    height: 2
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.2; color: "#ff6600" }
                        GradientStop { position: 0.5; color: "#003d6b" }
                        GradientStop { position: 0.8; color: "#ff6600" }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: 0.6
                }
                
                // Version, build, and status information
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 120
                    
                    Column {
                        spacing: 14
                        
                        Text {
                            text: "VERSION"
                            font.pixelSize: 12
                            color: "#8a9aaa"
                            font.family: "Segoe UI, Arial"
                            font.weight: Font.Bold
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "2.0.0"
                            font.pixelSize: 32
                            font.bold: true
                            color: "#ff6600"
                            font.family: "Segoe UI, Arial"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "Release"
                            font.pixelSize: 10
                            color: "#9aacba"
                            font.family: "Segoe UI, Arial"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    Column {
                        spacing: 14
                        
                        Text {
                            text: "BUILD"
                            font.pixelSize: 12
                            color: "#8a9aaa"
                            font.family: "Segoe UI, Arial"
                            font.weight: Font.Bold
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "2024.Q4.001"
                            font.pixelSize: 16
                            color: "#2a3a4a"
                            font.family: "Segoe UI, Arial"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Text {
                            text: "Enterprise Edition"
                            font.pixelSize: 10
                            color: "#9aacba"
                            font.family: "Segoe UI, Arial"
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                    }
                    
                    Column {
                        spacing: 14
                        
                        Text {
                            text: "STATUS"
                            font.pixelSize: 12
                            color: "#8a9aaa"
                            font.family: "Segoe UI, Arial"
                            font.weight: Font.Bold
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        Row {
                            spacing: 8
                            anchors.horizontalCenter: parent.horizontalCenter
                            
                            Rectangle {
                                width: 12
                                height: 12
                                radius: 6
                                color: "#009933"
                                
                                SequentialAnimation on opacity {
                                    running: true
                                    loops: Animation.Infinite
                                    PropertyAnimation { to: 0.4; duration: 800 }
                                    PropertyAnimation { to: 1.0; duration: 800 }
                                }
                            }
                            
                            Text {
                                text: "Operational"
                                font.pixelSize: 14
                                color: "#009933"
                                font.family: "Segoe UI, Arial"
                                font.weight: Font.DemiBold
                            }
                        }
                    }
                }
                
                // Initialization status and progress
                Column {
                    width: parent.width
                    spacing: 20
                    
                    Text {
                        text: "Initializing System Components & Loading Resources"
                        font.pixelSize: 13
                        color: "#4a5a6a"
                        font.family: "Segoe UI, Arial"
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.weight: Font.Light
                        
                        SequentialAnimation on opacity {
                            running: true
                            loops: Animation.Infinite
                            PropertyAnimation { to: 0.5; duration: 1200 }
                            PropertyAnimation { to: 1.0; duration: 1200 }
                        }
                    }
                    
                    // Premium progress bar
                    Rectangle {
                        width: 440
                        height: 10
                        color: "#e0e0e0"
                        radius: 5
                        anchors.horizontalCenter: parent.horizontalCenter
                        border.color: "#d0d0d0"
                        border.width: 1
                        
                        Rectangle {
                            id: progressBar
                            height: 10
                            color: "#ff6600"
                            radius: 5
                            width: 0
                            
                            PropertyAnimation on width {
                                to: 440
                                duration: 5000
                                running: true
                                easing.type: Easing.InOutCubic
                            }
                            
                            // Inner highlight glow
                            Rectangle {
                                anchors.fill: parent
                                color: "#ffaa55"
                                radius: 5
                                opacity: 0.25
                            }
                        }
                    }
                    
                    // Progress percentage display
                    Text {
                        text: Math.round((progressBar.width / 440) * 100) + "%"
                        font.pixelSize: 12
                        color: "#7a8a9a"
                        font.family: "Segoe UI, Arial"
                        anchors.horizontalCenter: parent.horizontalCenter
                        font.weight: Font.DemiBold
                    }
                }
            }
        }
        
        // Premium footer bar
        Rectangle {
            width: parent.width
            height: 100
            color: "#f5f5f5"
            border.color: "#e0e0e0"
            border.width: 1
            
            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14
                
                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 28
                    spacing: 14
                    
                    Row {
                        spacing: 10
                        
                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            color: "#009933"
                            anchors.verticalCenter: parent.verticalCenter
                            
                            SequentialAnimation on opacity {
                                running: true
                                loops: Animation.Infinite
                                PropertyAnimation { to: 0.4; duration: 700 }
                                PropertyAnimation { to: 1.0; duration: 700 }
                            }
                        }
                        
                        Text {
                            text: "System Ready"
                            font.pixelSize: 13
                            color: "#009933"
                            font.family: "Segoe UI, Arial"
                            font.weight: Font.DemiBold
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    
                    Item { Layout.fillWidth: true }
                    
                    Text {
                        text: "© 2024 TiHAN Foundation • Indian Institute of Technology Hyderabad"
                        font.pixelSize: 11
                        color: "#8a9aaa"
                        font.family: "Segoe UI, Arial"
                        font.weight: Font.Light
                        verticalAlignment: Text.AlignVCenter
                    }
                }
                
                // Premium feature highlights
                Row {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 22
                    spacing: 32
                    
                    Row {
                        spacing: 6
                        
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: "#ff6600"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: "Enterprise-Grade Platform"
                            font.pixelSize: 11
                            color: "#6a7a8a"
                            font.family: "Segoe UI, Arial"
                            font.weight: Font.Light
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    
                    Row {
                        spacing: 6
                        
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: "#ff6600"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: "Real-Time Processing"
                            font.pixelSize: 11
                            color: "#6a7a8a"
                            font.family: "Segoe UI, Arial"
                            font.weight: Font.Light
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    
                    Row {
                        spacing: 6
                        
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: "#ff6600"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: "Autonomous Control Systems"
                            font.pixelSize: 11
                            color: "#6a7a8a"
                            font.family: "Segoe UI, Arial"
                            font.weight: Font.Light
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    
                    Row {
                        spacing: 6
                        
                        Rectangle {
                            width: 5
                            height: 5
                            radius: 2.5
                            color: "#ff6600"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: "Military-Grade Security"
                            font.pixelSize: 11
                            color: "#6a7a8a"
                            font.family: "Segoe UI, Arial"
                            font.weight: Font.Light
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
}