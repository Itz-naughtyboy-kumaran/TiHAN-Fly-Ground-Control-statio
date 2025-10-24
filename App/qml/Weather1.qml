import QtQuick 2.15
import QtQuick.Controls 2.15
import QtLocation 5.11
import QtPositioning 5.11
import QtQuick.Layouts 1.0

Rectangle {
    id: weatherWidget
    width: 350
    height: expanded ? 320 : 60
    color: Qt.rgba(1, 1, 1, 0.80) // Semi-transparent white
    radius: 12
    anchors.left: parent.left
    anchors.bottom: parent.bottom
    anchors.margins: 20
    z: 2

    border {
        color: Qt.rgba(1, 1, 1, 0.3)
        width: 1
    }

    property bool expanded: true
    property var weatherData: ({
        temperature: "--",
        description: "No data",
        windSpeed: "--",
        windDirection: "--",
        visibility: "--",
        pressure: "--",
        humidity: "--",
        ceiling: "--"
    })
    function setWeatherData(newData){
        console.log(newData);
        updateWeatherWidget(newData);

    }
    Behavior on height {
        NumberAnimation {
            duration: 200
            easing.type: Easing.InOutQuad
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // 🔹 Header Section
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: Qt.rgba(1, 1, 1, 0.3)
            radius: 8

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Text {
                    text: "⛅"
                    font.pixelSize: 24
                }

                Text {
                    text: "Weather Dashboard"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#2c3e50"
                    Layout.fillWidth: true
                }

                Button {
                    text: weatherWidget.expanded ? "−" : "+"
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: weatherWidget.expanded = !weatherWidget.expanded

                    background: Rectangle {
                        color: parent.hovered ? Qt.rgba(0, 0, 0, 0.1) : "transparent"
                        radius: 6
                    }

                    contentItem: Text {
                        text: parent.text
                        color: "#2c3e50"
                        font.pixelSize: 18
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }
        }

        // 🔹 Main Weather Info
        RowLayout {
            Layout.fillWidth: true
            spacing: 16
            visible: weatherWidget.expanded

            // 🔸 Temperature & Description
            Rectangle {
                Layout.preferredWidth: 120
                Layout.preferredHeight: 80
                color: Qt.rgba(1, 1, 1, 0.3)
                radius: 8

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 4

                    Text {
                        text: weatherWidget.weatherData.temperature
                        font.pixelSize: 36
                        font.bold: true
                        color: "#2c3e50"
                    }

                    Text {
                        text: weatherWidget.weatherData.description
                        font.pixelSize: 14
                        color: "#2c3e50"
                        opacity: 0.8
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }

            // 🔸 Flight Status Indicator
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: getStatusColor(getFlightStatus(weatherData.windSpeed, weatherData.weatherCode))
                radius: 8

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4

                    Text {
                        text: "Flight Status"
                        color: "#ffffff"
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: getFlightStatus(weatherData.windSpeed, weatherData.weatherCode)
                        color: "#ffffff"
                        font.bold: true
                        font.pixelSize: 20
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // 🔹 Detailed Weather Data
        Flow {
            Layout.fillWidth: true
            Layout.topMargin: 8
            spacing: 8
            visible: weatherWidget.expanded

            Repeater {
                model: [
                    {icon: "🌬️", label: "Wind", value: weatherData.windSpeed},
                    {icon: "🧭", label: "Direction", value: weatherData.windDirection},
                    {icon: "👁️", label: "Visibility", value: weatherData.visibility},
                    {icon: "⏲️", label: "Pressure", value: weatherData.pressure},
                    {icon: "💧", label: "Humidity", value: weatherData.humidity},
                    {icon: "☁️", label: "Ceiling", value: weatherData.ceiling}
                ]

                delegate: Rectangle {
                    width: (weatherWidget.width - 32 - 16) / 3
                    height: 70
                    color: Qt.rgba(1, 1, 1, 0.3)
                    radius: 8

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 4

                        RowLayout {
                            spacing: 4
                            Text {
                                text: modelData.icon
                                font.pixelSize: 16
                            }
                            Text {
                                text: modelData.label
                                font.pixelSize: 12
                                color: "#2c3e50"
                                opacity: 0.7
                            }
                        }

                        Text {
                            text: modelData.value
                            font.pixelSize: 14
                            color: "#2c3e50"
                            font.bold: true
                        }
                    }
                }
            }
        }
    }

    // 🔹 Utility Functions
    function getCeiling(cloudCover) {
        return cloudCover > 80 ? "Low" : cloudCover > 40 ? "Medium" : "High";
    }

    function getFlightStatus(windSpeed, weatherCode) {
        if (windSpeed > 15 || weatherCode < 800) return "Unsafe";
        if (windSpeed > 10 || weatherCode === 801) return "Caution";
        return "Safe";
    }

    function getStatusColor(status) {
        switch (status) {
            case "Safe": return "#2ecc71";
            case "Caution": return "#f1c40f";
            case "Unsafe": return "#e74c3c";
            default: return "#f1c40f";
        }
    }

    function updateWeatherWidget(data) {
        weatherWidget.weatherData = {
            temperature: Math.round(data.main.temp) + "°C",
            description: data.weather[0].description,
            windSpeed: (data.wind.speed * 3.6).toFixed(1) + " km/h",
            windDirection: getWindDirection(data.wind.deg),
            visibility: (data.visibility / 1000).toFixed(1) + " km",
            pressure: data.main.pressure + " hPa",
            humidity: data.main.humidity + "%",
            ceiling: getCeiling(data.clouds.all)
        };
        console.log(weatherWidget.weatherData);
    }

    function getWindDirection(degrees) {
        var directions = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"];
        return directions[Math.round(((degrees % 360) / 45)) % 8];
    }
}
