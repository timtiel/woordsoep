// Store.js - bewaart de spelvoortgang via Qt's Settings-mechanisme.
//
// Op de tablet komt dat neer op een klein .conf-bestand onder
// /home/root/.config; op Windows in het register. De voortgang staat er
// als gewone JSON-tekst onder een sleutel per spel ("zoeker", "woordle",
// "galgje", "hussel", "bouwer", "ladder") en "stats" voor de statistieken.
//
// De Settings-module wordt dynamisch aangemaakt (createQmlObject), zodat
// de app ook blijft werken - alleen zonder voortgang bewaren - als de
// module onverwacht ontbreekt. Eerst wordt de moderne variant uit QtCore
// geprobeerd (Qt 6.5+); oudere Qt-versies gebruiken Qt.labs.settings.

var settings = null;

function tryCreate(parentItem, importLine) {
    try {
        var obj = Qt.createQmlObject(
            importLine + '\nSettings { category: "woordsoep" }',
            parentItem, "store-settings.qml");
        if (obj && typeof obj.setValue === "function") return obj;
    } catch (e) {
        // module ontbreekt of werkt niet
    }
    return null;
}

function init(parentItem) {
    if (settings) return;
    settings = tryCreate(parentItem, 'import QtCore');
    if (!settings) settings = tryCreate(parentItem, 'import Qt.labs.settings 1.0');
}

function read(key) {
    if (!settings) return "";
    try {
        var text = settings.value(key, "");
        return text ? String(text) : "";
    } catch (e) {
        return "";
    }
}

function write(key, text) {
    if (!settings) return;
    try {
        settings.setValue(key, text);
    } catch (e) {
        // niet erg: dan wordt er geen voortgang bewaard
    }
}

// Leest de statistieken, laat de aanroeper ze aanpassen en schrijft ze terug.
function updateStats(change) {
    var s = {};
    try {
        var t = read("stats");
        if (t) s = JSON.parse(t);
    } catch (e) {
        s = {};
    }
    change(s);
    write("stats", JSON.stringify(s));
}

