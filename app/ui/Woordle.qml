// Woordle - raad het verborgen vijfletterwoord in zes beurten.
import QtQuick
import "WoordleLogic.js" as WL
import "Store.js" as ST

Item {
    id: game
    anchors.fill: parent

    property string target: ""
    property var guesses: []
    property string current: ""
    property var keyStates: ({})
    property string status: "playing"
    property string message: ""

    function saveState() {
        ST.write("woordle", JSON.stringify({
            v: 1,
            target: target,
            guesses: guesses,
            keyStates: keyStates,
            status: status
        }));
    }

    function applyState(s) {
        if (!s || typeof s.target !== "string" || s.target.length !== 5) return false;
        target = s.target;
        guesses = s.guesses ? s.guesses : [];
        keyStates = s.keyStates ? s.keyStates : ({});
        status = (s.status === "won" || s.status === "lost") ? s.status : "playing";
        current = "";
        message = "";
        return true;
    }

    function tryLoad() {
        var text = ST.read("woordle");
        if (text === "") return false;
        var s = null;
        try {
            s = JSON.parse(text);
        } catch (e) {
            s = null;
        }
        return applyState(s);
    }

    function newGame() {
        target = WL.pickWord();
        guesses = [];
        current = "";
        keyStates = ({});
        status = "playing";
        message = "";
        saveState();
    }

    function letterAt(row, col) {
        if (row < guesses.length) return guesses[row].word.charAt(col);
        if (row === guesses.length && status === "playing") {
            return col < current.length ? current.charAt(col) : "";
        }
        return "";
    }

    function markAt(row, col) {
        if (row < guesses.length) return guesses[row].marks[col];
        return -1;
    }

    function tileColor(row, col) {
        var m = markAt(row, col);
        if (m === 2) return "#4F8A3D";
        if (m === 1) return "#C9A227";
        if (m === 0) return "#8A8578";
        return "#ffffff";
    }

    function tileTextColor(row, col) {
        return markAt(row, col) >= 0 ? "#ffffff" : "#20201c";
    }

    function addLetter(l) {
        if (status !== "playing") return;
        if (current.length >= 5) return;
        current = current + l;
    }

    function eraseLetter() {
        if (status !== "playing") return;
        if (current.length > 0) {
            current = current.substring(0, current.length - 1);
        }
    }

    function submitGuess() {
        if (status !== "playing") return;
        if (current.length !== 5) {
            showMessage("Woord van 5 letters");
            return;
        }
        var marks = WL.score(target, current);
        var g = guesses.slice();
        g.push({ word: current, marks: marks });
        guesses = g;

        var ks = {};
        for (var l in keyStates) {
            ks[l] = keyStates[l];
        }
        for (var i = 0; i < 5; i++) {
            var ch = current.charAt(i);
            var m = marks[i];
            if (ks[ch] === undefined || m > ks[ch]) {
                ks[ch] = m;
            }
        }
        keyStates = ks;

        if (current === target) {
            status = "won";
            ST.updateStats(function(s) {
                if (!s.woordle) s.woordle = {};
                var w = s.woordle;
                w.played = (w.played || 0) + 1;
                w.won = (w.won || 0) + 1;
                w.streak = (w.streak || 0) + 1;
                if ((w.best || 0) < w.streak) w.best = w.streak;
                if (!w.dist) w.dist = [0, 0, 0, 0, 0, 0];
                var d = guesses.length - 1;
                if (d >= 0 && d < 6) w.dist[d] = (w.dist[d] || 0) + 1;
            });
        } else if (guesses.length >= 6) {
            status = "lost";
            ST.updateStats(function(s) {
                if (!s.woordle) s.woordle = {};
                var w = s.woordle;
                w.played = (w.played || 0) + 1;
                w.streak = 0;
            });
        }
        current = "";
        saveState();
    }

    function showMessage(t) {
        message = t;
        msgTimer.restart();
    }

    Timer {
        id: msgTimer
        interval: 1600
        onTriggered: game.message = ""
    }

    Component.onCompleted: {
        ST.init(game);
        if (!tryLoad()) {
            newGame();
        }
    }

    // ---------------- statusregel ----------------
    Item {
        id: topInfo
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 56

        Text {
            anchors.centerIn: parent
            visible: game.message === ""
            text: game.status === "playing"
                  ? ("Beurt " + Math.min(game.guesses.length + 1, 6) + " van 6")
                  : ""
            font.pixelSize: 28
            color: "#6b655a"
        }

        Text {
            anchors.centerIn: parent
            visible: game.message !== ""
            text: game.message
            font.pixelSize: 30
            font.bold: true
            color: "#B34700"
        }
    }

    // ---------------- lettervakjes ----------------
    Item {
        id: tilesArea
        anchors.top: topInfo.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: kb.top
        anchors.bottomMargin: 8

        property int tile: Math.max(40, Math.floor(Math.min((width - 80) / 5, (height - 100) / 6)))

        Column {
            id: gridCol
            anchors.centerIn: parent
            spacing: 12

            Repeater {
                model: 6

                delegate: Row {
                    property int rowIndex: index
                    spacing: 12

                    Repeater {
                        model: 5

                        delegate: Rectangle {
                            width: tilesArea.tile
                            height: tilesArea.tile
                            radius: 10
                            color: game.tileColor(rowIndex, index)
                            border.width: game.markAt(rowIndex, index) >= 0 ? 0 : 2
                            border.color: (rowIndex === game.guesses.length && game.status === "playing")
                                          ? "#6b655a" : "#c9c2b4"

                            Text {
                                anchors.centerIn: parent
                                text: game.letterAt(rowIndex, index)
                                font.pixelSize: Math.floor(tilesArea.tile * 0.55)
                                font.bold: true
                                color: game.tileTextColor(rowIndex, index)
                            }
                        }
                    }
                }
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
        keyStates: game.keyStates
        onLetterPressed: (letter) => game.addLetter(letter)
        onEnterPressed: game.submitGuess()
        onErasePressed: game.eraseLetter()
    }

    // ---------------- resultaat ----------------
    Rectangle {
        id: resultOverlay
        anchors.fill: parent
        z: 50
        visible: game.status !== "playing"
        color: "#ddf6f3ec"

        MouseArea {
            anchors.fill: parent
        }

        Rectangle {
            width: 620
            height: 420
            radius: 28
            anchors.centerIn: parent
            color: "#ffffff"
            border.width: 3
            border.color: game.status === "won" ? "#4F8A3D" : "#B34700"

            Column {
                anchors.centerIn: parent
                spacing: 18

                Text {
                    width: 540
                    horizontalAlignment: Text.AlignHCenter
                    text: game.status === "won" ? "Gefeliciteerd!" : "Helaas!"
                    font.pixelSize: 54
                    font.bold: true
                    color: game.status === "won" ? "#2E5B25" : "#8C3600"
                }

                Text {
                    width: 540
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: game.status === "won"
                          ? ("Je raadde het woord in " + game.guesses.length
                             + (game.guesses.length === 1 ? " beurt." : " beurten."))
                          : ("Het woord was: " + game.target)
                    font.pixelSize: 32
                    color: "#40403a"
                }

                Item {
                    width: 540
                    height: 86

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 320
                        height: 86
                        radius: 18
                        color: againMouse.pressed ? "#e9e4d8" : "#ffffff"
                        border.width: 2
                        border.color: "#c9c2b4"

                        Text {
                            anchors.centerIn: parent
                            text: "Nieuw woord"
                            font.pixelSize: 32
                            color: "#20201c"
                        }
                        MouseArea {
                            id: againMouse
                            anchors.fill: parent
                            onClicked: game.newGame()
                        }
                    }
                }
            }
        }
    }
}
