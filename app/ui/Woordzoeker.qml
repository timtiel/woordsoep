// Woordzoeker - letterrooster met verborgen woorden.
import QtQuick
import "WoordzoekerLogic.js" as ZL
import "Store.js" as ST

Item {
    id: view
    anchors.fill: parent

    readonly property int cols: 10
    readonly property int rows: 12
    property var categories: ZL.CATEGORIES
    property int categoryIndex: ZL.CATEGORIES.length - 1
    property var puzzle: null
    property var found: []
    property var foundCells: []
    property var selCells: []
    property int startCol: -1
    property int startRow: -1
    property var lockedDir: null
    property var anchorCell: null
    property bool wrongFlash: false
    property bool catMenuOpen: false
    property var hintCell: null

    property var wordColors: ["#1E88E5", "#43A047", "#E53935", "#FB8C00", "#7B1FA2",
                              "#00897B", "#5D4037", "#3949AB", "#827717", "#D81B60"]

    // ---------------- helpers ----------------
    function wordColor(i) {
        return wordColors[((i % wordColors.length) + wordColors.length) % wordColors.length];
    }

    function wordFill(i) {
        return "#44" + wordColor(i).substring(1);
    }

    function isFound(i) {
        return found.indexOf(i) >= 0;
    }

    function wordAt(i) {
        if (!puzzle || i < 0 || i >= puzzle.placements.length) return "";
        return puzzle.placements[i].word;
    }

    function refreshFound() {
        var out = [];
        if (puzzle) {
            for (var i = 0; i < found.length; i++) {
                var p = puzzle.placements[found[i]];
                for (var j = 0; j < p.cells.length; j++) {
                    out.push([p.cells[j][0], p.cells[j][1], found[i]]);
                }
            }
        }
        foundCells = out;
    }

    function sameCells(a, b) {
        if (a.length !== b.length) return false;
        for (var i = 0; i < a.length; i++) {
            if (a[i][0] !== b[i][0] || a[i][1] !== b[i][1]) return false;
        }
        return true;
    }

    function findPlacementFor(sel) {
        for (var i = 0; i < puzzle.placements.length; i++) {
            var p = puzzle.placements[i];
            if (sameCells(p.cells, sel)) return i;
            var rev = [];
            for (var j = p.cells.length - 1; j >= 0; j--) rev.push(p.cells[j]);
            if (sameCells(rev, sel)) return i;
        }
        return -1;
    }

    function lineCells(c0, r0, dc, dr, len) {
        var out = [];
        for (var i = 0; i <= len; i++) {
            var c = c0 + dc * i;
            var r = r0 + dr * i;
            if (c < 0 || c >= cols || r < 0 || r >= rows) break;
            out.push([c, r]);
        }
        return out;
    }

    function clearSelectionVars() {
        selCells = [];
        startCol = -1;
        startRow = -1;
        lockedDir = null;
    }

    function evaluateSelection() {
        if (selCells.length < 2) { clearSelectionVars(); return; }
        var idx = findPlacementFor(selCells);
        if (idx >= 0 && !isFound(idx)) {
            var nf = found.slice();
            nf.push(idx);
            found = nf;
            refreshFound();
            saveState();
            if (found.length >= puzzle.placements.length) {
                ST.updateStats(function(s) {
                    if (!s.zoeker) s.zoeker = {};
                    s.zoeker.won = (s.zoeker.won || 0) + 1;
                });
            }
            anchorCell = null;
            selCells = [];
        } else if (idx < 0) {
            wrongFlash = true;
            flashTimer.restart();
        } else {
            selCells = [];
        }
        startCol = -1;
        startRow = -1;
        lockedDir = null;
    }

    function tryAnchorLine(a, b) {
        var dc = b[0] - a[0];
        var dr = b[1] - a[1];
        if (dc === 0 && dr === 0) { anchorCell = null; return; }
        if (!(dc === 0 || dr === 0 || Math.abs(dc) === Math.abs(dr))) {
            anchorCell = b;
            return;
        }
        var sx = dc === 0 ? 0 : (dc > 0 ? 1 : -1);
        var sy = dr === 0 ? 0 : (dr > 0 ? 1 : -1);
        var len = Math.max(Math.abs(dc), Math.abs(dr));
        anchorCell = null;
        selCells = lineCells(a[0], a[1], sx, sy, len);
        evaluateSelection();
    }

    function cellAt(px, py) {
        if (board.cell <= 0) return [0, 0];
        var c = Math.floor(px / board.cell);
        var r = Math.floor(py / board.cell);
        if (c < 0) c = 0;
        if (c >= cols) c = cols - 1;
        if (r < 0) r = 0;
        if (r >= rows) r = rows - 1;
        return [c, r];
    }

    function saveState() {
        ST.write("zoeker", JSON.stringify({
            v: 1,
            categoryIndex: categoryIndex,
            puzzle: puzzle,
            found: found
        }));
    }

    function applyState(s) {
        if (!s || !s.puzzle || !s.puzzle.grid || !s.puzzle.placements
                || s.puzzle.grid.length !== rows || s.puzzle.placements.length === 0) {
            return false;
        }
        categoryIndex = (s.categoryIndex >= 0 && s.categoryIndex < categories.length)
                        ? s.categoryIndex : categories.length - 1;
        puzzle = s.puzzle;
        var f = s.found ? s.found : [];
        var valid = [];
        for (var i = 0; i < f.length; i++) {
            if (f[i] >= 0 && f[i] < puzzle.placements.length) valid.push(f[i]);
        }
        found = valid;
        refreshFound();
        clearSelectionVars();
        anchorCell = null;
        wrongFlash = false;
        return true;
    }

    function tryLoad() {
        var text = ST.read("zoeker");
        if (text === "") return false;
        var s = null;
        try {
            s = JSON.parse(text);
        } catch (e) {
            s = null;
        }
        return applyState(s);
    }

    function tip() {
        if (!puzzle) return;
        for (var i = 0; i < puzzle.placements.length; i++) {
            if (!isFound(i)) {
                hintCell = puzzle.placements[i].cells[0];
                hintTimer.restart();
                return;
            }
        }
    }

    function newGame() {
        var words = ZL.pickWords(categoryIndex, 12);
        puzzle = ZL.generate(cols, rows, words);
        found = [];
        foundCells = [];
        clearSelectionVars();
        anchorCell = null;
        wrongFlash = false;
        hintCell = null;
        saveState();
    }

    Component.onCompleted: {
        ST.init(view);
        if (!tryLoad()) {
            newGame();
        }
    }

    Timer {
        id: flashTimer
        interval: 500
        onTriggered: {
            view.wrongFlash = false;
            view.selCells = [];
        }
    }

    Timer {
        id: hintTimer
        interval: 1600
        onTriggered: view.hintCell = null
    }

    // ---------------- categorien + status ----------------
    Item {
        id: topArea
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 86

        Text {
            id: counterText
            x: 20
            anchors.verticalCenter: parent.verticalCenter
            text: view.puzzle
                  ? (view.found.length + " / " + view.puzzle.placements.length + " woorden gevonden")
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
                width: 110
                height: 62
                radius: 14
                color: tipMouse.pressed ? "#e9e4d8" : "#ffffff"
                border.width: 2
                border.color: "#c9c2b4"

                Text {
                    anchors.centerIn: parent
                    text: "Tip"
                    font.pixelSize: 26
                    color: "#20201c"
                }
                MouseArea {
                    id: tipMouse
                    anchors.fill: parent
                    onClicked: view.tip()
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
                    font.pixelSize: 28
                    color: "#20201c"
                }
                MouseArea {
                    id: nieuwMouse
                    anchors.fill: parent
                    onClicked: view.newGame()
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
                            text: "Categorie: " + view.categories[view.categoryIndex].name
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
                            rotation: view.catMenuOpen ? 180 : 0
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
                    onClicked: view.catMenuOpen = !view.catMenuOpen
                }
            }
        }
    }

    // ---------------- rooster ----------------
    Item {
        id: boardArea
        anchors.top: topArea.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: wordPanel.top
        anchors.bottomMargin: 10
    }

    Rectangle {
        id: board
        anchors.centerIn: boardArea
        property int cell: Math.max(1, Math.floor(Math.min(boardArea.width / view.cols, boardArea.height / view.rows)))
        width: cell * view.cols
        height: cell * view.rows
        color: "#ffffff"
        border.width: 2
        border.color: "#d8d1c2"

        // gevonden woorden (onder de letters)
        Repeater {
            model: view.foundCells

            delegate: Rectangle {
                x: modelData[0] * board.cell
                y: modelData[1] * board.cell
                width: board.cell
                height: board.cell
                color: view.wordFill(modelData[2])
            }
        }

        // huidige selectie
        Repeater {
            model: view.selCells

            delegate: Rectangle {
                x: modelData[0] * board.cell
                y: modelData[1] * board.cell
                width: board.cell
                height: board.cell
                color: view.wrongFlash ? "#44E53935" : "#443458B3"
                border.width: 2
                border.color: view.wrongFlash ? "#E53935" : "#3458B3"
            }
        }

        // ankerpunt bij tikken
        Rectangle {
            visible: view.anchorCell !== null
            x: view.anchorCell ? view.anchorCell[0] * board.cell : 0
            y: view.anchorCell ? view.anchorCell[1] * board.cell : 0
            width: board.cell
            height: board.cell
            color: "#223458B3"
            border.width: 3
            border.color: "#3458B3"
        }

        // tip-highlight
        Rectangle {
            visible: view.hintCell !== null
            x: view.hintCell ? view.hintCell[0] * board.cell : 0
            y: view.hintCell ? view.hintCell[1] * board.cell : 0
            width: board.cell
            height: board.cell
            color: "#33C9A227"
            border.width: 3
            border.color: "#C9A227"
        }

        // letters
        Repeater {
            model: view.cols * view.rows

            delegate: Item {
                property int cc: index % view.cols
                property int rr: Math.floor(index / view.cols)
                x: cc * board.cell
                y: rr * board.cell
                width: board.cell
                height: board.cell

                Rectangle {
                    anchors.fill: parent
                    color: "transparent"
                    border.width: 1
                    border.color: "#e7e1d3"
                }

                Text {
                    anchors.centerIn: parent
                    text: view.puzzle ? view.puzzle.grid[rr][cc] : ""
                    font.pixelSize: Math.floor(board.cell * 0.58)
                    color: "#1c1c1c"
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            preventStealing: true

            onPressed: (mouse) => {
                var cell = view.cellAt(mouse.x, mouse.y);
                view.startCol = cell[0];
                view.startRow = cell[1];
                view.lockedDir = null;
                view.wrongFlash = false;
                view.selCells = [cell];
            }

            onPositionChanged: (mouse) => {
                if (view.startCol < 0) return;
                var cell = view.cellAt(mouse.x, mouse.y);
                var dc = cell[0] - view.startCol;
                var dr = cell[1] - view.startRow;
                if (!view.lockedDir) {
                    if (dc === 0 && dr === 0) {
                        view.selCells = [cell];
                        return;
                    }
                    var ang = Math.atan2(dr, dc);
                    var idx = Math.round(ang / (Math.PI / 4));
                    idx = ((idx % 8) + 8) % 8;
                    var dirs = [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]];
                    view.lockedDir = dirs[idx];
                }
                var len = Math.round(dc * view.lockedDir[0] + dr * view.lockedDir[1]);
                if (len < 0) len = 0;
                view.selCells = view.lineCells(view.startCol, view.startRow,
                                               view.lockedDir[0], view.lockedDir[1], len);
            }

            onReleased: {
                if (view.startCol < 0) return;
                if (view.selCells.length >= 2) {
                    view.evaluateSelection();
                } else {
                    var cell = [view.startCol, view.startRow];
                    if (view.anchorCell && (view.anchorCell[0] !== cell[0] || view.anchorCell[1] !== cell[1])) {
                        view.tryAnchorLine(view.anchorCell, cell);
                    } else if (view.anchorCell) {
                        view.anchorCell = null;
                    } else {
                        view.anchorCell = cell;
                    }
                    view.clearSelectionVars();
                }
            }

            onCanceled: {
                view.clearSelectionVars();
            }
        }
    }

    // ---------------- woordenlijst ----------------
    Item {
        id: wordPanel
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 280
        visible: view.puzzle !== null

        Grid {
            id: wordGrid
            columns: 3
            spacing: 10
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 10

            Repeater {
                model: view.puzzle ? view.puzzle.placements.length : 0

                delegate: Row {
                    property int wordIndex: index
                    width: 296
                    height: 46
                    spacing: 10

                    Item {
                        width: 26
                        height: 46

                        Rectangle {
                            width: 26
                            height: 26
                            radius: 6
                            anchors.centerIn: parent
                            color: view.isFound(wordIndex) ? view.wordColor(wordIndex) : "#ffffff"
                            border.width: 2
                            border.color: "#b9b2a4"
                        }
                    }

                    Text {
                        height: 46
                        verticalAlignment: Text.AlignVCenter
                        text: view.wordAt(wordIndex)
                        font.pixelSize: 30
                        color: "#20201c"
                        font.strikeout: view.isFound(wordIndex)
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
        visible: view.catMenuOpen
        color: "#77000000"

        MouseArea {
            anchors.fill: parent
            onClicked: view.catMenuOpen = false
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
                    model: view.categories.length

                    delegate: Rectangle {
                        property int catIndex: index
                        width: catText.width + 48
                        height: 66
                        radius: 16
                        color: view.categoryIndex === catIndex ? "#20201c" : "#ffffff"
                        border.width: 2
                        border.color: "#c9c2b4"

                        Text {
                            id: catText
                            anchors.centerIn: parent
                            text: view.categories[catIndex].name
                            font.pixelSize: 28
                            color: view.categoryIndex === catIndex ? "#f6f3ec" : "#20201c"
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                view.categoryIndex = catIndex;
                                view.catMenuOpen = false;
                                view.newGame();
                            }
                        }
                    }
                }
            }
        }
    }

    // ---------------- gewonnen ----------------
    Rectangle {
        id: winOverlay
        anchors.fill: parent
        z: 50
        visible: view.puzzle !== null
                 && view.puzzle.placements.length > 0
                 && view.found.length >= view.puzzle.placements.length
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
                    text: "Je hebt alle " + (view.puzzle ? view.puzzle.placements.length : 0) + " woorden gevonden."
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
                        color: winMouse.pressed ? "#e9e4d8" : "#ffffff"
                        border.width: 2
                        border.color: "#c9c2b4"

                        Text {
                            anchors.centerIn: parent
                            text: "Nieuw spel"
                            font.pixelSize: 32
                            color: "#20201c"
                        }
                        MouseArea {
                            id: winMouse
                            anchors.fill: parent
                            onClicked: view.newGame()
                        }
                    }
                }
            }
        }
    }
}
