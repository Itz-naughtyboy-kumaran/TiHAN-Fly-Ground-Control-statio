import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: detailItem
    
    property string icon: ""
    property string label: ""
    property string value: ""
    
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
            text: detailItem.icon
            font.pixelSize: 14
        }
        
        Column {
            Layout.fillWidth: true
            spacing: 0
            
            Text {
                text: detailItem.label
                font.pixelSize: 9
                color: "#6c757d"
                font.family: "Consolas"
            }
            
            Text {
                text: detailItem.value
                font.pixelSize: 11
                color: "#495057"
                font.family: "Consolas"
                font.bold: true
            }
        }
    }
}