// components/MapView.qml
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtWebEngine 1.10
import QtPositioning 5.15
import QtGraphicalEffects 1.10

Item {
    id: root
    width: 700
    height: 500

    // Properties for functionality
    property var lastClickedCoordinate: null
    property var markers: []
    property string droneIconBase64: ""
    property var theme: QtObject {
        property color cardBackground: "#1a1a1a"
        property color accent: "#00bcd4"
        property color textPrimary: "#e0e0e0"
        property color error: "#f44336"
        property int borderRadius: 8
    }

    // Try multiple image loading strategies
    Component.onCompleted: {
        console.log("=== DRONE ICON LOADING DEBUG ===")
        console.log("Current working directory:", Qt.application.arguments[0])
        tryLoadDroneIcon()
    }

    function tryLoadDroneIcon() {
        // Try different path strategies
        var paths = [
            "images/drone.png",
            "../images/drone.png",
            "qml/images/drone.png",
            "file:///home/tihan_012/Videos/Tfly_V1.0.1/App/qml/images/drone.png"
        ]
        
        console.log("Trying", paths.length, "different paths for drone icon...")
        droneIconLoader.currentPathIndex = 0
        droneIconLoader.pathsToTry = paths
        droneIconLoader.source = paths[0]
    }

    // Image loader with multiple path fallback
    Image {
        id: droneIconLoader
        visible: false
        cache: false
        asynchronous: false  // Changed to synchronous for better debugging
        
        property var pathsToTry: []
        property int currentPathIndex: 0
        
        onStatusChanged: {
            console.log("[Path " + (currentPathIndex + 1) + "/" + pathsToTry.length + "] Status:", 
                       status, "- Path:", source)
            
            if (status === Image.Ready) {
                console.log("✓✓✓ SUCCESS! Drone icon loaded!")
                console.log("✓ Image size:", sourceSize.width, "x", sourceSize.height)
                console.log("✓ Source:", source)
                
                // Grab image and convert to base64
                grabToImage(function(result) {
                    if (result.url) {
                        root.droneIconBase64 = result.url
                        console.log("✓ Converted to base64, length:", root.droneIconBase64.length)
                        
                        // Update map immediately if ready
                        updateMapWithCustomIcon()
                    } else {
                        console.log("✗ Failed to convert image to base64")
                    }
                }, Qt.size(100, 100))
                
            } else if (status === Image.Error) {
                console.log("✗ Failed to load from:", source)
                
                // Try next path
                currentPathIndex++
                if (currentPathIndex < pathsToTry.length) {
                    console.log("→ Trying next path...")
                    source = pathsToTry[currentPathIndex]
                } else {
                    console.log("✗✗✗ ALL PATHS FAILED!")
                    console.log("✗ Please ensure drone.png exists at one of these locations:")
                    for (var i = 0; i < pathsToTry.length; i++) {
                        console.log("  ", pathsToTry[i])
                    }
                    console.log("✗ Using fallback SVG icon")
                }
                
            } else if (status === Image.Loading) {
                console.log("⋯ Loading from:", source)
            } else if (status === Image.Null) {
                console.log("? Image status is Null")
            }
        }
    }

    function updateMapWithCustomIcon() {
        if (root.droneIconBase64.length > 100) {
            if (mapInitialized) {
                console.log("→ Updating map marker with custom icon NOW")
                mapWebView.runJavaScript(`
                    if (typeof updateDroneIcon === 'function') {
                        updateDroneIcon('${root.droneIconBase64}');
                        console.log('✓ Custom drone icon applied to map');
                    } else {
                        console.log('✗ updateDroneIcon function not ready');
                    }
                `)
            } else {
                console.log("→ Map not ready yet, will update when initialized")
            }
        }
    }

    // FIXED: Properly reference droneModel telemetry
    property real currentLat: (typeof droneModel !== "undefined" && droneModel && droneModel.telemetry) ? droneModel.telemetry.lat || 0 : 0
    property real currentLon: (typeof droneModel !== "undefined" && droneModel && droneModel.telemetry) ? droneModel.telemetry.lon || 0 : 0
    property real currentAlt: (typeof droneModel !== "undefined" && droneModel && droneModel.telemetry) ? droneModel.telemetry.rel_alt || 0 : 0
    property bool isDroneConnected: (typeof droneModel !== "undefined" && droneModel) ? droneModel.isConnected : false

    // ADDED: Track initialization state
    property bool mapInitialized: false
    property bool hasValidDroneLocation: currentLat !== 0 && currentLon !== 0 && !isNaN(currentLat) && !isNaN(currentLon)

    // Debug properties
    onCurrentLatChanged: {
        console.log("MapView: Drone lat updated to:", currentLat)
        checkForInitialCentering()
    }
    onCurrentLonChanged: {
        console.log("MapView: Drone lon updated to:", currentLon)
        checkForInitialCentering()
    }
    onIsDroneConnectedChanged: {
        console.log("MapView: Drone connection status changed to:", isDroneConnected)
        checkForInitialCentering()
    }

    // ADDED: Function to handle initial centering logic
    function checkForInitialCentering() {
        if (mapInitialized && isDroneConnected && hasValidDroneLocation) {
            console.log("MapView: Centering on drone location at startup:", currentLat, currentLon)
            Qt.callLater(function() {
                mapWebView.centerOnDroneJS()
            })
        }
    }

    // Professional map container with enhanced styling
    Rectangle {
        anchors.fill: parent
        color: "#0a0a0a"
        radius: 8
        border.color: "#404040"
        border.width: 1

        // Google Maps WebEngine View
        WebEngineView {
            id: mapWebView
            anchors.fill: parent
            anchors.margins: 2

            property bool addMarkersMode: false
            property string droneIcon: root.droneIconPath

            // Load Google Maps with satellite view and water removed
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
                        .drone-info {
                            position: absolute;
                            top: 10px;
                            left: 10px;
                            background: rgba(26, 26, 26, 0.9);
                            color: #e0e0e0;
                            padding: 8px 12px;
                            border-radius: 6px;
                            font-size: 12px;
                            border: 1px solid #00bcd4;
                            min-width: 200px;
                        }
                        .connection-status {
                            color: #00e676;
                            font-weight: bold;
                        }
                        .disconnected-status {
                            color: #f44336;
                            font-weight: bold;
                        }
                        /* Hide Google Maps development watermarks and controls */
                        .gm-style-cc, .gm-bundled-control, .gmnoprint, .gm-watermark,
                        .gm-style .gm-style-cc, [class*="watermark"], [id*="watermark"] {
                            display: none !important;
                        }
                        div[style*="background-color: rgba(0, 0, 0, 0.5)"],
                        div[style*="background: rgba(0, 0, 0, 0.5)"] {
                            display: none !important;
                        }
                    </style>
                </head>
                <body>
                    <div id="map"></div>
                    <div class="drone-info" id="droneInfo">
                        <div class="disconnected-status" id="connectionStatus">Drone Disconnected</div>
                        <div id="droneDetails" style="display: none;">
                            <div>Position: <span id="droneLat">0.000000</span>°, <span id="droneLon">0.000000</span>°</div>
                            <div>Altitude: <span id="droneAlt">0.0</span>m</div>
                            <div>Last Update: <span id="lastUpdate">Never</span></div>
                        </div>
                    </div>
                    <div class="info-panel" id="infoPanel">
                        <div>Cursor: <span id="lat">0.000000</span>°, <span id="lon">0.000000</span>°</div>
                        <div>Zoom: <span id="zoom">16</span> | Satellite View</div>
                    </div>

                    <script>
                        let map;
                        let droneMarker;
                        let markers = [];
                        let routePath;
                        let addMarkersMode = false;
                        let lastDroneUpdate = null;
                        let isDroneConnected = false;
                        let mapInitialized = false;
                        
                        // Enhanced drone icon with better visibility (used as fallback)
                        let droneIconUrl = 'data:image/svg+xml;charset=UTF-8,' + encodeURIComponent(
                            '<svg width="50" height="50" viewBox="0 0 50 50" xmlns="http://www.w3.org/2000/svg">' +
                            '<defs>' +
                            '<filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">' +
                            '<feDropShadow dx="0" dy="2" stdDeviation="2" flood-opacity="0.5"/>' +
                            '</filter>' +
                            '<radialGradient id="bodyGrad" cx="50%" cy="50%" r="50%">' +
                            '<stop offset="0%" style="stop-color:#00e676;stop-opacity:1" />' +
                            '<stop offset="100%" style="stop-color:#00c853;stop-opacity:1" />' +
                            '</radialGradient>' +
                            '</defs>' +
                            // Main body
                            '<circle cx="25" cy="25" r="12" fill="url(#bodyGrad)" stroke="white" stroke-width="2" filter="url(#shadow)"/>' +
                            // Four rotors
                            '<circle cx="10" cy="10" r="6" fill="#263238" stroke="white" stroke-width="1.5" filter="url(#shadow)"/>' +
                            '<circle cx="40" cy="10" r="6" fill="#263238" stroke="white" stroke-width="1.5" filter="url(#shadow)"/>' +
                            '<circle cx="10" cy="40" r="6" fill="#263238" stroke="white" stroke-width="1.5" filter="url(#shadow)"/>' +
                            '<circle cx="40" cy="40" r="6" fill="#263238" stroke="white" stroke-width="1.5" filter="url(#shadow)"/>' +
                            // Rotor blades (spinning effect)
                            '<line x1="10" y1="6" x2="10" y2="14" stroke="#455A64" stroke-width="2"/>' +
                            '<line x1="6" y1="10" x2="14" y2="10" stroke="#455A64" stroke-width="2"/>' +
                            '<line x1="40" y1="6" x2="40" y2="14" stroke="#455A64" stroke-width="2"/>' +
                            '<line x1="36" y1="10" x2="44" y2="10" stroke="#455A64" stroke-width="2"/>' +
                            '<line x1="10" y1="36" x2="10" y2="44" stroke="#455A64" stroke-width="2"/>' +
                            '<line x1="6" y1="40" x2="14" y2="40" stroke="#455A64" stroke-width="2"/>' +
                            '<line x1="40" y1="36" x2="40" y2="44" stroke="#455A64" stroke-width="2"/>' +
                            '<line x1="36" y1="40" x2="44" y2="40" stroke="#455A64" stroke-width="2"/>' +
                            // Arms connecting rotors
                            '<line x1="16" y1="16" x2="19" y2="19" stroke="#263238" stroke-width="2"/>' +
                            '<line x1="34" y1="16" x2="31" y2="19" stroke="#263238" stroke-width="2"/>' +
                            '<line x1="16" y1="34" x2="19" y2="31" stroke="#263238" stroke-width="2"/>' +
                            '<line x1="34" y1="34" x2="31" y2="31" stroke="#263238" stroke-width="2"/>' +
                            // Direction indicator (arrow)
                            '<path d="M 25 15 L 25 25 L 30 22 Z" fill="white" opacity="0.9"/>' +
                            // Center LED
                            '<circle cx="25" cy="25" r="3" fill="white" opacity="0.8"/>' +
                            '</svg>'
                        );
                        
                        // Function to update drone marker icon
                        function updateDroneIcon(newIconUrl) {
                            if (newIconUrl && droneMarker && newIconUrl.length > 50) {
                                droneIconUrl = newIconUrl;
                                droneMarker.setIcon({
                                    url: droneIconUrl,
                                    scaledSize: new google.maps.Size(50, 50),
                                    anchor: new google.maps.Point(25, 25)
                                });
                                console.log("Drone marker icon updated with custom image");
                            }
                        }
                        
                        // FIXED: Default location constants
                        const DEFAULT_LOCATION = { lat: 17.601680815915444, lng: 78.12696444254073 }; // Hyderabad
                        
                        function initMap() {
                            // CHANGED: Start with world view, let QML handle centering based on drone status
                            const initialCenter = { lat: 0, lng: 0 }; // World center
                            
                            map = new google.maps.Map(document.getElementById('map'), {
                                zoom: 2, // World view
                                center: initialCenter,
                                mapTypeId: google.maps.MapTypeId.SATELLITE,
                                disableDefaultUI: false,
                                zoomControl: false,
                                mapTypeControl: true,
                                scaleControl: true,
                                streetViewControl: false,
                                rotateControl: true,
                                fullscreenControl: false,
                                styles: [
                                    { featureType: "poi", stylers: [{ visibility: "off" }] },
                                    { featureType: "water", stylers: [{ visibility: "off" }] },
                                    { featureType: "water", elementType: "geometry", stylers: [{ visibility: "off" }] },
                                    { featureType: "water", elementType: "labels", stylers: [{ visibility: "off" }] },
                                    {
                                        featureType: "administrative",
                                        elementType: "geometry.stroke",
                                        stylers: [{ visibility: "on" }, { color: "#2d2d2d" }]
                                    },
                                    {
                                        featureType: "landscape",
                                        elementType: "geometry",
                                        stylers: [{ visibility: "on" }, { color: "#2d2d2d" }]
                                    }
                                ]
                            });

                            // Create drone marker with enhanced drone icon - start hidden
                            droneMarker = new google.maps.Marker({
                                position: DEFAULT_LOCATION,
                                map: null, // Hidden initially
                                title: 'Drone Position - Click for details',
                                icon: {
                                    url: droneIconUrl,
                                    scaledSize: new google.maps.Size(50, 50),
                                    anchor: new google.maps.Point(25, 25)
                                },
                                animation: null,
                                zIndex: 1000,
                                optimized: false  // Better rendering for custom icons
                            });

                            // Add info window for drone marker
                            const droneInfoWindow = new google.maps.InfoWindow({
                                content: '<div style="color: #333;"><strong>Drone Position</strong><br>Status: Disconnected<br>Lat: 0.000000°<br>Lon: 0.000000°<br>Alt: 0.0m</div>'
                            });

                            droneMarker.addListener('click', function() {
                                droneInfoWindow.open(map, droneMarker);
                            });

                            // Create route path
                            routePath = new google.maps.Polyline({
                                path: [],
                                geodesic: true,
                                strokeColor: '#FF0000',
                                strokeOpacity: 1.0,
                                strokeWeight: 3
                            });
                            routePath.setMap(map);

                            // Map click listener
                            map.addListener('click', function(event) {
                                const lat = event.latLng.lat();
                                const lng = event.latLng.lng();
                                
                                document.getElementById('lat').textContent = lat.toFixed(6);
                                document.getElementById('lon').textContent = lng.toFixed(6);

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

                            // ADDED: Mark map as initialized and notify QML
                            mapInitialized = true;
                            console.log("Map initialized successfully - notifying QML");
                            setTimeout(removeWatermarks, 2000);
                        }

                        function removeWatermarks() {
                            const walker = document.createTreeWalker(
                                document.body, NodeFilter.SHOW_TEXT, null, false
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
                                '[class*="watermark"]', 'div[style*="background-color: rgba(0, 0, 0, 0.5)"]'
                            ];
                            watermarkSelectors.forEach(selector => {
                                const elements = document.querySelectorAll(selector);
                                elements.forEach(el => { el.style.display = 'none'; el.remove(); });
                            });
                            setTimeout(removeWatermarks, 5000);
                        }

                        // FIXED: Enhanced drone position update function
                        function updateDronePosition(lat, lng, alt, connected) {
                            console.log("Updating drone position:", lat, lng, alt, "Connected:", connected);
                            
                            if (!droneMarker || !lat || !lng || lat === 0 || lng === 0) {
                                if (!connected) {
                                    // Hide drone marker when disconnected
                                    if (droneMarker.getMap() !== null) {
                                        droneMarker.setMap(null);
                                        console.log("Drone disconnected - hiding marker");
                                    }
                                }
                                return;
                            }

                            const position = new google.maps.LatLng(lat, lng);
                            droneMarker.setPosition(position);
                            lastDroneUpdate = new Date();
                            
                            // Update connection state
                            const wasDisconnected = !isDroneConnected;
                            isDroneConnected = connected;
                            
                            // Update drone info panel
                            const statusElement = document.getElementById('connectionStatus');
                            const detailsElement = document.getElementById('droneDetails');
                            
                            if (connected) {
                                // Show drone marker when connected
                                if (droneMarker.getMap() === null) {
                                    droneMarker.setMap(map);
                                    console.log("Drone connected - showing marker");
                                }
                                
                                statusElement.textContent = 'Drone Connected';
                                statusElement.className = 'connection-status';
                                detailsElement.style.display = 'block';
                                
                                document.getElementById('droneLat').textContent = lat.toFixed(6);
                                document.getElementById('droneLon').textContent = lng.toFixed(6);
                                document.getElementById('droneAlt').textContent = alt.toFixed(1);
                                document.getElementById('lastUpdate').textContent = lastDroneUpdate.toLocaleTimeString();
                                
                                // Add bounce animation on first connection or position change
                                droneMarker.setAnimation(google.maps.Animation.BOUNCE);
                                setTimeout(() => droneMarker.setAnimation(null), 2000);
                            } else {
                                statusElement.textContent = 'Drone Disconnected';
                                statusElement.className = 'disconnected-status';
                                detailsElement.style.display = 'none';
                                
                                // Hide marker when disconnected
                                droneMarker.setAnimation(null);
                                droneMarker.setMap(null);
                            }
                            
                            // Update info window content
                            const infoContent = 
                                '<div style="color: #333; min-width: 200px;">' +
                                '<strong>Drone Status</strong><br>' +
                                'Status: <span style="color: ' + (connected ? '#4CAF50' : '#f44336') + ';">' + 
                                (connected ? 'Connected' : 'Disconnected') + '</span><br>' +
                                'Lat: ' + lat.toFixed(6) + '°<br>' +
                                'Lon: ' + lng.toFixed(6) + '°<br>' +
                                'Alt: ' + alt.toFixed(1) + 'm<br>' +
                                'Updated: ' + (lastDroneUpdate ? lastDroneUpdate.toLocaleTimeString() : 'Never') +
                                '</div>';
                            
                            // Update the info window content
                            if (droneMarker.infoWindow) {
                                droneMarker.infoWindow.setContent(infoContent);
                            } else {
                                droneMarker.infoWindow = new google.maps.InfoWindow({ content: infoContent });
                                droneMarker.addListener('click', function() {
                                    droneMarker.infoWindow.open(map, droneMarker);
                                });
                            }
                        }
                        
                        // FIXED: Center on drone function with validation
                        function centerOnDrone(lat, lng) {
                            if (map && lat && lng && lat !== 0 && lng !== 0) {
                                const position = new google.maps.LatLng(lat, lng);
                                map.setCenter(position);
                                map.setZoom(20);
                                console.log("Centered map on drone position:", lat, lng, "at zoom level 20");
                            } else {
                                console.log("Cannot center on drone - invalid coordinates:", lat, lng);
                            }
                        }
                        
                        // ADDED: Function to return to default location
                        function returnToDefaultLocation() {
                            if (map) {
                                map.setCenter(new google.maps.LatLng(DEFAULT_LOCATION.lat, DEFAULT_LOCATION.lng));
                                map.setZoom(16); // Default zoom level
                                console.log("Returned to default location:", DEFAULT_LOCATION.lat, DEFAULT_LOCATION.lng);
                            }
                        }

                        // ADDED: Function to notify QML when map is ready
                        function notifyMapReady() {
                            console.log("Map is ready - notifying QML");
                        }

                        function addMarker(lat, lng, altitude = 10, speed = 5) {
                            const position = new google.maps.LatLng(lat, lng);
                            const markerIndex = markers.length;
                            
                            const marker = new google.maps.Marker({
                                position: position,
                                map: map,
                                title: 'Waypoint ' + (markerIndex + 1),
                                label: {
                                    text: (markerIndex + 1).toString(),
                                    color: 'white',
                                    fontWeight: 'bold'
                                },
                                icon: {
                                    path: google.maps.SymbolPath.CIRCLE,
                                    fillColor: '#00bcd4',
                                    fillOpacity: 1,
                                    strokeColor: '#ffffff',
                                    strokeWeight: 2,
                                    scale: 16
                                }
                            });

                            const markerData = {
                                marker: marker,
                                lat: lat,
                                lng: lng,
                                altitude: altitude,
                                speed: speed,
                                index: markerIndex
                            };

                            markers.push(markerData);
                            updateRoutePath();

                            marker.addListener('click', function() {
                                showMarkerPopup(markerData);
                            });

                            return markerIndex;
                        }

                        function deleteMarker(index) {
                            if (index >= 0 && index < markers.length) {
                                markers[index].marker.setMap(null);
                                markers.splice(index, 1);
                                
                                markers.forEach((markerData, i) => {
                                    markerData.index = i;
                                    markerData.marker.setLabel({
                                        text: (i + 1).toString(),
                                        color: 'white',
                                        fontWeight: 'bold'
                                    });
                                });
                                
                                updateRoutePath();
                            }
                        }

                        function clearAllMarkers() {
                            markers.forEach(markerData => {
                                markerData.marker.setMap(null);
                            });
                            markers = [];
                            updateRoutePath();
                            console.log("All markers cleared");
                        }

                        function updateRoutePath() {
                            const path = markers.map(m => new google.maps.LatLng(m.lat, m.lng));
                            routePath.setPath(path);
                        }

                        function showMarkerPopup(markerData) {
                            console.log("Marker clicked:", markerData);
                        }

                        function setAddMarkersMode(enabled) {
                            addMarkersMode = enabled;
                        }

                        function zoomIn() { 
                            if (map) {
                                map.setZoom(map.getZoom() + 1); 
                            }
                        }
                        
                        function zoomOut() { 
                            if (map) {
                                map.setZoom(map.getZoom() - 1); 
                            }
                        }
                        
                        function setMapType(type) {
                            if (!map) return;
                            
                            let mapStyles = [
                                { featureType: "poi", stylers: [{ visibility: "off" }] },
                                { featureType: "water", stylers: [{ visibility: "off" }] },
                                { featureType: "water", elementType: "geometry", stylers: [{ visibility: "off" }] },
                                { featureType: "water", elementType: "labels", stylers: [{ visibility: "off" }] }
                            ];

                            switch(type) {
                                case 'satellite':
                                    map.setMapTypeId(google.maps.MapTypeId.SATELLITE);
                                    break;
                                case 'hybrid':
                                    map.setMapTypeId(google.maps.MapTypeId.HYBRID);
                                    break;
                                case 'terrain':
                                    map.setMapTypeId(google.maps.MapTypeId.TERRAIN);
                                    break;
                                default:
                                    map.setMapTypeId(google.maps.MapTypeId.ROADMAP);
                            }
                            map.setOptions({ styles: mapStyles });
                        }

                        window.initMap = initMap;
                    </script>
                    <script async defer src="https://maps.googleapis.com/maps/api/js?key=AIzaSyDnBjIddcNnhfndEEJHi8puawYx3cPspWI&callback=initMap"></script>
                </body>
                </html>
            `)

            // FIXED: Enhanced timer for drone location updates with proper initialization handling
            Timer {
                interval: 500
                running: true
                repeat: true
                
                property bool previousConnectionState: false
                property bool hasTriggeredInitialCenter: false
                
                onTriggered: {
                    var hasValidData = root.currentLat && root.currentLon && 
                                      !isNaN(root.currentLat) && !isNaN(root.currentLon) &&
                                      root.currentLat !== 0 && root.currentLon !== 0;
                    
                    var currentConnectionState = root.isDroneConnected && hasValidData;
                    
                    // Always update drone position (will handle showing/hiding marker internally)
                    mapWebView.runJavaScript(
                        `updateDronePosition(${root.currentLat || 0}, ${root.currentLon || 0}, ${root.currentAlt || 0}, ${currentConnectionState});`
                    );
                    
                    // Handle initial centering when drone first connects OR when map first loads with connected drone
                    if (currentConnectionState && (!previousConnectionState || (!hasTriggeredInitialCenter && root.mapInitialized))) {
                        console.log("MapView: Triggering initial center - drone connected with valid data")
                        Qt.callLater(function() {
                            mapWebView.centerOnDroneJS()
                            hasTriggeredInitialCenter = true
                        })
                    }
                    // Handle disconnection - return to default view
                    else if (!currentConnectionState && previousConnectionState) {
                        console.log("MapView: Drone disconnected, returning to world view")
                        Qt.callLater(function() {
                            mapWebView.runJavaScript("map.setCenter({ lat: 0, lng: 0 }); map.setZoom(2);")
                        })
                        hasTriggeredInitialCenter = false
                    }
                    
                    previousConnectionState = currentConnectionState
                }
            }

            // ADDED: Handle map initialization completion
            onLoadingChanged: {
                if (loadRequest.status === WebEngineLoadRequest.LoadSucceededStatus) {
                    console.log("MapView: WebEngine loaded successfully")
                    // Add small delay to ensure JavaScript is ready
                    Qt.callLater(function() {
                        mapInitialized = true
                        checkForInitialCentering()
                        
                        // Try to update with custom icon if already loaded
                        if (droneIconBase64.length > 100) {
                            console.log("Applying custom drone icon to map...")
                            mapWebView.runJavaScript(`
                                if (typeof updateDroneIcon === 'function') {
                                    updateDroneIcon('${droneIconBase64}');
                                    console.log('Custom drone icon applied');
                                }
                            `)
                        }
                    })
                }
            }

            onJavaScriptConsoleMessage: function(level, message, lineNumber, sourceId) {
                console.log("WebEngine:", message);
                
                // ADDED: Handle map initialization notification
                if (message.includes("Map initialized successfully")) {
                    mapInitialized = true
                    checkForInitialCentering()
                }
            }

            // JavaScript execution functions
            function addMarkerJS(lat, lon, altitude, speed) {
                runJavaScript(`addMarker(${lat}, ${lon}, ${altitude || 10}, ${speed || 5});`);
            }

            function deleteMarkerJS(index) {
                runJavaScript(`deleteMarker(${index});`);
            }

            function setAddMarkersModeJS(enabled) {
                runJavaScript(`setAddMarkersMode(${enabled});`);
                addMarkersMode = enabled;
            }

            function centerOnDroneJS() {
                if (root.currentLat && root.currentLon && !isNaN(root.currentLat) && !isNaN(root.currentLon)) {
                    runJavaScript(`centerOnDrone(${root.currentLat}, ${root.currentLon});`);
                    console.log("MapView: Centering on drone at", root.currentLat, root.currentLon);
                } else {
                    console.log("MapView: Cannot center - invalid drone coordinates");
                }
            }

            function returnToDefaultLocation() {
                runJavaScript("returnToDefaultLocation();");
                console.log("MapView: Returning to default location");
            }

            function zoomInJS() {
                runJavaScript("zoomIn();");
            }

            function zoomOutJS() {
                runJavaScript("zoomOut();");
            }

            function setMapTypeJS(type) {
                runJavaScript(`setMapType('${type}');`);
            }
        }

        // Map controls
        Rectangle {
            id: mapControls
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.margins: 15
            width: 50
            height: 200
            color: "#1a1a1a"
            radius: 8
            border.color: "#404040"
            border.width: 1
            opacity: 0.9

            Column {
                anchors.centerIn: parent
                spacing: 8

                Button {
                    id: zoomInBtn
                    width: 35
                    height: 35
                    text: "+"
                    
                    background: Rectangle {
                        color: zoomInBtn.pressed ? "#404040" : (zoomInBtn.hovered ? "#303030" : "#2d2d2d")
                        radius: 6
                        border.color: "#00bcd4"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    contentItem: Text {
                        text: zoomInBtn.text
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: mapWebView.zoomInJS()
                }

                Button {
                    id: zoomOutBtn
                    width: 35
                    height: 35
                    text: "−"
                    
                    background: Rectangle {
                        color: zoomOutBtn.pressed ? "#404040" : (zoomOutBtn.hovered ? "#303030" : "#2d2d2d")
                        radius: 6
                        border.color: "#00bcd4"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    contentItem: Text {
                        text: zoomOutBtn.text
                        font.pixelSize: 18
                        font.weight: Font.Bold
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: mapWebView.zoomOutJS()
                }

                Button {
                    id: centerBtn
                    width: 35
                    height: 35
                    text: "🎯"
                    
                    background: Rectangle {
                        color: centerBtn.pressed ? "#404040" : (centerBtn.hovered ? "#303030" : "#2d2d2d")
                        radius: 6
                        border.color: root.isDroneConnected ? "#00e676" : "#f44336"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 300 } }
                    }
                    
                    contentItem: Text {
                        text: centerBtn.text
                        font.pixelSize: 14
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: mapWebView.centerOnDroneJS()
                    
                    ToolTip.visible: hovered
                    ToolTip.text: root.isDroneConnected ? "Center on drone" : "Drone not connected"
                    ToolTip.delay: 1000
                }

                Button {
                    id: mapTypeBtn
                    width: 35
                    height: 35
                    text: "🗺️"
                    
                    background: Rectangle {
                        color: mapTypeBtn.pressed ? "#404040" : (mapTypeBtn.hovered ? "#303030" : "#2d2d2d")
                        radius: 6
                        border.color: "#00bcd4"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    contentItem: Text {
                        text: mapTypeBtn.text
                        font.pixelSize: 14
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    property var mapTypes: ["satellite", "hybrid", "terrain", "roadmap"]
                    property int currentTypeIndex: 0
                    
                    onClicked: {
                        currentTypeIndex = (currentTypeIndex + 1) % mapTypes.length
                        mapWebView.setMapTypeJS(mapTypes[currentTypeIndex])
                    }
                }

                Button {
                    id: addMarkerBtn
                    width: 35
                    height: 35
                    text: "📍"
                    
                    background: Rectangle {
                        color: mapWebView.addMarkersMode ? "#00bcd4" : 
                               (addMarkerBtn.pressed ? "#404040" : (addMarkerBtn.hovered ? "#303030" : "#2d2d2d"))
                        radius: 6
                        border.color: "#00bcd4"
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    
                    contentItem: Text {
                        text: addMarkerBtn.text
                        font.pixelSize: 14
                        color: "#ffffff"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: {
                        mapWebView.setAddMarkersModeJS(!mapWebView.addMarkersMode)
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
    
    // Marker Popup
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
        property real markerLat: 0
        property real markerLon: 0
        property real altitude: 10
        property real speed: 5
        
        background: Rectangle {
            color: theme.cardBackground
            border.color: theme.accent
            border.width: 2
            radius: theme.borderRadius
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
                    text: "Marker #" + (markerPopup.markerIndex + 1)
                    font.pixelSize: 16
                    font.bold: true
                    color: "white"
                    anchors.centerIn: parent
                }
                
                Button {
                    width: 30
                    height: 30
                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter
                    contentItem: Text { text: "✖"; color: "white"; font.pixelSize: 14 }
                    background: Rectangle { color: "transparent" }
                    onClicked: markerPopup.close()
                }
            }
            
            Text { 
                text: "Lat: " + markerPopup.markerLat.toFixed(6)
                font.pixelSize: 14
                color: theme.textPrimary 
            }
            Text { 
                text: "Lon: " + markerPopup.markerLon.toFixed(6)
                font.pixelSize: 14
                color: theme.textPrimary 
            }
            
            Column {
                width: parent.width - 10
                spacing: 5
                Text { text: "Altitude (m):"; font.pixelSize: 14; color: theme.textPrimary }
                Row {
                    spacing: 3
                    width: parent.width
                    height: 35
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "−"; color: "white"; font.pixelSize: 16; font.bold: true }
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
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle { 
                            color: "#2d2d2d"
                            radius: 4; 
                            border.color: theme.accent; 
                            border.width: 1 
                        }
                        color: theme.textPrimary
                    }
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "+"; color: "white"; font.pixelSize: 16; font.bold: true }
                        background: Rectangle { color: theme.accent; radius: 4 }
                        onClicked: {
                            markerPopup.altitude += 1;
                            altitudeField.text = markerPopup.altitude.toString();
                        }
                    }
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "✓"; color: "white"; font.pixelSize: 16; font.bold: true }
                        background: Rectangle { color: "green"; radius: 4 }
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
                Text { text: "Speed (m/s):"; font.pixelSize: 14; color: theme.textPrimary }
                Row {
                    spacing: 3
                    width: parent.width
                    height: 35
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "−"; color: "white"; font.pixelSize: 16; font.bold: true }
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
                        horizontalAlignment: Text.AlignHCenter
                        background: Rectangle { 
                            color: "#2d2d2d"
                            radius: 4; 
                            border.color: theme.accent; 
                            border.width: 1 
                        }
                        color: theme.textPrimary
                    }
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "+"; color: "white"; font.pixelSize: 16; font.bold: true }
                        background: Rectangle { color: theme.accent; radius: 4 }
                        onClicked: {
                            markerPopup.speed += 0.5;
                            speedField.text = markerPopup.speed.toString();
                        }
                    }
                    
                    Button {
                        width: 35; height: parent.height
                        contentItem: Text { text: "✓"; color: "white"; font.pixelSize: 16; font.bold: true }
                        background: Rectangle { color: "green"; radius: 4 }
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
                contentItem: Text { text: "🗑️ Delete Marker"; color: "white"; font.pixelSize: 14 }
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

    // JavaScript functions for external access
    function addMarker(lat, lon, altitude, speed) {
        mapWebView.addMarkerJS(lat, lon, altitude || 10, speed || 5);
    }

    function deleteMarker(index) {
        mapWebView.deleteMarkerJS(index);
    }

    function setAddMarkersMode(enabled) {
        mapWebView.setAddMarkersModeJS(enabled);
    }

    function centerOnDrone() {
        mapWebView.centerOnDroneJS();
    }

    function showMarkerPopup(index, lat, lng, altitude, speed) {
        markerPopup.markerIndex = index;
        markerPopup.markerLat = lat;
        markerPopup.markerLon = lng;
        markerPopup.altitude = altitude || 10;
        markerPopup.speed = speed || 5;
        markerPopup.open();
    }
    
    function receiveMarkersFromNavigation(markersData) {
        console.log("MapView: Received " + markersData.length + " markers from NavigationControls");
        
        if (!markersData || markersData.length === 0) {
            clearAllMarkers();
            return;
        }
        
        // Clear existing markers first
        mapWebView.runJavaScript("clearAllMarkers();", function() {
            // Add each marker from the received data
            for (var i = 0; i < markersData.length; i++) {
                var marker = markersData[i];
                console.log("MapView: Adding marker", i, "at", marker.lat, marker.lng);
                
                mapWebView.runJavaScript(
                    `addMarker(${marker.lat}, ${marker.lng}, ${marker.altitude || 10}, ${marker.speed || 5}, '${marker.commandType || 'waypoint'}', ${marker.holdTime || 0});`
                );
            }
        });
    }
    
    function clearAllMarkers() {
        mapWebView.runJavaScript("clearAllMarkers();");
    }
}