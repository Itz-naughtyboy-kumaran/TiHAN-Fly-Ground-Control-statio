import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Window 2.15
import QtWebEngine 1.10
import QtPositioning 5.15
import QtQuick.Layouts 1.0
import QtGraphicalEffects 1.10
import QtQuick.Dialogs 1.3
import Qt.labs.platform 1.1 // For FileDialog

ApplicationWindow {
    id: mainWindow
    visible: true
    visibility: "Maximized"
    title: "TiHAN Fly-Drone Control Station"
    color: "#f8f9fa"  // Light background
    property var referencePoint: QtPositioning.coordinate(17.601588777182204, 78.12690006798547)
    property var lastClickedCoordinate: null
    property var waypoints: []
    property bool isDragging: false
    property var pendingWaypointData: ""  // ✅ Correct

    QtObject {
        id: theme
        property color primary: "#ffffff"
        property color accent: "#007bff"
        property color success: "#28a745"
        property color error: "#dc3545"
        property color cardBackground: "#ffffff"
        property color textPrimary: "#212529"
        property color textSecondary: "#6c757d"
        property color border: "#dee2e6"
        property int borderRadius: 8
    }
LanguageManager {
    id: languageManager
}


FileDialog {
    id: saveWaypointsDialog
    title: "Save Waypoints File"
    fileMode: FileDialog.SaveFile
    nameFilters: ["Waypoints Files (*.waypoints)"]
    defaultSuffix: "waypoints"
    folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)

    onAccepted: {
        var path = file.toString().replace("file://", "");
        if (!path.endsWith(".waypoints"))
            path += ".waypoints";

        console.log("💾 Saving to:", path);

        // Save using Python helper
        var success = waypointsSaver.save_file(path, pendingWaypointData);
        if (success) {
            console.log("✅ Waypoints saved at: " + path);
            statusNotification.color = theme.success;
            statusNotification.children[0].text = "✅ File saved: " + path;
        } else {
            console.log("❌ Save failed");
            statusNotification.color = theme.error;
            statusNotification.children[0].text = "Error saving file!";
        }
        mainWindow.statusNotification.opacity = 1;

        statusNotificationTimer.restart();
    }

    onRejected: {
        console.log("⚠️ Save canceled by user");
    }
}

FileDialog {
    id: openWaypointsDialog
    title: "Select Waypoints File"
    fileMode: FileDialog.OpenFile
    nameFilters: ["Waypoints Files (*.waypoints *.mission)"]
    folder: StandardPaths.writableLocation(StandardPaths.DocumentsLocation)
    onAccepted: {
        var path = file.toString().replace("file://", "");
        console.log("📂 Selected file:", path);
        selectedFileText.text = path;

        // Load file content immediately
        var content = waypointsSaver.load_file(path);
        if (content && content.length > 0) {
            loadDataInput.text = content;  // show content in text box for confirmation
        } else {
            statusNotification.color = theme.error;
            statusNotification.children[0].text = "⚠️ Failed to read file.";
            mainWindow.statusNotification.opacity = 1;

            statusNotificationTimer.restart();
        }
    }
    onRejected: {
        console.log("⚠️ File selection canceled");
    }
}
    // Header
   // Updated Header section with Language Dropdown
