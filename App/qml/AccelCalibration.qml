import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15


ApplicationWindow {
    id: root
    width: 420
    height: 360
    visible: true
    title: "Accelerometer Calibration"
    flags: Qt.Dialog
    modality: Qt.ApplicationModal
    color: "#121212"

    property int currentStep: 0
    property int totalSteps: 6
    property bool running: false
    property var calibrationModel

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 14

        // ---------------- Title ----------------
        Text {
            text: "Accelerometer Calibration"
            font.pixelSize: 20
            color: "white"
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            height: 1
            color: "#333"
            Layout.fillWidth: true
        }

        // ---------------- Instruction ----------------
        Text {
            id: instructionText
            text: "Press START to begin calibration."
            wrapMode: Text.WordWrap
            font.pixelSize: 14
            color: "#dddddd"
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        // ---------------- Progress ----------------
        ColumnLayout {
            Layout.fillWidth: true

            ProgressBar {
                value: currentStep
                from: 0
                to: totalSteps
                Layout.fillWidth: true
            }

            Text {
                text: "Step " + currentStep + " / " + totalSteps
                color: "#aaaaaa"
                font.pixelSize: 12
                Layout.alignment: Qt.AlignHCenter
            }
        }

        // ---------------- Buttons ----------------
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "Start"
                enabled: !running
                Layout.fillWidth: true
                onClicked: {
                    calibrationModel.start(1, 1)
                    running = true
                    currentStep = 0
                }
            }

            Button {
                text: "Next"
                enabled: running
                Layout.fillWidth: true
                onClicked: {
                    calibrationModel.user_next()
                }
            }

            
        }
    }

    // --------------------------------------------------
    // Python → QML signal bindings
    // --------------------------------------------------

  Connections {
    target: calibrationModel
    ignoreUnknownSignals: true

    function onInstructionUpdated(text) {
        instructionText.text = text
    }

    function onProgressUpdated(step, total) {
        currentStep = step
        totalSteps = total
    }

    function onFinished(success) {
        running = false
        instructionText.text = success
            ? "Calibration completed successfully ✔"
            : "Calibration failed ✖"
    }

    function onError(msg) {
        running = false
        instructionText.text = "Error: " + msg
    }
}
}
