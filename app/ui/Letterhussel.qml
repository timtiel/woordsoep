// Letterhussel - tik de gehusselde letters in de goede volgorde.
import QtQuick
import "WoordzoekerLogic.js" as ZL
import "Store.js" as ST

Item {
    id: game
    anchors.fill: parent

    property var categories: ZL.CATEGORIES
    property int categoryIndex: ZL.CATEGORIES.length - 1
    property string word: ""
    property var tiles: []
    property var placed: []
    property string status: "playing"
    property bool flash: false
    property bool catMenuOpen: false

    Timer {
        id: flashTimer
        interval: 750
        onTriggered: {
            game.flash = false;
            game.placed = [];
            game.saveState();
        }
    }

    function poolFor(cat) {
        if (cat < 0 || cat >= categories.length || categories[cat].words.length === 0) {
            return ZL.allWords();
        }
        return categories[cat].words;
    }

    function newGame() {
        var all = poolFor(categoryIndex);
        var pool = [];
        for (var i = 0; i < all.length; i++) {
            var len = all[i].length;
            if (len >= 4 && len <= 7) pool.push(all[i]);
        }
        word = pool[Math.floor(Math.random() * pool.length)];
        tiles = ZL.shuffle(word.split(""));
        placed = [];
        status = "playing";
        flash = false;
        saveState();
    }

    function placeTile(i) {
        if (status !== "playing") return;
        if (placed.indexOf(i) >= 0) return;
        var p = placed.slice();
        p.push(i);
        placed = p;
        flash = false;
        if (p.length === word.length) {
            checkAnswer();
        } else {
            saveState();
        }
    }

    function removeAt(pos) {
        if (status !== "playing") return;
        var p = placed.slice();
        p.splice(pos, 1);
        placed = p;
        flash = false;
        saveState();
    }

    function shuffleTiles() {
        if (status !== "playing") return;
        if (placed.length > 0) return;
        tiles = ZL.shuffle(tiles);
        saveState();
    }

    function checkAnswer() {
        var s = "";
        for (var i = 0; i < placed.length; i++) s += tiles[placed[i]];
        if (s === word) {
            status = "won";
            ST.updateStats(function(st) {
                if (!st.hussel) st.hussel = {};
                st.hussel.won = (st.hussel.won || 0) + 1;
            });
        } else {
            flash = true;
            flashTimer.restart();
        }
        saveState();
    }

    function hint() {
        if (status !== "playing") return;
        var arr = [];
        for (var i = 0; i < placed.length; i++) arr.push(tiles[placed[i]]);
        var idx = 0;
        while (idx < arr.length && arr[idx] === word.charAt(idx)) idx++;
        if (idx >= word.length) return;
        var needed = word.charAt(idx);

        var newPlaced = [];
        for (var k = 0; k < idx; k++) newPlaced.push(placed[k]);

        // hield de al goed geplaatste tegel van deze positie, of zoek een vrije tegel
        var pick = -1;
        if (idx < placed.length && tiles[placed[idx]] === needed
                && newPlaced.indexOf(placed[idx]) < 0) {
            pick = placed[idx];
        }
        if (pick < 0) {
            for (var t = 0; t < tiles.length; t++) {
                if (tiles[t] === needed && newPlaced.indexOf(t) < 0) {
                    pick = t;
                    break;
                }
            }
        }
        if (pick >= 0) newPlaced.push(pick);
        placed = newPlaced;
        flash = false;
        if (placed.length === word.length) {
            checkAnswer();
        } else {
            saveState();
        }
    }

    function saveState() {
        ST.write("hussel", JSON.stringify({
            v: 1,
            categoryIndex: categoryIndex,
            word: word,
            tiles: tiles,
            placed: placed,
            status: status
        }));
    }

    function applyState(s) {
        if (!s || typeof s.word !== "string" || s.word.length < 2) return false;
        if (!s.tiles || s.tiles.length !== s.word.length) return false;
        categoryIndex = (s.categoryIndex >= 0 && s.categoryIndex < categories.length)
                        ? s.categoryIndex : categories.length - 1;
        word = s.word;
        tiles = s.tiles;
        var p = s.placed ? s.placed : [];
        var valid = [];
        for (var i = 0; i < p.length; i++) {
            if (p[i] >= 0 && p[i] < tiles.length && valid.indexOf(p[i]) < 0) valid.push(p[i]);
        }
        placed = valid;
        status = s.status === "won" ? "won" : "playing";
        flash = false;
        return true;
    }

    function tryLoad() {
        var text = ST.read("hussel");
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
            width: 280
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            text: game.flash
                  ? "Helaas, probeer opnieuw!"
                  : ("Woord van " + game.word.length + " letters")
            font.pixelSize: 26
            color: game.flash ? "#B34700" : "#6b655a"
        }

        Row {
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            spacing: 16

            Rectangle {
                width: 130
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

    // ---------------- husselvlak ----------------
    Item {
        id: middleArea
        anchors.top: topArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            spacing: 46

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 10

                Repeater {
                    model: game.word.length

                    delegate: Rectangle {
                        width: 96
                        height: 110
                        radius: 14
                        color: "#ffffff"
                        border.width: 3
                        border.color: game.flash ? "#E53935"
                                                : (game.status === "won" ? "#4F8A3D" : "#c9c2b4")

                        Text {
                            anchors.centerIn: parent
                            text: index < game.placed.length ? game.tiles[game.placed[index]] : ""
                            font.pixelSize: 50
                            font.bold: true
                            color: "#20201c"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                if (index < game.placed.length) game.removeAt(index);
                            }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 12

                Repeater {
                    model: game.tiles.length

                    delegate: Rectangle {
                        width: 110
                        height: 110
                        radius: 16
                        property bool used: game.placed.indexOf(index) >= 0
                        color: used ? "#e9e4d8" : (tileMouse.pressed ? "#e9e4d8" : "#ffffff")
                        border.width: 2
                        border.color: "#c9c2b4"
                        opacity: used ? 0.35 : 1

                        Text {
                            anchors.centerIn: parent
                            text: game.tiles[index]
                            font.pixelSize: 52
                            font.bold: true
                            color: "#20201c"
                        }

                        MouseArea {
                            id: tileMouse
                            anchors.fill: parent
                            onClicked: game.placeTile(index)
                        }
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 200
                height: 64
                radius: 14
                color: shuffleMouse.pressed ? "#e9e4d8" : "#ffffff"
                border.width: 2
                border.color: "#c9c2b4"

                Text {
                    anchors.centerIn: parent
                    text: "Hussel"
                    font.pixelSize: 26
                    color: "#20201c"
                }
                MouseArea {
                    id: shuffleMouse
                    anchors.fill: parent
                    onClicked: game.shuffleTiles()
                }
            }
        }
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
                    text: "Je vormde het woord: " + game.word
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
                            text: "Volgende woord"
                            font.pixelSize: 32
                            color: "#20201c"
                        }
                        MouseArea {
                            id: nextMouse
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
