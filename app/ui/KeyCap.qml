// Losse toets voor het schermtoetsenbord.
// Bewust een eigen bestand (geen inline component) zodat de scope simpel blijft.
import QtQuick

Rectangle {
    id: cap
    property string letter: ""
    property color fillColor: "#ffffff"
    property color textColor: "#20201c"
    property int fontSize: 40

    signal activated(string letter)

    radius: 12
    color: fillColor
    border.width: 2
    border.color: "#b9b2a4"

    Text {
        anchors.centerIn: parent
        text: cap.letter
        font.pixelSize: cap.fontSize
        font.bold: true
        color: cap.textColor
    }

    MouseArea {
        anchors.fill: parent
        onClicked: cap.activated(cap.letter)
    }
}
