import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtGraphicalEffects 1.15

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 700
    title: "Radio Calibration - TiHAN Drone System"
    
    // Connection properties - using the same drone connection system
    property bool isConnected: droneModel ? droneModel.isConnected : false
    
    // Get channel info from backend instead of creating our own array
    property var channelInfo: radioCalibrationModel ? radioCalibrationModel.getChannelInfo() : []
    
    property bool calibrationActive: radioCalibrationModel ? radioCalibrationModel.calibrationActive : false
    property int calibrationStep: radioCalibrationModel ? radioCalibrationModel.calibrationStep : 0
    property string statusMessage: radioCalibrationModel ? radioCalibrationModel.statusMessage : "Connect drone to begin radio calibration"
    property int calibrationProgress: radioCalibrationModel ? radioCalibrationModel.calibrationProgress : 0
    
    // Listen for connection changes from DroneModel
    Connections {
        target: droneModel
        function onIsConnectedChanged() {
            window.isConnected = droneModel.isConnected;
        }
    }
    
    // Listen for calibration updates from RadioCalibrationModel
    Connections {
        target: radioCalibrationModel
        function onRadioChannelsChanged() {
            // Update channel info from backend
            window.channelInfo = radioCalibrationModel.getChannelInfo();
        }
    }
    
    // Light background
    Rectangle {
        anchors.fill: parent
        color: "#f5f5f5"
    }
    
    // Calibration Summary Dialog
    Dialog {
        id: calibrationSummaryDialog
        title: "Calibration Summary"
        anchors.centerIn: parent
        width: 600
        height: 400
        modal: true
        
        background: Rectangle {
            radius: 15
            color: "#ffffff"
            border.color: "#4CAF50"
            border.width: 2
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15
            
            Text {
                text: "Radio Calibration Complete"
                color: "#333333"
                font.pixelSize: 16
                font.bold: true
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Rectangle {
                width: parent.width
                height: 250
                color: "#f9f9f9"
                border.color: "#cccccc"
                border.width: 1
                radius: 5
                
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 10
                    
                    Column {
                        spacing: 8
                        width: parent.parent.width - 20
                        
                        // Header row
                        Row {
                            spacing: 10
                            width: parent.width
                            
                            Text { text: "Channel"; color: "#333333"; font.pixelSize: 12; font.bold: true; width: 120 }
                            Text { text: "Min"; color: "#333333"; font.pixelSize: 12; font.bold: true; width: 60 }
                            Text { text: "Max"; color: "#333333"; font.pixelSize: 12; font.bold: true; width: 60 }
                            Text { text: "Trim"; color: "#333333"; font.pixelSize: 12; font.bold: true; width: 60 }
                            Text { text: "Range"; color: "#333333"; font.pixelSize: 12; font.bold: true; width: 60 }
                        }
                        
                        Rectangle {
                            width: parent.width
                            height: 1
                            color: "#cccccc"
                        }
                        
                        // Channel data rows (first 8 channels)
                        Repeater {
                            model: Math.min(8, channelInfo.length)
                            
                            Row {
                                spacing: 10
                                width: parent.width
                                
                                property var channel: channelInfo[index]
                                property int rangeValue: channel ? (channel.max - channel.min) : 0
                                property color rangeColor: rangeValue < 200 ? "#ff4444" : rangeValue < 400 ? "#ffaa00" : "#00ff88"
                                
                                Text { 
                                    text: channel ? channel.name : ("Channel " + (index + 1))
                                    color: "#333333"
                                    font.pixelSize: 11
                                    width: 120
                                }
                                Text { 
                                    text: channel ? channel.min.toString() : "0"
                                    color: "#333333"
                                    font.pixelSize: 11
                                    width: 60
                                }
                                Text { 
                                    text: channel ? channel.max.toString() : "0"
                                    color: "#333333"
                                    font.pixelSize: 11
                                    width: 60
                                }
                                Text { 
                                    text: channel ? channel.trim.toString() : "0"
                                    color: "#333333"
                                    font.pixelSize: 11
                                    width: 60
                                }
                                Text { 
                                    text: rangeValue + "us"
                                    color: rangeColor
                                    font.pixelSize: 11
                                    font.bold: true
                                    width: 60
                                }
                            }
                        }
                    }
                }
            }
            
            Text {
                text: "Green: Good range (>400us) | Yellow: Acceptable (200-400us) | Red: Poor range (<200us)"
                color: "#666666"
                font.pixelSize: 10
                wrapMode: Text.WordWrap
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
            }
            
            Button {
                text: "OK"
                anchors.horizontalCenter: parent.horizontalCenter
                
                onClicked: {
                    calibrationSummaryDialog.close();
                    if (radioCalibrationModel) {
                        radioCalibrationModel.saveCalibration();
                    }
                }
                
                background: Rectangle {
                    radius: 10
                    color: "#4CAF50"
                    border.color: "#66BB6A"
                    border.width: 1
                }
                
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
    

    
    // Main container
    Item {
        anchors.fill: parent
        anchors.margins: 20
        
        Row {
            anchors.fill: parent
            spacing: 20
            
            // Left side - Primary channels as vertical bars (using backend data)
            Item {
                width: 300
                height: parent.height
                
                Column {
                    anchors.fill: parent
                    spacing: 20
                    
                    // Primary channels (Roll, Pitch, Throttle, Yaw) as vertical bars
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 20
                        
                        Repeater {
                            model: 4 // First 4 channels from backend
                            
                            Item {
                                width: 60
                                height: 300
                                
                                property var channelData: index < channelInfo.length ? channelInfo[index] : null
                                
                                // Channel name at top (from backend)
                                Text {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: channelData ? channelData.name.split(' ')[0] : ("Ch" + (index + 1))
                                    color: "#333333"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                
                                // Vertical bar background
                                Rectangle {
                                    id: channelBarBg
                                    anchors.top: parent.top
                                    anchors.topMargin: 25
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 40
                                    height: 250
                                    color: "#e0e0e0"
                                    border.color: "#cccccc"
                                    border.width: 1
                                    
                                    // Min/max range indicators (red lines)
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 2
                                        color: "#ff0000"
                                        y: parent.height - ((channelData ? channelData.min : 1000) - 1000) / 1000 * parent.height
                                        visible: calibrationActive && channelData && channelData.min > 1000
                                    }
                                    
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 2
                                        color: "#ff0000"
                                        y: parent.height - ((channelData ? channelData.max : 2000) - 1000) / 1000 * parent.height
                                        visible: calibrationActive && channelData && channelData.max < 2000
                                    }
                                    
                                    // Channel value fill (green) - using backend data
                                    Rectangle {
                                        anchors.bottom: parent.bottom
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: ((channelData ? channelData.current : 1500) - 1000) / 1000 * parent.height
                                        color: "#90EE90"
                                        
                                        Behavior on height {
                                            NumberAnimation { duration: 100 }
                                        }
                                    }
                                }
                                
                                // Value display at bottom (from backend)
                                Text {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: channelData ? Math.round(channelData.current) : "0"
                                    color: "#333333"
                                    font.pixelSize: 11
                                    font.bold: true
                                }
                            }
                        }
                    }
                    
                    // Horizontal bar for throttle (using backend throttle data - Channel 3)
                    Item {
                        width: parent.width
                        height: 60
                        
                        property var throttleData: channelInfo.length > 2 ? channelInfo[2] : null // Channel 3 (index 2)
                        
                        Text {
                            id: throttleLabel
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: throttleData ? throttleData.name : "Throttle (Ch3)"
                            color: "#333333"
                            font.pixelSize: 12
                            font.bold: true
                            width: 100
                        }
                        
                        Rectangle {
                            id: throttleBarBg
                            anchors.left: throttleLabel.right
                            anchors.leftMargin: 10
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            height: 25
                            color: "#e0e0e0"
                            border.color: "#cccccc"
                            border.width: 1
                            
                            // Min/max indicators (from backend throttle data)
                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 2
                                color: "#ff0000"
                                x: ((throttleData ? throttleData.min : 1000) - 1000) / 1000 * parent.width
                                visible: calibrationActive && throttleData && throttleData.min > 1000
                            }
                            
                            Rectangle {
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 2
                                color: "#ff0000"
                                x: ((throttleData ? throttleData.max : 2000) - 1000) / 1000 * parent.width
                                visible: calibrationActive && throttleData && throttleData.max < 2000
                            }
                            
                            // Value fill (using backend throttle data)
                            Rectangle {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: ((throttleData ? throttleData.current : 1000) - 1000) / 1000 * parent.width
                                color: "#90EE90"
                                
                                Behavior on width {
                                    NumberAnimation { duration: 100 }
                                }
                            }
                            
                            // Value text (from backend throttle data)
                            Text {
                                anchors.centerIn: parent
                                text: throttleData ? Math.round(throttleData.current) : "1000"
                                color: "#000000"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }
                    }
                }
            }
            
            // Right side - Additional channels and controls
            Item {
                width: 600
                height: parent.height
                
                Column {
                    anchors.fill: parent
                    spacing: 15
                    
                    // Radio channels grid for channels 5-12 (using backend data)
                    GridLayout {
                        columns: 2
                        columnSpacing: 15
                        rowSpacing: 8
                        width: parent.width
                        
                        Repeater {
                            id: radioChannelsRepeater
                            model: channelInfo.slice(4, 12) // Channels 5-12 from backend
                            
                            Row {
                                spacing: 10
                                
                                Text {
                                    text: "Radio " + (index + 5)
                                    color: "#333333"
                                    font.pixelSize: 11
                                    font.bold: true
                                    width: 60
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                
                                Rectangle {
                                    width: 200
                                    height: 20
                                    color: modelData.active ? "#90EE90" : "#e0e0e0"
                                    border.color: "#cccccc"
                                    border.width: 1
                                    
                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: modelData.active ? ((modelData.current - 1000) / 1000) * parent.width : 0
                                        color: "#4CAF50"
                                        
                                        Behavior on width {
                                            NumberAnimation { duration: 100 }
                                        }
                                    }
                                    
                                    Text {
                                        anchors.centerIn: parent
                                        text: Math.round(modelData.current)
                                        color: modelData.active ? "#000000" : "#333333"
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }
                                
                                Text {
                                    text: "0"
                                    color: "#333333"
                                    font.pixelSize: 11
                                    width: 20
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                    }
                    
                    // Click When Done button
                    Button {
                        id: clickWhenDoneBtn
                        text: "Click when Done"
                        width: 200
                        height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        enabled: isConnected && calibrationActive
                        visible: calibrationActive
                        
                        onClicked: {
                            // Show calibration summary directly
                            if (radioCalibrationModel) {
                                calibrationSummaryDialog.open();
                            }
                        }
                        
                        background: Rectangle {
                            color: "#90EE90"
                            border.color: "#4CAF50"
                            border.width: 2
                            radius: 5
                        }
                        
                        contentItem: Text {
                            text: clickWhenDoneBtn.text
                            color: "#000000"
                            font.bold: true
                            font.pixelSize: 14
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                    
                    // Spectrum Bind section
                    Rectangle {
                        width: 300
                        height: 80
                        anchors.horizontalCenter: parent.horizontalCenter
                        color: "#f0f0f0"
                        border.color: "#cccccc"
                        border.width: 1
                        radius: 5
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: 10
                            
                            Text {
                                text: "Spectrum Bind"
                                color: "#333333"
                                font.pixelSize: 12
                                font.bold: true
                                anchors.horizontalCenter: parent.horizontalCenter
                            }
                            
                            Row {
                                spacing: 10
                                anchors.horizontalCenter: parent.horizontalCenter
                                
                                Repeater {
                                    model: ["DSM2", "DSMX", "DSME"]
                                    
                                    Button {
                                        text: "Bind " + modelData
                                        width: 80
                                        height: 25
                                        enabled: isConnected && !calibrationActive
                                        
                                        onClicked: {
                                            console.log("Bind " + modelData + " clicked");
                                            if (radioCalibrationModel) {
                                                radioCalibrationModel.bindSpectrum(modelData);
                                            }
                                        }
                                        
                                        background: Rectangle {
                                            color: parent.enabled ? "#4CAF50" : "#cccccc"
                                            border.color: "#66BB6A"
                                            border.width: 1
                                            radius: 3
                                        }
                                        
                                        contentItem: Text {
                                            text: parent.text
                                            color: parent.enabled ? "white" : "#666666"
                                            font.pixelSize: 9
                                            font.bold: true
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Control button at bottom - Only Start Calibration button
                    Button {
                        text: "Start Calibration"
                        width: 150
                        height: 35
                        enabled: isConnected && !calibrationActive
                        anchors.horizontalCenter: parent.horizontalCenter
                        
                        onClicked: {
                            // Start calibration directly without dialog
                            if (radioCalibrationModel) {
                                radioCalibrationModel.startCalibration();
                            }
                        }
                        
                        background: Rectangle {
                            color: parent.enabled ? "#4CAF50" : "#cccccc"
                            border.color: "#66BB6A"
                            border.width: 2
                            radius: 5
                        }
                        
                        contentItem: Text {
                            text: parent.text
                            color: parent.enabled ? "white" : "#666666"
                            font.bold: true
                            font.pixelSize: 12
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }
        }
    }
    
    // Handle calibration step changes - removed step dialogs
    // No automatic dialogs, summary only shows when "Click When Done" is pressed
}