Rectangle {
    id: header
    width: parent.width
    height: 70
    color: "#ffffff"
    border.color: theme.border
    border.width: 1
    z: 2

    Rectangle {
        width: parent.width
        height: 2
        anchors.bottom: parent.bottom
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#00000020" }
            GradientStop { position: 1.0; color: "transparent" }
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
                color: theme.textPrimary
                font.pixelSize: 24
                font.family: "Consolas"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            background: Rectangle { 
                color: parent.hovered ? "#f8f9fa" : "transparent"
                radius: 6
            }
            onClicked: sidebar.opened ? sidebar.close() : sidebar.open()
        }

        Item { Layout.fillWidth: true }

        Text {
            text: "TiHAN FLY"
            font.pixelSize: 24
            font.bold: true
            font.family: "Consolas"
            color: "#007bff"
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        }

        Item { Layout.fillWidth: true }

        // Language Dropdown Button
        Button {
            id: languageButton
            width: 120
            height: 40
            Layout.alignment: Qt.AlignVCenter
            
            background: Rectangle {
                color: languageButton.pressed ? "#e9ecef" : 
                       (languageButton.hovered ? "#f8f9fa" : "#ffffff")
                radius: 6
                border.color: theme.border
                border.width: 1
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            contentItem: RowLayout {
                spacing: 8
                anchors.centerIn: parent
                
                Text {
                    text: "🌐"
                    font.pixelSize: 16
                    color: theme.textPrimary
                }
                
                Text {
                    text: languageManager.getLanguageName(languageManager.currentLanguage)
                    font.pixelSize: 12
                    font.family: "Consolas"
                    color: theme.textPrimary
                    Layout.fillWidth: true
                }
                
                Text {
                    text: languageDropdown.visible ? "▲" : "▼"
                    font.pixelSize: 10
                    color: theme.textSecondary
                }
            }
            
            onClicked: {
                languageDropdown.visible = !languageDropdown.visible
            }
        }
    }

    Image {
        source: "../images/tihan.png"
        width: 70
        height: 70
        fillMode: Image.PreserveAspectFit
        anchors.right: parent.right
        anchors.rightMargin: 15
        anchors.verticalCenter: parent.verticalCenter
        smooth: true
    }

    // Language Dropdown Menu
    Rectangle {
        id: languageDropdown
        width: 180
        height: Math.min(languageManager.availableLanguages.length * 45 + 10, 200)
        anchors.top: parent.bottom
        anchors.topMargin: 5
        anchors.right: parent.right
        anchors.rightMargin: 100
        color: "#ffffff"
        radius: 8
        border.color: theme.border
        border.width: 1
        visible: false
        z: 1000
        
        // Drop shadow effect
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 3
            anchors.leftMargin: 3
            color: "#00000020"
            radius: parent.radius
            z: -1
        }

        ListView {
            id: languageListView
            anchors.fill: parent
            anchors.margins: 5
            model: languageManager.availableLanguages
            clip: true
            
            delegate: Rectangle {
                width: languageListView.width
                height: 40
                color: mouseArea.containsMouse ? "#f8f9fa" : "transparent"
                radius: 4
                
                property bool isCurrentLanguage: modelData.code === languageManager.currentLanguage
                
                Rectangle {
                    anchors.fill: parent
                    color: parent.isCurrentLanguage ? "#007bff" : "transparent"
                    radius: parent.radius
                    opacity: 0.1
                }
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 10
                    
                    Text {
                        text: modelData.nativeName
                        font.pixelSize: 13
                        font.family: "Consolas"
                        color: parent.parent.isCurrentLanguage ? theme.accent : theme.textPrimary
                        font.bold: parent.parent.isCurrentLanguage
                        Layout.fillWidth: true
                    }
                    
                    Text {
                        text: parent.parent.isCurrentLanguage ? "✓" : ""
                        font.pixelSize: 14
                        color: theme.accent
                        font.bold: true
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        languageManager.changeLanguage(modelData.code)
                        languageDropdown.visible = false
                        console.log("Language changed to:", modelData.code, modelData.nativeName)
                    }
                }
            }
        }
    }
    
    // Close dropdown when clicking outside
    MouseArea {
        anchors.fill: parent
        enabled: languageDropdown.visible
        onClicked: languageDropdown.visible = false
        z: -1
    }
}
    // Status notification
    Item {
        id: parametersWindowRoot

        Rectangle {
            id: statusNotification
            anchors.top: parametersWindowRoot.top
            anchors.horizontalCenter: parametersWindowRoot.horizontalCenter
            anchors.topMargin: 100
            width: 300
            height: 50
            color: theme.success
            radius: 8
            opacity: 0
            z: 1000
            
            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 2
                color: "#00000015"
                radius: parent.radius
                z: -1
            }
        
            Label {
                anchors.centerIn: parent
                text: "Parameter updated successfully!"
                color: "white"
                font.pixelSize: 12
                font.bold: true
                font.family: "Consolas"
            }
            
            Behavior on opacity {
                NumberAnimation { duration: 300 }
            }
        }
        
        Timer {
            id: statusNotificationTimer
            interval: 2000
            onTriggered: statusNotification.opacity = 0
        }
    }

    // Google Maps WebEngine Implementation
    Rectangle {
        id: mapContainer
        anchors.fill: parent
        anchors.topMargin: header.height
        color: "#0a0a0a"
        radius: 8
        border.color: "#404040"
        border.width: 1

        WebEngineView {
            id: mapWebView
            anchors.fill: parent
            anchors.margins: 2

            property bool addMarkersMode: false
            property real currentLat: droneModel.telemetry.lat
            property real currentLon: droneModel.telemetry.lon
            property var markersList: []

            url: "data:text/html," + encodeURIComponent(`
                <!DOCTYPE html>
                <html>
                <head>
                    <meta charset="utf-8">
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <title>Drone Map</title>
                    <style>
                        body, html { margin: 0; padding: 0; height: 100%; font-family: Arial, sans-serif; }
                        #map { height: 100%; }
                        .info-panel {
                            position: absolute;
                            bottom: 10px;
                            left: 10px;
                            background: rgba(26, 26, 26, 0.9);
                            color: #e0e0e0;
                            padding: 8px 12px;
                            border-radius: 6px;
                            font-size: 12px;
                            border: 1px solid #404040;
                        }
                        .drone-marker {
                            width: 24px;
                            height: 24px;
                            background: linear-gradient(45deg, #00e676, #00c853);
                            border: 3px solid white;
                            border-radius: 50%;
                            position: relative;
                            animation: pulse 2s infinite;
                        }
                        .drone-marker::before {
                            content: '';
                            position: absolute;
                            top: -3px;
                            left: 50%;
                            transform: translateX(-50%);
                            width: 3px;
                            height: 12px;
                            background: white;
                            border-radius: 2px;
                        }
                        @keyframes pulse {
                            0% { box-shadow: 0 0 0 0 rgba(0, 188, 212, 0.7); }
                            70% { box-shadow: 0 0 0 20px rgba(0, 188, 212, 0); }
                            100% { box-shadow: 0 0 0 0 rgba(0, 188, 212, 0); }
                        }
                        .gm-style-cc, .gm-bundled-control, .gmnoprint, .gm-watermark {
                            display: none !important;
                        }
                        .gm-style .gm-style-cc {
                            display: none !important;
                        }
                        div[style*="background-color: rgba(0, 0, 0, 0.5)"],
                        div[style*="background: rgba(0, 0, 0, 0.5)"] {
                            display: none !important;
                        }
                        [class*="watermark"], [id*="watermark"] {
                            display: none !important;
                        }
                        .gm-style > div > div > div > div[style*="position: absolute"] > div[style*="background"] {
                            display: none !important;
                        }
                        .gm-style > div:first-child > div + div + div {
                            display: none !important;
                        }
                    </style>
                </head>
                <body>
                    <div id="map"></div>
                    <div class="info-panel" id="infoPanel">
                        <div>Lat: <span id="lat">0.000000</span>° Lon: <span id="lon">0.000000</span>°</div>
                        <div>Zoom: <span id="zoom">2</span> | Satellite View</div>
                    </div>

                    <script>
                        let map;
                        let droneMarker;
                        let markers = [];
                        let routePath;
                        let addMarkersMode = false;
                        let isDragging = false;
                        
                        function initMap() {
                            const initialCenter = { lat: 17.601588777182204, lng: 78.12690006798547 };
                            
                            map = new google.maps.Map(document.getElementById('map'), {
                                zoom: 2, // Start zoomed out to show world view
                                center: { lat: 0, lng: 0 }, // Center on world
                                mapTypeId: google.maps.MapTypeId.SATELLITE,
                                disableDefaultUI: false,
                                zoomControl: false,
                                mapTypeControl: true,
                                scaleControl: true,
                                streetViewControl: false,
                                rotateControl: true,
                                fullscreenControl: false,
                                styles: [
                                    {
                                        featureType: "poi",
                                        stylers: [{ visibility: "off" }]
                                    }
                                ]
                            });

                            // Create drone marker (initially hidden)
                            droneMarker = new google.maps.Marker({
                                position: initialCenter,
                                map: null, // Don't show initially
                                title: 'Drone Position',
                                icon: {
                                    url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent('<svg width="30" height="30" xmlns="http://www.w3.org/2000/svg"><circle cx="15" cy="15" r="12" fill="%2300e676" stroke="white" stroke-width="3"/><circle cx="15" cy="15" r="3" fill="white"/></svg>'),
                                    size: new google.maps.Size(30, 30),
                                    anchor: new google.maps.Point(15, 15)
                                }
                            });

                            // Create route path
                           routePath = new google.maps.Polyline({
                            path: [],
                            geodesic: false,  // Changed from true to false for straight lines
                            strokeColor: '#dc3545',  // Red color
                            strokeOpacity: 1.0,
                             strokeWeight: 3
                       });
                        routePath.setMap(map);


                            // Map click listener with auto-zoom functionality
// Map click listener with weather request
map.addListener('click', function(event) {
    if (isDragging) return;

    const lat = event.latLng.lat();
    const lng = event.latLng.lng();
    
    // Update coordinate display
    document.getElementById('lat').textContent = lat.toFixed(6);
    document.getElementById('lon').textContent = lng.toFixed(6);
    
    // Always trigger weather request for clicked location
    console.log('Weather request for: ' + lat + ', ' + lng);

    if (addMarkersMode) {
        addMarker(lat, lng);
        addMarkersMode = false;
    }
});

                            // Zoom change listener
                            map.addListener('zoom_changed', function() {
                                document.getElementById('zoom').textContent = map.getZoom();
                            });

                            // Center change listener
                            map.addListener('center_changed', function() {
                                const center = map.getCenter();
                                document.getElementById('lat').textContent = center.lat().toFixed(6);
                                document.getElementById('lon').textContent = center.lng().toFixed(6);
                            });

                            setTimeout(removeWatermarks, 2000);
                        }

                        function removeWatermarks() {
                            const walker = document.createTreeWalker(
                                document.body,
                                NodeFilter.SHOW_TEXT,
                                null,
                                false
                            );

                            const nodesToRemove = [];
                            let node;
                            while (node = walker.nextNode()) {
                                if (node.nodeValue && node.nodeValue.includes('For development purposes only')) {
                                    let parent = node.parentElement;
                                    while (parent && parent !== document.body) {
                                        if (parent.style) {
                                            parent.style.display = 'none';
                                            break;
                                        }
                                        parent = parent.parentElement;
                                    }
                                    nodesToRemove.push(node.parentElement || node);
                                }
                            }

                            nodesToRemove.forEach(node => {
                                if (node && node.parentElement) {
                                    node.parentElement.removeChild(node);
                                }
                            });

                            const watermarkSelectors = [
                                '.gm-style-cc', '.gmnoprint', '.gm-bundled-control', '.gm-watermark',
                                '[class*="watermark"]', 'div[style*="background-color: rgba(0, 0, 0, 0.5)"]',
                                'div[style*="background: rgba(0, 0, 0, 0.5)"]'
                            ];

                            watermarkSelectors.forEach(selector => {
                                const elements = document.querySelectorAll(selector);
                                elements.forEach(el => {
                                    el.style.display = 'none';
                                    el.remove();
                                });
                            });

                            setTimeout(removeWatermarks, 5000);
                        }

                 function updateDronePosition(lat, lng) {
    if (droneMarker && lat && lng) {
        const position = new google.maps.LatLng(lat, lng);
        droneMarker.setPosition(position);
        
        // Show drone marker when position is updated
        if (droneMarker.getMap() === null) {
            droneMarker.setMap(map);
            // Auto-center and zoom to level 20 ONLY when drone first appears
            map.setCenter(position);
            map.setZoom(20);
            console.log("Drone connected - centered at zoom level 20");
        }
        // NOTE: Removed auto-centering on every position update - only centers when drone first connects
    }
}

// Add this new function to your JavaScript code
function updateMarkerIcon(index) {
    if (index >= 0 && index < markers.length) {
        const markerData = markers[index];
        let markerLetter;
        let markerTitle;
        
        if (index === 0) {
            markerLetter = 'H';
            markerTitle = 'Home';
        } else {
            switch(markerData.commandType) {
                case 'takeoff': markerLetter = 'T'; markerTitle = 'Takeoff ' + (index + 1); break;
                case 'land': markerLetter = 'L'; markerTitle = 'Land ' + (index + 1); break;
                case 'return': markerLetter = 'R'; markerTitle = 'Return to Launch ' + (index + 1); break;
                case 'loiter': markerLetter = 'O'; markerTitle = 'Loiter ' + (index + 1); break;
                case 'circle': markerLetter = 'C'; markerTitle = 'Circle ' + (index + 1); break;
                case 'follow': markerLetter = 'F'; markerTitle = 'Follow Me ' + (index + 1); break;
                default: markerLetter = 'W'; markerTitle = 'Waypoint ' + (index + 1); break;
            }
        }
        
        // Update the marker icon
        markerData.marker.setIcon({
            url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(
                '<svg width="24" height="36" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 36">' +
                '<path d="M12 0C5.373 0 0 5.373 0 12c0 9 12 24 12 24s12-15 12-24C24 5.373 18.627 0 12 0z" fill="#ea4335" stroke="#ffffff" stroke-width="1"/>' +
                '<circle cx="12" cy="12" r="6" fill="white"/>' +
                '<text x="12" y="16" text-anchor="middle" fill="#ea4335" font-size="10" font-weight="bold" font-family="Arial">' + 
                markerLetter + '</text>' +
                '</svg>'
            ),
            scaledSize: new google.maps.Size(24, 36),
            anchor: new google.maps.Point(12, 36)
        });
        
        // Update title
        markerData.marker.setTitle(markerTitle);
    }
}

function centerOnDrone(lat, lng) {
    if (map && lat && lng) {
        map.setCenter(new google.maps.LatLng(lat, lng));
        map.setZoom(20);
        console.log("Centered on drone at zoom level 20");
    }
}
// Replace the addMarker function in your JavaScript with this corrected version:
function addMarker(lat, lng, altitude = 10, speed = 5, commandType = 'waypoint', holdTime = 0) {
    const position = new google.maps.LatLng(lat, lng);
    const markerIndex = markers.length;
    
    // Determine the letter to display based on index and command type
    let markerLetter;
    let markerTitle;
    
    if (markerIndex === 0) {
        markerLetter = 'H'; // First marker is always Home
        markerTitle = 'Home';
    } else {
        switch(commandType) {
            case 'takeoff': 
                markerLetter = 'T'; 
                markerTitle = 'Takeoff ' + markerIndex;
                break;
            case 'land': 
                markerLetter = 'L'; 
                markerTitle = 'Land ' + markerIndex;
                break;
            case 'return': 
                markerLetter = 'R'; 
                markerTitle = 'Return to Launch ' + markerIndex;
                break;
            case 'loiter': 
                markerLetter = 'O'; 
                markerTitle = 'Loiter ' + markerIndex;
                break;
            case 'circle': 
                markerLetter = 'C'; 
                markerTitle = 'Circle ' + markerIndex;
                break;
            case 'follow': 
                markerLetter = 'F'; 
                markerTitle = 'Follow Me ' + markerIndex;
                break;
            default: 
                markerLetter = 'W'; 
                markerTitle = 'Waypoint ' + markerIndex;
                break;
        }
    }
    
    const marker = new google.maps.Marker({
        position: position,
        map: map,
        title: markerTitle,
        icon: {
            // Professional teardrop location pin marker with letter
            url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(
                '<svg width="24" height="36" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 36">' +
                '<path d="M12 0C5.373 0 0 5.373 0 12c0 9 12 24 12 24s12-15 12-24C24 5.373 18.627 0 12 0z" fill="#ea4335" stroke="#ffffff" stroke-width="1"/>' +
                '<circle cx="12" cy="12" r="6" fill="white"/>' +
                '<text x="12" y="16" text-anchor="middle" fill="#ea4335" font-size="10" font-weight="bold" font-family="Arial">' + 
                markerLetter + '</text>' +
                '</svg>'
            ),
            scaledSize: new google.maps.Size(24, 36),
            anchor: new google.maps.Point(12, 36), // Anchor at the bottom point
        },
        draggable: true
    });
    
    const markerData = {
        marker: marker,
        lat: lat,
        lng: lng,
        altitude: altitude,
        speed: speed,
        commandType: commandType,
        holdTime: holdTime,
        index: markerIndex
    };

    markers.push(markerData);
    updateRoutePath();
    
    // This tells QML that a marker was added
    console.log("Marker added at: " + lat + ", " + lng);

    // Add event listeners
    marker.addListener('dragstart', function() {
        isDragging = true;
        routePath.setOptions({strokeColor: '#007bff'});
    });

    marker.addListener('drag', function() {
        const pos = marker.getPosition();
        markerData.lat = pos.lat();
        markerData.lng = pos.lng();
        updateRoutePath();
    });

    marker.addListener('dragend', function() {
        isDragging = false;
        routePath.setOptions({strokeColor: '#dc3545'});
        const pos = marker.getPosition();
        markerData.lat = pos.lat();
        markerData.lng = pos.lng();
        
        console.log('Waypoint ' + (markerIndex + 1) + ' moved to: ' + 
                  pos.lat().toFixed(6) + ', ' + pos.lng().toFixed(6));
    });

    marker.addListener('click', function() {
        if (!isDragging) {
            window.showMarkerPopup && window.showMarkerPopup(markerData);
        }
    });

    return markerIndex;
}
function addMarkerWithQMLResource(lat, lng, altitude = 10, speed = 5, commandType = 'waypoint', holdTime = 0) {
    const position = new google.maps.LatLng(lat, lng);
    const markerIndex = markers.length;
    
    const marker = new google.maps.Marker({
        position: position,
        map: map,
        title: 'Waypoint ' + (markerIndex + 1),
        label: {
            text: (markerIndex + 1).toString(),
            color: 'white',
            fontWeight: 'bold',
            fontSize: '12px'
        },
        icon: {
            url: 'qrc:/images/marker.png', // QML resource path
            scaledSize: new google.maps.Size(32, 32),
            anchor: new google.maps.Point(16, 32),
            labelOrigin: new google.maps.Point(16, 16)
        },
        draggable: true
    });
}
function deleteMarker(index) {
    if (index >= 0 && index < markers.length) {
        markers[index].marker.setMap(null);
        markers.splice(index, 1);
        
        // Update all remaining markers with correct letters and indices
        markers.forEach((markerData, i) => {
            markerData.index = i;
            
            // Determine new letter and title
            let markerLetter;
            let markerTitle;
            
            if (i === 0) {
                markerLetter = 'H';
                markerTitle = 'Home';
            } else {
                switch(markerData.commandType) {
                    case 'takeoff': markerLetter = 'T'; markerTitle = 'Takeoff ' + (i + 1); break;
                    case 'land': markerLetter = 'L'; markerTitle = 'Land ' + (i + 1); break;
                    case 'return': markerLetter = 'R'; markerTitle = 'Return to Launch ' + (i + 1); break;
                    case 'loiter': markerLetter = 'O'; markerTitle = 'Loiter ' + (i + 1); break;
                    case 'circle': markerLetter = 'C'; markerTitle = 'Circle ' + (i + 1); break;
                    case 'follow': markerLetter = 'F'; markerTitle = 'Follow Me ' + (i + 1); break;
                    default: markerLetter = 'W'; markerTitle = 'Waypoint ' + (i + 1); break;
                }
            }
            
            // Update the marker icon with new letter
            markerData.marker.setIcon({
                url: 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(
                    '<svg width="24" height="36" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 36">' +
                    '<path d="M12 0C5.373 0 0 5.373 0 12c0 9 12 24 12 24s12-15 12-24C24 5.373 18.627 0 12 0z" fill="#ea4335" stroke="#ffffff" stroke-width="1"/>' +
                    '<circle cx="12" cy="12" r="6" fill="white"/>' +
                    '<text x="12" y="16" text-anchor="middle" fill="#ea4335" font-size="10" font-weight="bold" font-family="Arial">' + 
                    markerLetter + '</text>' +
                    '</svg>'
                ),
                scaledSize: new google.maps.Size(24, 36),
                anchor: new google.maps.Point(12, 36)
            });
            
            // Update title
            markerData.marker.setTitle(markerTitle);
        });
        
        updateRoutePath();
        
        // This tells QML that a marker was deleted
        console.log("Marker deleted at index: " + index);
    }
}
// Add this function to your main QML file
function refreshWaypointDashboard() {
    if (waypointDashboard.visible) {
        updateWaypointDashboard();
    }
}
                        function updateRoutePath() {
                            const path = markers.map(m => new google.maps.LatLng(m.lat, m.lng));
                            routePath.setPath(path);
                        }

                        function setAddMarkersMode(enabled) {
                            addMarkersMode = enabled;
                        }

                        function clearAllMarkers() {
    markers.forEach(markerData => {
        markerData.marker.setMap(null);
    });
    markers = [];
    routePath.setPath([]);
    
    // Reset map to world view when clearing markers
    map.setCenter({ lat: 0, lng: 0 });
    map.setZoom(2);
    
    // ADD THIS LINE - This tells QML that all markers were cleared
    console.log("All markers cleared");
}

                        function getAllMarkers() {
    return markers.map(m => ({
        lat: m.lat,
        lng: m.lng,
        altitude: m.altitude,
        speed: m.speed,
        commandType: m.commandType,
        holdTime: m.holdTime
    }));
}

                        // Function to reset map to world view
                        function resetToWorldView() {
                            map.setCenter({ lat: 0, lng: 0 });
                            map.setZoom(2);
                        }

                        window.initMap = initMap;
                    </script>
                    <script async defer src="https://maps.googleapis.com/maps/api/js?key=AIzaSyDnBjIddcNnhfndEEJHi8puawYx3cPspWI&callback=initMap"></script>
                </body>
                </html>
            `)

          Timer {
                id: dronePositionTimer  // Add this ID
                interval: 100
                running: true
                repeat: true
    
    property bool wasConnected: false
    
    onTriggered: {
        var isCurrentlyConnected = droneModel.telemetry.lat && droneModel.telemetry.lon && 
                                  droneModel.telemetry.lat !== 0 && droneModel.telemetry.lon !== 0;
        
        if (isCurrentlyConnected) {
            mapWebView.runJavaScript(
                `updateDronePosition(${droneModel.telemetry.lat}, ${droneModel.telemetry.lon});`
            );
            
            // If drone just connected (transition from disconnected to connected)
            if (!wasConnected) {
                console.log("Drone just connected - centering at zoom 20");
                mapWebView.runJavaScript(
                    `centerOnDrone(${droneModel.telemetry.lat}, ${droneModel.telemetry.lon});`
                );
            }
        }
        
        wasConnected = isCurrentlyConnected;
    }
}            Component.onCompleted: {
                mapWebView.runJavaScript(`
                    window.getWeatherCallback = function(lat, lng) {
                        // This will be handled by QML
                    };
                    window.showMarkerPopup = function(markerData) {
                        // This will be handled by QML
                    };
                `);
            }

            onLoadingChanged: {
                if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
                    runJavaScript(`
                        window.getWeatherCallback = function(lat, lng) {
                            console.log('Weather request for: ' + lat + ', ' + lng);
                        };
                        window.showMarkerPopup = function(markerData) {
                            console.log('Show popup for marker: ' + markerData.index);
                        };
                    `);
                }
            }

// Replace the existing weather-related code in your main QML file with these modifications:

onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceId) {
    console.log("WebEngine:", message);
    
    if (message.startsWith("Weather request for:")) {
        var coords = message.split(": ")[1].split(", ");
        var lat = parseFloat(coords[0]);
        var lng = parseFloat(coords[1]);
        console.log("Triggering weather dashboard for:", lat, lng);
        
        // Make sure we're using the correct instance
        weatherDashboard.setLocation(lat, lng);
        weatherDashboard.show();
    }
    
    if (message.startsWith("Show popup for marker:")) {
        var index = parseInt(message.split(": ")[1]);
        showMarkerPopupForIndex(index);
    }
    
    // Listen for marker addition from JavaScript
    if (message.startsWith("Marker added at:")) {
        Qt.callLater(function() {
            onWaypointAdded();
        });
    }
    
    // Listen for marker deletion from JavaScript
    if (message.startsWith("Marker deleted at index:") || message === "All markers cleared") {
        Qt.callLater(function() {
            onWaypointDeleted();
        });
    }
}

