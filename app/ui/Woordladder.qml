// Woordladder - verander elke stap één letter en bereik het doelwoord.
import QtQuick
import "WoordladderPuzzles.js" as LP
import "Store.js" as ST

Item {
    id: game
    anchors.fill: parent

    property int puzzleIndex: 0
    property string fromWord: ""
    property string toWord: ""
    property int wordLen: 4
    property var path: []
    property string current: ""
    property string status: "playing"
    property string message: ""

    Timer {
        id: msgTimer
        interval: 1800
        onTriggered: game.message = ""
    }

    function validList() {
        return wordLen === 4 ? LP.LADDER_WORDS_4 : LP.LADDER_WORDS_5;
    }

    function diffCount(a, b) {
        var n = 0;
        for (var i = 0; i < a.length; i++) {
            if (a.charAt(i) !== b.charAt(i)) n++;
        }
        return n;
    }

    function newPuzzle() {
        var n = LP.LADDER_PUZZLES.length;
        var idx = Math.floor(Math.random() * n);
        if (n > 1 && idx === puzzleIndex) idx = (idx + 1) % n;
        loadPuzzle(idx);
        saveState();
    }

    function loadPuzzle(idx) {
        var p = LP.LADDER_PUZZLES[idx];
        puzzleIndex = idx;
        fromWord = p.from;
        toWord = p.to;
        wordLen = p.len;
        path = [fromWord];
        current = "";
        status = "playing";
        message = "";
    }

    function addLetter(l) {
        if (status !== "playing") return;
        if (current.length >= wordLen) return;
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
        if (current.length !== wordLen) {
            showMessage("Woorden van " + wordLen + " letters");
            return;
        }
        var w = current;
        var last = path[path.length - 1];
        if (diffCount(w, last) !== 1) {
            showMessage("Verander precies één letter");
            return;
        }
        if (path.indexOf(w) >= 0) {
            showMessage("Dat woord had je al!");
            return;
        }
        if (validList().indexOf(w) < 0) {
            showMessage("Woord niet bekend");
            return;
        }
        current = "";
        var p = path.slice();
        p.push(w);
        path = p;
        if (w === toWord) {
            status = "won";
            ST.updateStats(function(s) {
                if (!s.ladder) s.ladder = {};
                s.ladder.won = (s.ladder.won || 0) + 1;
            });
        }
        saveState();
    }

    function undoStep() {
        if (status !== "playing") return;
        if (path.length <= 1) return;
        var p = path.slice();
        p.pop();
        path = p;
        current = "";
        saveState();
    }

    function findHint() {
        var list = validList();
        var start = path[path.length - 1];
        if (start === toWord) return "";
        var prev = {};
        prev[start] = null;
        var queue = [start];
        var foundGoal = false;
        while (queue.length > 0 && !foundGoal) {
            var w = queue.shift();
            for (var i = 0; i < list.length; i++) {
                var n = list[i];
                if (prev.hasOwnProperty(n)) continue;
                if (diffCount(w, n) === 1) {
                    prev[n] = w;
                    if (n === toWord) {
                        foundGoal = true;
                        break;
                    }
                    queue.push(n);
                }
            }
        }
        if (!prev.hasOwnProperty(toWord)) return "";
        var step = toWord;
        while (prev[step] !== start) {
            if (prev[step] === null || prev[step] === undefined) return "";
            step = prev[step];
        }
        return step;
    }

    function hint() {
        if (status !== "playing") return;
        var step = findHint();
        if (step === "") {
            showMessage("Geen route meer vanaf hier - stap terug!");
        } else {
            current = step;
            showMessage("Tip: dit woord past");
        }
    }

    function showMessage(t) {
        message = t;
        msgTimer.restart();
    }

    function saveState() {
        ST.write("ladder", JSON.stringify({
            v: 1,
            puzzleIndex: puzzleIndex,
            path: path,
            status: status
        }));
    }

    function applyState(s) {
        if (!s || typeof s.puzzleIndex !== "number") return false;
        if (s.puzzleIndex < 0 || s.puzzleIndex >= LP.LADDER_PUZZLES.length) return false;
        var p = s.path ? s.path : [];
        if (p.length < 1 || typeof p[0] !== "string") return false;
        loadPuzzle(s.puzzleIndex);
        path = p;
        status = (path[path.length - 1] === toWord) ? "won" : "playing";
        current = "";
        message = "";
        return true;
    }

    function tryLoad() {
        var text = ST.read("ladder");
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
            text: "Doel: " + game.toWord + "  ·  Stap: " + (game.path.length - 1)
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
            color: "#B34700"
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 14

            Rectangle {
                width: 170
                height: 62
                radius: 14
                color: undoMouse.pressed ? "#e9e4d8" : "#ffffff"
                border.width: 2
                border.color: "#c9c2b4"

                Text {
                    anchors.centerIn: parent
                    text: "Stap terug"
                    font.pixelSize: 26
                    color: "#20201c"
                }
                MouseArea {
                    id: undoMouse
                    anchors.fill: parent
                    onClicked: game.undoStep()
                }
            }

            Rectangle {
                width: 120
                height: 62
                radius: 14
                color: hintMouse.pressed ? "#e9e4d8" : "#ffffff"
                border.width: 2
                border.color: "#c9c2b4"

                Text {
                    anchors.centerIn: parent
                    text: "Hint"
                    font.pixelSize: 26
                    color: "#20201c"
                }
                MouseArea {
                    id: hintMouse
                    anchors.fill: parent
                    onClicked: game.hint()
                }
            }

            Rectangle {
                width: 150
                height: 62
                radius: 14
                color: nieuwMouse.pressed ? "#e9e4d8" : "#ffffff"
                border.width: 2
                border.color: "#c9c2b4"

                Text {
                    anchors.centerIn: parent
                    text: "Nieuw"
                    font.pixelSize: 26
                    color: "#20201c"
                }
                MouseArea {
                    id: nieuwMouse
                    anchors.fill: parent
                    onClicked: game.newPuzzle()
                }
            }
        }
    }

    // ---------------- stappen ----------------
    Item {
        id: stepsArea
        anchors.top: topArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: inputRow.top
        anchors.bottomMargin: 10

        Column {
            id: stepsCol
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: game.path.length > 7
                text: "\u22ee"
                font.pixelSize: 34
                color: "#9a9384"
            }

            Repeater {
                model: Math.min(game.path.length, 7)

                delegate: Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: stepText.width + 56
                    height: 56
                    radius: 14
                    property int stepIndex: game.path.length - Math.min(game.path.length, 7) + index
                    color: {
                        if (stepIndex === game.path.length - 1) {
                            return game.status === "won" ? "#4F8A3D" : "#20201c";
                        }
                        return "#ffffff";
                    }
                    border.width: 2
                    border.color: "#c9c2b4"

                    Text {
                        id: stepText
                        anchors.centerIn: parent
                        text: game.path[stepIndex]
                        font.pixelSize: 30
                        font.bold: stepIndex === game.path.length - 1
                        color: stepIndex === game.path.length - 1 ? "#f6f3ec" : "#20201c"
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

        Row {
            anchors.centerIn: parent
            spacing: 8

            Repeater {
                model: game.wordLen

                delegate: Rectangle {
                    width: 64
                    height: 76
                    radius: 10
                    color: "#ffffff"
                    border.width: 2
                    border.color: index === game.current.length && game.status === "playing"
                                  ? "#6b655a" : "#c9c2b4"

                    Text {
                        anchors.centerIn: parent
                        text: index < game.current.length ? game.current.charAt(index) : ""
                        font.pixelSize: 38
                        font.bold: true
                        color: "#20201c"
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
                    text: "Van " + game.fromWord + " naar " + game.toWord
                          + " in " + (game.path.length - 1) + " stappen."
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
                            text: "Nieuw spel"
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
