import QtQuick 2.15
import QtQuick.Controls 2.15
import QtGraphicalEffects 1.12

ComboBox {
    id: languageSelector
    
    // Add this property to receive the language manager
    property var languageManager
    
    width: 150
    height: 35
    
    // Use the model from your LanguageManager
    model: languageManager ? languageManager.availableLanguages : []
    textRole: "nativeName"
    
    // Set current index based on language manager's current language
    currentIndex: {
        if (languageManager && model) {
            for (var i = 0; i < model.length; i++) {
                if (model[i].code === languageManager.currentLanguage) {
                    return i;
                }
            }
        }
        return 0;
    }
    
    // Handle language changes
    onActivated: function(index) {
        if (languageManager && model && model[index]) {
            languageManager.changeLanguage(model[index].code);
        }
    }
    
    // Custom styling for the ComboBox button
    background: Rectangle {
        radius: 8
        border.color: languageSelector.activeFocus ? "#4CAF50" : "#ddd"
        border.width: 1
        color: languageSelector.pressed ? "#f0f0f0" : "#ffffff"
        
        // Smooth color transitions
        Behavior on border.color {
            ColorAnimation { duration: 200 }
        }
        Behavior on color {
            ColorAnimation { duration: 150 }
        }
    }
    
    // Custom styling for the main text
    contentItem: Text {
        text: languageSelector.displayText
        font.pixelSize: 12
        font.family: "Segoe UI, Noto Sans, Arial Unicode MS, Mangal, Latha, Gautami"
        color: "#333"
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignLeft
        leftPadding: 10
        rightPadding: 30  // Space for the dropdown arrow
        elide: Text.ElideRight
        renderType: Text.NativeRendering
    }
    
    // Custom dropdown indicator arrow
    indicator: Canvas {
        id: canvas
        x: languageSelector.width - width - 10
        y: languageSelector.topPadding + (languageSelector.availableHeight - height) / 2
        width: 12
        height: 8
        contextType: "2d"
        
        Connections {
            target: languageSelector
            function onPressedChanged() { canvas.requestPaint(); }
        }
        
        onPaint: {
            context.reset();
            context.moveTo(0, 0);
            context.lineTo(width, 0);
            context.lineTo(width / 2, height);
            context.closePath();
            context.fillStyle = languageSelector.pressed ? "#4CAF50" : "#666";
            context.fill();
        }
    }
    
    // Custom popup styling
    popup: Popup {
        y: languageSelector.height + 2
        width: languageSelector.width
        padding: 4
        
        background: Rectangle {
            color: "#ffffff"
            border.color: "#ddd"
            border.width: 1
            radius: 8
            
            // Drop shadow effect
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 8
                samples: 16
                color: "#40000000"
            }
        }
        
        contentItem: ListView {
            implicitHeight: contentHeight
            model: languageSelector.popup.visible ? languageSelector.delegateModel : null
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            
            delegate: ItemDelegate {
                width: languageSelector.width
                height: 32
                
                background: Rectangle {
                    color: {
                        // Green background with white text on hover/press
                        if (parent.hovered || parent.pressed) {
                            return "#4CAF50"  // Green background
                        }
                        // Light green for currently selected item
                        else if (languageSelector.currentIndex === index) {
                            return "#E8F5E9"  // Light green background
                        }
                        // Default white background
                        else {
                            return "#ffffff"
                        }
                    }
                    radius: 4
                    
                    // Smooth color transitions
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
                
                contentItem: Text {
                    text: model ? model.nativeName : ""
                    font.pixelSize: 12
                    font.family: "Segoe UI, Noto Sans, Arial Unicode MS, Mangal, Latha, Gautami"
                    renderType: Text.NativeRendering
                    
                    color: {
                        // White text on hover/press for good contrast with green background
                        if (parent.hovered || parent.pressed) {
                            return "#ffffff"
                        }
                        // Green text for selected item
                        else if (languageSelector.currentIndex === index) {
                            return "#2E7D32"  // Dark green text
                        }
                        // Default black text
                        else {
                            return "#333333"
                        }
                    }
                    
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignLeft
                    leftPadding: 10
                    elide: Text.ElideRight
                    
                    // Smooth text color transitions
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
                
                // Subtle scale effect on interaction
                scale: (hovered || pressed) ? 1.02 : 1.0
                Behavior on scale {
                    NumberAnimation { duration: 150 }
                }
            }
        }
    }
}