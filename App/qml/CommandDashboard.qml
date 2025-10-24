import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: commandDashboard
    width: 300
    height: parent.height
    color: "#2c3e50"
    border.color: "#34495e"
    border.width: 1
    
    property bool opened: false
    property alias currentCommand: commandTypeCombo.currentText
    property real currentAltitude: 10.0
    property real currentSpeed: 5.0
    property int currentHoldTime: 0
    
    // Signals for communication with main window
    signal addWaypointClicked()
    signal sendMissionClicked()
    signal clearWaypointsClicked()
    signal commandParametersChanged(string commandType, real altitude, real speed, int holdTime)
    
    states: [
        State {
            name: "open"
            when: commandDashboard.opened
            PropertyChanges { target: commandDashboard; x: 0 }
        },
        State {
            name: "closed"
            when: !commandDashboard.opened
            PropertyChanges { target: commandDashboard; x: -commandDashboard.width }
        }
    ]
    
    transitions: Transition {
        NumberAnimation { property: "x"; duration: 300; easing.type: Easing.OutQuart }
    }
    
    function open() { opened = true }
    function close() { opened = false }
    function toggle() { opened = !opened }
    
    ScrollView {
        anchors.fill: parent
        anchors.margins: 10
        
        Column {
            width: parent.width - 20
            spacing: 15
            
            // Header
            Rectangle {
                width: parent.width
                height: 50
                color: "#34495e"
                radius: 8
                border.color: "#4a5f7a"
                border.width: 1
                
                Text {
                    anchors.centerIn: parent
                    text: "Command Editor"
                    color: "#ecf0f1"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "Segoe UI"
                }
            }
            
            // Mission Control Section
            Rectangle {
                width: parent.width
                height: missionControlColumn.height + 20
                color: "#34495e"
                radius: 8
                border.color: "#4a5f7a"
                border.width: 1
                
                Column {
                    id: missionControlColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 10
                    
                    Text {
                        text: "Mission Control"
                        color: "#bdc3c7"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: "Segoe UI"
                    }
                    
                    // Mission Start Button
                    Button {
                        width: parent.width
                        height: 35
                        
                        background: Rectangle {
                            color: parent.pressed ? "#27ae60" : (parent.hovered ? "#2ecc71" : "#1abc9c")
                            radius: 6
                            border.color: "#16a085"
                            border.width: 1
                        }
                        
                        contentItem: Row {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: "#e8f8f5"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "Mission Start"
                                color: "#e8f8f5"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "Segoe UI"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        onClicked: sendMissionClicked()
                    }
                    
                    // Takeoff Button
                    Button {
                        width: parent.width
                        height: 35
                        
                        background: Rectangle {
                            color: parent.pressed ? "#f39c12" : (parent.hovered ? "#f1c40f" : "#e67e22")
                            radius: 6
                            border.color: "#d35400"
                            border.width: 1
                        }
                        
                        contentItem: Row {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Text {
                                text: "↗"
                                color: "#fef9e7"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "Takeoff"
                                color: "#fef9e7"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "Segoe UI"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        onClicked: {
                            commandTypeCombo.currentIndex = 1; // Set to takeoff
                            addWaypointClicked();
                        }
                    }
                }
            }
            
            // Command Editor Section
            Rectangle {
                width: parent.width
                height: commandEditorColumn.height + 20
                color: "#34495e"
                radius: 8
                border.color: "#4a5f7a"
                border.width: 1
                
                Column {
                    id: commandEditorColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 12
                    
                    Text {
                        text: "Waypoint Command Editor"
                        color: "#3498db"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: "Segoe UI"
                    }
                    
                    Text {
                        text: "Point to position at 30 above..."
                        color: "#95a5a6"
                        font.pixelSize: 10
                        font.family: "Segoe UI"
                    }
                    
                    // Command Type
                    Column {
                        width: parent.width
                        spacing: 5
                        
                        Text {
                            text: "Command"
                            color: "#bdc3c7"
                            font.pixelSize: 11
                            font.family: "Segoe UI"
                        }
                        
                        ComboBox {
                            id: commandTypeCombo
                            width: parent.width
                            height: 30
                            
                            model: [
                                "Waypoint",
                                "Takeoff", 
                                "Land",
                                "Return to Launch",
                                "Loiter",
                                "Circle",
                                "Follow Me"
                            ]
                            
                            background: Rectangle {
                                color: "#2c3e50"
                                border.color: "#4a5f7a"
                                border.width: 1
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: commandTypeCombo.displayText
                                color: "#ecf0f1"
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            
                            popup: Popup {
                                y: commandTypeCombo.height - 1
                                width: commandTypeCombo.width
                                implicitHeight: contentItem.implicitHeight
                                padding: 1
                                
                                contentItem: ListView {
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: commandTypeCombo.popup.visible ? commandTypeCombo.delegateModel : null
                                    currentIndex: commandTypeCombo.highlightedIndex
                                }
                                
                                background: Rectangle {
                                    color: "#2c3e50"
                                    border.color: "#4a5f7a"
                                    border.width: 1
                                    radius: 4
                                }
                            }
                            
                            delegate: ItemDelegate {
                                width: commandTypeCombo.width
                                height: 25
                                
                                contentItem: Text {
                                    text: modelData
                                    color: parent.hovered ? "#3498db" : "#ecf0f1"
                                    font.pixelSize: 11
                                    font.family: "Segoe UI"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: parent.hovered ? "#34495e" : "transparent"
                                    radius: 2
                                }
                            }
                            
                            onCurrentTextChanged: {
                                commandParametersChanged(currentText.toLowerCase().replace(/ /g, ""), currentAltitude, currentSpeed, currentHoldTime);
                            }
                        }
                    }
                    
                    // Altitude
                    Column {
                        width: parent.width
                        spacing: 5
                        
                        Row {
                            width: parent.width
                            
                            Text {
                                text: "Altitude"
                                color: "#bdc3c7"
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                                width: parent.width - 60
                            }
                            
                            Text {
                                text: "m (Rel)"
                                color: "#7f8c8d"
                                font.pixelSize: 9
                                font.family: "Segoe UI"
                                horizontalAlignment: Text.AlignRight
                                width: 60
                            }
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 30
                            color: "#2c3e50"
                            border.color: "#4a5f7a"
                            border.width: 1
                            radius: 4
                            
                            Row {
                                anchors.fill: parent
                                anchors.margins: 2
                                
                                Button {
                                    width: 26
                                    height: parent.height
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#1abc9c" : (parent.hovered ? "#16a085" : "#34495e")
                                        radius: 2
                                    }
                                    
                                    contentItem: Text {
                                        text: "-"
                                        color: "#ecf0f1"
                                        font.pixelSize: 12
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: {
                                        if (currentAltitude > 1) {
                                            currentAltitude -= 1;
                                            altitudeField.text = currentAltitude.toString();
                                        }
                                    }
                                }
                                
                                TextField {
                                    id: altitudeField
                                    width: parent.width - 52
                                    height: parent.height
                                    text: currentAltitude.toString()
                                    
                                    background: Rectangle {
                                        color: "transparent"
                                        border.width: 0
                                    }
                                    
                                    color: "#ecf0f1"
                                    font.pixelSize: 11
                                    font.family: "Segoe UI"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    
                                    validator: DoubleValidator { bottom: 0; decimals: 1 }
                                    
                                    onTextChanged: {
                                        var val = parseFloat(text);
                                        if (!isNaN(val)) {
                                            currentAltitude = val;
                                            commandParametersChanged(commandTypeCombo.currentText.toLowerCase().replace(/ /g, ""), currentAltitude, currentSpeed, currentHoldTime);
                                        }
                                    }
                                }
                                
                                Button {
                                    width: 26
                                    height: parent.height
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#1abc9c" : (parent.hovered ? "#16a085" : "#34495e")
                                        radius: 2
                                    }
                                    
                                    contentItem: Text {
                                        text: "+"
                                        color: "#ecf0f1"
                                        font.pixelSize: 12
                                        font.bold: true
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: {
                                        currentAltitude += 1;
                                        altitudeField.text = currentAltitude.toString();
                                    }
                                }
                            }
                        }
                    }
                    
                    // Hold Time
                    Column {
                        width: parent.width
                        spacing: 5
                        
                        Row {
                            width: parent.width
                            
                            Text {
                                text: "Hold"
                                color: "#bdc3c7"
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                                width: parent.width - 60
                            }
                            
                            Text {
                                text: "secs"
                                color: "#7f8c8d"
                                font.pixelSize: 9
                                font.family: "Segoe UI"
                                horizontalAlignment: Text.AlignRight
                                width: 60
                            }
                        }
                        
                        TextField {
                            id: holdTimeField
                            width: parent.width
                            height: 30
                            text: currentHoldTime.toString()
                            
                            background: Rectangle {
                                color: "#2c3e50"
                                border.color: "#4a5f7a"
                                border.width: 1
                                radius: 4
                            }
                            
                            color: "#ecf0f1"
                            font.pixelSize: 11
                            font.family: "Segoe UI"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            
                            validator: IntValidator { bottom: 0 }
                            
                            onTextChanged: {
                                var val = parseInt(text);
                                if (!isNaN(val)) {
                                    currentHoldTime = val;
                                    commandParametersChanged(commandTypeCombo.currentText.toLowerCase().replace(/ /g, ""), currentAltitude, currentSpeed, currentHoldTime);
                                }
                            }
                        }
                    }
                    
                    // Flight Speed
                    Column {
                        width: parent.width
                        spacing: 5
                        
                        Text {
                            text: "Flight Speed"
                            color: "#bdc3c7"
                            font.pixelSize: 11
                            font.family: "Segoe UI"
                        }
                        
                        ComboBox {
                            id: speedCombo
                            width: parent.width
                            height: 30
                            
                            model: ["Very Slow (1 m/s)", "Slow (3 m/s)", "Normal (5 m/s)", "Fast (8 m/s)", "Very Fast (12 m/s)"]
                            currentIndex: 2 // Default to Normal
                            
                            background: Rectangle {
                                color: "#2c3e50"
                                border.color: "#4a5f7a"
                                border.width: 1
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: speedCombo.displayText
                                color: "#ecf0f1"
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                            
                            popup: Popup {
                                y: speedCombo.height - 1
                                width: speedCombo.width
                                implicitHeight: contentItem.implicitHeight
                                padding: 1
                                
                                contentItem: ListView {
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: speedCombo.popup.visible ? speedCombo.delegateModel : null
                                    currentIndex: speedCombo.highlightedIndex
                                }
                                
                                background: Rectangle {
                                    color: "#2c3e50"
                                    border.color: "#4a5f7a"
                                    border.width: 1
                                    radius: 4
                                }
                            }
                            
                            delegate: ItemDelegate {
                                width: speedCombo.width
                                height: 25
                                
                                contentItem: Text {
                                    text: modelData
                                    color: parent.hovered ? "#3498db" : "#ecf0f1"
                                    font.pixelSize: 11
                                    font.family: "Segoe UI"
                                    verticalAlignment: Text.AlignVCenter
                                    leftPadding: 8
                                }
                                
                                background: Rectangle {
                                    color: parent.hovered ? "#34495e" : "transparent"
                                    radius: 2
                                }
                            }
                            
                            onCurrentIndexChanged: {
                                var speeds = [1, 3, 5, 8, 12];
                                currentSpeed = speeds[currentIndex];
                                commandParametersChanged(commandTypeCombo.currentText.toLowerCase().replace(/ /g, ""), currentAltitude, currentSpeed, currentHoldTime);
                            }
                        }
                    }
                    
                    // Camera Control (Placeholder)
                    Column {
                        width: parent.width
                        spacing: 5
                        
                        Text {
                            text: "Camera"
                            color: "#bdc3c7"
                            font.pixelSize: 11
                            font.family: "Segoe UI"
                        }
                        
                        ComboBox {
                            width: parent.width
                            height: 30
                            
                            model: ["No Change", "Photo", "Video Start", "Video Stop"]
                            
                            background: Rectangle {
                                color: "#2c3e50"
                                border.color: "#4a5f7a"
                                border.width: 1
                                radius: 4
                            }
                            
                            contentItem: Text {
                                text: parent.displayText
                                color: "#ecf0f1"
                                font.pixelSize: 11
                                font.family: "Segoe UI"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 8
                            }
                        }
                    }
                }
            }
            
            // Action Buttons Section
            Rectangle {
                width: parent.width
                height: actionButtonsColumn.height + 20
                color: "#34495e"
                radius: 8
                border.color: "#4a5f7a"
                border.width: 1
                
                Column {
                    id: actionButtonsColumn
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 10
                    
                    Text {
                        text: "Actions"
                        color: "#bdc3c7"
                        font.pixelSize: 12
                        font.bold: true
                        font.family: "Segoe UI"
                    }
                    
                    // Add Waypoint Button
                    Button {
                        width: parent.width
                        height: 35
                        
                        background: Rectangle {
                            color: parent.pressed ? "#2980b9" : (parent.hovered ? "#3498db" : "#2c3e50")
                            radius: 6
                            border.color: "#3498db"
                            border.width: 1
                        }
                        
                        contentItem: Row {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Text {
                                text: "+"
                                color: "#ecf0f1"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "Add Waypoint"
                                color: "#ecf0f1"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "Segoe UI"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        onClicked: addWaypointClicked()
                    }
                    
                    // Clear Waypoints Button
                    Button {
                        width: parent.width
                        height: 35
                        
                        background: Rectangle {
                            color: parent.pressed ? "#c0392b" : (parent.hovered ? "#e74c3c" : "#2c3e50")
                            radius: 6
                            border.color: "#e74c3c"
                            border.width: 1
                        }
                        
                        contentItem: Row {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Text {
                                text: "✖"
                                color: "#ecf0f1"
                                font.pixelSize: 12
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "Clear Waypoints"
                                color: "#ecf0f1"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "Segoe UI"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        onClicked: clearWaypointsClicked()
                    }
                    
                    // Land Button
                    Button {
                        width: parent.width
                        height: 35
                        
                        background: Rectangle {
                            color: parent.pressed ? "#d35400" : (parent.hovered ? "#e67e22" : "#2c3e50")
                            radius: 6
                            border.color: "#e67e22"
                            border.width: 1
                        }
                        
                        contentItem: Row {
                            anchors.centerIn: parent
                            spacing: 8
                            
                            Text {
                                text: "↙"
                                color: "#ecf0f1"
                                font.pixelSize: 14
                                font.bold: true
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                text: "Land"
                                color: "#ecf0f1"
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "Segoe UI"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                        
                        onClicked: {
                            commandTypeCombo.currentIndex = 2; // Set to land
                            addWaypointClicked();
                        }
                    }
                }
            }
        }
    }
    
    // Drop shadow effect
    DropShadow {
        anchors.fill: parent
        horizontalOffset: 3
        verticalOffset: 0
        radius: 8
        samples: 17
        color: "#40000000"
        source: parent
        z: -1
    }
}