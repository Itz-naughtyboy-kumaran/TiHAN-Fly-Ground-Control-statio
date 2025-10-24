// CustomMap.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtLocation 5.15
import QtPositioning 5.15
import QtQuick.Layouts 1.0


ApplicationWindow {
    visible: true
    width: 1500
    height: 900
    title: "TiHAN Ground Station"
    
    
     // Workaround: Use an invisible Image to load the icon (ensures QML recognizes the file)


    property bool loggedIn: true// This will toggle when the user logs in
    property var flightPath: []


    // Signal to notify successful login
    // Background container to ensure proper layering




    // Loader to load login.qml if user is not logged in
    Loader {
        id: loginLoader
       anchors.fill: parent
     active: !loggedIn // Only active when loggedIn is false
     source: "Login.qml"

       onLoaded: {
            //After login.qml is loaded, connect its signal to main.qml
            loginLoader.item.loginSignal.connect(function() {
               loggedIn = true // Set loggedIn property to true after login
            })
        }
   }
   

    //waypoint Model data
    ListModel {
        id: markerModel
    }
    
    // Main contnt (visible only if logged in)
    Rectangle {
        visible: loggedIn // Only visible when logged in
        anchors.fill: parent
        color: "#f1f1f1"
         QtObject {
        id: theme
        property color primary: "#2c3e50"
        property color accent: "#3498db"
        property color success: "#2ecc71"
        property color error: "#e74c3c"
        property color cardBackground: "#ffffff"
        property color textPrimary: "#2c3e50"
        property color textSecondary: "#7f8c8d"
        property int borderRadius: 8
    }

    
    Rectangle {
    id: header
    width: parent.width
    height: 70
    color: "#3498db"  // Navbar background color
    border.color: "#0047a5"
    z: 2

    Image {
        source: "./images/tihan.png"
        width: 75  // Slightly bigger
        height: 75
        fillMode: Image.PreserveAspectFit  // Prevent stretching
        anchors.right: parent.right
        anchors.rightMargin: 20  // Adjust spacing from right
        anchors.verticalCenter: parent.verticalCenter  // Keep it centered

        MouseArea {
            anchors.fill: parent
            onClicked: Qt.openUrlExternally("https://example.com")
        }
    }






              RowLayout {
                  anchors.fill: parent
                  anchors.margins: 10
                  spacing: 20

  Button {
    id: menuToggle
    text: sidebar.opened ? "✖" : "☰"
    contentItem: Text {
        text: parent.text
        color: "white"
        font.pixelSize: 24
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        color: "transparent"
    }
    onClicked: {
        if (sidebar.opened) {
            sidebar.close();  // Close when clicking "✖"
        } else {
            sidebar.open();   // Open when clicking "☰"
        }
    }
}




                  Text {
                      text: "TiHAN Fly"
                      anchors.centerIn: parent
                      font.pixelSize: 24
                      font.bold: true
                      color: "#0047a5"
                  }

                             }
                         }


        
    

    Plugin {
        id: mapPlugin
        name: "osm"
        
        parameters: [
            PluginParameter { 
                name: "osm.mapping.custom.host" 
                value: "https://a.tile.openstreetmap.fr/hot/"
            },
            PluginParameter {
                name: "osm.mapping.providersrepository.disabled"
                value: true
            },
            PluginParameter {
                name: "osm.mapping.cache.directory"
                value: "/tmp/osmcache"
            },
            PluginParameter {
                name: "osm.mapping.cache.disk.size"
                value: 50000000
            }
        ]
    }

    Map {
        id: map
        anchors.fill: parent
        plugin: mapPlugin
        center: QtPositioning.coordinate()
        zoomLevel: 19

        PinchHandler {
            id: pinch
            target: null
            onActiveChanged: if (active) {
                map.startCentroid = map.toCoordinate(pinch.centroid.position, false)
            }
            onScaleChanged: (delta) => {
                map.zoomLevel += Math.log2(delta)
            }
        }

        DragHandler {
            id: drag
            target: null
            onTranslationChanged: (delta) => {
                var coordinate = map.toCoordinate(Qt.point(width/2 + delta.x, height/2 + delta.y))
                map.center = coordinate
            }
        }

        WheelHandler {
            id: wheel
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            rotationScale: 1/120
            property: "zoomLevel"
        }

        MouseArea {
            anchors.fill: parent
            onClicked: (mouse) => {
                var coordinate = map.toCoordinate(Qt.point(mouse.x, mouse.y))
                addMarker(coordinate.latitude, coordinate.longitude)
                console.log("Marker added at:", coordinate.latitude, coordinate.longitude)
            }
        }
// Property to store the zoom animation
PropertyAnimation {
    id: zoomAnimation
    target: map
    property: "zoomLevel"
    duration: 1000  // 1-second animation
}
MapQuickItem {
    id: droneMarker
    coordinate: QtPositioning.coordinate(0, 0)  // Placeholder
    anchorPoint: Qt.point(16, 16)  // Center point of the image
    visible: false  // Hidden until valid location is received

    sourceItem: Item {
        width: 48
        height: 48

        Image {
            id: droneImage
            source: "file:///home/tihan_husky/Desktop/TFly%202.0%20(2)%20(1)/TFly%202.0/TihanFly-v.0.1/images/drone.png"
            width: parent.width
            height: parent.height
            fillMode: Image.PreserveAspectFit
        }

        // Click event to zoom in on the drone
        MouseArea {
            anchors.fill: parent
            onClicked: {
                console.log("🔍 Zooming into drone location...");

                // Start zoom-in animation
                zoomAnimation.from = map.zoomLevel;
                zoomAnimation.to = 19;
                zoomAnimation.start();

                // Center the map on the drone location
                map.center = droneMarker.coordinate;
          
              }
                }
        
    Component.onCompleted: {
        console.log("MapQuickItem Loaded!");
    }

     


                MouseArea {
                    id: markerMouseArea
                    anchors.fill: parent
                    onClicked: {
                        markerPopup.visible = true
                    }
                }

                Popup {
                    id: markerPopup
                    x: map.toScreenCoordinate(coordinate).x
                    y: map.toScreenCoordinate(coordinate).y - 70
                    width: 250
                    height: 150
                    visible: false

                    Rectangle {
                        width: parent.width
                        height: parent.height
                        color: "#FFFFFF"
                        border.color: "#D1D1D1"
                        border.width: 1
                        radius: 8

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 10

                            Text {
                                text: "Latitude: " + model.lat
                                font.pixelSize: 14
                                color: "#333333"
                            }

                            Text {
                                text: "Longitude: " + model.lon
                                font.pixelSize: 14
                                color: "#333333"
                            }
                        }
                    }
                }
            
        }

        MapPolyline {
            id: routeLine
            line.width: 3
            line.color: "red"
            path: []
        }
    }
    }
      Drawer {
    id: sidebar
    width: 300
    height: parent.height - 70
    y: header.height
    modal: false
    background: Rectangle {
        color: "#2c3e50"
        radius: 12
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#1a2530"
            Layout.bottomMargin: 10
        }
        
        Text {
            text: "CONTROL PANEL"
            color: "#ecf0f1"
            font.pixelSize: 14
            font.bold: true
            font.letterSpacing: 1.2
            Layout.bottomMargin: 10
        }
        
        Button {
            id: flightButton
            text: "Open Flight Controls"
            Layout.fillWidth: true
            height: 50
            
            property bool isActive: flightControlsLoader.source.toString().includes("BasicFlightControls.qml")
            
            background: Rectangle {
                color: flightButton.isActive ? "#2980b9" : (flightButton.hovered ? "#3498db" : "#34495e")
                radius: 8
                border.width: 1
                border.color: flightButton.isActive ? "#2980b9" : "#2c3e50"
                
                Rectangle {
                    width: 4
                    height: parent.height
                    color: flightButton.isActive ? "#3498db" : "transparent"
                    anchors.left: parent.left
                    radius: 2
                }
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            contentItem: RowLayout {
                spacing: 10
                
                Rectangle {
                    width: 24
                    height: 24
                    color: "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "✈️"
                        font.pixelSize: 16
                    }
                }
                
                Text {
                    text: "Flight Controls"
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }
                
                Rectangle {
                    width: 16
                    height: 16
                    color: "transparent"
                    visible: flightButton.isActive
                    
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }
            
            onClicked: {
                flightControlsLoader.source = ""; // Reset first
                flightControlsLoader.source = "BasicFlightControls.qml";
            }
        }
        
        Button {
            id: navButton
            text: "Open Navigation Controls"
            Layout.fillWidth: true
            height: 50
            Layout.topMargin: 5
            
            property bool isActive: flightControlsLoader.source.toString().includes("NavigationControls.qml")
            
            background: Rectangle {
                color: navButton.isActive ? "#1e8449" : (navButton.hovered ? "#27ae60" : "#34495e")
                radius: 8
                border.width: 1
                border.color: navButton.isActive ? "#1e8449" : "#2c3e50"
                
                Rectangle {
                    width: 4
                    height: parent.height
                    color: navButton.isActive ? "#27ae60" : "transparent"
                    anchors.left: parent.left
                    radius: 2
                }
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            contentItem: RowLayout {
                spacing: 10
                
                Rectangle {
                    width: 24
                    height: 24
                    color: "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "🧭"
                        font.pixelSize: 16
                    }
                }
                
                Text {
                    text: "Navigation Controls"
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }
                
                Rectangle {
                    width: 16
                    height: 16
                    color: "transparent"
                    visible: navButton.isActive
                    
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }
            
            onClicked: {
                flightControlsLoader.source = ""; // Reset first
                flightControlsLoader.source = "NavigationControls.qml";
            }
        }
        
        Button {
            id: settingsButton
            text: "Open Settings"
            Layout.fillWidth: true
            height: 50
            Layout.topMargin: 5
            
            property bool isActive: flightControlsLoader.source.toString().includes("Settings.qml")
            
            background: Rectangle {
                color: settingsButton.isActive ? "#d35400" : (settingsButton.hovered ? "#e67e22" : "#34495e")
                radius: 8
                border.width: 1
                border.color: settingsButton.isActive ? "#d35400" : "#2c3e50"
                
                Rectangle {
                    width: 4
                    height: parent.height
                    color: settingsButton.isActive ? "#e67e22" : "transparent"
                    anchors.left: parent.left
                    radius: 2
                }
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            contentItem: RowLayout {
                spacing: 10
                
                Rectangle {
                    width: 24
                    height: 24
                    color: "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "⚙️"
                        font.pixelSize: 16
                    }
                }
                
                Text {
                    text: "Settings"
                    color: "#ffffff"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    Layout.fillWidth: true
                }
                
                Rectangle {
                    width: 16
                    height: 16
                    color: "transparent"
                    visible: settingsButton.isActive
                    
                    Text {
                        anchors.centerIn: parent
                        text: "✓"
                        color: "#ffffff"
                        font.pixelSize: 14
                        font.bold: true
                    }
                }
            }
            
            onClicked: {
                flightControlsLoader.source = ""; // Reset first
                flightControlsLoader.source = "Settings.qml";
            }
        }
        
        Item {
            Layout.fillHeight: true
        }
        
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#1a2530"
            Layout.topMargin: 10
            Layout.bottomMargin: 10
        }
        
        Text {
            text: "App v1.0.3"
            color: "#95a5a6"
            font.pixelSize: 12
            horizontalAlignment: Text.AlignRight
            Layout.fillWidth: true
        }
    }
}

Loader {
    id: flightControlsLoader
    anchors.centerIn: parent
}

  
    Rectangle {
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 2
        color: "transparent"
        height: minimalAttribution.height + 2
        width: minimalAttribution.width + 4

        Text {
            id: minimalAttribution
            text: "© OSM"
            font.pixelSize: 6
            color: "#40000000"
            anchors.centerIn: parent
        }
    }

    // Replace your current drone connection interface with this code
// Position at bottom left corner with integrated add drone input
property var coordinate: null  // Ensure this is initialized
Rectangle {
    id: droneConnectionPanel
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: 20
    width: 500
    height: 400
    color: "#f9f9f9"
    radius: 8
    border.color: "#e0e0e0"
    border.width: 1

    property bool showAddDroneInput: false

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 12

        Text {
            text: "Drone Connection Manager"
            font.pixelSize: 18
            font.bold: true
            color: "#34495e"
        }
        
        // Add Drone Input Section (conditionally visible)
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#ecf0f1"
            radius: 6
            visible: droneConnectionPanel.showAddDroneInput
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10
                
                Text {
                    text: "Number of drones:"
                    font.pixelSize: 14
                    color: "#34495e"
                }
                
                TextField {
                    id: droneCountInput
                    color: black
                    Layout.fillWidth: true
                    placeholderText: "Enter number"
                    validator: IntValidator { bottom: 1 }
                    
                    background: Rectangle {
                        border.color: droneCountInput.focus ? "#3498db" : "#bdc3c7"
                        border.width: 1
                        radius: 4
                    }
                }
                
                Button {
                    id: confirmAddButton
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 40
                    
                    background: Rectangle {
                        color: confirmAddButton.hovered ? "#1e8449" : "#34495e"
                        radius: 8
                        
                        Rectangle {
                            width: 4
                            height: parent.height
                            color: confirmAddButton.hovered ? "#27ae60" : "transparent"
                            anchors.left: parent.left
                            radius: 2
                        }
                    }
                    
                    contentItem: Text {
                        text: "Confirm"
                        color: "#ffffff"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        if (droneCountInput.text.length > 0) {
                            var count = parseInt(droneCountInput.text)
                            for (var i = 0; i < count; i++) {
                                droneModel.append({"connectionString": "", "connected": false})
                            }
                            droneCountInput.text = ""
                            droneConnectionPanel.showAddDroneInput = false
                        }
                    }
                }
                
                Button {
                    id: cancelAddButton
                    Layout.preferredWidth: 80
                    Layout.preferredHeight: 40
                    
                    background: Rectangle {
                        color: cancelAddButton.hovered ? "#922b21" : "#34495e"
                        radius: 8
                        
                        Rectangle {
                            width: 4
                            height: parent.height
                            color: cancelAddButton.hovered ? "#c0392b" : "transparent"
                            anchors.left: parent.left
                            radius: 2
                        }
                    }
                    
                    contentItem: Text {
                        text: "Cancel"
                        color: "#ffffff"
                        font.pixelSize: 14
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        droneCountInput.text = ""
                        droneConnectionPanel.showAddDroneInput = false
                    }
                }
            }
        }
        
        ListView {
            id: droneListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: droneModel
            spacing: 8
            
            delegate: Item {
                width: ListView.view.width
                height: 50
                
                RowLayout {
                    anchors.fill: parent
                    spacing: 8
                    
                    TextField {
                        id: connectionStringField
                        color: black
                        Layout.fillWidth: true
                        text: model.connectionString
                        placeholderText: "Enter connection string"
                        onTextChanged: {
                            model.connectionString = text
                        }
                        
                        background: Rectangle {
                            border.color: connectionStringField.focus ? "#3498db" : "#bdc3c7"
                            border.width: 1
                            radius: 4
                        }
                    }
                    
                    Button {
                        id: removeButton
                        Layout.preferredWidth: 100
                        Layout.preferredHeight: 40
                        
                        background: Rectangle {
                            color: removeButton.hovered ? "#922b21" : "#34495e"
                            radius: 8
                            
                            Rectangle {
                                width: 4
                                height: parent.height
                                color: removeButton.hovered ? "#c0392b" : "transparent"
                                anchors.left: parent.left
                                radius: 2
                            }
                        }
                        
                        contentItem: RowLayout {
                            spacing: 6
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            
                            Text {
                                text: "🗑️"
                                font.pixelSize: 16
                                Layout.alignment: Qt.AlignVCenter
                                color: "#ffffff"
                            }
                            
                            Text {
                                text: "Remove"
                                color: "#ffffff"
                                font.pixelSize: 14
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                        
                        onClicked: droneModel.remove(index)
                    }
                }
            }
        }
        
        // Buttons at the bottom
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            
            Button {
                id: addDroneButton
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                visible: !droneConnectionPanel.showAddDroneInput
                
                background: Rectangle {
                    color: addDroneButton.hovered ? "#2874a6" : "#34495e"
                    radius: 8
                    
                    Rectangle {
                        width: 4
                        height: parent.height
                        color: addDroneButton.hovered ? "#3498db" : "transparent"
                        anchors.left: parent.left
                        radius: 2
                    }
                }
                
                contentItem: RowLayout {
                    spacing: 10
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    
                    Text {
                        text: "➕"
                        font.pixelSize: 16
                        Layout.alignment: Qt.AlignVCenter
                        color: "#ffffff"
                    }
                    
                    Text {
                        text: "Add Drone"
                        color: "#ffffff"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                
                onClicked: {
                    droneConnectionPanel.showAddDroneInput = true
                }
            }
            
            // New single connect button
            Button {
                id: connectAllButton
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                visible: !droneConnectionPanel.showAddDroneInput && droneModel.count > 0
                
                background: Rectangle {
                    color: connectAllButton.hovered ? "#1e8449" : "#34495e"
                    radius: 8
                    
                    Rectangle {
                        width: 4
                        height: parent.height
                        color: connectAllButton.hovered ? "#27ae60" : "transparent"
                        anchors.left: parent.left
                        radius: 2
                    }
                }
                
                contentItem: RowLayout {
                    spacing: 10
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    
                    Text {
                        text: "🔗"
                        font.pixelSize: 16
                        Layout.alignment: Qt.AlignVCenter
                        color: "#ffffff"
                    }
                    
                    Text {
                        text: "Connect All Drones"
                        color: "#ffffff"
                        font.pixelSize: 14
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
                
                onClicked: {
                    // Connect all drones with valid connection strings
                    console.log("Connecting all drones")
                    var validConnectionCount = 0
                    
                    for (var i = 0; i < droneModel.count; i++) {
                        var connectionString = droneModel.get(i).connectionString
                        if (connectionString && connectionString.trim() !== "") {
                            console.log("Connecting to drone:", connectionString)
                            connectToDrone(connectionString, i)
                            droneModel.setProperty(i, "connected", true)
                            validConnectionCount++
                        }
                    }
                    
                    if (validConnectionCount === 0) {
                        connectionErrorDialog.text = "No valid connection strings found.\nPlease enter at least one connection string."
                        connectionErrorDialog.open()
                    }
                }
            }
        }
    }
}

ListModel {
    id: droneModel
}

// Dialog for connection errors
Dialog {
    id: connectionErrorDialog
    title: "Connection Error"
    modal: true
    standardButtons: Dialog.Ok
    property string text: "Failed to establish connection with the drone.\nPlease check the connection string and try again."
    
    background: Rectangle {
        color: "#ffffff"
        radius: 8
        border.color: "#e0e0e0"
        border.width: 1
    }
    
    Text {
        anchors.centerIn: parent
        text: connectionErrorDialog.text
        color: "#e74c3c"
    }
}
    }
// Connection function
function connectToDrone(connectionString, index) {
    if (!connectionString || connectionString.trim() === "") {
        console.log("❌ Error: Connection string is required");
        return;
    }

    console.log("🚀 Connecting to:", connectionString);

    var request = new XMLHttpRequest();
    request.open("POST", "http://127.0.0.1:5000/connect", true);
    request.setRequestHeader("Content-Type", "application/json");

    var data = JSON.stringify({
        "connection_string": connectionString
    });

    request.onreadystatechange = function() {
        if (request.readyState === 4) {
            console.log("📩 Server Response:", request.responseText);
            if (request.status === 200) {
                console.log("✅ Drone connected successfully!");

                // Fetch the drone's live location
                getDroneLocation(connectionString);
            } else {
                console.log("❌ Failed to connect drone:", request.responseText);
                connectionErrorDialog.text = "Failed to connect to drone: " + connectionString + "\nPlease check the connection string and try again.";
                connectionErrorDialog.open();
                if (index !== undefined) {
                    droneModel.setProperty(index, "connected", false);
                }
            }
        }
    };

    request.send(data);
}

// Function to get the drone's location and update the marker
function getDroneLocation(droneID) {
    var request = new XMLHttpRequest();
    request.open("GET", "http://127.0.0.1:5000/drone_location/" + encodeURIComponent(droneID), true);

    request.onreadystatechange = function() {
        if (request.readyState === 4 && request.status === 200) {
            var response = JSON.parse(request.responseText);
            var latitude = response.latitude;
            var longitude = response.longitude;

            console.log("📍 Drone Location: ", latitude, longitude);

            // Update the drone marker position
            droneMarker.coordinate = QtPositioning.coordinate(latitude, longitude);
            droneMarker.visible = true;

            // Zoom out to view the larger area
            map.zoomLevel = 12;
            map.center = droneMarker.coordinate;
        } else if (request.readyState === 4) {
            console.log("❌ Error fetching drone location:", request.responseText);
        }
    };

    request.send();
}
    

}