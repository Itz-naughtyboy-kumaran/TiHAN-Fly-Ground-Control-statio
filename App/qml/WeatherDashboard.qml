import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

Rectangle {
    id: root
    
    property bool expanded: false
    property bool dashboardVisible: false
    property bool hasWarnings: false
    property real latitude: 0
    property real longitude: 0
    property string locationName: "Unknown Location"
    property var languageManager: null
    // Weather data properties
    property string temperature: "N/A"
    property string description: "Loading..."
    property string humidity: "N/A"
    property string windSpeed: "N/A"
    property string windDirection: "N/A"
    property string pressure: "N/A"
    property string visibility: "N/A"
    property string uvIndex: "N/A"
    property string cloudCover: "N/A"
    property string weatherIcon: ""
    
    // Warning properties
    property var warnings: []
    
    color: "#ffffff"
    radius: 12
    border.color: "#e0e0e0"
    border.width: 1
    opacity: dashboardVisible ? 1.0 : 0.0
    visible: dashboardVisible
    
    Behavior on opacity {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    Behavior on height {
        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
    }
    
    // Drop shadow effect
    DropShadow {
        anchors.fill: parent
        horizontalOffset: 0
        verticalOffset: 4
        radius: 12
        samples: 25
        color: "#40000000"
        source: parent
        visible: root.dashboardVisible
    }
    
    Column {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10
        
        // Header
        Rectangle {
            id: headerRect
            width: parent.width
            height: 50
            color: "#2196F3"
            radius: 8
            
            MouseArea {
                anchors.fill: parent
                onClicked: root.toggleExpanded()
                cursorShape: Qt.PointingHandCursor
            }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                
                Item {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    
                   Text {
    text: languageManager ? languageManager.getText("Weather Info") : "Weather Info"
    color: "white"
    font.pixelSize: 14
    font.bold: true
    font.family: "Consolas"
}
                }
                
                Column {
                    Layout.fillWidth: true
                    spacing: 2
                    
                    Text {
                        text: "Weather Info"
                        color: "white"
                        font.pixelSize: 14
                        font.bold: true
                        font.family: "Consolas"
                    }
                    
Text {
    text: root.locationName === "Unknown Location" ? 
          (languageManager ? languageManager.getText("Unknown Location") : "Unknown Location") : 
          root.locationName
    color: "#E3F2FD"
    font.pixelSize: 11
    font.family: "Consolas"
    elide: Text.ElideRight
    width: parent.width
}
                }
                
                Text {
                    text: root.temperature
                    color: "white"
                    font.pixelSize: 16
                    font.bold: true
                    font.family: "Consolas"
                }
                
                Text {
                    text: root.expanded ? "▲" : "▼"
                    color: "white"
                    font.pixelSize: 12
                    font.family: "Consolas"
                }
            }
        }
        
        // Expanded content
        Item {
            width: parent.width
            height: root.expanded ? (root.hasWarnings ? 300 : 220) : 0
            visible: root.expanded
            clip: true
            
            ScrollView {
                anchors.fill: parent
                contentWidth: parent.width
                
                Column {
                    width: parent.width
                    spacing: 12
                    
                    // Weather warnings (if any)
                    Repeater {
                        model: root.warnings
                        
                        Rectangle {
                            width: parent.width
                            height: 60
                            color: "#fff3cd"
                            border.color: "#ffc107"
                            border.width: 1
                            radius: 6
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 8
                                spacing: 8
                                
                                Text {
                                    text: "⚠️"
                                    font.pixelSize: 20
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    
                                    Text {
                                        text: modelData.title || "Weather Warning"
                                        font.pixelSize: 12
                                        font.bold: true
                                        color: "#856404"
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                    }
                                    
                                    Text {
                                        text: modelData.description || "Check local weather conditions"
                                        font.pixelSize: 10
                                        color: "#856404"
                                        wrapMode: Text.WordWrap
                                        width: parent.width
                                    }
                                }
                            }
                        }
                    }
                    
                    // Current weather description
                    Rectangle {
                        width: parent.width
                        height: 40
                        color: "#f8f9fa"
                        radius: 6
                        border.color: "#dee2e6"
                        border.width: 1
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8
                            
                            Text {
                                text: "🌤️"
                                font.pixelSize: 16
                            }
                            
Text {
    text: root.description === "Loading..." ? 
          (languageManager ? languageManager.getText("Loading...") : root.description) : 
          root.description
    font.pixelSize: 12
    font.family: "Consolas"
    color: "#495057"
    Layout.fillWidth: true
}

                        }
                    }
                    
                    // Weather details grid
                    Grid {
                        width: parent.width
                        columns: 2
                        spacing: 8
                        
                        // Create individual weather detail items directly
                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: 35
                            color: "#ffffff"
                            radius: 6
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6
                                
                                Text {
                                    text: "💨"
                                    font.pixelSize: 14
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
Text {
    text: languageManager ? languageManager.getText("Wind") : "Wind"
    font.pixelSize: 9
    color: "#6c757d"
    font.family: "Consolas"
}
                                    
                                    Text {
                                        text: root.windSpeed + " " + root.windDirection
                                        font.pixelSize: 11
                                        color: "#495057"
                                        font.family: "Consolas"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: 35
                            color: "#ffffff"
                            radius: 6
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6
                                
                                Text {
                                    text: "💧"
                                    font.pixelSize: 14
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
Text {
    text: languageManager ? languageManager.getText("Pressure") : "Pressure"
    font.pixelSize: 9
    color: "#6c757d"
    font.family: "Consolas"
}
                                    Text {
                                        text: root.humidity
                                        font.pixelSize: 11
                                        color: "#495057"
                                        font.family: "Consolas"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: 35
                            color: "#ffffff"
                            radius: 6
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6
                                
                                Text {
                                    text: "🌡️"
                                    font.pixelSize: 14
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
Text {
    text: languageManager ? languageManager.getText("Pressure") : "Pressure"
    font.pixelSize: 9
    color: "#6c757d"
    font.family: "Consolas"
}

                                    Text {
                                        text: root.pressure
                                        font.pixelSize: 11
                                        color: "#495057"
                                        font.family: "Consolas"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: 35
                            color: "#ffffff"
                            radius: 6
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6
                                
                                Text {
                                    text: "👁️"
                                    font.pixelSize: 14
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
Text {
    text: languageManager ? languageManager.getText("Visibility") : "Visibility"
    font.pixelSize: 9
    color: "#6c757d"
    font.family: "Consolas"
}
                                    
                                    Text {
                                        text: root.visibility
                                        font.pixelSize: 11
                                        color: "#495057"
                                        font.family: "Consolas"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: 35
                            color: "#ffffff"
                            radius: 6
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6
                                
                                Text {
                                    text: "☀️"
                                    font.pixelSize: 14
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0
        Text {
    text: languageManager ? languageManager.getText("UV Index") : "UV Index"
    font.pixelSize: 9
    color: "#6c757d"
    font.family: "Consolas"
}
                                    Text {
                                        text: root.uvIndex
                                        font.pixelSize: 11
                                        color: "#495057"
                                        font.family: "Consolas"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                        
                        Rectangle {
                            width: (parent.width - parent.spacing) / 2
                            height: 35
                            color: "#ffffff"
                            radius: 6
                            border.color: "#dee2e6"
                            border.width: 1
                            
                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 6
                                
                                Text {
                                    text: "☁️"
                                    font.pixelSize: 14
                                }
                                
                                Column {
                                    Layout.fillWidth: true
                                    spacing: 0
                                    
Text {
    text: languageManager ? languageManager.getText("Cloud Cover") : "Cloud Cover"
    font.pixelSize: 9
    color: "#6c757d"
    font.family: "Consolas"
}
                                    
                                    Text {
                                        text: root.cloudCover
                                        font.pixelSize: 11
                                        color: "#495057"
                                        font.family: "Consolas"
                                        font.bold: true
                                    }
                                }
                            }
                        }
                    }
                    
                    // Coordinates
                    Rectangle {
                        width: parent.width
                        height: 35
                        color: "#e9ecef"
                        radius: 6
                        
                        Text {
                            anchors.centerIn: parent
                            text: "📍 " + root.latitude.toFixed(6) + "°, " + root.longitude.toFixed(6) + "°"
                            font.pixelSize: 11
                            font.family: "Consolas"
                            color: "#6c757d"
                        }
                    }
                }
            }
        }
        
        // Close button
        Button {
            width: parent.width
            height: 30
            visible: root.dashboardVisible
            
            background: Rectangle {
                color: parent.hovered ? "#f8d7da" : "#f5c6cb"
                radius: 6
                border.color: "#f5c6cb"
                border.width: 1
            }
            
contentItem: Text {
    text: languageManager ? ("✖ " + languageManager.getText("Close")) : "✖ Close"
    font.pixelSize: 12
    font.family: "Consolas"
    color: "#721c24"
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
}
            
            onClicked: root.hide()
        }
    }
    
    // Functions
    function show() {
        dashboardVisible = true;
        expanded = true;
        console.log("Weather dashboard shown - expanded:", expanded, "visible:", dashboardVisible);
    }
    
    function hide() {
        expanded = false;
        dashboardVisible = false;
        console.log("Weather dashboard hidden");
    }
    
    function toggleExpanded() {
        expanded = !expanded;
        console.log("Weather dashboard toggled - expanded:", expanded);
    }
    
    function setLocation(lat, lon) {
        console.log("Setting location:", lat, lon);
        latitude = lat;
        longitude = lon;
        locationName = "Lat: " + lat.toFixed(4) + ", Lon: " + lon.toFixed(4);
        fetchWeatherData(lat, lon);
    }
    
    function getWeatherEmoji() {
        if (description.toLowerCase().includes("clear")) return "☀️";
        if (description.toLowerCase().includes("cloud")) return "☁️";
        if (description.toLowerCase().includes("rain")) return "🌧️";
        if (description.toLowerCase().includes("storm")) return "⛈️";
        if (description.toLowerCase().includes("snow")) return "❄️";
        if (description.toLowerCase().includes("fog")) return "🌫️";
        return "🌤️";
    }
    
    function fetchWeatherData(lat, lon) {
        console.log("Fetching weather data for:", lat, lon);
        
        // Reset to loading state
        description = "Loading weather data...";
        temperature = "...";
        humidity = "...";
        windSpeed = "...";
        windDirection = "...";
        pressure = "...";
        visibility = "...";
        uvIndex = "...";
        cloudCover = "...";
        warnings = [];
        hasWarnings = false;
        
        // First try real API, fallback to simulation
        fetchRealWeatherData(lat, lon);
        
        // Also fetch location name
        fetchLocationName(lat, lon);
    }
    
    function fetchRealWeatherData(lat, lon) {
        var xhr = new XMLHttpRequest();
        var apiKey = "cd240072891992b8c40e64f05825fa55"; // Your OpenWeather API key
        var url = "https://api.openweathermap.org/data/2.5/weather?lat=" + lat + "&lon=" + lon + "&appid=" + apiKey + "&units=metric";
        
        console.log("Fetching from URL:", url);
        
        xhr.onreadystatechange = function() {
            console.log("XHR state changed - readyState:", xhr.readyState, "status:", xhr.status);
            
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        console.log("API Response:", xhr.responseText);
                        var data = JSON.parse(xhr.responseText);
                        updateWeatherData(data);
                        console.log("Real weather data updated successfully");
                    } catch (e) {
                        console.log("Error parsing weather data:", e);
                        simulateWeatherData(lat, lon);
                    }
                } else {
                    console.log("API request failed with status:", xhr.status);
                    console.log("Response text:", xhr.responseText);
                    simulateWeatherData(lat, lon);
                }
            }
        };
        
        xhr.open("GET", url);
        xhr.send();
    }
    
    function simulateWeatherData(lat, lon) {
        console.log("Using simulated weather data for:", lat, lon);
        
        // Simulate realistic weather data based on location
        var temp = Math.round(20 + Math.random() * 15); // 20-35°C
        var windSpd = Math.round(Math.random() * 15); // 0-15 m/s
        var humid = Math.round(40 + Math.random() * 40); // 40-80%
        var press = Math.round(1000 + Math.random() * 50); // 1000-1050 hPa
        
        temperature = temp + "°C";
    description = languageManager ? languageManager.getText("Loading weather data...") : "Loading weather data...";        humidity = humid + "%";
        windSpeed = Math.round(windSpd * 3.6) + " km/h";
        windDirection = getWindDirection(Math.random() * 360);
        pressure = press + " hPa";
        visibility = "10 km";
        cloudCover = Math.round(Math.random() * 100) + "%";
        uvIndex = Math.round(Math.random() * 10).toString();
        
        // Check for simulated weather warnings
        checkSimulatedWarnings(temp, windSpd);
        
        console.log("Simulated weather data updated - temp:", temperature, "desc:", description);
    }
    
    function checkSimulatedWarnings(temp, windSpeed) {
        var newWarnings = [];
        
        if (temp > 32) {
            newWarnings.push({
                title: "High Temperature Warning",
                description: "Temperature is above 32°C. Consider drone battery performance and overheating risks."
            });
        }
        
        if (windSpeed > 8) {
            newWarnings.push({
                title: "High Wind Warning",
                description: "Wind speeds above 28 km/h. Drone flight stability may be affected."
            });
        }
        
        warnings = newWarnings;
        hasWarnings = warnings.length > 0;
        console.log("Weather warnings updated:", hasWarnings ? warnings.length + " warnings" : "no warnings");
    }
    
    function fetchLocationName(lat, lon) {
        var xhr = new XMLHttpRequest();
        var apiKey = "cd240072891992b8c40e64f05825fa55";
        var url = "https://api.openweathermap.org/geo/1.0/reverse?lat=" + lat + "&lon=" + lon + "&limit=1&appid=" + apiKey;
        
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    if (data && data.length > 0) {
                        var location = data[0];
                        locationName = (location.name || "") + (location.country ? ", " + location.country : "");
                        console.log("Location name updated:", locationName);
                    }
                } catch (e) {
                    console.log("Error fetching location name:", e);
                }
            }
        };
        
        xhr.open("GET", url);
        xhr.send();
    }
    
    function updateWeatherData(data) {
        console.log("Updating weather data with real API data");
        
        try {
            root.temperature = Math.round(data.main.temp) + "°C";
            root.description = data.weather[0].description.charAt(0).toUpperCase() + data.weather[0].description.slice(1);
            root.humidity = data.main.humidity + "%";
            root.windSpeed = Math.round(data.wind.speed * 3.6) + " km/h"; // Convert m/s to km/h
            root.windDirection = getWindDirection(data.wind.deg || 0);
            root.pressure = data.main.pressure + " hPa";
            root.visibility = data.visibility ? Math.round(data.visibility / 1000) + " km" : "N/A";
            root.cloudCover = (data.clouds && data.clouds.all) ? data.clouds.all + "%" : "N/A";
            root.uvIndex = "N/A"; // UV data requires separate API call
            
            // Check for weather warnings
            checkWeatherWarnings(data);
            
            console.log("Real weather data updated - temp:", root.temperature, "desc:", root.description);
        } catch (e) {
            console.log("Error in updateWeatherData:", e);
            setErrorState("Error updating weather data");
        }
    }
    
    function checkWeatherWarnings(data) {
        var newWarnings = [];
        
        // Check for extreme temperatures
        if (data.main.temp > 35) {
            newWarnings.push({
                title: "High Temperature Warning",
                description: "Temperature is above 35°C. Stay hydrated and avoid prolonged sun exposure."
            });
        } else if (data.main.temp < -10) {
            newWarnings.push({
                title: "Low Temperature Warning", 
                description: "Temperature is below -10°C. Take precautions against frostbite."
            });
        }
        
        // Check for high wind speeds
        if (data.wind.speed > 10) {
            newWarnings.push({
                title: "High Wind Warning",
                description: "Wind speeds above 36 km/h. Be cautious when flying drones."
            });
        }
        
        // Check for low visibility
        if (data.visibility && data.visibility < 1000) {
            newWarnings.push({
                title: "Low Visibility Warning",
                description: "Visibility below 1 km. Flight operations may be impaired."
            });
        }
        
        warnings = newWarnings;
        hasWarnings = warnings.length > 0;
    }
    
    function getWindDirection(degrees) {
        var directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE", 
                         "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"];
        var index = Math.round(degrees / 22.5) % 16;
        return directions[index];
    }
    
    function setErrorState(message) {
        description = message;
        temperature = "N/A";
        humidity = "N/A";
        windSpeed = "N/A";
        windDirection = "";
        pressure = "N/A";
        visibility = "N/A";
        uvIndex = "N/A";
        cloudCover = "N/A";
        warnings = [];
        hasWarnings = false;
    }
}