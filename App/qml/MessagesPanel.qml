import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.10

Rectangle {
    id: messagesPanel
    width: parent.width
    height: 300
    color: "#1e1e1e"  // Dark theme like Mission Planner
    radius: 8
    border.color: "#3a3a3a"
    border.width: 1
    
    property var languageManager: null
    property bool filterInfo: true
    property bool filterSuccess: true
    property bool filterWarning: true
    property bool filterError: true
    
    DropShadow {
        anchors.fill: parent
        horizontalOffset: 0
        verticalOffset: 2
        radius: 8
        samples: 17
        color: "#40000000"
        source: parent
    }
    
    // Connect to MessageLogger backend
    Connections {
        target: messageLogger
        function onMessageAdded(message, severity) {
            messagesPanel.addMessage(message, severity)
        }
    }
    
    Column {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0
        
        // Header with controls
        Rectangle {
            width: parent.width
            height: 45
            color: "#2d2d30"
            radius: 8
            
            // Top radius only
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 8
                color: parent.color
            }
            
            Row {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 10
                
                // Title section
                Row {
                    spacing: 8
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Text {
                        text: "📋"
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    
                    Text {
                        text: "System Messages"
                        font.pixelSize: 14
                        font.weight: Font.Bold
                        color: "#ffffff"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
                
                // Spacer
                Item { 
                    height: 1
                    width: 10
                }
                
                // Message counter
                Rectangle {
                    width: 70
                    height: 26
                    color: messagesListModel.count > 0 ? "#007acc" : "#3e3e42"
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        
                        Text {
                            text: "📊"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: messagesListModel.count
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 300 }
                    }
                }
                
                // Filter buttons
                Row {
                    spacing: 4
                    anchors.verticalCenter: parent.verticalCenter
                    
                    // Info filter
                    Rectangle {
                        width: 32
                        height: 26
                        color: messagesPanel.filterInfo ? "#007acc" : "#3e3e42"
                        radius: 4
                        
                        Text {
                            anchors.centerIn: parent
                            text: "ℹ️"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: messagesPanel.filterInfo = !messagesPanel.filterInfo
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }
                    
                    // Success filter
                    Rectangle {
                        width: 32
                        height: 26
                        color: messagesPanel.filterSuccess ? "#4ec9b0" : "#3e3e42"
                        radius: 4
                        
                        Text {
                            anchors.centerIn: parent
                            text: "✅"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: messagesPanel.filterSuccess = !messagesPanel.filterSuccess
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }
                    
                    // Warning filter
                    Rectangle {
                        width: 32
                        height: 26
                        color: messagesPanel.filterWarning ? "#dcdcaa" : "#3e3e42"
                        radius: 4
                        
                        Text {
                            anchors.centerIn: parent
                            text: "⚠️"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: messagesPanel.filterWarning = !messagesPanel.filterWarning
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }
                    
                    // Error filter
                    Rectangle {
                        width: 32
                        height: 26
                        color: messagesPanel.filterError ? "#f48771" : "#3e3e42"
                        radius: 4
                        
                        Text {
                            anchors.centerIn: parent
                            text: "❌"
                            font.pixelSize: 14
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: messagesPanel.filterError = !messagesPanel.filterError
                        }
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }
                }
                
                // Separator
                Rectangle {
                    width: 1
                    height: 26
                    color: "#3a3a3a"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                // Auto-scroll toggle
                Rectangle {
                    id: autoScrollBtn
                    width: 80
                    height: 28
                    color: autoScrollEnabled ? "#0e639c" : "#3e3e42"
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    
                    property bool autoScrollEnabled: true
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Text {
                            text: autoScrollBtn.autoScrollEnabled ? "⬇️" : "⏸️"
                            font.pixelSize: 12
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: "Auto"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: autoScrollBtn.autoScrollEnabled = !autoScrollBtn.autoScrollEnabled
                        
                        onPressed: parent.opacity = 0.7
                        onReleased: parent.opacity = 1.0
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
                
                // Clear button
                Rectangle {
                    id: clearBtn
                    width: 70
                    height: 28
                    color: messagesListModel.count > 0 ? "#c5354d" : "#3e3e42"
                    radius: 4
                    anchors.verticalCenter: parent.verticalCenter
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        Text {
                            text: "🗑️"
                            font.pixelSize: 11
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            text: "Clear"
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        enabled: messagesListModel.count > 0
                        onClicked: {
                            messagesListModel.clear()
                            if (typeof messageLogger !== 'undefined' && messageLogger) {
                                messageLogger.logMessage("Messages cleared", "info")
                            }
                        }
                        
                        onPressed: parent.opacity = 0.7
                        onReleased: parent.opacity = 1.0
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 100 }
                    }
                    
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }
        
        // Messages display area
        Rectangle {
            width: parent.width
            height: parent.height - 45
            color: "#1e1e1e"
            radius: 8
            clip: true
            
            // Bottom radius only
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 8
                color: parent.color
            }
            
            // Scrollable messages
            Flickable {
                id: messagesFlickable
                anchors.fill: parent
                anchors.margins: 8
                contentHeight: messagesColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick
                
                Column {
                    id: messagesColumn
                    width: messagesFlickable.width - 20
                    spacing: 2
                    
                    Repeater {
                        model: messagesListModel
                        
                        Rectangle {
                            width: messagesColumn.width
                            height: messageRow.height + 12
                            color: index % 2 === 0 ? "#252526" : "#1e1e1e"
                            
                            // Hover effect
                            Rectangle {
                                anchors.fill: parent
                                color: "#ffffff"
                                opacity: messageMouseArea.containsMouse ? 0.05 : 0
                                
                                Behavior on opacity {
                                    NumberAnimation { duration: 150 }
                                }
                            }
                            
                            // Left severity indicator
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 4
                                color: getMessageAccentColor(model.severity)
                            }
                            
                            Row {
                                id: messageRow
                                anchors.fill: parent
                                anchors.margins: 6
                                anchors.leftMargin: 10
                                spacing: 8
                                
                                // Timestamp
                                Text {
                                    text: Qt.formatTime(model.timestamp, "hh:mm:ss")
                                    font.pixelSize: 10
                                    font.family: "Consolas"
                                    color: "#858585"
                                    anchors.top: parent.top
                                    anchors.topMargin: 2
                                }
                                
                                // Severity icon
                                Text {
                                    text: getMessageIcon(model.severity)
                                    font.pixelSize: 14
                                    anchors.top: parent.top
                                }
                                
                                // Message text
                                Text {
                                    id: messageText
                                    width: parent.width - 80
                                    text: model.message
                                    font.pixelSize: 11
                                    font.family: "Consolas"
                                    color: getMessageTextColor(model.severity)
                                    wrapMode: Text.WordWrap
                                }
                            }
                            
                            MouseArea {
                                id: messageMouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.IBeamCursor
                                
                                onDoubleClicked: {
                                    // Copy message to clipboard on double-click
                                    if (typeof messageLogger !== 'undefined' && messageLogger) {
                                        messageLogger.logMessage("Message copied to clipboard", "info")
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Auto-scroll behavior
                onContentHeightChanged: {
                    if (autoScrollBtn.autoScrollEnabled && contentHeight > height) {
                        contentY = contentHeight - height
                    }
                }
                
                // Custom scrollbar
                ScrollBar.vertical: ScrollBar {
                    id: messagesScrollBar
                    width: 12
                    policy: ScrollBar.AsNeeded
                    active: true
                    
                    background: Rectangle {
                        color: "#2d2d30"
                        radius: 6
                    }
                    
                    contentItem: Rectangle {
                        color: messagesScrollBar.pressed ? "#6e6e6e" : "#424242"
                        radius: 6
                        implicitWidth: 12
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }
                }
            }
            
            // Empty state
            Item {
                anchors.centerIn: parent
                width: parent.width - 40
                height: 100
                visible: messagesListModel.count === 0
                
                Column {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Text {
                        text: "📭"
                        font.pixelSize: 42
                        anchors.horizontalCenter: parent.horizontalCenter
                        opacity: 0.3
                    }
                    
                    Text {
                        text: "Waiting for system messages..."
                        font.pixelSize: 13
                        color: "#858585"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                    
                    Text {
                        text: "All terminal output will appear here"
                        font.pixelSize: 11
                        color: "#5a5a5a"
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
    
    // List model for messages
    ListModel {
        id: messagesListModel
    }
    
    // Add message function
    function addMessage(message, severity) {
        if (severity === undefined) severity = "info"
        
        messagesListModel.append({
            message: message,
            severity: severity,
            timestamp: new Date()
        })
        
        // Keep only last 500 messages
        if (messagesListModel.count > 500) {
            messagesListModel.remove(0)
        }
    }
    
    // Clear messages
    function clearMessages() {
        messagesListModel.clear()
    }
    
    // Styling functions
    function getMessageTextColor(severity) {
        switch(severity) {
            case "error": return "#f48771"
            case "warning": return "#dcdcaa"
            case "success": return "#4ec9b0"
            case "info":
            default: return "#d4d4d4"
        }
    }
    
    function getMessageAccentColor(severity) {
        switch(severity) {
            case "error": return "#c5354d"
            case "warning": return "#e8ab53"
            case "success": return "#16c60c"
            case "info":
            default: return "#007acc"
        }
    }
    
    function getMessageIcon(severity) {
        switch(severity) {
            case "error": return "❌"
            case "warning": return "⚠️"
            case "success": return "✅"
            case "info":
            default: return "ℹ️"
        }
    }
    
    Component.onCompleted: {
        console.log("📋 Enhanced MessagesPanel initialized (Mission Planner style)")
    }
}