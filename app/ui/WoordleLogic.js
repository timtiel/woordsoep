// WoordleLogic.js - woordenlijst en scorefunctie voor de Woordle-modus.
// Plain JavaScript zodat het ook met Node getest kan worden.

var WORDS = [
    "AARDE", "ABDIJ", "ACTIE", "ADRES", "AFVAL", "AGENT", "ALARM", "ALBUM",
    "ALLEE", "ALLES", "ANDER", "ANGEL", "ANGST", "ANKER", "APART", "APPEL",
    "ARENA", "ASBAK", "ATLAS", "AVOND", "AZIJN",
    "BARST", "BASIS", "BEGIN", "BEELD", "BEEST", "BELEG", "BESEF", "BESTE",
    "BETON", "BEZEM", "BLAAS", "BLANK", "BLAUW", "BLEEK", "BLIND", "BLOED",
    "BLOEM", "BLOOS", "BODEM", "BOCHT", "BOETE", "BONUS", "BOORD", "BORST",
    "BOTER", "BOVEN", "BRAAF", "BRAND", "BREED", "BRIEF", "BROEK", "BROER",
    "BROOD", "BRUID", "BRUIN", "BUURT",
    "CAVIA", "CHAOS", "CLAIM", "COACH", "COBRA",
    "DADEL", "DATUM", "DEKEN", "DELEN", "DERDE", "DICHT", "DOPEN", "DORST",
    "DRAAI", "DRAAD", "DRAAK", "DRANK", "DREEF", "DROEF", "DROOG", "DROOM",
    "DRUIF", "DUWEN", "DWAAS", "DWARS", "DWERG",
    "EERST", "EIGEN", "EINDE", "ELAND", "EMMER", "ENGEL", "ENKEL", "ENORM",
    "ERNST", "ETAGE", "EXACT", "EXTRA",
    "FABEL", "FALEN", "FEEST", "FIETS", "FIRMA", "FLANK", "FLAUW", "FLINK",
    "FLITS", "FLORA", "FLUIT", "FONDS", "FRAAI", "FRIET", "FRONS", "FRUIT",
    "GAREN", "GEBED", "GEBIT", "GEDOE", "GEEST", "GELEI", "GELUK", "GEMAK",
    "GENIE", "GENOT", "GERST", "GETAL", "GEVAL", "GEVEL", "GEZAG", "GEZEL",
    "GEZIN", "GLANS", "GLOED", "GRAAD", "GRAAG", "GRAAF", "GRAAN", "GRAUW",
    "GREEP", "GRENS", "GRIEP", "GRIJS", "GROEI", "GROEN", "GROEP", "GROET",
    "GROND", "GROOT", "GUNST",
    "HAARD", "HALEN", "HALLO", "HALTE", "HAMER", "HAVEN", "HAVIK", "HEIDE",
    "HELFT", "HEMEL", "HOBBY", "HOEST", "HOOFD", "HOORN", "HOPEN", "HOREN",
    "HOTEL", "HULDE", "HUMOR",
    "IJZER", "INHAM", "INVAL", "INZET",
    "JACHT", "JAGER", "JARIG", "JASJE", "JEUGD", "JOKER", "JUBEL", "JUIST",
    "KAART", "KABEL", "KADER", "KAMER", "KANON", "KAPER", "KAPOT", "KASSA",
    "KEBAB", "KEGEL", "KEREL", "KEREN", "KERST", "KETEL", "KETEN", "KEUZE",
    "KIOSK", "KLAAR", "KLAUW", "KLEED", "KLEIN", "KLEUR", "KLOOF", "KLUIS",
    "KNAAP", "KOALA", "KOERS", "KOGEL", "KOKEN", "KOKER", "KOLOM", "KOMEN",
    "KOORD", "KOPJE", "KOPER", "KOREN", "KOUDE", "KRAAG", "KRAAL", "KRAAN",
    "KRAMP", "KRANT", "KREEK", "KRIJT", "KROEG", "KROON", "KRUID", "KRUIS",
    "KUBUS", "KUDDE", "KUNST", "KWAAD", "KWAAL", "KWART",
    "LAARS", "LADEN", "LATEN", "LEEUW", "LEGEN", "LEGER", "LENEN", "LENTE",
    "LEPEL", "LEVEN", "LEZEN", "LEZER", "LICHT", "LIJST", "LINDE", "LINKS",
    "LITER", "LOPEN", "LOTUS", "LUCHT", "LUNCH",
    "MAAND", "MACHT", "MAGER", "MAGIE", "MAKEN", "MALEN", "MANGO", "MARKT",
    "MASSA", "MEEST", "MEREL", "METEN", "MOLEN", "MOORD", "MOTEL", "MOTOR",
    "MYTHE",
    "NAALD", "NAAST", "NABIJ", "NACHT", "NAGEL", "NATIE", "NAVEL", "NEGEN",
    "NEVEL", "NICHT", "NIEUW", "NODIG", "NOBEL", "NOOIT", "NOORD", "NOTEN",
    "OFFER", "ONDER", "ONZIN", "OOGST", "OPHEF", "OPTIE", "OPZET", "OUDER",
    "PAARD", "PAARS", "PANEL", "PAREL", "PASTA", "PATAT", "PAUZE", "PEPER",
    "PIANO", "PISTE", "PIZZA", "PLAAG", "PLAAT", "PLANT", "PLEIN", "PLOEG",
    "PLONS", "PLUIM", "POKER", "POORT", "PRAAT", "PREEK", "PRENT", "PRIJS",
    "PRINS", "PROEF", "PROOI", "PRUIK", "PRUIM", "PUPIL",
    "QUOTA",
    "RABAT", "RADAR", "RADEN", "RADIO", "RAKET", "RAMEN", "REBEL", "RECHT",
    "REDEN", "REEKS", "REGEL", "REGEN", "RIJST", "ROBOT", "ROEST", "ROMAN",
    "RONDE", "ROUTE", "ROZEN", "RUGBY",
    "SALDO", "SALON", "SALTO", "SAMEN", "SCHAT", "SCHIL", "SCHIP", "SCHOK",
    "SERIE", "SERRE", "SFEER", "SHIRT", "SJAAL", "SLAAN", "SLANK", "SLIJM",
    "SLUIS", "SMAAK", "SMEER", "SNAAR", "SNACK", "SNOEP", "SNOER", "SOORT",
    "SPEER", "SPIES", "SPIER", "SPIJT", "SPION", "SPITS", "SPOED",
    "SPOEL", "SPOOK", "SPOOR", "SPONS", "SPORT", "SPUIT", "STAAL", "STAAN",
    "STAND", "START", "STEEK", "STEEL", "STEEN", "STEIL", "STERK", "STEUN",
    "STIER", "STIFT", "STIJF", "STIJL", "STOEL", "STOOM", "STOEP", "STORM",
    "STOUT", "STRAF", "STRAK", "STRIK", "STROP", "STUUR", "STUNT",
    "TAART", "TABAK", "TABEL", "TAFEL", "TANTE", "TEGEL", "TEGEN", "TEKEN",
    "TEKST", "TERUG", "THEMA", "TITEL", "TOCHT", "TONEN", "TONNE", "TOREN",
    "TRAAG", "TREND", "TROEP", "TROON", "TROTS", "TROUW", "TRUCK", "TWIST",
    "UITEN", "UITJE",
    "VADER", "VAART", "VAREN", "VEDER", "VEGEN", "VETER", "VLAAG", "VLEES",
    "VLIEG", "VLOED", "VLOEK", "VLOER", "VOGEL", "VREES", "VREDE", "VROEG",
    "VROUW", "VUIST",
    "WAARD", "WACHT", "WAGEN", "WAPEN", "WATER", "WEGEN", "WEIDE", "WEKEN",
    "WENEN", "WETEN", "WEZEN", "WINST", "WOEDE", "WONEN", "WOORD", "WORST",
    "WRAAK", "WREED",
    "ZACHT", "ZADEL", "ZAGEN", "ZEBRA", "ZEGEL", "ZEGEN", "ZEKER", "ZENUW",
    "ZETEL", "ZICHT", "ZIJDE", "ZOALS", "ZOMER", "ZONDE", "ZUCHT", "ZWAAN",
    "ZWAAR", "ZWART", "ZWEEP", "ZWEER", "ZWEET", "ZWERM"
];

function pickWord() {
    return WORDS[Math.floor(Math.random() * WORDS.length)];
}

// 2 = goede letter op de goede plek, 1 = letter zit in het woord,
// 0 = letter zit niet in het woord.
function score(target, guess) {
    var marks = [0, 0, 0, 0, 0];
    var counts = {};
    var i;
    for (i = 0; i < 5; i++) {
        var c = target.charAt(i);
        counts[c] = (counts[c] || 0) + 1;
    }
    for (i = 0; i < 5; i++) {
        if (guess.charAt(i) === target.charAt(i)) {
            marks[i] = 2;
            counts[target.charAt(i)] = counts[target.charAt(i)] - 1;
        }
    }
    for (i = 0; i < 5; i++) {
        if (marks[i] === 2) continue;
        var ch = guess.charAt(i);
        if ((counts[ch] || 0) > 0) {
            marks[i] = 1;
            counts[ch] = counts[ch] - 1;
        }
    }
    return marks;
}
