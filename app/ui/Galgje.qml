// Galgje - raad het verborgen woord letter voor letter.
import QtQuick
import "WoordzoekerLogic.js" as ZL
import "Store.js" as ST

Item {
    id: game
    anchors.fill: parent

    readonly property int maxWrong: 6
    property var categories: ZL.CATEGORIES
    property int categoryIndex: ZL.CATEGORIES.length - 1
    property string word: ""
    property var guessed: []
    property string status: "playing"
    property bool catMenuOpen: false

    property var keyStates: {
        var ks = {};
        for (var i = 0; i < guessed.length; i++) {
            ks[guessed[i]] = word.indexOf(guessed[i]) >= 0 ? 2 : 0;
        }
        return ks;
    }

    function wrongCount() {
        var n = 0;
        for (var i = 0; i < guessed.length; i++) {
            if (word.indexOf(guessed[i]) < 0) n++;
        }
        return n;
    }

    function letterShown(l) {
        return status === "won" || guessed.indexOf(l) >= 0;
    }

    function wordWon() {
        for (var i = 0; i < word.length; i++) {
            if (guessed.indexOf(word.charAt(i)) < 0) return false;
        }
        return true;
    }

    function guessLetter(l) {
        if (status !== "playing") return;
        if (guessed.indexOf(l) >= 0) return;
        var g = guessed.slice();
        g.push(l);
        guessed = g;
        if (wordWon()) {
            status = "won";
            ST.updateStats(function(s) {
                if (!s.galgje) s.galgje = {};
                var gg = s.galgje;
                gg.won = (gg.won || 0) + 1;
                gg.streak = (gg.streak || 0) + 1;
                if ((gg.best || 0) < gg.streak) gg.best = gg.streak;
            });
        } else if (wrongCount() >= maxWrong) {
            status = "lost";
            ST.updateStats(function(s) {
                if (!s.galgje) s.galgje = {};
                var gg = s.galgje;
                gg.lost = (gg.lost || 0) + 1;
                gg.streak = 0;
            });
        }
        saveState();
    }

    function saveState() {
        ST.write("galgje", JSON.stringify({
            v: 1,
            categoryIndex: categoryIndex,
            word: word,
            guessed: guessed,
            status: status
        }));
    }

    function applyState(s) {
        if (!s || typeof s.word !== "string" || s.word.length < 2) return false;
        categoryIndex = (s.categoryIndex >= 0 && s.categoryIndex < categories.length)
                        ? s.categoryIndex : categories.length - 1;
        word = s.word;
        guessed = s.guessed ? s.guessed : [];
        status = (s.status === "won" || s.status === "lost") ? s.status : "playing";
        return true;
    }

    function tryLoad() {
        var text = ST.read("galgje");
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
        word = ZL.pickWords(categoryIndex, 1)[0];
        guessed = [];
        status = "playing";
        saveState();
    }

    Component.onCompleted: {
        ST.init(game);
        if (!tryLoad()) {
            newGame();
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
            text: game.status === "playing"
                  ? ("Fouten: " + game.wrongCount() + " / " + game.maxWrong)
                  : ""
            font.pixelSize: 28
            color: "#6b655a"
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

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
                    font.pixelSize: 28
                    color: "#20201c"
                }
                MouseArea {
                    id: nieuwMouse
                    anchors.fill: parent
                    onClicked: game.newGame()
                }
            }

            Rectangle {
                id: catButton
                width: catButtonRow.width + 44
                height: 62
                radius: 14
                color: catMouse.pressed ? "#e9e4d8" : "#ffffff"
                border.width: 2
                border.color: "#c9c2b4"

                Row {
                    id: catButtonRow
                    anchors.centerIn: parent
                    spacing: 12

                    Item {
                        height: 62
                        width: catButtonLabel.implicitWidth

                        Text {
                            id: catButtonLabel
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Categorie: " + game.categories[game.categoryIndex].name
                            font.pixelSize: 26
                            color: "#20201c"
                        }
                    }

                    Item {
                        height: 62
                        width: 24

                        Canvas {
                            width: 22
                            height: 12
                            anchors.centerIn: parent
                            rotation: game.catMenuOpen ? 180 : 0
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.reset();
                                ctx.beginPath();
                                ctx.moveTo(0, 0);
                                ctx.lineTo(width, 0);
                                ctx.lineTo(width / 2, height);
                                ctx.closePath();
                                ctx.fillStyle = "#20201c";
                                ctx.fill();
                            }
                        }
                    }
                }

                MouseArea {
                    id: catMouse
                    anchors.fill: parent
                    onClicked: game.catMenuOpen = !game.catMenuOpen
                }
            }
        }
    }

    // ---------------- woordvakjes ----------------
    Row {
        id: wordRow
        anchors.top: topArea.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        Repeater {
            model: game.word.length

            delegate: Rectangle {
                width: 78
                height: 98
                radius: 12
                color: game.status === "won" ? "#D7EED0" : "#ffffff"
                border.width: 2
                border.color: game.status === "won" ? "#4F8A3D" : "#c9c2b4"

                Text {
                    anchors.centerIn: parent
                    text: game.letterShown(game.word.charAt(index)) ? game.word.charAt(index) : ""
                    font.pixelSize: 46
                    font.bold: true
                    color: "#20201c"
                }
            }
        }
    }

    // ---------------- galg-tekening ----------------
    Item {
        id: drawingArea
        anchors.top: wordRow.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: kb.top

        Canvas {
            id: gallows
            width: 620
            height: 470
            anchors.centerIn: parent
            property int stage: game.wrongCount()

            onStageChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                ctx.lineWidth = 6;
                ctx.lineCap = "round";
                ctx.strokeStyle = "#4a4438";

                // galg
                ctx.beginPath();
                ctx.moveTo(70, 440);
                ctx.lineTo(300, 440);
                ctx.moveTo(140, 440);
                ctx.lineTo(140, 80);
                ctx.lineTo(430, 80);
                ctx.moveTo(400, 80);
                ctx.lineTo(400, 140);
                ctx.stroke();

                // poppetje per fout
                ctx.strokeStyle = "#20201c";
                var hx = 400;
                var hy = 170;
                if (stage >= 1) {
                    ctx.beginPath();
                    ctx.arc(hx, hy + 30, 32, 0, Math.PI * 2);
                    ctx.stroke();
                }
                if (stage >= 2) {
                    ctx.beginPath();
                    ctx.moveTo(hx, hy + 62);
                    ctx.lineTo(hx, hy + 190);
                    ctx.stroke();
                }
                if (stage >= 3) {
                    ctx.beginPath();
                    ctx.moveTo(hx, hy + 90);
                    ctx.lineTo(hx - 55, hy + 140);
                    ctx.stroke();
                }
                if (stage >= 4) {
                    ctx.beginPath();
                    ctx.moveTo(hx, hy + 90);
                    ctx.lineTo(hx + 55, hy + 140);
                    ctx.stroke();
                }
                if (stage >= 5) {
                    ctx.beginPath();
                    ctx.moveTo(hx, hy + 190);
                    ctx.lineTo(hx - 48, hy + 268);
                    ctx.stroke();
                }
                if (stage >= 6) {
                    ctx.beginPath();
                    ctx.moveTo(hx, hy + 190);
                    ctx.lineTo(hx + 48, hy + 268);
                    ctx.stroke();
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
        onLetterPressed: (letter) => game.guessLetter(letter)
        onEnterPressed: {
            if (game.status !== "playing") game.newGame();
        }
        onErasePressed: {}
    }

    // ---------------- resultaat ----------------
    Rectangle {
        id: resultOverlay
        anchors.fill: parent
        z: 50
        visible: game.status !== "playing"
        color: "#ddf6f3ec"

        // Alleen het gebied boven het toetsenbord vangt klikken op; zo blijft
        // de OK-toets bruikbaar om (na het einde) een nieuw spel te starten.
        MouseArea {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.bottomMargin: kb.height
        }

        Rectangle {
            width: 640
            height: 400
            radius: 28
            anchors.centerIn: parent
            color: "#ffffff"
            border.width: 3
            border.color: game.status === "won" ? "#4F8A3D" : "#B34700"

            Column {
                anchors.centerIn: parent
                spacing: 20

                Text {
                    width: 560
                    horizontalAlignment: Text.AlignHCenter
                    text: game.status === "won" ? "Gefeliciteerd!" : "Helaas!"
                    font.pixelSize: 56
                    font.bold: true
                    color: game.status === "won" ? "#2E5B25" : "#8C3600"
                }

                Text {
                    width: 560
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: game.status === "won"
                          ? ("Je vond het woord: " + game.word)
                          : ("Het woord was: " + game.word)
                    font.pixelSize: 30
                    color: "#40403a"
                }

                Item {
                    width: 560
                    height: 84

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 300
                        height: 84
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

    // ---------------- categorie-menu ----------------
    Rectangle {
        id: catOverlay
        anchors.fill: parent
        z: 60
        visible: game.catMenuOpen
        color: "#77000000"

        MouseArea {
            anchors.fill: parent
            onClicked: game.catMenuOpen = false
        }

        Rectangle {
            id: catCard
            anchors.centerIn: parent
            width: catGrid.width + 96
            height: 96 + catGrid.height + 40
            radius: 28
            color: "#ffffff"
            border.width: 3
            border.color: "#c9c2b4"

            MouseArea {
                anchors.fill: parent
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 30
                text: "Kies een categorie"
                font.pixelSize: 36
                font.bold: true
                color: "#20201c"
            }

            Grid {
                id: catGrid
                anchors.horizontalCenter: parent.horizontalCenter
                y: 96
                columns: 3
                spacing: 16

                Repeater {
                    model: game.categories.length

                    delegate: Rectangle {
                        property int catIndex: index
                        width: catText.width + 48
                        height: 66
                        radius: 16
                        color: game.categoryIndex === catIndex ? "#20201c" : "#ffffff"
                        border.width: 2
                        border.color: "#c9c2b4"

                        Text {
                            id: catText
                            anchors.centerIn: parent
                            text: game.categories[catIndex].name
                            font.pixelSize: 28
                            color: game.categoryIndex === catIndex ? "#f6f3ec" : "#20201c"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                game.categoryIndex = catIndex;
                                game.catMenuOpen = false;
                                game.newGame();
                            }
                        }
                    }
                }
            }
        }
    }
}
