// Draait de app gewoon in een venster op de pc (testen zonder tablet).
// Het venster is even groot als het scherm van de Paper Pro Move (950 x 1570),
// maar krimpt mee op kleinere schermen zodat alles zichtbaar blijft.
import QtQuick
import QtQuick.Window
import "../../app/ui"

Window {
    id: testWindow
    width: 950
    height: Math.min(1570, Screen.height - 100)
    visible: true
    color: "#f6f3ec"
    title: "Woordsoep - testbed (Paper Pro Move)"

    Main {
        id: app
        anchors.fill: parent
        onClose: testWindow.close()
    }

    // Handig op de pc: Escape sluit het venster.
    Shortcut {
        sequence: "Escape"
        onActivated: testWindow.close()
    }
}
