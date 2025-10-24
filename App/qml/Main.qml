import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.10
import "."
import QtQuick.Window 2.15
import QtQuick.Layouts 1.0

ApplicationWindow {
    id: mainWindow
    visible: true
    visibility: "Maximized"
    title: "TiHAN FLY-Groud Control Station"
    color: "#f5f5f5"

    // ADD THIS: Global reference for marker synchronization
    property var mapViewInstance: null
    property var navigationControlsInstance: null

    // Colors - Light Theme
    readonly property color primaryColor: "#ffffff"
    readonly property color secondaryColor: "#f8f9fa"
    readonly property color accentColor: "#0066cc"
    readonly property color successColor: "#28a745"
    readonly property color warningColor: "#ffc107"
    readonly property color errorColor: "#dc3545"
    readonly property color textPrimary: "#212529"
    readonly property color textSecondary: "#6c757d"
    readonly property color borderColor: "#dee2e6"

    // Properties
    property string currentLanguage: "en"
    property bool sidebarVisible: true
    property int sidebarWidth: 520
    property int collapsedSidebarWidth: 50

    property real currentAltitude: 0.09
    property real currentGroundSpeed: 0.98
    property real currentYaw: 274.87
    property real currentDistToWP: 62.51
    property real currentVerticalSpeed: 0.65
    property real currentDistToMAV: 31.74

    // Font loaders
    FontLoader { id: tamilFont; source: "fonts/NotoSansTamil-Regular.ttf" }
    FontLoader { id: hindiFont; source: "fonts/NotoSansDevanagari-Regular.ttf" }
    FontLoader { id: teluguFont; source: "fonts/NotoSansTelugu-Regular.ttf" }

    // Language manager
    LanguageManager { id: languageManager }

    Connections {
        target: languageManager
        function onCurrentLanguageChanged() {
            saveLanguagePreference(languageManager.currentLanguage);
            updateLanguageForAllComponents();
        }
    }

    // Copyright Window Loader
    Loader {
        id: copyrightWindowLoader
        source: ""
        
        function showCopyrightWindow() {
            if (item === null) {
                source = "CopyrightWindow.qml"
            }
            if (item !== null) {
                item.show()
                item.raise()
                item.requestActivate()
            }
        }
    }

    // Feedback Dialog Loader
    Loader {
        id: feedbackDialogLoader
        active: false
        source: "FeedbackDialog.qml"  // Back to simple filename
        
        onLoaded: {
            if (item) {
                item.parent = mainWindow.contentItem
                item.open()
            }
        }
    }

    // Background gradient - Light Theme
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#f5f5f5" }
            GradientStop { position: 1.0; color: "#e9ecef" }
        }

        // Optional grid overlay - Light Theme
        Canvas {
            anchors.fill: parent
            opacity: 0.08
            onPaint: {
                var ctx = getContext("2d")
                ctx.strokeStyle = "#adb5bd"
                ctx.lineWidth = 1
                for (var x = 0; x < width; x += 50) {
                    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, height); ctx.stroke()
                }
                for (var y = 0; y < height; y += 50) {
                    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(width, y); ctx.stroke()
                }
            }
        }

        // Top Connection Bar
        ConnectionBar {
            id: connectionBar
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: 60
            languageManager: languageManager
        }

        // Main Layout Area
        Rectangle {
            id: mainContent
            anchors.top: connectionBar.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            color: "transparent"

            // Sidebar
            Rectangle {
                id: leftPanel
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 15
                width: sidebarVisible ? sidebarWidth : collapsedSidebarWidth
                color: primaryColor
                radius: 12
                border.color: borderColor
                border.width: 2
                clip: true

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                DropShadow {
                    anchors.fill: parent
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8
                    samples: 17
                    color: "#20000000"
                    source: parent
                }

                Rectangle {
                    id: toggleButton
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 8
                    anchors.topMargin: 8
                    width: 30
                    height: 30
                    color: accentColor
                    radius: 15
                    border.color: borderColor
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: sidebarVisible ? "◀" : "▶"
                        color: "#ffffff"
                        font.pixelSize: 12
                        font.weight: Font.Bold
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: sidebarVisible = !sidebarVisible
                        cursorShape: Qt.PointingHandCursor
                    }

                    ColorAnimation on color { duration: 200 }
                }

                Rectangle {
                    id: sidebarContent
                    anchors.fill: parent
                    anchors.margins: 15
                    color: "transparent"
                    opacity: sidebarVisible ? 1.0 : 0.0
                    visible: opacity > 0

                    Behavior on opacity {
                        NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                    }

                    // Add ScrollView for scrollable content
                    ScrollView {
                        id: scrollView
                        anchors.fill: parent
                        anchors.topMargin: 45  // Space for toggle button
                        anchors.bottomMargin: 5
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        clip: true
                        
                        // Force scrollbar to always show for testing
                        ScrollBar.vertical: ScrollBar {
                            id: vScrollBar
                            width: 12
                            policy: ScrollBar.AsNeeded  // Changed back to AsNeeded
                            active: true
                            
                            background: Rectangle {
                                color: "#e0e0e0"
                                radius: 6
                                border.color: borderColor
                                border.width: 1
                            }
                            
                            contentItem: Rectangle {
                                color: vScrollBar.pressed ? "#004499" : accentColor
                                radius: 6
                                
                                Behavior on color {
                                    ColorAnimation { duration: 200 }
                                }
                            }
                        }
                        
                        ScrollBar.horizontal: ScrollBar {
                            policy: ScrollBar.AlwaysOff  // Disable horizontal scrolling
                        }

                        // Content column that will be scrollable
                        Column {
                            id: scrollableContent
                            width: scrollView.availableWidth
                            spacing: 15

                            Rectangle {
                                width: parent.width
                                height: 320
                                color: secondaryColor
                                radius: 8
                                border.color: borderColor
                                border.width: 1

                                HudWidget {
                                    id: hudunit
                                    clip: true
                                    anchors.fill: parent
                                    anchors.margins: 5
                                }
                            }

                            StatusPanel {
                                id: statusPanel
                                width: parent.width
                                languageManager: languageManager

                                altitude: droneModel.isConnected && droneModel.telemetry.alt !== undefined ? droneModel.telemetry.alt : 0
                                groundSpeed: droneModel.isConnected && droneModel.telemetry.groundspeed !== undefined ? droneModel.telemetry.groundspeed : 0
                                yaw: droneModel.isConnected && droneModel.telemetry.yaw !== undefined ? droneModel.telemetry.yaw : 0
                                vibration: droneModel.isConnected && droneModel.telemetry.vibration !== undefined ? droneModel.telemetry.vibration : 0
                                epk: droneModel.isConnected && droneModel.telemetry.epk !== undefined ? droneModel.telemetry.epk : 0
                            }

                            StatusBar {
                                width: parent.width
                            }

                            MessagesPanel {
                                id: messagesPanel
                                width: parent.width
                                languageManager: languageManager
                            }

                            // Add some bottom padding
                            Item {
                                width: parent.width
                                height: 15
                            }
                        }
                    }
                }
            }

            // Map Panel
            Rectangle {
                id: rightPanel
                anchors.top: parent.top
                anchors.bottom: controlPanel.top
                anchors.left: leftPanel.right
                anchors.right: parent.right
                anchors.margins: 15
                color: primaryColor
                radius: 12
                border.color: borderColor
                border.width: 2

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                DropShadow {
                    anchors.fill: parent
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 8
                    samples: 17
                    color: "#20000000"
                    source: parent
                }

                Item {
                    anchors.fill: parent

                    MapView {
                        id: mapViewComponent
                        anchors.fill: parent
                        
                        // MODIFIED: Register with mainWindow when created
                        Component.onCompleted: {
                            mainWindow.mapViewInstance = mapViewComponent
                            console.log("MapView registered with mainWindow")
                        }
                    }
                }
            }

            // Control Panel Bottom Center - NO BACKGROUND BOX
            Rectangle {
                id: controlPanel
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: rightPanel.horizontalCenter
                anchors.bottomMargin: 15
                width: 400
                height: 80
                color: "transparent"  // Transparent background - no white box
                radius: 12
                border.color: "transparent"  // Transparent border
                border.width: 0  // No border

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                ControlButtons {
                    id: controlButtons
                    mainWindowRef: mainWindow
                    
                    // MODIFIED: Register NavigationControls when created
                    Component.onCompleted: {
                        mainWindow.navigationControlsInstance = controlButtons
                        console.log("NavigationControls registered with mainWindow")
                    }
                }
            }

            // Floating Access Button (optional)
            Rectangle {
                id: quickAccessButton
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.leftMargin: 20
                anchors.bottomMargin: 20
                width: 60
                height: 60
                color: accentColor
                radius: 30
                opacity: sidebarVisible ? 0.0 : 1.0
                visible: opacity > 0

                Behavior on opacity {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                DropShadow {
                    anchors.fill: parent
                    horizontalOffset: 0
                    verticalOffset: 2
                    radius: 6
                    samples: 13
                    color: "#30000000"
                    source: parent
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 2

                    Text {
                        text: "📊"
                        color: "#ffffff"
                        font.pixelSize: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "OPEN"
                        color: "#ffffff"
                        font.pixelSize: 8
                        font.weight: Font.Bold
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: sidebarVisible = true
                    cursorShape: Qt.PointingHandCursor
                }
            }
        }

        // Feedback Button - Above copyright notice (no API needed)
        Rectangle {
            id: feedbackButton
            anchors.bottom: copyrightNotice.top
            anchors.right: parent.right
            anchors.bottomMargin: 10
            anchors.rightMargin: 20
            width: 120
            height: 35
            color: accentColor
            radius: 8
            opacity: 0.9
            z: 1000

            DropShadow {
                anchors.fill: parent
                horizontalOffset: 0
                verticalOffset: 2
                radius: 4
                samples: 9
                color: "#30000000"
                source: parent
            }

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "📧"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "Feedback"
                    font.family: "Segoe UI"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                onClicked: {
                    // Open feedback dialog
                    feedbackDialogLoader.active = true
                }

                onEntered: {
                    parent.opacity = 1.0
                    parent.scale = 1.05
                }
                onExited: {
                    parent.opacity = 0.9
                    parent.scale = 1.0
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Behavior on scale {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        // Copyright Notice - Direct child of background Rectangle  
        Text {
            id: copyrightNotice
            anchors.bottom: parent.bottom
            anchors.right: parent.right
            anchors.bottomMargin: 20
            anchors.rightMargin: 20
            text: "© 2025 TiHAN IIT Hyderabad. All rights reserved."
            font.family: "Consolas"
            font.pixelSize: 14
            color: textSecondary
            opacity: 0.8
            z: 1000

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    copyrightWindowLoader.showCopyrightWindow()
                }

                hoverEnabled: true
                onEntered: {
                    parent.opacity = 1.0
                    parent.color = accentColor
                }
                onExited: {
                    parent.opacity = 0.9
                    parent.color = textSecondary
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: 200 }
            }

            Behavior on color {
                ColorAnimation { duration: 200 }
            }
        }
    }

    // Functions
    function updateFlightData(altitude, groundSpeed, yaw, distToWP, verticalSpeed, distToMAV) {
        currentAltitude = altitude
        currentGroundSpeed = groundSpeed
        currentYaw = yaw
        currentDistToWP = distToWP
        currentVerticalSpeed = verticalSpeed
        currentDistToMAV = distToMAV
    }

    function saveLanguagePreference(languageCode) {
        // Save to local storage or settings file
        // This is a placeholder - implement based on your storage method
        console.log("Saving language preference:", languageCode);
    }

    function loadLanguagePreference() {
        // Load from local storage or settings file
        // This is a placeholder - implement based on your storage method
        return "en"; // Default to English
    }

    function updateLanguageForAllComponents() {
        console.log("Language updated to:", languageManager.currentLanguage);
    }

    Component.onCompleted: {
        showMaximized()
        var savedLang = loadLanguagePreference()
        languageManager.changeLanguage(savedLang)
    }

    onVisibilityChanged: {
        if (visibility === ApplicationWindow.Windowed) {
            showMaximized()
        }
    }
}