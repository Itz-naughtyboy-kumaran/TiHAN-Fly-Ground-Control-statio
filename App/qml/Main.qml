import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.10
import QtQuick.Window 2.15
import QtQuick.Layouts 1.0
import "."

ApplicationWindow {
    id: mainWindow
    visible: true
    visibility: "Maximized"
    title: "TiHAN FLY - Ground Control Station (SECURE)"
    color: "#f5f5f5"

    // Global properties
    property var mapViewInstance: null
    property var navigationControlsInstance: null
    
    // Security: Session management
    property string sessionToken: ""
    property bool isAuthenticated: false
    property int failedLoginAttempts: 0
    
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
    property var parametersWindowInstance: null
    property var navigationControlsWindowInstance: null
    
    // Font loaders
    FontLoader { id: tamilFont; source: "fonts/NotoSansTamil-Regular.ttf" }
    FontLoader { id: hindiFont; source: "fonts/NotoSansDevanagari-Regular.ttf" }
    FontLoader { id: teluguFont; source: "fonts/NotoSansTelugu-Regular.ttf" }

    // Language manager
    LanguageManager { id: languageManager }

    Connections {
        target: languageManager
        enabled: true
        
        function onCurrentLanguageChanged() {
            // Use Qt.callLater to defer non-critical updates
            Qt.callLater(function() {
                saveLanguagePreference(languageManager.currentLanguage);
                updateLanguageForAllComponents();
            });
        }
    }

    // Security Manager Connections - OPTIMIZED
    Connections {
        target: typeof securityManager !== 'undefined' ? securityManager : null
        enabled: target !== null
        
        function onSecurityAlert(message, severity) {
            console.log("🔒 SECURITY ALERT [" + severity + "]: " + message)
            // Use Qt.callLater for non-critical UI updates
            Qt.callLater(function() {
                showSecurityNotification(message, severity)
            });
        }
        
        function onAuthenticationFailed(reason) {
            console.log("❌ Authentication failed: " + reason)
            failedLoginAttempts++
            if (failedLoginAttempts >= 3) {
                showSecurityNotification("Too many failed attempts. Access blocked.", "critical")
            }
        }
        
        function onSessionExpired() {
            console.log("⏰ Session expired")
            isAuthenticated = false
            sessionToken = ""
            showSecurityNotification("Session expired. Please reconnect.", "warning")
        }
        
        function onUnauthorizedAccess(action) {
            console.log("⚠️ Unauthorized access attempt: " + action)
            Qt.callLater(function() {
                showSecurityNotification("Unauthorized action blocked: " + action, "error")
            });
        }
    }

    // Copyright Window Loader
    Loader {
        id: copyrightWindowLoader
        source: ""
        asynchronous: true  // CRITICAL: Load asynchronously
        
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
        asynchronous: true  // CRITICAL: Load asynchronously
        sourceComponent: Component {
            FeedbackDialog {
                onClosed: feedbackDialogLoader.active = false
            }
        }
    }

    // Security Notification Dialog
    Popup {
        id: securityNotificationDialog
        modal: true
        focus: true
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: 400
        height: 200
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property string alertMessage: ""
        property string alertSeverity: "info"
        
        background: Rectangle {
            color: "#ffffff"
            radius: 12
            border.color: borderColor
            border.width: 2
            
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 12
                samples: 25
                color: "#40000000"
            }
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 25
            spacing: 20
            
            Text {
                text: "Security Alert"
                font.pixelSize: 18
                font.weight: Font.Bold
                color: textPrimary
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Row {
                spacing: 12
                width: parent.width
                
                Text {
                    text: {
                        switch(securityNotificationDialog.alertSeverity) {
                            case "critical": return "🚨"
                            case "error": return "❌"
                            case "warning": return "⚠️"
                            case "success": return "✅"
                            default: return "ℹ️"
                        }
                    }
                    font.pixelSize: 28
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Text {
                    text: securityNotificationDialog.alertMessage
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    width: parent.width - 50
                    anchors.verticalCenter: parent.verticalCenter
                    color: {
                        switch(securityNotificationDialog.alertSeverity) {
                            case "critical": return "#dc3545"
                            case "error": return "#dc3545"
                            case "warning": return "#ffc107"
                            case "success": return "#28a745"
                            default: return "#0066cc"
                        }
                    }
                }
            }
            
            Rectangle {
                width: 100
                height: 35
                radius: 6
                color: securityOkMouseArea.pressed ? "#004499" : accentColor
                anchors.horizontalCenter: parent.horizontalCenter

                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    color: "white"
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                }

                MouseArea {
                    id: securityOkMouseArea
                    anchors.fill: parent
                    onClicked: securityNotificationDialog.close()
                }

                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
        }
    }
    
    // Background gradient
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#f5f5f5" }
            GradientStop { position: 1.0; color: "#e9ecef" }
        }

        // Grid overlay - OPTIMIZED: Render once, not continuously
        Canvas {
            anchors.fill: parent
            opacity: 0.08
            renderStrategy: Canvas.Threaded  // CRITICAL: Use threaded rendering
            renderTarget: Canvas.FramebufferObject  // CRITICAL: Cache the rendering
            
            Component.onCompleted: {
                requestPaint()  // Paint once on startup
            }
            
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
                    cached: true  // CRITICAL: Cache the shadow
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

                    ScrollView {
                        id: scrollView
                        anchors.fill: parent
                        anchors.topMargin: 45
                        anchors.bottomMargin: 5
                        anchors.leftMargin: 5
                        anchors.rightMargin: 5
                        clip: true
                        
                        ScrollBar.vertical: ScrollBar {
                            id: vScrollBar
                            width: 12
                            policy: ScrollBar.AsNeeded
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
                            policy: ScrollBar.AlwaysOff
                        }

                        Column {
                            id: scrollableContent
                            width: scrollView.availableWidth
                            spacing: 15

                            // HUD Widget - OPTIMIZED
                            Loader {
                                id: hudLoader
                                width: parent.width
                                height: 320
                                asynchronous: true  // CRITICAL: Load asynchronously
                                active: sidebarVisible  // Only load when visible
                                
                                sourceComponent: Rectangle {
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
                            }

                            // Status Text Display Panel - OPTIMIZED
                            Loader {
                                id: statusTextLoader
                                width: parent.width
                                height: 400
                                asynchronous: true  // CRITICAL: Load asynchronously
                                active: sidebarVisible  // Only load when visible
                                
                                sourceComponent: StatusTextDisplay {
                                    width: parent.width
                                    height: 400
                                    languageManager: languageManager
                                }
                            }

                            // Original StatusPanel - OPTIMIZED
                            StatusPanel {
                                id: statusPanel
                                width: parent.width
                                languageManager: languageManager

                                // CRITICAL: Throttle updates to prevent UI freezing
                                altitude: droneModel.isConnected && droneModel.telemetry.alt !== undefined ? droneModel.telemetry.alt : 0
                                groundSpeed: droneModel.isConnected && droneModel.telemetry.groundspeed !== undefined ? droneModel.telemetry.groundspeed : 0
                                yaw: droneModel.isConnected && droneModel.telemetry.yaw !== undefined ? droneModel.telemetry.yaw : 0
                                vibration: droneModel.isConnected && droneModel.telemetry.vibration !== undefined ? droneModel.telemetry.vibration : 0
                                efk: droneModel.isConnected && droneModel.telemetry.ekf !== undefined ? droneModel.telemetry.ekf : 0
                            }

                            StatusBar {
                                width: parent.width
                            }

                            Item {
                                width: parent.width
                                height: 15
                            }
                        }
                    }
                }
            }

            // Map Panel - OPTIMIZED
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
                    cached: true  // CRITICAL: Cache the shadow
                }

                // CRITICAL: Use Loader for MapView to load asynchronously
                Loader {
                    id: mapLoader
                    anchors.fill: parent
                    asynchronous: true  // CRITICAL: Load asynchronously
                    
                    sourceComponent: MapView {
                        id: mapViewComponent
                        
                        Component.onCompleted: {
                            mainWindow.mapViewInstance = mapViewComponent
                            console.log("MapView registered with mainWindow")
                        }
                    }
                }
            }

            // Control Panel Bottom Center
            Rectangle {
                id: controlPanel
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: rightPanel.horizontalCenter
                anchors.bottomMargin: 15
                width: 400
                height: 80
                color: "transparent"
                radius: 12
                border.color: "transparent"
                border.width: 0

                Behavior on width {
                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                }

                ControlButtons {
                    id: controlButtons
                    mainWindowRef: mainWindow
                    
                    Component.onCompleted: {
                        mainWindow.navigationControlsInstance = controlButtons
                        console.log("NavigationControls registered")
                    }
                }
            }

            // Floating Access Button
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
                    cached: true  // CRITICAL: Cache the shadow
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
        
        // Security Indicator Badge - OPTIMIZED: Reduce animation complexity
        Rectangle {
            id: securityBadge
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 80
            anchors.rightMargin: 20
            width: 140
            height: 35
            color: successColor
            radius: 8
            opacity: 0.9
            z: 1001

            Row {
                anchors.centerIn: parent
                spacing: 8

                Text {
                    text: "🔒"
                    font.pixelSize: 16
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: "SECURE MODE"
                    font.family: "Segoe UI"
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    color: "#ffffff"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            DropShadow {
                anchors.fill: parent
                horizontalOffset: 0
                verticalOffset: 2
                radius: 4
                samples: 9
                color: "#30000000"
                source: parent
                cached: true  // CRITICAL: Cache the shadow
            }

            // OPTIMIZED: Slower pulsing animation to reduce CPU usage
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                NumberAnimation { to: 1.0; duration: 2000 }  // Increased from 1000
                NumberAnimation { to: 0.85; duration: 2000 }  // Increased from 1000, changed target
            }
        }
        
        // Feedback Button
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
                cached: true  // CRITICAL: Cache the shadow
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

        // Copyright Notice
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

    // ============================================================
    // SECURITY FUNCTIONS
    // ============================================================
    
    function showSecurityNotification(message, severity) {
        securityNotificationDialog.alertMessage = message
        securityNotificationDialog.alertSeverity = severity
        securityNotificationDialog.open()
    }
    
    function validateCoordinateInput(lat, lng) {
        if (typeof securityManager === 'undefined') {
            console.warn("⚠️ Security Manager not available")
            return true
        }
        
        var latValid = securityManager.validate_coordinate(lat, "latitude")
        var lngValid = securityManager.validate_coordinate(lng, "longitude")
        
        if (!latValid || !lngValid) {
            showSecurityNotification("Invalid coordinates detected. Action blocked.", "error")
            if (typeof messageLogger !== 'undefined') {
                messageLogger.logMessage("🚫 Invalid coordinates rejected: " + lat + ", " + lng, "error")
            }
            return false
        }
        
        return true
    }
    
    function validateAltitudeInput(altitude) {
        if (typeof securityManager === 'undefined') {
            console.warn("⚠️ Security Manager not available")
            return true
        }
        
        var valid = securityManager.validate_altitude(altitude)
        
        if (!valid) {
            showSecurityNotification("Invalid altitude: " + altitude + "m. Must be 0-500m.", "error")
            if (typeof messageLogger !== 'undefined') {
                messageLogger.logMessage("🚫 Invalid altitude rejected: " + altitude + "m", "error")
            }
            return false
        }
        
        return true
    }
    
    function validateSpeedInput(speed) {
        if (typeof securityManager === 'undefined') {
            console.warn("⚠️ Security Manager not available")
            return true
        }
        
        var valid = securityManager.validate_speed(speed)
        
        if (!valid) {
            showSecurityNotification("Invalid speed: " + speed + "m/s. Must be 0-25m/s.", "error")
            if (typeof messageLogger !== 'undefined') {
                messageLogger.logMessage("🚫 Invalid speed rejected: " + speed + "m/s", "error")
            }
            return false
        }
        
        return true
    }
    
    function validateCommandExecution(command, params) {
        if (typeof commandValidator === 'undefined') {
            console.warn("⚠️ Command Validator not available")
            return true
        }
        
        var valid = commandValidator.validate_command(command, params)
        
        if (!valid) {
            showSecurityNotification("Command rejected: " + command, "error")
            if (typeof messageLogger !== 'undefined') {
                messageLogger.logMessage("🚫 Command rejected: " + command, "error")
            }
            return false
        }
        
        return true
    }
    
    function sanitizeTextInput(input, maxLength) {
        if (typeof securityManager === 'undefined') {
            console.warn("⚠️ Security Manager not available")
            return input
        }
        
        maxLength = maxLength || 255
        return securityManager.sanitize_string(input, maxLength)
    }
    
    function logSecurityEvent(eventType, details) {
        // Use Qt.callLater for non-critical logging
        Qt.callLater(function() {
            if (typeof securityManager !== 'undefined') {
                securityManager.log_security_event(eventType, details)
            }
            console.log("🔒 Security Event: " + eventType + " - " + details)
        });
    }
    
    function checkRateLimit(identifier, maxAttempts, windowSeconds) {
        if (typeof securityManager === 'undefined') {
            console.warn("⚠️ Security Manager not available")
            return true
        }
        
        maxAttempts = maxAttempts || 10
        windowSeconds = windowSeconds || 60
        
        return securityManager.check_rate_limit(identifier, maxAttempts, windowSeconds)
    }

    // ============================================================
    // REGULAR FUNCTIONS
    // ============================================================
    
    function updateFlightData(altitude, groundSpeed, yaw, distToWP, verticalSpeed, distToMAV) {
        currentAltitude = altitude
        currentGroundSpeed = groundSpeed
        currentYaw = yaw
        currentDistToWP = distToWP
        currentVerticalSpeed = verticalSpeed
        currentDistToMAV = distToMAV
    }

    function saveLanguagePreference(languageCode) {
        console.log("Saving language preference:", languageCode);
    }

    function loadLanguagePreference() {
        return "en";
    }

    function updateLanguageForAllComponents() {
        console.log("Language updated to:", languageManager.currentLanguage);
    }

    Component.onCompleted: {
        showMaximized()
        var savedLang = loadLanguagePreference()
        languageManager.changeLanguage(savedLang)
        
        // Verify droneCommander
        if (typeof droneCommander !== 'undefined') {
            console.log("✓ DroneCommander connected to QML")
        } else {
            console.log("✗ ERROR: DroneCommander NOT available!")
        }
        
        // Verify security manager
        if (typeof securityManager !== 'undefined') {
            console.log("🔒 Security Manager connected to QML")
            logSecurityEvent("SYSTEM_READY", "QML interface initialized")
        } else {
            console.warn("⚠️ WARNING: Security Manager NOT available!")
        }
        
        // Verify command validator
        if (typeof commandValidator !== 'undefined') {
            console.log("🔒 Command Validator connected to QML")
        } else {
            console.warn("⚠️ WARNING: Command Validator NOT available!")
        }
        
        // Log initialization
        if (typeof messageLogger !== 'undefined') {
            messageLogger.logMessage("🚀 TiHAN Secure GCS loaded successfully", "success")
            messageLogger.logMessage("🔒 Security features active", "info")
        }
    }

    onVisibilityChanged: {
        if (visibility === ApplicationWindow.Windowed) {
            showMaximized()
        }
    }
    
    // OPTIMIZED: Longer interval for security monitoring to reduce overhead
    Timer {
        id: securityMonitorTimer
        interval: 60000  // Changed from 30000 to 60000 (1 minute)
        running: true
        repeat: true
        
        onTriggered: {
            // Use Qt.callLater for non-critical logging
            Qt.callLater(function() {
                if (typeof securityManager !== 'undefined') {
                    logSecurityEvent("SECURITY_CHECK", "Periodic security monitoring")
                }
            });
        }
    }
    
    // Security: Auto-lock after inactivity
    Timer {
        id: inactivityTimer
        interval: 1800000  // 30 minutes
        running: false
        repeat: false
        
        onTriggered: {
            if (typeof securityManager !== 'undefined') {
                console.log("⏰ Auto-lock triggered due to inactivity")
                showSecurityNotification("Session locked due to inactivity", "warning")
                logSecurityEvent("AUTO_LOCK", "Inactivity timeout")
            }
        }
    }
    
    // OPTIMIZED: Throttle mouse activity tracking
    // Reset inactivity timer on user interaction - but not too frequently
    Timer {
        id: activityThrottleTimer
        interval: 1000  // Only reset once per second max
        running: false
        repeat: false
        
        onTriggered: {
            inactivityTimer.restart()
        }
    }
    
    MouseArea {
        anchors.fill: parent
        propagateComposedEvents: true
        z: -1
        
        onClicked: {
            if (!activityThrottleTimer.running) {
                activityThrottleTimer.start()
            }
            mouse.accepted = false
        }
        
        onPressed: {
            if (!activityThrottleTimer.running) {
                activityThrottleTimer.start()
            }
            mouse.accepted = false
        }
    }
}