Popup {
    id: saveWaypointsPopup
    width: 400
    height: 200
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    background: Rectangle {
        color: theme.cardBackground
        border.color: theme.border
        border.width: 1
        radius: theme.borderRadius
    }
    
    contentItem: Column {
        spacing: 15
        padding: 20
        
        Text {
            text: "Save Waypoints"
            font.pixelSize: 18
            font.bold: true
            font.family: "Consolas"
            color: theme.textPrimary
        }
        
        Text {
            text: "Enter filename for waypoints:"
            font.pixelSize: 12
            font.family: "Consolas"
            color: theme.textSecondary
        }
        
        Rectangle {
            width: parent.width - 10
            height: 40
            radius: 6
            border.color: theme.border
            border.width: 1
            color: "#ffffff"
            
            TextInput {
                id: saveFilenameInput
                anchors.fill: parent
                anchors.margins: 10
                font.pixelSize: 14
                font.family: "Consolas"
                color: theme.textPrimary
                text: "mission_" + new Date().getTime()
                selectByMouse: true
            }
        }
        
        Row {
            spacing: 10
            width: parent.width - 10
            height: 40
            
            Button {
                width: (parent.width - 10) / 2
                height: parent.height
                background: Rectangle {
                    color: parent.pressed ? "#0056b3" : "#007bff"
                    radius: 6
                }
                contentItem: Text {
                    text: "Save"
                    color: "white"
                    font.pixelSize: 14
                    font.family: "Consolas"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (saveFilenameInput.text.trim() !== "") {
                        saveWaypointsData(saveFilenameInput.text);
                        saveWaypointsPopup.close();
                        saveFilenameInput.text = "mission_" + new Date().getTime();
                    }
                }
            }
            
            Button {
                width: (parent.width - 10) / 2
                height: parent.height
                background: Rectangle {
                    color: parent.pressed ? "#6c757d" : "#8a8a8a"
                    radius: 6
                }
                contentItem: Text {
                    text: "Cancel"
                    color: "white"
                    font.pixelSize: 14
                    font.family: "Consolas"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    saveWaypointsPopup.close();
                    saveFilenameInput.text = "mission_" + new Date().getTime();
                }
            }
        }
    }
}

