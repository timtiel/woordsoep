// Woordbouwer - maak zoveel mogelijk woorden uit de gegeven letters.
import QtQuick
import "WoordbouwerPuzzles.js" as BP
import "Store.js" as ST

Item {
    id: game
    anchors.fill: parent

    property int puzzleIndex: 0
    property var found: []
    property string current: ""
    property string status: "playing"
    property string message: ""

    Timer {
        id: msgTimer
        interval: 1600
        onTriggered: game.message = ""
    }

    function puzzle() {
        return BP.BOUWER_PUZZLES[puzzleIndex];
    }

    function totalWords() {
        return puzzle().words.length;
    }

    function maskText(len) {
        var s = "";
        for (var i = 0; i < len; i++) s += (i > 0 ? " " : "") + "\u00b7";
        return s;
    }

    function isFound(w) {
        return found.indexOf(w) >= 0;
    }

    function newPuzzle() {
        var n = BP.BOUWER_PUZZLES.length;
        var idx = Math.floor(Math.random() * n);
        if (n > 1 && idx === puzzleIndex) idx = (idx + 1) % n;
        puzzleIndex = idx;
        found = [];
        current = "";
        status = "playing";
        message = "";
        saveState();
    }

    function addLetter(l) {
        if (status !== "playing") return;
        if (current.length >= 8) return;
        current = current + l;
    }

    function eraseLetter() {
        if (status !== "playing") return;
        if (current.length > 0) {
            current = current.substring(0, current.length - 1);
        }
    }

    function submitWord() {
        if (status !== "playing") return;
        if (current.length < 4) {
            showMessage("Woorden van minstens 4 letters");
            return;
        }
        var w = current;
        current = "";
        if (isFound(w)) {
            showMessage("Al gevonden!");
            return;
        }
        if (puzzle().words.indexOf(w) < 0) {
            showMessage("Helaas, niet in het spel!");
            return;
        }
        var f = found.slice();
        f.push(w);
        found = f;
        if (found.length >= totalWords()) {
            status = "won";
            ST.updateStats(function(s) {
                if (!s.bouwer) s.bouwer = {};
                s.bouwer.won = (s.bouwer.won || 0) + 1;
            });
        } else {
            showMessage("Gevonden: " + w);
        }
        saveState();
    }

    function showMessage(t) {
        message = t;
        msgTimer.restart();
    }

    function saveState() {
        ST.write("bouwer", JSON.stringify({
            v: 1,
            puzzleIndex: puzzleIndex,
            found: found,
            status: status
        }));
    }

    function applyState(s) {
        if (!s || typeof s.puzzleIndex !== "number") return false;
        if (s.puzzleIndex < 0 || s.puzzleIndex >= BP.BOUWER_PUZZLES.length) return false;
        puzzleIndex = s.puzzleIndex;
        var f = s.found ? s.found : [];
        var valid = [];
        for (var i = 0; i < f.length; i++) {
            if (puzzle().words.indexOf(f[i]) >= 0 && valid.indexOf(f[i]) < 0) valid.push(f[i]);
        }
        found = valid;
        current = "";
        status = found.length >= totalWords() ? "won" : "playing";
        message = "";
        return true;
    }

    function tryLoad() {
        var text = ST.read("bouwer");
        if (text === "") return false;
        var s = null;
        try {
            s = JSON.parse(text);
        } catch (e) {
            s = null;
        }
        return applyState(s);
    }

    Component.onCompleted: {
        ST.init(game);
        if (!tryLoad()) {
            newPuzzle();
        }
    }

    // ---------------- statusbalk ----------------
    Item {
        id: topArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 86

        Text {
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: game.message === ""
            text: game.found.length + " / " + game.totalWords() + " woorden gevonden"
            font.pixelSize: 28
            color: "#6b655a"
        }

        Text {
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            visible: game.message !== ""
            text: game.message
            font.pixelSize: 28
            font.bold: true
            color: game.message.indexOf("Gevonden") === 0 ? "#2E5B25" : "#B34700"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            width: 150
            height: 62
            radius: 14
            color: nieuwMouse.pressed ? "#e9e4d8" : "#ffffff"
            border.width: 2
            border.color: "#c9c2b4"

            Text {
                anchors.centerIn: parent
                text: "Nieuw"
                font.pixelSize: 28
                color: "#20201c"
            }
            MouseArea {
                id: nieuwMouse
                anchors.fill: parent
                onClicked: game.newPuzzle()
            }
        }
    }

    // ---------------- letters ----------------
    Row {
        id: lettersRow
        anchors.top: topArea.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Repeater {
            model: game.puzzle().letters.length

            delegate: Rectangle {
                width: 96
                height: 96
                radius: 16
                color: "#20201c"

                Text {
                    anchors.centerIn: parent
                    text: game.puzzle().letters.charAt(index)
                    font.pixelSize: 46
                    font.bold: true
                    color: "#f6f3ec"
                }
            }
        }
    }

    // ---------------- te vinden woorden ----------------
    Item {
        id: listArea
        anchors.top: lettersRow.bottom
        anchors.topMargin: 14
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: inputRow.top
        anchors.bottomMargin: 10

        Grid {
            id: wordGrid
            columns: 3
            spacing: 8
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top

            Repeater {
                model: game.puzzle().words.length

                delegate: Row {
                    property int wordIndex: index
                    width: 296
                    height: 44
                    spacing: 10

                    Item {
                        width: 26
                        height: 44

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 6
                            anchors.centerIn: parent
                            color: game.isFound(game.puzzle().words[wordIndex]) ? "#4F8A3D" : "#ffffff"
                            border.width: 2
                            border.color: "#b9b2a4"
                        }
                    }

                    Text {
                        height: 44
                        verticalAlignment: Text.AlignVCenter
                        text: game.isFound(game.puzzle().words[wordIndex])
                              ? game.puzzle().words[wordIndex]
                              : game.maskText(game.puzzle().words[wordIndex].length)
                        font.pixelSize: 28
                        font.bold: game.isFound(game.puzzle().words[wordIndex])
                        color: game.isFound(game.puzzle().words[wordIndex]) ? "#2E5B25" : "#9a9384"
                    }
                }
            }
        }
    }

    // ---------------- invoer ----------------
    Item {
        id: inputRow
        anchors.bottom: kb.top
        anchors.bottomMargin: 10
        anchors.left: parent.left
        anchors.right: parent.right
        height: 84

        Rectangle {
            width: 460
            height: 84
            radius: 16
            anchors.centerIn: parent
            color: "#ffffff"
            border.width: 2
            border.color: "#c9c2b4"

            Text {
                anchors.centerIn: parent
                text: game.current + (game.status === "playing" ? "_" : "")
                font.pixelSize: 42
                font.bold: true
                color: "#20201c"
            }
        }
    }

    // ---------------- toetsenbord ----------------
    Kb {
        id: kb
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 520
        keyStates: ({})
        onLetterPressed: (letter) => game.addLetter(letter)
        onEnterPressed: game.submitWord()
        onErasePressed: game.eraseLetter()
    }

    // ---------------- gewonnen ----------------
    Rectangle {
        id: winOverlay
        anchors.fill: parent
        z: 50
        visible: game.status === "won"
        color: "#ddf6f3ec"

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            width: 640
            height: 380
            radius: 28
            anchors.centerIn: parent
            color: "#ffffff"
            border.width: 3
            border.color: "#4F8A3D"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    width: 560
                    horizontalAlignment: Text.AlignHCenter
                    text: "Gefeliciteerd!"
                    font.pixelSize: 56
                    font.bold: true
                    color: "#2E5B25"
                }

                Text {
                    width: 560
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "Je vond alle " + game.totalWords() + " woorden."
                    font.pixelSize: 30
                    color: "#40403a"
                }

                Item {
                    width: 560
                    height: 84

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 340
                        height: 84
                        radius: 18
                        color: nextMouse.pressed ? "#e9e4d8" : "#ffffff"
                        border.width: 2
                        border.color: "#c9c2b4"

                        Text {
                            anchors.centerIn: parent
                            text: "Nieuwe puzzel"
                            font.pixelSize: 32
                            color: "#20201c"
                        }
                        MouseArea {
                            id: nextMouse
                            anchors.fill: parent
                            onClicked: game.newPuzzle()
                        }
                    }
                }
            }
        }
    }
}
