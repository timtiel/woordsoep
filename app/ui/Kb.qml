// Schermtoetsenbord (QWERTY) voor de spellmodi met typen.
import QtQuick

Item {
    id: kb

    // letter -> 2 (goed), 1 (aanwezig), 0 (afwezig); leeg = nog geen info
    property var keyStates: ({})
    property int gap: 6
    property int keyW: Math.floor((width - 24 - 9 * gap) / 10)
    property int keyH: Math.floor(keyW * 1.25)

    signal letterPressed(string letter)
    signal enterPressed()
    signal erasePressed()

    function keyColor(ch) {
        var m = keyStates[ch];
        if (m === 2) return "#4F8A3D";
        if (m === 1) return "#C9A227";
        if (m === 0) return "#8A8578";
        return "#ffffff";
    }

    function keyTextColor(ch) {
        var m = keyStates[ch];
        if (m === 0 || m === 1 || m === 2) return "#ffffff";
        return "#20201c";
    }

    Column {
        id: rows
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        spacing: 10

        Repeater {
            model: ["QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM"]

            delegate: Row {
                property string rowLetters: modelData
                property int rowIndex: index
                spacing: kb.gap

                Item {
                    width: rowIndex === 1 ? Math.floor((kb.keyW + kb.gap) / 2)
                         : (rowIndex === 2 ? Math.floor((kb.keyW + kb.gap) * 1.5) : 0)
                    height: 1
                }

                Repeater {
                    model: rowLetters.length

                    delegate: KeyCap {
                        width: kb.keyW
                        height: kb.keyH
                        letter: rowLetters.charAt(index)
                        fontSize: Math.floor(kb.keyH * 0.42)
                        fillColor: kb.keyColor(letter)
                        textColor: kb.keyTextColor(letter)
                        onActivated: (letter) => kb.letterPressed(letter)
                    }
                }
            }
        }

        Row {
            spacing: kb.gap * 2

            Item {
                width: Math.floor(kb.keyW * 2 + kb.gap * 1.5)
                height: 1
            }

            Rectangle {
                width: kb.keyW * 3 + kb.gap * 2
                height: kb.keyH
                radius: 12
                color: "#ffffff"
                border.width: 2
                border.color: "#b9b2a4"

                Text {
                    anchors.centerIn: parent
                    text: "WIS"
                    font.pixelSize: Math.floor(kb.keyH * 0.34)
                    font.bold: true
                    color: "#20201c"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: kb.erasePressed()
                }
            }

            Rectangle {
                width: kb.keyW * 3 + kb.gap * 2
                height: kb.keyH
                radius: 12
                color: "#20201c"
                border.width: 2
                border.color: "#20201c"

                Text {
                    anchors.centerIn: parent
                    text: "OK"
                    font.pixelSize: Math.floor(kb.keyH * 0.34)
                    font.bold: true
                    color: "#f6f3ec"
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: kb.enterPressed()
                }
            }
        }
    }
}