// Load Waypoints Popup with File Browser
Popup {
    id: loadWaypointsPopup
    width: 500
    height: 350
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    background: Rectangle {
        color: theme.cardBackground
        border.color: theme.border
        border.width: 1
        radius: theme.borderRadius
    }
    
    contentItem: Column {
        spacing: 15
        padding: 20
        
        Text {
            text: "Load Waypoints"
            font.pixelSize: 18
            font.bold: true
            font.family: "Consolas"
            color: theme.textPrimary
        }
        
        // File Browser Section
        Column {
            width: parent.width - 10
            spacing: 8
            
            Text {
                text: "Select file from your system:"
                font.pixelSize: 12
                font.family: "Consolas"
                color: theme.textSecondary
            }
            
            Rectangle {
                width: parent.width
                height: 45
                radius: 6
                border.color: theme.border
                border.width: 1
                color: "#f8f9fa"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10
                    
                    Text {
                        id: selectedFileText
                        text: "No file selected"
                        font.pixelSize: 12
                        font.family: "Consolas"
                        color: theme.textSecondary
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                    }
                    
                    Button {
                        width: 80
                        height: parent.height - 4
                        background: Rectangle {
                            color: parent.pressed ? "#0056b3" : "#007bff"
                            radius: 4
                        }
                        contentItem: Text {
                            text: "Browse"
                            color: "white"
                            font.pixelSize: 12
                            font.family: "Consolas"
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        onClicked: {
                            openFileDialog();
                        }
                    }
                }
            }
        }
        
        // Manual Paste Section
        Column {
            width: parent.width - 10
            spacing: 8
            
            Text {
                text: "Or paste waypoints data (JSON format):"
                font.pixelSize: 12
                font.family: "Consolas"
                color: theme.textSecondary
            }
            
            Rectangle {
                width: parent.width
                height: 100
                radius: 6
                border.color: theme.border
                border.width: 1
                color: "#ffffff"
                clip: true
                
                TextEdit {
                    id: loadDataInput
                    anchors.fill: parent
                    anchors.margins: 10
                    font.pixelSize: 12
                    font.family: "Consolas"
                    color: theme.textPrimary
                    wrapMode: TextEdit.Wrap
                    selectByMouse: true
                    text: ""
                }
            }
        }
        
        Row {
            spacing: 10
            width: parent.width - 10
            height: 40
            
            Button {
                width: (parent.width - 10) / 2
                height: parent.height
                background: Rectangle {
                    color: parent.pressed ? "#0d6923" : "#28a745"
                    radius: 6
                }
                contentItem: Text {
                    text: "Load"
                    color: "white"
                    font.pixelSize: 14
                    font.family: "Consolas"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    if (loadDataInput.text.trim() !== "") {
                        loadWaypointsData(loadDataInput.text);
                        loadWaypointsPopup.close();
                        loadDataInput.text = "";
                        selectedFileText.text = "No file selected";
                    }
                }
            }
            
            Button {
                width: (parent.width - 10) / 2
                height: parent.height
                background: Rectangle {
                    color: parent.pressed ? "#6c757d" : "#8a8a8a"
                    radius: 6
                }
                contentItem: Text {
                    text: "Cancel"
                    color: "white"
                    font.pixelSize: 14
                    font.family: "Consolas"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    loadWaypointsPopup.close();
                    loadDataInput.text = "";
                    selectedFileText.text = "No file selected";
                }
            }
        }
    }
}

// 3. Update your WeatherDashboard instantiation (replace the existing one):
WeatherDashboard {
    id: weatherDashboardwidget
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 20
    anchors.bottomMargin: 20
    width: 350
    height: expanded ? (hasWarnings ? 400 : 320) : 60
    visible: dashboardVisible
    z: 100
    
    // ADD THIS LINE to pass the language manager reference
    languageManager: languageManager
}

function showWeatherForLocation(lat, lon) {
    console.log("Showing weather for coordinates:", lat, lon);
    weatherDashboard.setLocation(lat, lon);
    weatherDashboard.show();
}
//weather


            function addMarkerJS(lat, lon, altitude, speed, commandType, holdTime) {
                runJavaScript(`addMarker(${lat}, ${lon}, ${altitude || 10}, ${speed || 5}, '${commandType || 'waypoint'}', ${holdTime || 0});`);
            }

            function deleteMarkerJS(index) {
                runJavaScript(`deleteMarker(${index});`);
            }

            function setAddMarkersModeJS(enabled) {
                runJavaScript(`setAddMarkersMode(${enabled});`);
                addMarkersMode = enabled;
            }

            function clearAllMarkersJS() {
                runJavaScript("clearAllMarkers();");
            }

            function getAllMarkersJS(callback) {
    runJavaScript("JSON.stringify(getAllMarkers());", callback);
}

            function resetToWorldViewJS() {
                runJavaScript("resetToWorldView();");
            }
        }

        // Map overlay controls
