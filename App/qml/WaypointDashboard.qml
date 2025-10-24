import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.10

Rectangle {
    id: waypointDashboard
    
    // Properties
    property bool expanded: false
    property int selectedWaypointIndex: -1
    property var waypointData: null
    property var waypoints: []
    
    // Signal to notify main window of command execution
    signal executeWaypointCommand(int index, string commandType, var waypointData)
    
    // Appearance - Dark military style
    width: expanded ? 280 : 50
    height: expanded ? 450 : 50
    color: "#2a2a2a"
    radius: 4
    border.color: "#4a4a4a"
    border.width: 1
    opacity: 0.95
    z: 100
    
    // Smooth transitions
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
    Behavior on opacity { NumberAnimation { duration: 200 } }
    
    // Shadow effect
    DropShadow {
        anchors.fill: parent
        horizontalOffset: 2
        verticalOffset: 2
        radius: 8
        samples: 17
        color: "#80000000"
        source: parent
    }
    
    // Collapsed state - just the toggle button
    Rectangle {
        id: collapsedHeader
        anchors.fill: parent
        visible: !expanded
        color: "transparent"
        radius: parent.radius
        
        Button {
            id: toggleButton
            anchors.centerIn: parent
            width: 40
            height: 40
            
            background: Rectangle {
                color: parent.pressed ? "#4CAF50" : (parent.hovered ? "#3a3a3a" : "#2a2a2a")
                radius: 4
                border.color: "#4CAF50"
                border.width: 1
                
                Behavior on color { ColorAnimation { duration: 150 } }
            }
            
            contentItem: Text {
                text: "≡"
                font.pixelSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                color: "#4CAF50"
            }
            
            onClicked: expanded = true
        }
    }
    
    // Expanded state - full dashboard
    Item {
        id: expandedContent
        anchors.fill: parent
        visible: expanded
        
        // Header
        Rectangle {
            id: dashboardHeader
            width: parent.width
            height: 35
            color: "#1e1e1e"
            radius: 4
            border.color: "#4a4a4a"
            border.width: 1
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                
                Text {
                    text: "Command Editor"
                    color: "#4CAF50"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: "Arial"
                    Layout.fillWidth: true
                }
                
                Button {
                    width: 20
                    height: 20
                    background: Rectangle {
                        color: parent.hovered ? "#FF5722" : "transparent"
                        radius: 2
                    }
                    contentItem: Text {
                        text: "×"
                        color: "#FF5722"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: expanded = false
                }
            }
        }
        
        // Content area
        Item {
            anchors.top: dashboardHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 8
            
            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true
                
                ColumnLayout {
                    width: scrollView.width
                    spacing: 8
                    
                    // Mission Start section
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 25
                        color: "#333333"
                        border.color: "#4a4a4a"
                        border.width: 1
                        radius: 2
                        
                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Mission Start"
                            font.pixelSize: 10
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }
                    
                    // Waypoint List
                    Repeater {
                        model: waypoints.length
                        delegate: waypointItem
                    }
                    
                    // Selected Waypoint Editor
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: selectedWaypointIndex >= 0 ? 220 : 0
                        color: "#333333"
                        radius: 4
                        border.color: "#4a4a4a"
                        border.width: 1
                        visible: selectedWaypointIndex >= 0
                        
                        Behavior on Layout.preferredHeight { NumberAnimation { duration: 200 } }
                        
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 6
                            
                            Text {
                                text: "Edit Waypoint " + (selectedWaypointIndex + 1)
                                font.pixelSize: 10
                                font.bold: true
                                color: "#4CAF50"
                            }
                            
                            // Command Type Selector - WITH IMMEDIATE EXECUTION
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 3
                                
                                Text {
                                    text: "Command:"
                                    font.pixelSize: 9
                                    color: "#CCCCCC"
                                }
                                
                                ComboBox {
                                    id: commandCombo
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 25
                                    
                                    model: [
                                        { text: "Waypoint", value: "waypoint", icon: "W" },
                                        { text: "Takeoff", value: "takeoff", icon: "T" },
                                        { text: "Land", value: "land", icon: "L" },
                                        { text: "Return to Launch", value: "return", icon: "R" },
                                        { text: "Loiter", value: "loiter", icon: "O" },
                                        { text: "Circle", value: "circle", icon: "C" },
                                        { text: "Follow Me", value: "follow", icon: "F" }
                                    ]
                                    
                                    textRole: "text"
                                    valueRole: "value"
                                    
                                    delegate: ItemDelegate {
                                        width: commandCombo.width
                                        height: 25
                                        
                                        contentItem: Text {
                                            text: modelData.text
                                            font.pixelSize: 9
                                            color: "#FFFFFF"
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                        
                                        background: Rectangle {
                                            color: parent.hovered ? "#4CAF50" : "#2a2a2a"
                                            radius: 2
                                        }
                                    }
                                    
                                    background: Rectangle {
                                        color: "#2a2a2a"
                                        border.color: "#4a4a4a"
                                        border.width: 1
                                        radius: 2
                                    }
                                    
                                    contentItem: Text {
                                        text: commandCombo.displayText
                                        font.pixelSize: 9
                                        color: "#FFFFFF"
                                        verticalAlignment: Text.AlignVCenter
                                        leftPadding: 8
                                    }
                                    
                                    onActivated: {
                                        if (selectedWaypointIndex >= 0) {
                                            var newCommand = currentValue;
                                            updateWaypointCommand(selectedWaypointIndex, newCommand);
                                            
                                            // EXECUTE COMMAND IMMEDIATELY
                                            executeCommandImmediately(selectedWaypointIndex, newCommand);
                                        }
                                    }
                                }
                            }
                            
                            // Parameters
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                
                                // Altitude
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Text {
                                        text: "Altitude (m):"
                                        font.pixelSize: 9
                                        color: "#CCCCCC"
                                        Layout.preferredWidth: 70
                                    }
                                    
                                    SpinBox {
                                        id: altitudeSpinBox
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 25
                                        from: 0
                                        to: 1000
                                        stepSize: 1
                                        value: waypointData ? waypointData.altitude || 10 : 10
                                        
                                        background: Rectangle {
                                            color: "#2a2a2a"
                                            border.color: "#4a4a4a"
                                            border.width: 1
                                            radius: 2
                                        }
                                        
                                        contentItem: TextInput {
                                            text: altitudeSpinBox.textFromValue(altitudeSpinBox.value, altitudeSpinBox.locale)
                                            font.pixelSize: 9
                                            color: "#FFFFFF"
                                            horizontalAlignment: Qt.AlignHCenter
                                            verticalAlignment: Qt.AlignVCenter
                                            readOnly: !altitudeSpinBox.editable
                                            validator: altitudeSpinBox.validator
                                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        }
                                        
                                        onValueChanged: {
                                            if (selectedWaypointIndex >= 0) {
                                                updateWaypointAltitude(selectedWaypointIndex, value);
                                            }
                                        }
                                    }
                                }
                                
                                // Speed
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Text {
                                        text: "Speed (m/s):"
                                        font.pixelSize: 9
                                        color: "#CCCCCC"
                                        Layout.preferredWidth: 70
                                    }
                                    
                                    SpinBox {
                                        id: speedSpinBox
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 25
                                        from: 1
                                        to: 100
                                        stepSize: 1
                                        value: waypointData ? waypointData.speed || 5 : 5
                                        
                                        background: Rectangle {
                                            color: "#2a2a2a"
                                            border.color: "#4a4a4a"
                                            border.width: 1
                                            radius: 2
                                        }
                                        
                                        contentItem: TextInput {
                                            text: speedSpinBox.textFromValue(speedSpinBox.value, speedSpinBox.locale)
                                            font.pixelSize: 9
                                            color: "#FFFFFF"
                                            horizontalAlignment: Qt.AlignHCenter
                                            verticalAlignment: Qt.AlignVCenter
                                            readOnly: !speedSpinBox.editable
                                            validator: speedSpinBox.validator
                                            inputMethodHints: Qt.ImhFormattedNumbersOnly
                                        }
                                        
                                        onValueChanged: {
                                            if (selectedWaypointIndex >= 0) {
                                                updateWaypointSpeed(selectedWaypointIndex, value);
                                            }
                                        }
                                    }
                                }
                                
                                // Camera dropdown
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    Text {
                                        text: "Camera:"
                                        font.pixelSize: 9
                                        color: "#CCCCCC"
                                        Layout.preferredWidth: 70
                                    }
                                    
                                    ComboBox {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 25
                                        
                                        model: ["None", "Photo", "Video", "Survey"]
                                        
                                        background: Rectangle {
                                            color: "#2a2a2a"
                                            border.color: "#4a4a4a"
                                            border.width: 1
                                            radius: 2
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.displayText
                                            font.pixelSize: 9
                                            color: "#FFFFFF"
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: 8
                                        }
                                        
                                        delegate: ItemDelegate {
                                            width: parent.width
                                            height: 25
                                            
                                            contentItem: Text {
                                                text: modelData
                                                font.pixelSize: 9
                                                color: "#FFFFFF"
                                                verticalAlignment: Text.AlignVCenter
                                            }
                                            
                                            background: Rectangle {
                                                color: parent.hovered ? "#4CAF50" : "#2a2a2a"
                                                radius: 2
                                            }
                                        }
                                    }
                                }
                                
                                // Land checkbox
                                RowLayout {
                                    Layout.fillWidth: true
                                    
                                    CheckBox {
                                        id: landCheckbox
                                        text: "Land"
                                        
                                        indicator: Rectangle {
                                            implicitWidth: 16
                                            implicitHeight: 16
                                            x: landCheckbox.leftPadding
                                            y: parent.height / 2 - height / 2
                                            radius: 2
                                            border.color: "#4a4a4a"
                                            border.width: 1
                                            color: "#2a2a2a"
                                            
                                            Rectangle {
                                                width: 10
                                                height: 10
                                                x: 3
                                                y: 3
                                                radius: 1
                                                color: "#4CAF50"
                                                visible: landCheckbox.checked
                                            }
                                        }
                                        
                                        contentItem: Text {
                                            text: landCheckbox.text
                                            font.pixelSize: 9
                                            color: "#CCCCCC"
                                            verticalAlignment: Text.AlignVCenter
                                            leftPadding: landCheckbox.indicator.width + landCheckbox.spacing
                                        }
                                    }
                                }
                            }
                            
                            // Action buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 4
                                
                                Button {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 25
                                    text: "Delete"
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#FF5722" : (parent.hovered ? "#d32f2f" : "#2a2a2a")
                                        border.color: "#FF5722"
                                        border.width: 1
                                        radius: 2
                                        
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 9
                                        color: "#FF5722"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: {
                                        deleteWaypoint(selectedWaypointIndex);
                                        selectedWaypointIndex = -1;
                                        waypointData = null;
                                    }
                                }
                                
                                Button {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 25
                                    text: "Apply"
                                    
                                    background: Rectangle {
                                        color: parent.pressed ? "#4CAF50" : (parent.hovered ? "#66BB6A" : "#2a2a2a")
                                        border.color: "#4CAF50"
                                        border.width: 1
                                        radius: 2
                                        
                                        Behavior on color { ColorAnimation { duration: 150 } }
                                    }
                                    
                                    contentItem: Text {
                                        text: parent.text
                                        font.pixelSize: 9
                                        color: "#4CAF50"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                    
                                    onClicked: {
                                        applyWaypointChanges();
                                    }
                                }
                            }
                        }
                    }
                    
                    // Mission Command List footer
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        color: "#1e1e1e"
                        border.color: "#4a4a4a"
                        border.width: 1
                        radius: 2
                        
                        Text {
                            anchors.centerIn: parent
                            text: "Mission Command List"
                            font.pixelSize: 8
                            color: "#888888"
                        }
                    }
                }
            }
        }
    }
    
    // Waypoint Item Component
    Component {
        id: waypointItem
        
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: selectedWaypointIndex === index ? "#4CAF50" : "#444444"
            radius: 2
            border.color: "#4a4a4a"
            border.width: 1
            
            Behavior on color { ColorAnimation { duration: 150 } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 6
                spacing: 6
                
                Rectangle {
                    width: 18
                    height: 18
                    color: index === 0 ? "#FF9800" : "#4CAF50"
                    radius: 2
                    
                    Text {
                        text: getWaypointTypeIcon(index)
                        font.pixelSize: 8
                        font.bold: true
                        color: "white"
                        anchors.centerIn: parent
                    }
                }
                
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 1
                    
                    Text {
                        text: getWaypointTypeName(index)
                        font.pixelSize: 9
                        font.bold: true
                        color: selectedWaypointIndex === index ? "white" : "#FFFFFF"
                    }
                    
                    Text {
                        text: "Alt: " + (getWaypointAltitude(index) || 10) + "m"
                        font.pixelSize: 8
                        color: selectedWaypointIndex === index ? "#E8F5E8" : "#CCCCCC"
                    }
                }
                
                Text {
                    text: (index + 1).toString()
                    font.pixelSize: 8
                    font.bold: true
                    color: selectedWaypointIndex === index ? "white" : "#888888"
                }
            }
            
            MouseArea {
                anchors.fill: parent
                onClicked: selectWaypoint(index)
            }
        }
    }
    
    // Functions
    function show() {
        visible = true;
        expanded = true;
    }
    
    function hide() {
        expanded = false;
        visible = false;
    }
    
    function updateWaypoints(newWaypoints) {
        console.log("Dashboard updateWaypoints called with:", newWaypoints ? newWaypoints.length : 0, "waypoints");
        waypoints = [];
        waypoints = newWaypoints || [];
        console.log("Dashboard waypoints updated to length:", waypoints.length);
        
        if (selectedWaypointIndex >= 0 && selectedWaypointIndex < waypoints.length) {
            waypointData = waypoints[selectedWaypointIndex];
            updateEditorFields();
        } else if (selectedWaypointIndex >= waypoints.length) {
            selectedWaypointIndex = -1;
            waypointData = null;
        }
    }
    
    function selectWaypoint(index) {
        selectedWaypointIndex = index;
        
        if (typeof mapWebView !== 'undefined' && mapWebView.runJavaScript) {
            mapWebView.runJavaScript(`
                if (markers[${index}]) {
                    JSON.stringify(markers[${index}]);
                } else {
                    null;
                }
            `, function(result) {
                if (result) {
                    try {
                        waypointData = JSON.parse(result);
                        updateEditorFields();
                    } catch (e) {
                        console.log("Error parsing waypoint data:", e);
                    }
                }
            });
        }
    }
    
    function updateEditorFields() {
        if (waypointData) {
            altitudeSpinBox.value = waypointData.altitude || 10;
            speedSpinBox.value = waypointData.speed || 5;
            
            var commandType = waypointData.commandType || "waypoint";
            for (var i = 0; i < commandCombo.model.length; i++) {
                if (commandCombo.model[i].value === commandType) {
                    commandCombo.currentIndex = i;
                    break;
                }
            }
        }
    }
    
    function updateWaypointCommand(index, commandType) {
        if (typeof mapWebView !== 'undefined' && mapWebView.runJavaScript) {
            mapWebView.runJavaScript(`
                if (markers[${index}]) {
                    markers[${index}].commandType = '${commandType}';
                    updateMarkerIcon(${index});
                }
            `);
            
            if (waypoints && waypoints[index]) {
                waypoints[index].commandType = commandType;
                var tempWaypoints = waypoints.slice();
                waypoints = [];
                waypoints = tempWaypoints;
            }
        }
    }
    
    function updateWaypointAltitude(index, altitude) {
        if (typeof mapWebView !== 'undefined' && mapWebView.runJavaScript) {
            mapWebView.runJavaScript(`
                if (markers[${index}]) {
                    markers[${index}].altitude = ${altitude};
                }
            `);
            if (waypoints && waypoints[index]) {
                waypoints[index].altitude = altitude;
            }
        }
    }
    
    function updateWaypointSpeed(index, speed) {
        if (typeof mapWebView !== 'undefined' && mapWebView.runJavaScript) {
            mapWebView.runJavaScript(`
                if (markers[${index}]) {
                    markers[${index}].speed = ${speed};
                }
            `);
            if (waypoints && waypoints[index]) {
                waypoints[index].speed = speed;
            }
        }
    }
    
    function deleteWaypoint(index) {
        if (typeof mapWebView !== 'undefined' && mapWebView.deleteMarkerJS) {
            mapWebView.deleteMarkerJS(index);
        }
    }
    
    function applyWaypointChanges() {
        selectedWaypointIndex = -1;
        waypointData = null;
    }
    
    // NEW: Execute command immediately when changed
    function executeCommandImmediately(index, commandType) {
        console.log("Executing command:", commandType, "for waypoint:", index);
        
        var currentData = waypointData || {};
        currentData.commandType = commandType;
        currentData.index = index;
        
        // Emit signal to main window to handle execution
        executeWaypointCommand(index, commandType, currentData);
    }
    
    function getWaypointTypeIcon(index) {
        if (waypoints && waypoints[index]) {
            var commandType = waypoints[index].commandType || "waypoint";
            switch(commandType) {
                case "takeoff": return "T";
                case "land": return "L";
                case "return": return "R";
                case "loiter": return "O";
                case "circle": return "C";
                case "follow": return "F";
                default: return index === 0 ? "H" : "W";
            }
        }
        return index === 0 ? "H" : "W";
    }
    
    function getWaypointTypeName(index) {
        if (waypoints && waypoints[index]) {
            var commandType = waypoints[index].commandType || "waypoint";
            switch(commandType) {
                case "takeoff": return "Takeoff";
                case "land": return "Land";
                case "return": return "Return to Launch";
                case "loiter": return "Loiter";
                case "circle": return "Circle";
                case "follow": return "Follow Me";
                default: return index === 0 ? "Home" : "Waypoint";
            }
        }
        return index === 0 ? "Home" : "Waypoint";
    }
    
    function getWaypointAltitude(index) {
        if (waypoints && waypoints[index]) {
            return waypoints[index].altitude || 10;
        }
        return 10;
    }
    
    function getWaypointSpeed(index) {
        if (waypoints && waypoints[index]) {
            return waypoints[index].speed || 5;
        }
        return 5;
    }
}