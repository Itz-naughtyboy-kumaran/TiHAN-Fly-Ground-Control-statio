//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.

//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.

//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//    (c) 2014 Author: Bill Bonney <billbonney@communistech.com>
//

import QtQuick 2.15

Rectangle {
    // Property Defintions
    id:root

    property bool enableBackgroundVideo: false
    property string statusMessage: ""
    property bool showStatusMessage: false
    property color statusMessageColor: statusMessageIndicator.messageColor

    function activeUasSet() {
        rollPitchIndicator.rollAngle = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.roll: 0.0)
        rollPitchIndicator.pitchAngle = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.pitch: 0)
        pitchIndicator.rollAngle = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.roll: 0)
        pitchIndicator.pitchAngle = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.pitch: 0)
        speedIndicator.groundspeed = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.groundspeed: 0)
        informationIndicator.groundSpeed = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.groundspeed: 0)
        informationIndicator.airSpeed = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.airspeed: 0 )
        compassIndicator.heading = Qt.binding(() => droneModel.isConnected?(droneModel.telemetry.yaw < 0 ? droneModel.telemetry.yaw + 360 : droneModel.telemetry.yaw): 0)
        speedIndicator.airspeed = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.airspeed: 0)
        altIndicator.alt = Qt.binding(() => droneModel.isConnected? droneModel.telemetry.rel_alt: 0)

       
    }
    
    function activeUasUnset() {
        console.log("PFD-QML: Active UAS is now unset");
        //Code to make display show a lack of connection here.
    }

    onShowStatusMessageChanged: {
        statusMessageTimer.start()
    }

    Timer{
        id: statusMessageTimer
        interval: 5000;
        repeat: false;
        onTriggered: showStatusMessage = false
    }

    RollPitchIndicator {
        id: rollPitchIndicator

        rollAngle: 0
        pitchAngle: 0
        enableBackgroundVideo: parent.enableBackgroundVideo
    }

    PitchIndicator {
        id: pitchIndicator
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        opacity: 0.6

        pitchAngle: 0
        rollAngle: 0
    }

    AltitudeIndicator {
        id: altIndicator
        anchors.right: parent.right
        width: 40
        alt: 0
    }

    SpeedIndicator {
        id: speedIndicator
        anchors.left: parent.left
        width: 40
        airspeed: 0
        groundspeed: 0
    }

    // Compass Indicator - Now enabled
    CompassIndicator {
        id: compassIndicator
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 10
        visible: false
        heading: 0
        scale: 0.6  // Make it smaller to fit better in the HUD
    }

    StatusMessageIndicator  {
        id: statusMessageIndicator
        anchors.fill: parent
        message: statusMessage
        messageColor: statusMessageColor;
        visible: showStatusMessage
    }

    InformationOverlayIndicator{
        id: informationIndicator
        anchors.fill: parent
        airSpeed: 0
        groundSpeed: 0
    }
}