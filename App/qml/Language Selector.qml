// LanguageSelector.qml
import QtQuick 2.15
import QtQuick.Controls 2.15

ComboBox {
    id: languageSelector
    width: 120
    height: 35
    
    // Reference to language manager
    property var languageManager: null
    
    model: languageManager ? languageManager.availableLanguages : []
    textRole: "nativeName"
    
    // Set current index based on language manager's current language
    currentIndex: {
        if (languageManager) {
            for (var i = 0; i < model.length; i++) {
                if (model[i].code === languageManager.currentLanguage) {
                    return i;
                }
            }
        }
        return 0;
    }
    
    onActivated: {
        if (languageManager && model[index]) {
            languageManager.changeLanguage(model[index].code);
        }
    }
    
    background: Rectangle {
        color: "#1a1a1a"
        border.color: languageSelector.hovered ? "#00e5ff" : "#37474f"
        border.width: 1
        radius: 8
        
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#252525" }
            GradientStop { position: 1.0; color: "#1a1a1a" }
        }
        
        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
    }
    
    contentItem: Text {
        text: languageSelector.displayText
        font.pixelSize: 11
        font.family: "Segoe UI"
        color: "#ffffff"
        verticalAlignment: Text.AlignVCenter
        leftPadding: 10
    }
    
    popup: Popup {
        y: languageSelector.height + 2
        width: languageSelector.width
        height: contentItem.implicitHeight
        padding: 2
        
        background: Rectangle {
            color: "#1a1a1a"
            border.color: "#37474f"
            border.width: 1
            radius: 8
            
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#252525" }
                GradientStop { position: 1.0; color: "#1a1a1a" }
            }
        }
        
        contentItem: ListView {
            implicitHeight: contentHeight
            model: languageSelector.popup.visible ? languageSelector.delegateModel : null
            
            delegate: ItemDelegate {
                width: languageSelector.width - 4
                height: 30
                
                background: Rectangle {
                    color: parent.hovered ? "#00e5ff" : "transparent"
                    radius: 4
                    opacity: parent.hovered ? 0.3 : 1  // Increased opacity for better visibility
                    
                    Behavior on color {
                        ColorAnimation { duration: 150 }
                    }
                    
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }
                }
                
                contentItem: Row {
                    spacing: 8
                    leftPadding: 10
                    
                    Text {
                        text: modelData.nativeName
                        // Changed to dark color when hovered for better contrast
                        color: parent.parent.hovered ? "#000000" : "#ffffff"
                        font.pixelSize: 11
                        font.family: "Segoe UI"
                        font.weight: parent.parent.hovered ? Font.DemiBold : Font.Normal
                        anchors.verticalCenter: parent.verticalCenter
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                        
                        Behavior on font.weight {
                            NumberAnimation { duration: 150 }
                        }
                    }
                    
                    Text {
                        text: "(" + modelData.name + ")"
                        // Keep lighter gray text that works with both states
                        color: parent.parent.hovered ? "#cccccc" : "#888888"
                        font.pixelSize: 9
                        font.family: "Segoe UI"
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0.8
                        
                        Behavior on color {
                            ColorAnimation { duration: 150 }
                        }
                    }
                }
            }
        }
    }
}