Rectangle {
    id: mapControls
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: 15
    width: 50
    height: 350  // Increased to accommodate all buttons
    color: "#ffffff"
    radius: 8
    border.color: theme.border
    border.width: 1
    opacity: 0.95

    Column {
        anchors.centerIn: parent
        spacing: 8

        // World View Button
        Button {
            id: worldViewBtn
            width: 35
            height: 35
            text: "🌍"
            
            background: Rectangle {
                color: worldViewBtn.pressed ? "#e9ecef" : (worldViewBtn.hovered ? "#f8f9fa" : "#ffffff")
                radius: 6
                border.color: theme.accent
                border.width: 1
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            contentItem: Text {
                text: worldViewBtn.text
                font.pixelSize: 14
                color: theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: {
                mapWebView.resetToWorldViewJS();
            }
        }

        // Weather Button
        Button {
    id: weatherControlBtn
    width: 35
    height: 35
    text: "🌤️"
    
    background: Rectangle {
        color: weatherDashboard.visible ? theme.accent : 
               (weatherControlBtn.pressed ? "#e9ecef" : (weatherControlBtn.hovered ? "#f8f9fa" : "#ffffff"))
        radius: 6
        border.color: theme.accent
        border.width: 1
    }
    
    contentItem: Text {
        text: weatherControlBtn.text
        font.pixelSize: 14
        color: weatherDashboard.visible ? "white" : theme.textPrimary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }

            
   onClicked: {
        if (weatherDashboard.dashboardVisible) {  // Use dashboardVisible instead of visible
            weatherDashboard.hide();
        } else {
            var lat = droneModel.telemetry.lat || 17.601588777182204;
            var lon = droneModel.telemetry.lon || 78.12690006798547;
            weatherDashboard.setLocation(lat, lon);
            weatherDashboard.show();
        }
    }
}

        // Waypoint Dashboard Button
        Button {
            id: waypointDashboardBtn
            width: 35
            height: 35
            text: "📝"
            
            background: Rectangle {
                color: waypointDashboard.visible ? theme.accent : 
                       (waypointDashboardBtn.pressed ? "#e9ecef" : (waypointDashboardBtn.hovered ? "#f8f9fa" : "#ffffff"))
                radius: 6
                border.color: theme.accent
                border.width: 1
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            contentItem: Text {
                text: waypointDashboardBtn.text
                font.pixelSize: 14
                color: waypointDashboard.visible ? "white" : theme.textPrimary
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }

            onClicked: {
                if (waypointDashboard.visible) {
                    waypointDashboard.hide();
                } else {
                    waypointDashboard.show();
                    testGetAllMarkers();
                    
                    var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 500; repeat: false; }', mainWindow);
                    timer.triggered.connect(function() {
                        updateWaypointDashboard();
                        timer.destroy();
                    });
                    timer.start();
                }
            }
        }
    }

    DropShadow {
        anchors.fill: parent
        horizontalOffset: 0
        verticalOffset: 3
        radius: 8
        samples: 17
        color: "#60000000"
        source: parent
    }
}
    }




    // Marker Popup (unchanged)
    Popup {
        id: markerPopup
        width: 300
        height: 400
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        property int markerIndex: -1
        property real altitude: 10
        property real speed: 5
        
        background: Rectangle {
            color: theme.cardBackground
            border.color: theme.border
            border.width: 1
            radius: theme.borderRadius
            
            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                color: "#00000010"
                radius: parent.radius
                z: -1
            }
        }
        
        contentItem: Column {
            spacing: 12
            padding: 15
            
            Rectangle {
                width: parent.width - 10
                height: 40
                color: theme.accent
                radius: theme.borderRadius
                
                Text {
                    text: "Waypoint " + (markerPopup.markerIndex + 1)
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "Consolas"
                    color: "white"
                    anchors.centerIn: parent
                }
                
                Button {
                    width: 30
                    height: 30
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    contentItem: Text { text: "✖"; color: "white"; font.pixelSize: 14; font.family: "Consolas" }
                    background: Rectangle { 
                        color: parent.hovered ? "#ffffff20" : "transparent" 
                        radius: 4
                    }
                    onClicked: markerPopup.close()
                }
            }
            
            Text {
                text: "💡 Tip: Drag marker to move it"
                font.pixelSize: 12
                font.family: "Consolas"
                color: theme.textSecondary
                font.italic: true
            }
            
            Column {
                width: parent.width - 10
                spacing: 5
                Text { text: "Altitude (m):"; font.pixelSize: 14; font.family: "Consolas"; color: theme.textPrimary }
                Row {
                    spacing: 3
                    width: parent.width
                    height: 35
                
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "−"; color: "white"; font.pixelSize: 16; font.bold: true; font.family: "Consolas" }
                        background: Rectangle { color: theme.accent; radius: 4 }
                        onClicked: {
                            if (markerPopup.altitude > 1) {
                                markerPopup.altitude -= 1;
                                altitudeField.text = markerPopup.altitude.toString();
                            }
                        }
                    }
                    
                    TextField {
                        id: altitudeField
                        width: parent.width - 115; height: parent.height
                        text: markerPopup.altitude.toString()
                        validator: DoubleValidator { bottom: 0; decimals: 1 }
                        font.pixelSize: 14
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle { 
                            color: "#ffffff"
                            radius: 4
                            border.color: theme.border
                            border.width: 1 
                        }
                        color: theme.textPrimary
                    }
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "+"; color: "white"; font.pixelSize: 16; font.bold: true; font.family: "Consolas" }
                        background: Rectangle { color: theme.accent; radius: 4 }
                        onClicked: {
                            markerPopup.altitude += 1;
                            altitudeField.text = markerPopup.altitude.toString();
                        }
                    }
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "✓"; color: "white"; font.pixelSize: 16; font.bold: true; font.family: "Consolas" }
                        background: Rectangle { color: theme.success; radius: 4 }
                        onClicked: {
                            var val = parseFloat(altitudeField.text);
                            if (!isNaN(val) && markerPopup.markerIndex >= 0) {
                                markerPopup.altitude = val;
                                mapWebView.runJavaScript(`
                                    if (markers[${markerPopup.markerIndex}]) {
                                        markers[${markerPopup.markerIndex}].altitude = ${val};
                                    }
                                `);
                            }
                        }
                    }
                }
            }
            
            Column {
                width: parent.width - 10
                spacing: 5
                Text { text: "Speed (m/s):"; font.pixelSize: 14; font.family: "Consolas"; color: theme.textPrimary }
                Row {
                    spacing: 3
                    width: parent.width
                    height: 35
                
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "−"; color: "white"; font.pixelSize: 16; font.bold: true; font.family: "Consolas" }
                        background: Rectangle { color: theme.accent; radius: 4 }
                        onClicked: {
                            if (markerPopup.speed > 0.5) {
                                markerPopup.speed -= 0.5;
                                speedField.text = markerPopup.speed.toString();
                            }
                        }
                    }
                    
                    TextField {
                        id: speedField
                        width: parent.width - 115; height: parent.height
                        text: markerPopup.speed.toString()
                        validator: DoubleValidator { bottom: 0; decimals: 1 }
                        font.pixelSize: 14
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle { 
                            color: "#ffffff"
                            radius: 4
                            border.color: theme.border
                            border.width: 1 
                        }
                        color: theme.textPrimary
                    }
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "+"; color: "white"; font.pixelSize: 16; font.bold: true; font.family: "Consolas" }
                        background: Rectangle { color: theme.accent; radius: 4 }
                        onClicked: {
                            markerPopup.speed += 0.5;
                            speedField.text = markerPopup.speed.toString();
                        }
                    }
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "✓"; color: "white"; font.pixelSize: 16; font.bold: true; font.family: "Consolas" }
                        background: Rectangle { color: theme.success; radius: 4 }
                        onClicked: {
                            var val = parseFloat(speedField.text);
                            if (!isNaN(val) && markerPopup.markerIndex >= 0) {
                                markerPopup.speed = val;
                                mapWebView.runJavaScript(`
                                    if (markers[${markerPopup.markerIndex}]) {
                                        markers[${markerPopup.markerIndex}].speed = ${val};
                                    }
                                `);
                            }
                        }
                    }
                }
            }
            
            Button {
                width: parent.width - 10
                height: 40
                contentItem: Text { text: "🗑️ Delete Waypoint"; color: "white"; font.pixelSize: 14; font.family: "Consolas" }
                background: Rectangle { color: theme.error; radius: 4 }
                onClicked: {
                    if (markerPopup.markerIndex >= 0) {
                        mapWebView.deleteMarkerJS(markerPopup.markerIndex);
                        markerPopup.close();
                    }
                }
            }
        }
    }

   
WeatherDashboard {
    id: weatherDashboard
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.leftMargin: 20
    anchors.bottomMargin: 20
    width: 350
    height: expanded ? (hasWarnings ? 400 : 320) : 60
    visible: dashboardVisible  // Make sure this uses the internal property
    z: 100
}
    WaypointDashboard {
    id: waypointDashboard
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.topMargin: header.height + 20
    anchors.rightMargin: 20
    visible: false
    z: 100
}

   // Updated Sidebar with language translations
