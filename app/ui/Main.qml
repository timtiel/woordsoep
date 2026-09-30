// Woordsoep - Nederlands woordenspel voor de reMarkable Paper Pro Move.
// Hoofdbestand: menu, hulp en statistieken; wisselt tussen de zes spellen.
import QtQuick
import net.asivery.ApploadUtils
import "Store.js" as ST

Rectangle {
    id: root
    anchors.fill: parent
    color: "#f6f3ec"

    // AppLoad-conventies (net als de officiële voorbeeld-apps)
    signal close
    function unloading() {
        console.log("Woordsoep: app wordt afgesloten");
    }

    property string page: "menu"
    property bool zoekerLoaded: false
    property bool woordleLoaded: false
    property bool galgjeLoaded: false
    property bool husselLoaded: false
    property bool bouwerLoaded: false
    property bool ladderLoaded: false
    property bool helpOpen: false
    property bool statsOpen: false
    property var statsData: ({})
    property bool resetArmed: false
    property string statsMessage: ""
    property var busyBadges: ({})

    property var helpTexts: ({
        "zoeker": {
            "title": "Woordzoeker",
            "text": "Vind alle 12 verborgen woorden in het letterrooster.\n\n• Sleep met je vinger of pen van de eerste naar de laatste letter van een woord - of tik eerst op de eerste en dan op de laatste letter.\n• Woorden staan horizontaal, verticaal en diagonaal, ook achterstevoren.\n• Gevonden woorden kleuren in het rooster en krijgen een streep in de lijst.\n• Vastgelopen? Tip licht kort een vakje van een nog niet gevonden woord op.\n• Met de categorie-knop kies je een onderwerp; Nieuw maakt een nieuw rooster."
        },
        "woordle": {
            "title": "Woordle",
            "text": "Raad het verborgen woord van vijf letters in zes beurten.\n\n• Typ een woord met het toetsenbord en druk op OK.\n• Groen: goede letter op de goede plek. Geel: letter zit in het woord, maar op de verkeerde plek. Grijs: letter zit niet in het woord.\n• De kleuren op het toetsenbord helpen je herinneren.\n• Nieuw woord begint een nieuw spel."
        },
        "galgje": {
            "title": "Galgje",
            "text": "Raad het woord letter voor letter.\n\n• Kies een categorie en raad letters via het toetsenbord.\n• Goede letters komen in de vakjes en kleuren groen.\n• Foute letters kleuren grijs en tekenen het poppetje - na zes fouten is het spel voorbij.\n• Nieuw - of OK als het spel voorbij is - kiest een nieuw woord."
        },
        "hussel": {
            "title": "Letterhussel",
            "text": "Vorm het woord van de gehusselde letters.\n\n• Tik de letters één voor één aan in de goede volgorde.\n• Tik op een geplaatste letter om die terug te leggen.\n• Als alle vakjes gevuld zijn, wordt het woord gecontroleerd.\n• Hint onthult een volgende letter en Hussel gooit de letters opnieuw door elkaar."
        },
        "bouwer": {
            "title": "Woordbouwer",
            "text": "Maak zoveel mogelijk woorden uit de gegeven letters.\n\n• Typ een woord van minstens 4 letters en druk op OK.\n• Elk woord mag elke letter maar zo vaak gebruiken als hij in de letterrij staat.\n• Gevonden woorden komen in de lijst te staan - vind ze allemaal!\n• Nieuw geeft een nieuwe letterrij."
        },
        "ladder": {
            "title": "Woordladder",
            "text": "Ga van het beginwoord naar het doelwoord.\n\n• Verander elke stap precies één letter; elk tussenwoord moet een bestaand woord zijn.\n• Typ een woord en druk op OK.\n• Hint tipt een woord dat past en Stap terug haalt je laatste stap weg.\n• Hoe minder stappen, hoe beter!"
        }
    })

    Component.onCompleted: {
        ST.init(root);
        refreshBadges();
    }

    function refreshBadges() {
        var b = {};
        try {
            var s = JSON.parse(ST.read("zoeker") || "null");
            if (s && s.puzzle && s.found && s.found.length > 0
                    && s.found.length < s.puzzle.placements.length) {
                b.zoeker = s.found.length + "/" + s.puzzle.placements.length;
            }
            var w = JSON.parse(ST.read("woordle") || "null");
            if (w && w.status === "playing" && w.guesses && w.guesses.length > 0) {
                b.woordle = "beurt " + Math.min(w.guesses.length + 1, 6);
            }
            var g = JSON.parse(ST.read("galgje") || "null");
            if (g && g.status === "playing" && g.guessed && g.guessed.length > 0) {
                b.galgje = "bezig";
            }
            var h = JSON.parse(ST.read("hussel") || "null");
            if (h && h.status === "playing" && h.placed && h.placed.length > 0) {
                b.hussel = "bezig";
            }
            var p = JSON.parse(ST.read("bouwer") || "null");
            if (p && p.status === "playing" && p.found && p.found.length > 0) {
                b.bouwer = p.found.length + " gevonden";
            }
            var l = JSON.parse(ST.read("ladder") || "null");
            if (l && l.status === "playing" && l.path && l.path.length > 1) {
                b.ladder = "stap " + (l.path.length - 1);
            }
        } catch (e) {
            // kapotte of ontbrekende saves: gewoon geen badges
        }
        busyBadges = b;
    }

    function loadStats() {
        var s = {};
        try {
            var t = ST.read("stats");
            if (t) s = JSON.parse(t);
        } catch (e) {
            s = {};
        }
        statsData = s;
    }

    function openStats() {
        loadStats();
        statsMessage = "";
        resetArmed = false;
        statsOpen = true;
    }

    function tryReset() {
        if (!resetArmed) {
            resetArmed = true;
            disarmTimer.restart();
            return;
        }
        resetArmed = false;
        var keys = ["zoeker", "woordle", "galgje", "hussel", "bouwer", "ladder", "stats"];
        for (var i = 0; i < keys.length; i++) {
            ST.write(keys[i], "");
        }
        loadStats();
        refreshBadges();
        statsMessage = "Voortgang gewist!";
    }

    function statsTiles() {
        var s = statsData;
        var n = function(v) { return v || 0; };
        var t = [];
        var z = s.zoeker || {};
        t.push({ name: "Woordzoeker", big: String(n(z.won)),
                 sub: "borden afgemaakt", extra: "", dist: "" });
        var w = s.woordle || {};
        var wExtra = "";
        if (n(w.played) > 0) {
            wExtra = n(w.played) + " gespeeld · reeks " + n(w.streak)
                     + " · best " + n(w.best);
        }
        var wDist = "";
        if (n(w.played) > 0 && w.dist) {
            var d = [];
            for (var i = 0; i < 6; i++) {
                d.push((i + 1) + ":" + n(w.dist[i]));
            }
            wDist = d.join(" · ");
        }
        t.push({ name: "Woordle", big: String(n(w.won)),
                 sub: "gewonnen", extra: wExtra, dist: wDist });
        var g = s.galgje || {};
        var gExtra = "";
        if (n(g.won) + n(g.lost) > 0) {
            gExtra = n(g.lost) + " verloren · reeks " + n(g.streak)
                     + " · best " + n(g.best);
        }
        t.push({ name: "Galgje", big: String(n(g.won)),
                 sub: "gewonnen", extra: gExtra, dist: "" });
        var h = s.hussel || {};
        t.push({ name: "Letterhussel", big: String(n(h.won)),
                 sub: "woorden gevormd", extra: "", dist: "" });
        var b = s.bouwer || {};
        t.push({ name: "Woordbouwer", big: String(n(b.won)),
                 sub: "puzzels afgerond", extra: "", dist: "" });
        var l = s.ladder || {};
        t.push({ name: "Woordladder", big: String(n(l.won)),
                 sub: "ladders gelopen", extra: "", dist: "" });
        return t;
    }

    onPageChanged: {
        helpOpen = false;
        statsOpen = false;
        if (page === "menu") {
            refreshBadges();
        }
        if (page === "zoeker") {
            zoekerLoaded = true;
        } else if (page === "woordle") {
            woordleLoaded = true;
        } else if (page === "galgje") {
            galgjeLoaded = true;
        } else if (page === "hussel") {
            husselLoaded = true;
        } else if (page === "bouwer") {
            bouwerLoaded = true;
        } else if (page === "ladder") {
            ladderLoaded = true;
        }
        // Sluit categorie-menu's als we een spel verlaten.
        if (page !== "zoeker" && zoekerLoader.item) {
            zoekerLoader.item.catMenuOpen = false;
        }
        if (page !== "galgje" && galgjeLoader.item) {
            galgjeLoader.item.catMenuOpen = false;
        }
        if (page !== "hussel" && husselLoader.item) {
            husselLoader.item.catMenuOpen = false;
        }
    }

    // ---------------- header ----------------
    Rectangle {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: 120
        color: "#f6f3ec"

        Rectangle {
            id: backButton
            visible: root.page !== "menu"
            x: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 96
            height: 96
            radius: 18
            color: backMouse.pressed ? "#e9e4d8" : "#ffffff"
            border.width: 2
            border.color: "#c9c2b4"

            Text {
                anchors.centerIn: parent
                text: "\u2190"
                font.pixelSize: 52
                color: "#20201c"
            }
            MouseArea {
                id: backMouse
                anchors.fill: parent
                onClicked: root.page = "menu"
            }
        }

        Text {
            visible: root.page === "menu"
            x: 30
            anchors.verticalCenter: parent.verticalCenter
            text: "Woordsoep"
            font.pixelSize: 52
            font.bold: true
            color: "#20201c"
        }

        Text {
            visible: root.page === "zoeker"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: "Woordzoeker"
            font.pixelSize: 44
            font.bold: true
            color: "#20201c"
        }

        Text {
            visible: root.page === "woordle"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: "Woordle"
            font.pixelSize: 44
            font.bold: true
            color: "#20201c"
        }

        Text {
            visible: root.page === "galgje"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: "Galgje"
            font.pixelSize: 44
            font.bold: true
            color: "#20201c"
        }

        Text {
            visible: root.page === "hussel"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: "Letterhussel"
            font.pixelSize: 44
            font.bold: true
            color: "#20201c"
        }

        Text {
            visible: root.page === "bouwer"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: "Woordbouwer"
            font.pixelSize: 44
            font.bold: true
            color: "#20201c"
        }

        Text {
            visible: root.page === "ladder"
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: "Woordladder"
            font.pixelSize: 44
            font.bold: true
            color: "#20201c"
        }

        Rectangle {
            id: helpButton
            visible: root.page !== "menu"
            x: parent.width - width - 16
            anchors.verticalCenter: parent.verticalCenter
            width: 96
            height: 96
            radius: 18
            color: helpMouse.pressed ? "#e9e4d8" : "#ffffff"
            border.width: 2
            border.color: "#c9c2b4"

            Text {
                anchors.centerIn: parent
                text: "?"
                font.pixelSize: 52
                font.bold: true
                color: "#20201c"
            }

            MouseArea {
                id: helpMouse
                anchors.fill: parent
                onClicked: root.helpOpen = true
            }
        }
    }

    // ---------------- menu ----------------
    Item {
        id: menuArea
        visible: root.page === "menu"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom

        Text {
            id: menuSubtitle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 24
            text: "Nederlands woordenspel"
            font.pixelSize: 30
            color: "#6b655a"
        }

        Grid {
            id: menuGrid
            columns: 2
            spacing: 24
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: menuSubtitle.bottom
            anchors.topMargin: 22

            property var games: [
                { title: "Woordzoeker", desc: "Vind de verborgen woorden in het letterrooster.", page: "zoeker" },
                { title: "Woordle", desc: "Raad het verborgen woord van vijf letters in zes beurten.", page: "woordle" },
                { title: "Galgje", desc: "Raad het woord letter voor letter - zes fouten en je hangt.", page: "galgje" },
                { title: "Letterhussel", desc: "Hussel de letters en tik het woord in de goede volgorde.", page: "hussel" },
                { title: "Woordbouwer", desc: "Maak zoveel mogelijk woorden uit de gegeven letters.", page: "bouwer" },
                { title: "Woordladder", desc: "Verander elke stap een letter en bereik het doelwoord.", page: "ladder" }
            ]

            Repeater {
                model: menuGrid.games

                delegate: Rectangle {
                    width: 440
                    height: 200
                    radius: 24
                    color: cardMouse.pressed ? "#f0ecdf" : "#ffffff"
                    border.width: 3
                    border.color: "#c9c2b4"

                    Text {
                        x: 26
                        y: 24
                        text: modelData.title
                        font.pixelSize: 40
                        font.bold: true
                        color: "#20201c"
                    }
                    Text {
                        x: 26
                        y: 86
                        width: parent.width - 52
                        wrapMode: Text.WordWrap
                        text: modelData.desc
                        font.pixelSize: 23
                        color: "#6b655a"
                    }
                    Rectangle {
                        visible: root.busyBadges[modelData.page] !== undefined
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        anchors.bottomMargin: 14
                        anchors.rightMargin: 14
                        width: badgeText.width + 24
                        height: 38
                        radius: 12
                        color: "#20201c"

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: root.busyBadges[modelData.page] !== undefined
                                  ? root.busyBadges[modelData.page] : ""
                            font.pixelSize: 22
                            color: "#f6f3ec"
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        onClicked: root.page = modelData.page
                    }
                }
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 46
            spacing: 26

            Rectangle {
                width: 240
                height: 74
                radius: 16
                color: statsMouse.pressed ? "#e9e4d8" : "#ffffff"
                border.width: 2
                border.color: "#c9c2b4"

                Text {
                    anchors.centerIn: parent
                    text: "Statistieken"
                    font.pixelSize: 28
                    color: "#20201c"
                }
                MouseArea {
                    id: statsMouse
                    anchors.fill: parent
                    onClicked: root.openStats()
                }
            }

            Rectangle {
                width: 190
                height: 74
                radius: 16
                color: sluitMouse.pressed ? "#e9e4d8" : "#ffffff"
                border.width: 2
                border.color: "#c9c2b4"

                Text {
                    anchors.centerIn: parent
                    text: "Sluiten"
                    font.pixelSize: 30
                    color: "#20201c"
                }
                MouseArea {
                    id: sluitMouse
                    anchors.fill: parent
                    onClicked: root.close()
                }
            }
        }
    }

    // ---------------- spellen ----------------
    Loader {
        id: zoekerLoader
        active: root.zoekerLoaded
        visible: root.page === "zoeker"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: "Woordzoeker.qml"
    }

    Loader {
        id: woordleLoader
        active: root.woordleLoaded
        visible: root.page === "woordle"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: "Woordle.qml"
    }

    Loader {
        id: galgjeLoader
        active: root.galgjeLoaded
        visible: root.page === "galgje"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: "Galgje.qml"
    }

    Loader {
        id: husselLoader
        active: root.husselLoaded
        visible: root.page === "hussel"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: "Letterhussel.qml"
    }

    Loader {
        id: bouwerLoader
        active: root.bouwerLoaded
        visible: root.page === "bouwer"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: "Woordbouwer.qml"
    }

    Loader {
        id: ladderLoader
        active: root.ladderLoaded
        visible: root.page === "ladder"
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        source: "Woordladder.qml"
    }

    // ---------------- help ----------------
    Rectangle {
        id: helpOverlay
        anchors.fill: parent
        z: 80
        visible: root.helpOpen
        color: "#77000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.helpOpen = false
        }

        Rectangle {
            id: helpCard
            width: 780
            height: helpCol.height + 56
            radius: 28
            anchors.centerIn: parent
            color: "#ffffff"
            border.width: 3
            border.color: "#c9c2b4"

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: helpCol
                width: parent.width - 72
                anchors.horizontalCenter: parent.horizontalCenter
                y: 28
                spacing: 16

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        var h = root.helpTexts[root.page];
                        return h ? h.title : "Help";
                    }
                    font.pixelSize: 40
                    font.bold: true
                    color: "#20201c"
                }

                Text {
                    width: parent.width
                    wrapMode: Text.WordWrap
                    lineHeight: 1.2
                    text: {
                        var h = root.helpTexts[root.page];
                        return h ? h.text : "";
                    }
                    font.pixelSize: 26
                    color: "#40403a"
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 260
                    height: 78
                    radius: 16
                    color: okMouse.pressed ? "#e9e4d8" : "#ffffff"
                    border.width: 2
                    border.color: "#c9c2b4"

                    Text {
                        anchors.centerIn: parent
                        text: "Begrepen"
                        font.pixelSize: 30
                        color: "#20201c"
                    }
                    MouseArea {
                        id: okMouse
                        anchors.fill: parent
                        onClicked: root.helpOpen = false
                    }
                }
            }
        }
    }

    // ---------------- statistieken ----------------
    Timer {
        id: disarmTimer
        interval: 3000
        onTriggered: root.resetArmed = false
    }

    Rectangle {
        id: statsOverlay
        anchors.fill: parent
        z: 85
        visible: root.statsOpen
        color: "#77000000"

        MouseArea {
            anchors.fill: parent
            onClicked: root.statsOpen = false
        }

        Rectangle {
            id: statsCard
            width: 820
            height: statsCol.height + 56
            radius: 28
            anchors.centerIn: parent
            color: "#ffffff"
            border.width: 3
            border.color: "#c9c2b4"

            MouseArea {
                anchors.fill: parent
            }

            Column {
                id: statsCol
                width: parent.width - 72
                anchors.horizontalCenter: parent.horizontalCenter
                y: 28
                spacing: 16

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: "Statistieken"
                    font.pixelSize: 40
                    font.bold: true
                    color: "#20201c"
                }

                Grid {
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: 2
                    rowSpacing: 22
                    columnSpacing: 22

                    Repeater {
                        model: root.statsTiles()

                        delegate: Rectangle {
                            width: 362
                            height: 190
                            radius: 18
                            color: "#faf8f2"
                            border.width: 2
                            border.color: "#e2dccf"

                            Column {
                                width: parent.width - 32
                                anchors.centerIn: parent
                                spacing: 7

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.name
                                    font.pixelSize: 23
                                    font.bold: true
                                    color: "#20201c"
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.big
                                    font.pixelSize: 44
                                    font.bold: true
                                    color: "#20201c"
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    text: modelData.sub
                                    font.pixelSize: 20
                                    color: "#6b655a"
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    visible: modelData.extra !== ""
                                    text: modelData.extra
                                    font.pixelSize: 17
                                    color: "#8a8478"
                                }

                                Text {
                                    width: parent.width
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    visible: modelData.dist !== ""
                                    text: modelData.dist
                                    font.pixelSize: 16
                                    color: "#8a8478"
                                }
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    visible: root.statsMessage !== ""
                    text: root.statsMessage
                    font.pixelSize: 24
                    font.bold: true
                    color: "#2E5B25"
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 26

                    Rectangle {
                        width: 280
                        height: 72
                        radius: 16
                        color: resetMouse.pressed ? "#e9e4d8" : "#ffffff"
                        border.width: 2
                        border.color: root.resetArmed ? "#B34700" : "#c9c2b4"

                        Text {
                            anchors.centerIn: parent
                            text: root.resetArmed ? "Zeker weten?" : "Wis voortgang"
                            font.pixelSize: 26
                            color: root.resetArmed ? "#B34700" : "#20201c"
                        }
                        MouseArea {
                            id: resetMouse
                            anchors.fill: parent
                            onClicked: root.tryReset()
                        }
                    }

                    Rectangle {
                        width: 200
                        height: 72
                        radius: 16
                        color: closeStatsMouse.pressed ? "#e9e4d8" : "#ffffff"
                        border.width: 2
                        border.color: "#c9c2b4"

                        Text {
                            anchors.centerIn: parent
                            text: "Sluiten"
                            font.pixelSize: 26
                            color: "#20201c"
                        }
                        MouseArea {
                            id: closeStatsMouse
                            anchors.fill: parent
                            onClicked: root.statsOpen = false
                        }
                    }
                }
            }
        }
    }
}
