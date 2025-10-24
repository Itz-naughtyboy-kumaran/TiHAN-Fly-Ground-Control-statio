import QtQuick 2.15
import QtQuick.Controls 2.15
import QtMultimedia 5.15

ApplicationWindow {
    id: aboutWindow
    width: 2000
    height: 1200
    title: "About TIHAN - Technology Innovation Hub for Autonomous Navigation"
    visible: true
    modality: Qt.ApplicationModal
    flags: Qt.Dialog
    
    // Professional gradient background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#0f1419" }
            GradientStop { position: 0.5; color: "#1a202c" }
            GradientStop { position: 1.0; color: "#2d3748" }
        }
    }
    
    ScrollView {
        id: scrollView
        anchors.fill: parent
        anchors.margins: 40
        clip: true
        
        ScrollBar.vertical: ScrollBar {
            policy: ScrollBar.AsNeeded
            background: Rectangle {
                color: "#2d3748"
                radius: 6
            }
            contentItem: Rectangle {
                color: "#4a5568"
                radius: 6
            }
        }
        
        Column {
            width: scrollView.width - 80
            spacing: 40
            
            // Professional Header Section
            Rectangle {
                width: parent.width
                height: 150
                color: "transparent"
                
                Column {
                    anchors.centerIn: parent
                    spacing: 15
                    
                    Text {
                        text: "TIHAN"
                        font.pixelSize: 48
                        font.bold: true
                        font.family: "Consolas"
                        color: "#ffffff"
                        anchors.horizontalCenter: parent.horizontalCenter
                        style: Text.Raised
                        styleColor: "#1a365d"
                    }
                    
                    Text {
                        text: "Technology Innovation Hub for Autonomous Navigation"
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        font.family: "Consolas"
                        color: "#a0aec0"
                        anchors.horizontalCenter: parent.horizontalCenter
                        horizontalAlignment: Text.AlignHCenter
                    }
                    
                    Rectangle {
                        width: 100
                        height: 4
                        color: "#3182ce"
                        radius: 2
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        Rectangle {
                            width: parent.width * 0.6
                            height: parent.height
                            color: "#63b3ed"
                            radius: parent.radius
                            anchors.centerIn: parent
                        }
                    }
                }
            }
            
            // Video Section with Professional Frame
            Rectangle {
                width: parent.width
                height: 500
                color: "#2d3748"
                radius: 20
                border.width: 2
                border.color: "#4a5568"
                
                // Subtle shadow effect
                Rectangle {
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.leftMargin: 4
                    color: "#000000"
                    opacity: 0.3
                    radius: parent.radius
                    z: parent.z - 1
                }
                
                Column {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 30
                    spacing: 20
                    
                    Row {
                        spacing: 15
                        
                        Rectangle {
                            width: 6
                            height: 30
                            color: "#3182ce"
                            radius: 3
                        }
                        
                        Text {
                            text: "TIHAN Showcase"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "Consolas"
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Video Player Container
                    Rectangle {
                        width: parent.width
                        height: 380
                        color: "#1a202c"
                        radius: 15
                        border.width: 1
                        border.color: "#4a5568"
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 20
                            
                            Rectangle {
                                width: 80
                                height: 80
                                color: "#3182ce"
                                radius: 40
                                anchors.horizontalCenter: parent.horizontalCenter
                                
                                Text {
                                    text: "▶"
                                    font.pixelSize: 40
                                    font.family: "Consolas"
                                    color: "#ffffff"
                                    anchors.centerIn: parent
                                    anchors.horizontalCenterOffset: 3
                                }
                            }
                            
                            Text {
                                text: "TIHAN Demo Video"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "Consolas"
                                color: "#ffffff"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Text {
                                text: "Click to play demonstration video"
                                font.pixelSize: 16
                                font.family: "Consolas"
                                color: "#a0aec0"
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                        }
                        
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered: parent.border.color = "#3182ce"
                            onExited: parent.border.color = "#4a5568"
                            onClicked: {
                                console.log("Video clicked - implement video player here")
                                // Implement video player functionality
                            }
                        }
                    }
                }
            }
            
            // About Section
            Rectangle {
                width: parent.width
                height: aboutContent.height + 60
                color: "#2d3748"
                radius: 20
                border.width: 1
                border.color: "#4a5568"
                
                Column {
                    id: aboutContent
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 30
                    spacing: 20
                    
                    Row {
                        spacing: 15
                        
                        Rectangle {
                            width: 6
                            height: 30
                            color: "#38a169"
                            radius: 3
                        }
                        
                        Text {
                            text: "About TIHAN"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "Consolas"
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    Text {
                        width: parent.width
                        text: "TIHAN is India's first dedicated testbed for autonomous navigation, focusing on both aerial (drones) and terrestrial (ground vehicles) systems. Established under the National Mission on Interdisciplinary Cyber-Physical Systems (NM-ICPS) by the Department of Science & Technology (DST), Government of India, TIHAN aims to accelerate the development and deployment of autonomous technologies across various sectors."
                        font.pixelSize: 16
                        font.weight: Font.Normal
                        font.family: "Consolas"
                        color: "#e2e8f0"
                        wrapMode: Text.WordWrap
                        lineHeight: 1.6
                    }
                }
            }
            
            // Infrastructure Section
            Rectangle {
                width: parent.width
                height: infrastructureContent.height + 60
                color: "#2d3748"
                radius: 20
                border.width: 1
                border.color: "#4a5568"
                
                Column {
                    id: infrastructureContent
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 30
                    spacing: 25
                    
                    Row {
                        spacing: 15
                        
                        Rectangle {
                            width: 6
                            height: 30
                            color: "#ed8936"
                            radius: 3
                        }
                        
                        Text {
                            text: "Infrastructure & Testbed Facilities"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "Consolas"
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    Text {
                        width: parent.width
                        text: "TIHAN boasts state-of-the-art infrastructure designed to support the development and validation of autonomous systems:"
                        font.pixelSize: 16
                        font.family: "Consolas"
                        color: "#e2e8f0"
                        wrapMode: Text.WordWrap
                        lineHeight: 1.5
                    }
                    
                    // Infrastructure Grid
                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: 30
                        rowSpacing: 20
                        
                        // Infrastructure Item 1
                        Rectangle {
                            width: (parent.width - parent.columnSpacing) / 2
                            height: 120
                            color: "#1a202c"
                            radius: 15
                            border.width: 1
                            border.color: "#4a5568"
                            
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 20
                                spacing: 10
                                
                                Text {
                                    text: "🏁 Proving Grounds & Test Tracks"
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: "Consolas"
                                    color: "#ffffff"
                                    width: parent.width
                                }
                                
                                Text {
                                    text: "Dedicated areas for real-world testing of autonomous vehicles"
                                    font.pixelSize: 16
                                    font.family: "Consolas"
                                    color: "#cbd5e0"
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                        
                        // Infrastructure Item 2
                        Rectangle {
                            width: (parent.width - parent.columnSpacing) / 2
                            height: 120
                            color: "#1a202c"
                            radius: 15
                            border.width: 1
                            border.color: "#4a5568"
                            
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 20
                                spacing: 10
                                
                                Text {
                                    text: "🔧 Simulation Tools"
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: "Consolas"
                                    color: "#ffffff"
                                    width: parent.width
                                }
                                
                                Text {
                                    text: "SIL, MIL, HIL, and VIL simulation capabilities"
                                    font.pixelSize: 16
                                    font.family: "Consolas"
                                    color: "#cbd5e0"
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                        
                        // Infrastructure Item 3
                        Rectangle {
                            width: (parent.width - parent.columnSpacing) / 2
                            height: 120
                            color: "#1a202c"
                            radius: 15
                            border.width: 1
                            border.color: "#4a5568"
                            
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 20
                                spacing: 10
                                
                                Text {
                                    text: "🛣️ Smart Road Infrastructure"
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: "Consolas"
                                    color: "#ffffff"
                                    width: parent.width
                                }
                                
                                Text {
                                    text: "Signalized intersections, smart poles, environment emulators"
                                    font.pixelSize: 16
                                    font.family: "Consolas"
                                    color: "#cbd5e0"
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                        
                        // Infrastructure Item 4
                        Rectangle {
                            width: (parent.width - parent.columnSpacing) / 2
                            height: 120
                            color: "#1a202c"
                            radius: 15
                            border.width: 1
                            border.color: "#4a5568"
                            
                            Column {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.margins: 20
                                spacing: 10
                                
                                Text {
                                    text: "📡 Communication Networks"
                                    font.pixelSize: 16
                                    font.bold: true
                                    font.family: "Consolas"
                                    color: "#ffffff"
                                    width: parent.width
                                }
                                
                                Text {
                                    text: "Wi-Fi, 5G, CV2X, and edge cloud capabilities"
                                    font.pixelSize: 16
                                    font.family: "Consolas"
                                    color: "#cbd5e0"
                                    width: parent.width
                                    wrapMode: Text.WordWrap
                                }
                            }
                        }
                    }
                }
            }
            
            // Vision & Recognition Section
            Rectangle {
                width: parent.width
                height: visionContent.height + 60
                color: "#2d3748"
                radius: 20
                border.width: 1
                border.color: "#4a5568"
                
                Column {
                    id: visionContent
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 30
                    spacing: 25
                    
                    Row {
                        spacing: 15
                        
                        Rectangle {
                            width: 6
                            height: 30
                            color: "#9f7aea"
                            radius: 3
                        }
                        
                        Text {
                            text: "Vision & Recognition"
                            font.pixelSize: 16
                            font.bold: true
                            font.family: "Consolas"
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                    
                    // Vision Card
                    Rectangle {
                        width: parent.width
                        height: visionText.height + 40
                        color: "#1a202c"
                        radius: 15
                        border.width: 1
                        border.color: "#4a5568"
                        
                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 40
                            spacing: 15
                            
                            Text {
                                text: "🎯 Our Vision"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "Consolas"
                                color: "#ffffff"
                            }
                            
                            Text {
                                id: visionText
                                width: parent.width
                                text: "To become a global destination for next-generation smart mobility technologies utilizing reliable and efficient autonomous navigation systems."
                                font.pixelSize: 16
                                font.family: "Consolas"
                                color: "#cbd5e0"
                                wrapMode: Text.WordWrap
                                lineHeight: 1.5
                            }
                        }
                    }
                    
                    // Recognition Card
                    Rectangle {
                        width: parent.width
                        height: recognitionText.height + 40
                        color: "#1a202c"
                        radius: 15
                        border.width: 1
                        border.color: "#4a5568"
                        
                        Column {
                            anchors.centerIn: parent
                            width: parent.width - 40
                            spacing: 15
                            
                            Text {
                                text: "🏆 Recognition"
                                font.pixelSize: 16
                                font.bold: true
                                font.family: "Consolas"
                                color: "#ffffff"
                            }
                            
                            Text {
                                id: recognitionText
                                width: parent.width
                                text: "TIHAN is recognized as a Scientific and Industrial Research Organisation (SIRO) by the Department of Scientific and Industrial Research, Ministry of Science and Technology, Government of India."
                                font.pixelSize: 16
                                font.family: "Consolas"
                                color: "#cbd5e0"
                                wrapMode: Text.WordWrap
                                lineHeight: 1.5
                            }
                        }
                    }
                }
            }
    
            // Open Website Button
            Rectangle {
                width: parent.width
                height: 100
                color: "transparent"

                Button {
                    anchors.centerIn: parent
                    width: 250
                    height: 50

                    background: Rectangle {
                        color: parent.hovered ? "#ff9933" : "#ff6600"   // Orange shades
                        radius: 25
                        border.width: 3
                        border.color: "#2b6cb0"  // Blue border

                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }

                    contentItem: Text {
                        text: "Visit TIHAN Website"
                        color: "#1e3a8a"   // Deep blue text
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: {
                        Qt.openUrlExternally("https://tihan.iith.ac.in/")
                    }
                }
            }

            // Professional Close Button
            Rectangle {
                width: parent.width
                height: 100
                color: "transparent"
                
                Button {
                    anchors.centerIn: parent
                    width: 200
                    height: 50
                    
                    background: Rectangle {
                        color: parent.hovered ? "#4299e1" : "#3182ce"
                        radius: 25
                        border.width: 2
                        border.color: "#2b6cb0"
                        
                        Behavior on color {
                            ColorAnimation { duration: 200 }
                        }
                    }
                    
                    contentItem: Text {
                        text: "Close"
                        color: "#ffffff"
                        font.pixelSize: 16
                        font.bold: true
                        font.family: "Consolas"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    
                    onClicked: aboutWindow.close()
                }
            }
            
            // Bottom spacing
            Item { height: 40 }
        }
    }
}