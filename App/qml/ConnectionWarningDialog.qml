import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: root
    
    property string title: "Warning"
    property string message: "Please check your connection."
    
    width: 400
    height: 200
    modal: true
    
    background: Rectangle {
        color: "#2d2d30"
        border.color: "#666666"
        border.width: 1
        radius: 8
    }
    
    header: Rectangle {
        width: parent.width
        height: 50
        color: "#404040"
        radius: 8
        
        Text {
            anchors.centerIn: parent
            text: root.title
            font.pixelSize: 16
            font.bold: true
            color: "#ffffff"
        }
    }
    
    contentItem: Rectangle {
        color: "#2d2d30"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 20
            
            Text {
                Layout.fillWidth: true
                text: root.message
                font.pixelSize: 12
                color: "#ffffff"
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
            
            Button {
                Layout.alignment: Qt.AlignHCenter
                text: "OK"
                width: 80
                height: 35
                
                onClicked: root.close()
                
                background: Rectangle {
                    color: parent.pressed ? "#0056b3" : "#0066cc"
                    border.color: "#0066cc"
                    border.width: 1
                    radius: 4
                }
                
                contentItem: Text {
                    text: parent.text
                    font.pixelSize: 12
                    font.bold: true
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }
}