Drawer {
    id: sidebar
    width: 300
    height: parent.height - 70
    y: header.height
    modal: false
    dim: false
    interactive: false
    
    background: Rectangle { 
        color: "#ffffff"
        border.color: theme.border
        border.width: 1
    }
    
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15
        
        Text {
            text: "Mission Upload" // You can add this to translations later
            color: theme.textPrimary
            font.pixelSize: 14
            font.bold: true
            font.family: "Consolas"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }
        
        Button {
            Layout.fillWidth: true
            height: 50
            background: Rectangle {
                color: parent.hovered ? "#e3f2fd" : "#f8f9fa"
                radius: 8
                border.color: theme.border
                border.width: 1
            }
            contentItem: RowLayout {
                spacing: 10
                Text { text: "➕"; font.pixelSize: 16; font.family: "Consolas"; color: theme.accent }
                Text { 
                    text: "Add " + languageManager.getText("Waypoints")
                    color: theme.textPrimary
                    font.pixelSize: 14
                    font.family: "Consolas"
                    Layout.fillWidth: true
                }
            }
            onClicked: {
                mapWebView.setAddMarkersModeJS(true);
                // Auto-show waypoint dashboard when adding waypoints
                if (!waypointDashboard.visible) {
                    waypointDashboard.show();
                    Qt.callLater(function() {
                        updateWaypointDashboard();
                    });
                }
            }
        }
        
        Button {
            Layout.fillWidth: true
            height: 50
            background: Rectangle {
                color: parent.hovered ? "#e8f5e8" : "#f8f9fa"
                radius: 8
                border.color: theme.border
                border.width: 1
            }
            contentItem: RowLayout {
                spacing: 10
                Text { text: "📤"; font.pixelSize: 16; font.family: "Consolas"; color: theme.success }
                Text { 
                    text: "Send " + languageManager.getText("Waypoints")
                    color: theme.textPrimary
                    font.pixelSize: 14
                    font.family: "Consolas"
                    Layout.fillWidth: true
                }
            }
            onClicked: sendMarkers()
        }
        
        Button {
            Layout.fillWidth: true
            height: 50
            background: Rectangle {
                color: parent.hovered ? "#ffeaea" : "#f8f9fa"
                radius: 8
                border.color: theme.border
                border.width: 1
            }
            contentItem: RowLayout {
                spacing: 10
                Text { text: "🗑️"; font.pixelSize: 16; font.family: "Consolas"; color: theme.error }
                Text { 
                    text: "Clear " + languageManager.getText("Waypoints")
                    color: theme.textPrimary
                    font.pixelSize: 14
                    font.family: "Consolas"
                    Layout.fillWidth: true
                }
            }
            onClicked: { 
                mapWebView.clearAllMarkersJS(); 
                lastClickedCoordinate = null;
                // Update dashboard after clearing
                Qt.callLater(function() {
                    onWaypointDeleted();
                });
            }
        }
           Button {
    Layout.fillWidth: true
    height: 50
    background: Rectangle {
        color: parent.hovered ? "#e3f2fd" : "#f8f9fa"
        radius: 8
        border.color: theme.border
        border.width: 1
    }
    contentItem: RowLayout {
        spacing: 10
        Text { text: "💾"; font.pixelSize: 16; font.family: "Consolas"; color: "#007bff" }
        Text { 
            text: "Save " + languageManager.getText("Waypoints")
            color: theme.textPrimary
            font.pixelSize: 14
            font.family: "Consolas"
            Layout.fillWidth: true
        }
    }
    onClicked: {
        saveWaypointsPopup.open();
    }
}

Button {
    Layout.fillWidth: true
    height: 50
    background: Rectangle {
        color: parent.hovered ? "#f0f4ff" : "#f8f9fa"
        radius: 8
        border.color: theme.border
        border.width: 1
    }
    contentItem: RowLayout {
        spacing: 10
        Text { text: "📂"; font.pixelSize: 16; font.family: "Consolas"; color: "#28a745" }
        Text { 
            text: "Load " + languageManager.getText("Waypoints")
            color: theme.textPrimary
            font.pixelSize: 14
            font.family: "Consolas"
            Layout.fillWidth: true
        }
    }
    onClicked: {
        loadWaypointsPopup.open();
    }
}
        Item { Layout.fillHeight: true }
        Text { 
            color: theme.textSecondary
            font.pixelSize: 12
            font.family: "Consolas"
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight 
        }
        
    }
    
 
}
Popup {
    id: uploadSuccessPopup
    width: 400
    height: 250
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    property int waypointCount: 0
    
    background: Rectangle {
        color: theme.cardBackground
        border.color: theme.success
        border.width: 2
        radius: theme.borderRadius
        
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            color: "#00000010"
            radius: parent.radius
            z: -1
        }
    }
    
    contentItem: Column {
        spacing: 20
        padding: 20
        
        // Success Icon
        Rectangle {
            width: 80
            height: 80
            radius: 40
            color: "#28a74520"
            anchors.horizontalCenter: parent.horizontalCenter
            
            Text {
                text: "✓"
                font.pixelSize: 48
                font.bold: true
                color: theme.success
                anchors.centerIn: parent
            }
        }
        
        // Success Message
        Text {
            text: "Mission Uploaded Successfully!"
            font.pixelSize: 18
            font.bold: true
            font.family: "Consolas"
            color: theme.textPrimary
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        // Details
        Text {
            text: uploadSuccessPopup.waypointCount + " waypoint(s) uploaded to drone"
            font.pixelSize: 14
            font.family: "Consolas"
            color: theme.textSecondary
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        // Close Button
        Button {
            width: parent.width - 40
            height: 45
            anchors.horizontalCenter: parent.horizontalCenter
            
            background: Rectangle {
                color: parent.pressed ? "#1e7e34" : (parent.hovered ? "#218838" : theme.success)
                radius: 6
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            contentItem: Text {
                text: "OK"
                color: "white"
                font.pixelSize: 16
                font.family: "Consolas"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: uploadSuccessPopup.close()
        }
    }
    
    // Auto-close timer (optional)
    Timer {
        id: autoCloseSuccessTimer
        interval: 3000
        onTriggered: uploadSuccessPopup.close()
    }
    
    onOpened: {
        // Uncomment to enable auto-close after 3 seconds
        // autoCloseSuccessTimer.start()
    }
}
Popup {
    id: missionUploadSuccessPopup
    width: 520
    height: 600
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
    
    property int waypointCount: 0
    property var waypointsData: []
    
    background: Rectangle {
        color: theme.cardBackground
        border.color: theme.success
        border.width: 2
        radius: theme.borderRadius
        
        Rectangle {
            anchors.fill: parent
            anchors.topMargin: 2
            color: "#00000010"
            radius: parent.radius
            z: -1
        }
    }
    
    // Function to calculate distance between two coordinates
function calculateDistance(lat1, lon1, lat2, lon2) {
    var R = 6371000; // Earth radius in meters
    var dLat = (lat2 - lat1) * Math.PI / 180;
    var dLon = (lon2 - lon1) * Math.PI / 180;
    var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon/2) * Math.sin(dLon/2);
    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
    return R * c; // Distance in meters
}
    // Function to populate waypoints and calculate distances
    function populateWaypoints(waypoints) {
        waypointsData = waypoints;
        uploadWaypointListModel.clear();
        
        for (var i = 0; i < waypoints.length; i++) {
            var wpData = {
                lat: waypoints[i].lat,
                lng: waypoints[i].lng,
                altitude: waypoints[i].altitude || 0,
                speed: waypoints[i].speed || 0,
                commandType: waypoints[i].commandType || "waypoint",
                placeName: undefined,
                distanceToNext: ""
            };
            
            // Calculate distance to next waypoint
            if (i < waypoints.length - 1) {
                var dist = calculateDistance(
                    waypoints[i].lat, 
                    waypoints[i].lng,
                    waypoints[i + 1].lat, 
                    waypoints[i + 1].lng
                );
                wpData.distanceToNext = (dist / 1000).toFixed(2) + " km (" + dist.toFixed(0) + " m)";
            }
            
            uploadWaypointListModel.append(wpData);
        }
        
        waypointCount = waypoints.length;
    }
    
    onOpened: {
        // Fetch place names for all waypoints
        for (var i = 0; i < waypointsData.length; i++) {
            fetchPlaceName(i, waypointsData[i].lat, waypointsData[i].lng);
        }
    }
    
    function fetchPlaceName(index, lat, lng) {
        var url = "https://maps.googleapis.com/maps/api/geocode/json?latlng=" + 
                  lat + "," + lng + 
                  "&key=AIzaSyDnBjIddcNnhfndEEJHi8puawYx3cPspWI";
        
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4 && xhr.status === 200) {
                try {
                    var response = JSON.parse(xhr.responseText);
                    if (response.results && response.results.length > 0) {
                        waypointsData[index].placeName = response.results[0].formatted_address;
                        uploadWaypointListModel.set(index, waypointsData[index]);
                    }
                } catch (e) {
                    console.log("Error parsing geocoding response:", e);
                }
            }
        };
        xhr.send();
    }
    
    contentItem: Column {
        spacing: 15
        padding: 20
        
        // Success Icon
        Rectangle {
            width: 70
            height: 70
            radius: 35
            color: "#28a74520"
            anchors.horizontalCenter: parent.horizontalCenter
            
            Text {
                text: "✓"
                font.pixelSize: 42
                font.bold: true
                color: theme.success
                anchors.centerIn: parent
            }
        }
        
        // Success Message
        Text {
            text: "Mission Uploaded Successfully!"
            font.pixelSize: 18
            font.bold: true
            font.family: "Consolas"
            color: theme.textPrimary
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        // Summary
        Text {
            text: missionUploadSuccessPopup.waypointCount + " waypoint(s) uploaded to drone"
            font.pixelSize: 13
            font.family: "Consolas"
            color: theme.textSecondary
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        // Waypoints List Header
        Rectangle {
            width: parent.width - 40
            height: 35
            color: "#f8f9fa"
            radius: 6
            border.color: theme.border
            border.width: 1
            
            Text {
                text: "📍 Waypoint Details"
                font.pixelSize: 14
                font.bold: true
                font.family: "Consolas"
                color: theme.textPrimary
                anchors.centerIn: parent
            }
        }
        
        // Scrollable Waypoints List
        Rectangle {
            width: parent.width - 40
            height: 320
            color: "#ffffff"
            radius: 6
            border.color: theme.border
            border.width: 1
            clip: true
            
            ListView {
                id: uploadWaypointListView
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                clip: true
                
                model: ListModel {
                    id: uploadWaypointListModel
                }
                
                delegate: Rectangle {
                    width: uploadWaypointListView.width - 10
                    height: uploadWaypointColumn.height + 16
                    color: index % 2 === 0 ? "#f8f9fa" : "#ffffff"
                    radius: 6
                    border.color: "#e9ecef"
                    border.width: 1
                    
                    Column {
                        id: uploadWaypointColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        spacing: 4
                        
                        // Waypoint Header
                        Row {
                            spacing: 8
                            width: parent.width
                            
                            Rectangle {
                                width: 24
                                height: 24
                                radius: 12
                                color: theme.accent
                                
                                Text {
                                    text: (index + 1).toString()
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: "Consolas"
                                    color: "white"
                                    anchors.centerIn: parent
                                }
                            }
                            
                            Text {
                                text: model.commandType === "waypoint" ? "Waypoint " + (index + 1) :
                                      model.commandType === "takeoff" ? "Takeoff Point" :
                                      model.commandType === "land" ? "Landing Point" :
                                      model.commandType === "return" ? "Return Point" :
                                      "Waypoint " + (index + 1)
                                font.pixelSize: 12
                                font.bold: true
                                font.family: "Consolas"
                                color: theme.textPrimary
                            }
                        }
                        
                        // Coordinates
                        Text {
                            text: "📍 " + model.lat.toFixed(6) + "°, " + model.lng.toFixed(6) + "°"
                            font.pixelSize: 10
                            font.family: "Consolas"
                            color: theme.textSecondary
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                        
                        // Place Name
                        Text {
                            text: model.placeName ? "📌 " + model.placeName : "📌 Fetching location..."
                            font.pixelSize: 10
                            font.family: "Consolas"
                            color: "#007bff"
                            wrapMode: Text.WordWrap
                            width: parent.width
                            visible: model.placeName !== undefined
                        }
                        
                        // Altitude & Speed
                        Row {
                            spacing: 15
                            width: parent.width
                            
                            Text {
                                text: "⬆️ " + model.altitude.toFixed(1) + "m"
                                font.pixelSize: 10
                                font.family: "Consolas"
                                color: theme.textSecondary
                            }
                            
                            Text {
                                text: "🚀 " + model.speed.toFixed(1) + "m/s"
                                font.pixelSize: 10
                                font.family: "Consolas"
                                color: theme.textSecondary
                            }
                        }
                        
                        // Distance to next waypoint
                        Text {
                            text: model.distanceToNext ? 
                                  "➡️ Distance to next: " + model.distanceToNext : ""
                            font.pixelSize: 10
                            font.family: "Consolas"
                            color: "#28a745"
                            font.bold: true
                            visible: model.distanceToNext !== undefined && model.distanceToNext !== ""
                        }
                    }
                }
                
                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                    width: 8
                    
                    contentItem: Rectangle {
                        radius: 4
                        color: parent.pressed ? "#adb5bd" : "#dee2e6"
                    }
                }
            }
        }
        
        // Close Button
        Button {
            width: parent.width - 40
            height: 45
            anchors.horizontalCenter: parent.horizontalCenter
            
            background: Rectangle {
                color: parent.pressed ? "#1e7e34" : (parent.hovered ? "#218838" : theme.success)
                radius: 6
                
                Behavior on color {
                    ColorAnimation { duration: 150 }
                }
            }
            
            contentItem: Text {
                text: "OK"
                color: "white"
                font.pixelSize: 16
                font.family: "Consolas"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            
            onClicked: missionUploadSuccessPopup.close()
        }
    }
}
function addMarker(lat, lon) {
    mapWebView.addMarkerJS(lat, lon, 10, 5, "waypoint", 0);
    lastClickedCoordinate = QtPositioning.coordinate(lat, lon);
    // Trigger dashboard update after marker is added
    Qt.callLater(function() {
        onWaypointAdded();
    });
}

function deleteMarker(index) {
    mapWebView.deleteMarkerJS(index);
    if (lastClickedCoordinate) {
        lastClickedCoordinate = null;
    }
    // Trigger dashboard update after marker is deleted
    Qt.callLater(function() {
        onWaypointDeleted();
    });
}
    function fetchDroneLocation() {
        // This is now handled by the Timer in WebEngineView
    }

function getWeather(lat, lon) {
    console.log("Getting weather for coordinates:", lat, lon);
    weatherDashboard.setLocation(lat, lon);
    weatherDashboard.show();
}

    function showMarkerPopupForIndex(index) {
        mapWebView.runJavaScript(`
            if (markers[${index}]) {
                JSON.stringify({
                    index: ${index},
                    lat: markers[${index}].lat,
                    lng: markers[${index}].lng,
                    altitude: markers[${index}].altitude,
                    speed: markers[${index}].speed
                });
            } else {
                null;
            }
        `, function(result) {
            if (result) {
                try {
                    var data = JSON.parse(result);
                    markerPopup.markerIndex = data.index;
                    markerPopup.altitude = data.altitude;
                    markerPopup.speed = data.speed;
                    markerPopup.open();
                } catch (e) {
                    console.log("Error parsing marker data:", e);
                }
            }
        });
    }
// Add these functions at the bottom of your ApplicationWindow
function updateWaypointDashboard() {
    console.log("=== DEBUG: updateWaypointDashboard called ===");
    console.log("Dashboard visible:", waypointDashboard.visible);
    console.log("Dashboard expanded:", waypointDashboard.expanded);
    
    if (mapWebView && typeof mapWebView.getAllMarkersJS !== 'undefined') {
        console.log("Calling getAllMarkersJS...");
        mapWebView.getAllMarkersJS(function(result) {
            console.log("getAllMarkersJS result type:", typeof result);
            console.log("getAllMarkersJS result:", result);
            
            if (result && typeof result === 'string') {
                try {
                    var markersData = JSON.parse(result);
                    console.log("Parsed markers data:", markersData.length, "waypoints");
                    
                    // Force the dashboard to completely refresh by hiding and showing
                    waypointDashboard.updateWaypoints(markersData);
                    
                    // Force a visual refresh by temporarily changing a property
                    var currentExpanded = waypointDashboard.expanded;
                    waypointDashboard.expanded = false;
                    Qt.callLater(function() {
                        waypointDashboard.expanded = currentExpanded;
                    });
                    
                    console.log("Dashboard waypoints length after update:", waypointDashboard.waypoints.length);
                } catch (e) {
                    console.log("Error parsing markers data:", e);
                    waypointDashboard.updateWaypoints([]);
                }
            } else {
                console.log("Invalid result from getAllMarkersJS - not a string");
                waypointDashboard.updateWaypoints([]);
            }
        });
    } else {
        console.log("mapWebView or getAllMarkersJS not available");
    }
}
// Add this test function to check if getAllMarkersJS works
function testGetAllMarkers() {
    console.log("=== Testing getAllMarkersJS ===");
    if (mapWebView) {
        mapWebView.runJavaScript("markers.length", function(result) {
            console.log("JavaScript markers.length:", result);
        });
        
        mapWebView.runJavaScript("JSON.stringify(getAllMarkers())", function(result) {
            console.log("Direct getAllMarkers():", result);
        });
    }
}
function onWaypointAdded() {
    console.log("Waypoint added, dashboard visible:", waypointDashboard.visible);
    if (waypointDashboard.visible) {
        // Add a small delay to ensure the JavaScript markers array is updated
        var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 300; repeat: false; }', mainWindow);
        timer.triggered.connect(function() {
            updateWaypointDashboard();
            timer.destroy();
        });
        timer.start();
    }
}


function onWaypointDeleted() {
    console.log("Waypoint deleted, dashboard visible:", waypointDashboard.visible);
    if (waypointDashboard.visible) {
        // Add a small delay to ensure the JavaScript markers array is updated
        var timer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 300; repeat: false; }', mainWindow);
        timer.triggered.connect(function() {
            updateWaypointDashboard();
            timer.destroy();
        });
        timer.start();
    }
}
function sendMarkers() {
    mapWebView.runJavaScript("JSON.stringify(getAllMarkers());", function(result) {
        if (!result) {
            console.log("No markers to send");
            uploadErrorPopup.errorMessage = "No waypoints found to upload.\nPlease add waypoints to the map first.";
            uploadErrorPopup.open();
            return;
        }

        try {
            var markersData = JSON.parse(result);
            if (markersData.length === 0) {
                uploadErrorPopup.errorMessage = "No waypoints available.\nPlease add waypoints before uploading.";
                uploadErrorPopup.open();
                return;
            }

            var waypoints = [];
            console.log("Sending " + markersData.length + " markers as waypoints...");
            
            // Calculate distances and prepare data
            var waypointsWithDistance = [];
            for (var i = 0; i < markersData.length; i++) {
                var marker = markersData[i];
                var command = 16;
                
                switch(marker.commandType) {
                    case "takeoff": command = 22; break;
                    case "land": command = 21; break;
                    case "return": command = 20; break;
                    case "loiter": command = 17; break;
                    case "circle": command = 18; break;
                    case "follow": command = 19; break;
                    default: command = 16; break;
                }

                waypoints.push({
                    seq: i+1,
                    frame: 6,
                    command: command,
                    autocontinue: 1,
                    param1: marker.holdTime || 0,
                    param2: 0,
                    param3: 0,
                    param4: 0,
                    x: marker.lat,
                    y: marker.lng,
                    z: marker.altitude || 10
                });
                
                // Prepare waypoint display data with distance calculation
                var wpData = {
                    lat: marker.lat,
                    lng: marker.lng,
                    altitude: marker.altitude || 10,
                    speed: marker.speed || 5,
                    commandType: marker.commandType || "waypoint",
                    placeName: "Fetching...",
                    distanceToNext: ""
                };
                
                // Calculate distance to next waypoint using the helper function
                if (i < markersData.length - 1) {
                    var nextMarker = markersData[i + 1];
                    var distance = calculateDistance(
                        marker.lat, marker.lng,
                        nextMarker.lat, nextMarker.lng
                    );
                    
                    if (distance < 1000) {
                        wpData.distanceToNext = distance.toFixed(1) + " m";
                    } else {
                        wpData.distanceToNext = (distance / 1000).toFixed(2) + " km";
                    }
                }
                
                waypointsWithDistance.push(wpData);
            }

            if (typeof droneCommander === 'undefined') {
                uploadErrorPopup.errorMessage = "Drone commander not initialized.\nPlease check your drone connection.";
                uploadErrorPopup.open();
                return;
            }

            try {
                var uploadResult = droneCommander.uploadMission(waypoints);
                
                if (uploadResult === false || uploadResult === null) {
                    throw new Error("Mission upload returned false");
                }
                
                // Populate the list model and show success popup
                uploadWaypointListModel.clear();
                missionUploadSuccessPopup.waypointsData = waypointsWithDistance;

                for (var j = 0; j < waypointsWithDistance.length; j++) {
                    uploadWaypointListModel.append(waypointsWithDistance[j]);
                }
                
                missionUploadSuccessPopup.waypointCount = markersData.length;
                missionUploadSuccessPopup.open();
                
                console.log("✅ Mission uploaded successfully: " + markersData.length + " waypoints");
                
                if (typeof mapViewInstance !== 'undefined' && mapViewInstance) {
                    console.log("Sending markers to MapView...");
                    mapViewInstance.receiveMarkersFromNavigation(markersData);
                }
                
            } catch (uploadError) {
                console.log("❌ Upload failed:", uploadError);
                uploadErrorPopup.errorMessage = "Failed to upload mission to drone:\n" + 
                    (uploadError.message || uploadError.toString()) + 
                    "\n\nPlease check:\n• Drone connection\n• Telemetry link\n• Flight controller status";
                uploadErrorPopup.open();
            }
            
        } catch (e) {
            console.log("❌ Error preparing mission:", e);
            uploadErrorPopup.errorMessage = "Error preparing waypoints for upload:\n" + 
                e.toString() + "\n\nPlease check your waypoint data.";
            uploadErrorPopup.open();
        }
    });
}

   function calculateDistance(lat1, lon1, lat2, lon2) {
        var R = 6371000; // Earth radius in meters
        var dLat = (lat2 - lat1) * Math.PI / 180;
        var dLon = (lon2 - lon1) * Math.PI / 180;
        var a = Math.sin(dLat/2) * Math.sin(dLat/2) +
                Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
                Math.sin(dLon/2) * Math.sin(dLon/2);
        var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
        return R * c; // Distance in meters
    }

// ===============================
// WAYPOINTS HANDLING SCRIPT
// ===============================

// Open File Dialog for loading waypoints
function openFileDialog() {
    mapWebView.runJavaScript(`
        var fileInput = document.createElement('input');
        fileInput.type = 'file';
        fileInput.accept = '.waypoints,.json';
        fileInput.style.display = 'none';
        
        fileInput.onchange = function(e) {
            var file = e.target.files[0];
            if (file) {
                var reader = new FileReader();
                reader.onload = function(event) {
                    window.selectedFileContent = event.target.result;
                    window.selectedFileName = file.name;
                    console.log('File selected: ' + file.name);
                };
                reader.readAsText(file);
            }
        };
        
        document.body.appendChild(fileInput);
        fileInput.click();
        document.body.removeChild(fileInput);
    `);

    // Create QML timer to wait for file read completion
    var checkTimer = Qt.createQmlObject('import QtQuick 2.15; Timer { interval: 500; repeat: true }', mainWindow);
    var attempts = 0;

    checkTimer.triggered.connect(function() {
        attempts++;

        mapWebView.runJavaScript(`
            if (window.selectedFileContent && window.selectedFileName) {
                JSON.stringify({
                    content: window.selectedFileContent,
                    name: window.selectedFileName
                });
            } else null;
        `, function(result) {
            if (result) {
                try {
                    var data = JSON.parse(result);
                    loadDataInput.text = data.content;
                    selectedFileText.text = data.name;

                    mapWebView.runJavaScript(`
                        window.selectedFileContent = null;
                        window.selectedFileName = null;
                    `);

                    checkTimer.stop();
                    checkTimer.destroy();

                    console.log("✅ File loaded successfully: " + data.name);

                } catch (err) {
                    console.log("⚠️ Error parsing file data:", err);
                }
            } else if (attempts > 20) {
                checkTimer.stop();
                checkTimer.destroy();
            }
        });
    });

    checkTimer.start();
        openWaypointsDialog.open(); // ✅ Opens the native system file explorer

}



// ===============================
// SAVE WAYPOINTS TO SYSTEM
// ===============================

function saveWaypointsData(filename) {
    mapWebView.runJavaScript("JSON.stringify(getAllMarkers());", function(result) {
        if (!result) {
            console.log("⚠️ No waypoints to save");
            statusNotification.color = theme.error;
            statusNotification.children[0].text = "No waypoints to save!";
            mainWindow.statusNotification.opacity = 1;

            statusNotificationTimer.restart();
            return;
        }

        try {
            var markersData = JSON.parse(result);
            var waypointsData = {
                version: "1.0",
                timestamp: new Date().toISOString(),
                filename: filename,
                totalWaypoints: markersData.length,
                waypoints: markersData
            };
            mainWindow.pendingWaypointData = JSON.stringify(waypointsData, null, 2);


            // ✅ Open Save As dialog (user chooses location)
            saveWaypointsDialog.open();

        } catch (e) {
            console.log("❌ Error preparing waypoints data:", e);
            statusNotification.color = theme.error;
            statusNotification.children[0].text = "Error preparing data";
            mainWindow.statusNotification.opacity = 1;

            statusNotificationTimer.restart();
        }
    });
}
// ===============================
// LOAD WAYPOINTS DATA
// ===============================
// LOAD WAYPOINTS DATA (Dynamic Dialog - always opens system folder)
// ===============================
// ===============================
// LOAD WAYPOINTS DATA (Mission Planner style)
// ===============================
function loadWaypointsData(jsonString) {
    try {
        var waypointsData = JSON.parse(jsonString);
        if (!waypointsData.waypoints || !Array.isArray(waypointsData.waypoints))
            throw new Error("Invalid format");

        // Clear and add markers to map
        if (typeof mapWebView !== "undefined" && mapWebView.clearAllMarkersJS)
            mapWebView.clearAllMarkersJS();

        if (typeof mapWebView !== "undefined" && mapWebView.addMarkerJS) {
            for (var i = 0; i < waypointsData.waypoints.length; i++) {
                var wp = waypointsData.waypoints[i];
                mapWebView.addMarkerJS(
                    wp.lat,
                    wp.lng,
                    wp.altitude || 10,
                    wp.speed || 5,
                    wp.commandType || "waypoint",
                    wp.holdTime || 0
                );
            }
        }

        // Optional: refresh map display
        if (typeof mapWebView !== "undefined")
            mapWebView.runJavaScript("refreshMap && refreshMap();");

        console.log("✅ Loaded " + waypointsData.waypoints.length + " waypoints");
        statusNotification.color = theme.success;
        statusNotification.children[0].text = "✅ Loaded " + waypointsData.waypoints.length + " waypoints!";
        mainWindow.statusNotification.opacity = 1;

        statusNotificationTimer.restart();

    } catch (err) {
        console.log("❌ Error loading waypoints:", err);
        statusNotification.color = theme.error;
        statusNotification.children[0].text = "Invalid waypoints file.";
        mainWindow.statusNotification.opacity = 1;

        statusNotificationTimer.restart();
    }
}


// ===============================
// COPY TO CLIPBOARD
// ===============================
function copyToClipboard(text) {
    mapWebView.runJavaScript(`
        const textarea = document.createElement('textarea');
        textarea.value = ${JSON.stringify(text)};
        document.body.appendChild(textarea);
        textarea.select();
        try {
            document.execCommand('copy');
            console.log('✅ Data copied to clipboard');
        } catch (err) {
            console.log('❌ Failed to copy to clipboard');
        }
        document.body.removeChild(textarea);
    `);
}



// ===============================
// SHOW EXPORT DATA POPUP
// ===============================
function showWaypointExportData(jsonString) {
    var exportPopup = Qt.createQmlObject(`
        import QtQuick 2.15
        import QtQuick.Controls 2.15

        Popup {
            width: 500
            height: 420
            x: (parent.width - width) / 2
            y: (parent.height - height) / 2
            modal: true
            focus: true
            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

            background: Rectangle {
                color: "#ffffff"
                border.color: "#dee2e6"
                border.width: 1
                radius: 8
            }

            Column {
                anchors.fill: parent
                anchors.margins: 15
                spacing: 10

                Text {
                    text: "Exported Waypoints Data"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#212529"
                }

                Rectangle {
                    width: parent.width - 10
                    height: 310
                    radius: 6
                    border.color: "#dee2e6"
                    border.width: 1
                    color: "#f8f9fa"
                    clip: true

                    TextEdit {
                        anchors.fill: parent
                        anchors.margins: 10
                        font.pixelSize: 11
                        font.family: "Courier New"
                        color: "#212529"
                        readOnly: true
                        wrapMode: TextEdit.Wrap
                        selectByMouse: true
                        text: ${JSON.stringify(jsonString)}
                    }
                }

                Button {
                    width: parent.width - 10
                    height: 35
                    background: Rectangle {
                        color: "#007bff"
                        radius: 6
                    }
                    contentItem: Text {
                        text: "Close"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: destroy()
                }
            }
        }
    `, mainWindow);
    exportPopup.open();
}


Connections {
    target: droneCommander
    
    // If droneCommander emits missionUploadSuccess signal
    function onMissionUploadSuccess(waypointCount) {
        uploadSuccessPopup.waypointCount = waypointCount;
        uploadSuccessPopup.open();
    }
    
    // If droneCommander emits missionUploadFailed signal
    function onMissionUploadFailed(errorMsg) {
        uploadErrorPopup.errorMessage = "Upload failed:\n" + errorMsg;
        uploadErrorPopup.open();
    }
}
}




