// HudWidget.qml
import QtQuick 2.15
import QtQuick.Shapes 1.15

Item {
    id: hud
    width: 400
    height: 400

    PrimaryFlightDisplayQML {
        id: pfd
        anchors.fill: parent

        Component.onCompleted: {
            activeUasSet()
        }
    }
}