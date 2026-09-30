// WoordzoekerLogic.js - woordlijsten en puzzelgenerator voor de Woordzoeker.
// Dit bestand is bewust "plain JavaScript" (geen QML-specifieke syntax),
// zodat het ook los getest kan worden met Node.js (zie tools/test_logic.js).

var CATEGORIES = [
    {
        name: "Dieren",
        words: [
            "EEND", "HOND", "HAAS", "WOLF", "BEER", "LEEUW", "TIJGER", "ZEBRA",
            "PAARD", "SCHAAP", "GEIT", "VARKEN", "EZEL", "MUIS", "SLANG",
            "KIKKER", "DOLFIJN", "WALVIS", "ZEEHOND", "KREEFT", "SPIN", "PANDA",
            "OLIFANT", "KONIJN", "LUIPAARD",
            "GANS", "ZWAAN", "EKSTER", "MEREL", "LIJSTER", "VINK", "MEES",
            "SPREEUW", "KRAAI", "DUIF", "RAAF", "AREND", "VALK", "OOIEVAAR",
            "PUMA", "LYNX", "JAGUAR", "GORILLA", "MUILEZEL", "KAMEEL", "LAMA",
            "RENDIER", "ELAND", "OTTER", "BEVER", "EGEL", "HAMSTER", "CAVIA",
            "HAAN", "KUIKEN", "ZEUG", "STIER", "POES", "KITTEN", "PUPPY",
            "ZEELEEUW", "ZEEPAARD", "WALRUS", "KRAB", "HAAI", "ZALM", "FOREL",
            "HARING", "MAKREEL", "SARDINE", "SNOEK", "BAARS", "KARPER", "MEERVAL",
            "HAGEDIS", "KAMELEON", "PYTHON", "COBRA", "ADDER", "LIBEL", "WESP",
            "MIER", "VLIEG", "KEVER", "KREKEL", "WORM", "ZEESTER"
        ]
    },
    {
        name: "Eten",
        words: [
            "APPEL", "BROOD", "KAAS", "MELK", "BOTER", "SOEP", "RIJST", "PATAT",
            "PIZZA", "PASTA", "FRUIT", "SUIKER", "TAART", "KOEK", "THEE",
            "KOFFIE", "WATER", "TOMAAT", "WORTEL", "PREI", "BONEN", "ERWTEN",
            "WORST", "VLEES", "GEBAK", "CAKE", "SNOEP", "DROP", "CHIPS",
            "HONING", "LIMONADE",
            "BANAAN", "CITROEN", "LIMOEN", "AARDBEI", "KERS", "DRUIF", "PERZIK",
            "PRUIM", "MANGO", "MELOEN", "FRAMBOOS", "BRAAM", "VIJG", "DADEL",
            "AMANDEL", "PINDA", "WALNOOT", "KASTANJE", "PISTACHE", "GROENTE",
            "SPINAZIE", "ANDIJVIE", "KOOL", "SPRUIT", "WITLOF", "PAPRIKA",
            "RADIJS", "BIET", "RAAP", "KNOL", "SJALOT", "ASPERGE", "DOPERWT",
            "OMELET", "BESCHUIT", "KOEKJE", "BROODJE", "BOUILLON", "POMPOEN",
            "NOEDELS", "YOGHURT", "PUDDING", "MOUSSE", "WAFEL", "BONBON",
            "LOLLY", "APPELSAP", "COLA", "ESPRESSO", "PEPER", "ZOUT", "KANEEL",
            "KRUIDEN", "GEMBER", "KNOFLOOK", "SIROOP", "AZIJN", "MOSTERD",
            "KETCHUP", "SAMBAL", "SOJASAUS", "VANILLE", "SPEK", "BRIE",
            "KIPFILET"
        ]
    },
    {
        name: "Natuur",
        words: [
            "BLOEM", "BOOM", "BLAD", "GRAS", "REGEN", "WOLK", "MAAN", "STER",
            "HEMEL", "STRAND", "DUIN", "VIJVER", "RIVIER", "MEER", "BERG",
            "HEIDE", "KLOOF", "GROT", "EILAND", "WATERVAL", "BLIKSEM", "DONDER",
            "ONWEER", "SNEEUW", "WIND", "STORM", "VULKAAN", "WOESTIJN", "ZAND",
            "SCHELP", "GOLF", "LENTE", "ZOMER", "HERFST", "WINTER", "VLINDER",
            "VOGEL", "NEST", "STAM", "SEIZOEN",
            "ORKAAN", "WOLKEN", "HAGEL", "IJZEL", "MIST", "NEVEL", "DAUW",
            "VORST", "DOOI", "HITTE", "BEUK", "BERK", "SPAR", "WILG", "LINDE",
            "ESDOORN", "SCHORS", "ROOS", "TULP", "NARCIS", "LELIE", "IRIS",
            "JASMIJN", "LAVENDEL", "MARGRIET", "KROKUS", "HYACINT", "BEGONIA",
            "KLAPROOS", "DISTEL", "VLAKTE", "WEIDE", "PARK", "OASE", "KUST",
            "OEVER", "BRON", "BEEK", "MOERAS", "VEEN", "PLAS", "POEL", "OCEAAN",
            "GETIJDE", "WOUD", "OERBOS", "JUNGLE", "SAVANNE", "STEPPE",
            "TOENDRA", "IJSBERG", "GLETSJER", "PLANEET", "KOMEET", "MELKWEG",
            "REGENBUI", "HAGELBUI", "RIJM", "KORAAL"
        ]
    },
    {
        name: "Huis",
        words: [
            "DEUR", "RAAM", "TAFEL", "STOEL", "KAST", "LAMP", "MUUR", "VLOER",
            "TRAP", "TUIN", "SCHUUR", "GARAGE", "KEUKEN", "KAMER", "BADKAMER",
            "ZOLDER", "KELDER", "GORDIJN", "SPIEGEL", "BANK", "KUSSEN", "DEKEN",
            "LAKEN", "HANDDOEK", "ZEEP", "SPONS", "BEZEM", "EMMER", "GIETER",
            "HARK", "SCHOP", "LADDER", "HAMER", "SPIJKER", "SCHROEF", "ZAAG",
            "POTLOOD", "PAPIER", "SCHAAR", "VERF", "BLOEMPOT",
            "PLANK", "NIJPTANG", "TANG", "BEITEL", "VIJL", "BOOR", "HOUT",
            "METAAL", "STEEN", "BAKSTEEN", "TEGEL", "CEMENT", "LIJM", "MATRAS",
            "TAPIJT", "VITRAGE", "LADE", "BUREAU", "ZETEL", "BARKRUK", "FORNUIS",
            "OVEN", "KOELKAST", "VRIEZER", "KOOKPAN", "KOEKEPAN", "BORD", "KOPJE",
            "GLAS", "BESTEK", "VORK", "THEEPOT", "SERVIES", "SCHOTEL", "DOUCHE",
            "WASTAFEL", "KRAAN", "TOILET", "BADKUIP", "SHAMPOO", "BORSTEL",
            "KAARS", "LIJST", "FOTO", "KLOK", "SLEUTEL", "SLOT", "POORT",
            "DWEIL", "VEGER"
        ]
    },
    {
        name: "Sport",
        words: [
            "VOETBAL", "TENNIS", "HOCKEY", "ZWEMMEN", "FIETSEN", "SCHAAK",
            "DAMMEN", "KAARTEN", "DOBBEL", "PUZZEL", "SPELEN", "RENNEN",
            "SCHAATS", "MARATHON", "KORFBAL", "TRAINEN", "COACH", "SCORE",
            "GOAL", "DOELPUNT", "STADION", "MEDAILLE", "WINNAAR", "TOERNOOI",
            "KAMPIOEN", "ATLETIEK", "TURNEN", "BOKSEN", "JUDO", "KARATE",
            "HANDBAL", "ZWEMBAD", "SPRINGEN", "WANDELEN", "JOGGEN", "SKATEN",
            "SURFEN", "ZEILEN", "ROEIEN", "KANO", "KAJAK", "DUIKEN", "VECHTEN",
            "SCHERMEN", "DARTS", "BILJART", "BOWLEN", "MINIGOLF", "FITNESS",
            "SPORTEN", "SPRINTEN", "DISCUS", "SPEER", "TEAM", "PLOEG", "CLUB",
            "ELFTAL", "KEEPER", "AANVAL", "SCHEIDS", "DOEL", "CORNER", "PENALTY",
            "STOK", "RACKET", "HELM", "GOUD", "ZILVER", "BRONS", "TROFEE",
            "RECORD", "FINALE", "RONDE"
        ]
    },
    {
        name: "Beroepen",
        words: [
            "ARTS", "LERAAR", "BAKKER", "SLAGER", "VISSER", "BOER", "TUINDER",
            "BLOEMIST", "KAPPER", "OBER", "POLITIE", "AGENT", "SOLDAAT",
            "PILOOT", "MATROOS", "KAPITEIN", "SCHIPPER", "MONTEUR", "ADVOCAAT",
            "RECHTER", "NOTARIS", "TANDARTS", "CHIRURG", "MEESTER", "AUTEUR",
            "DICHTER", "REPORTER", "ACTEUR", "ZANGER", "MUSICUS", "PIANIST",
            "DIRIGENT", "VIOLIST", "SCHILDER", "BAAS", "CHEF", "MANAGER",
            "KASSIER", "VERKOPER", "LASSER", "DRAAIER", "SMID", "MELKBOER",
            "VEEARTS", "HERDER", "POSTBODE", "BEZORGER", "BEWAKER", "GIDS",
            "TOLK"
        ]
    },
    {
        name: "Lichaam",
        words: [
            "HOOFD", "HAAR", "OGEN", "NEUS", "MOND", "TAND", "TONG", "LIPPEN",
            "WANG", "OORBEL", "SCHOUDER", "ELLEBOOG", "HAND", "VINGER", "DUIM",
            "NAGEL", "POLS", "BORST", "BUIK", "NAVEL", "HEUP", "BEEN", "KNIE",
            "SCHEEN", "KUIT", "ENKEL", "VOET", "TEEN", "HIEL", "HUID", "SPIER",
            "HART", "LONGEN", "LEVER", "NIEREN", "MAAG", "DARMEN", "HERSENEN",
            "ZENUW", "ADER", "BLOED", "KEEL", "STEM", "GLIMLACH", "TRAAN"
        ]
    },
    {
        name: "Kleding",
        words: [
            "BROEK", "JEANS", "SHIRT", "TRUI", "VEST", "MANTEL", "REGENJAS",
            "SJAAL", "MUTS", "HOED", "SOKKEN", "SCHOEN", "LAARS", "SANDAAL",
            "SLIPPER", "HEMD", "BLOUSE", "TOPJE", "BEHA", "LINGERIE", "JURK",
            "KIMONO", "KOSTUUM", "COLBERT", "STROPDAS", "WANTEN", "RIEM",
            "GORDEL", "GESP", "KNOOP", "RITS", "ZAKDOEK", "BEURS", "RUGZAK",
            "KOFFER", "KLEDING", "MODE", "KATOEN", "ZIJDE", "LEER"
        ]
    },
    {
        name: "Vervoer",
        words: [
            "AUTO", "FIETS", "MOTOR", "SCOOTER", "BROMMER", "TREIN", "TRAM",
            "METRO", "TAXI", "RAKET", "BOOT", "SCHIP", "ZEILBOOT", "ROEIBOOT",
            "PONT", "VEERBOOT", "TRUCK", "BUSJE", "STATION", "PERRON", "SPOOR",
            "STEP", "SKELTER", "FIETSPAD", "BRUG", "TUNNEL", "VIADUCT",
            "KRUISING", "ROTONDE", "VERKEER", "SPITS", "BENZINE", "DIESEL",
            "SNELWEG", "AUTOWEG", "VOETPAD", "OVERWEG"
        ]
    },
    {
        name: "School",
        words: [
            "SCHOOL", "KLAS", "LOKAAL", "LEERLING", "STUDENT", "BOEK", "SCHRIFT",
            "LINIAAL", "PASSER", "TELRAAM", "WISKUNDE", "BIOLOGIE", "TAAL",
            "TEKENING", "SPORTHAL", "HUISWERK", "OPDRACHT", "TOETS", "CIJFER",
            "RAPPORT", "DIPLOMA", "EXAMEN", "STUDIE", "KENNIS", "VRAAG",
            "ANTWOORD", "FOUT", "KRIJT", "STIFT", "PROEF", "THEORIE",
            "PRAKTIJK", "BEGRIP", "ZINNEN", "LETTER", "ALFABET"
        ]
    },
    {
        name: "Muziek",
        words: [
            "MUZIEK", "LIED", "ZANG", "KOOR", "ORKEST", "BAND", "SOLIST",
            "PIANO", "GITAAR", "VIOOL", "CELLO", "FLUIT", "TROMPET", "SAXOFOON",
            "KLARINET", "HARP", "TROMMEL", "ORGEL", "BANJO", "UKULELE",
            "TRIANGEL", "NOOT", "TOON", "AKKOORD", "MELODIE", "RITME",
            "HARMONIE", "TEMPO", "JAZZ", "ROCK", "BLUES", "KLASSIEK", "OPERA",
            "MUSICAL", "CONCERT", "FESTIVAL", "OPTREDEN", "PUBLIEK", "PODIUM",
            "APPLAUS", "SOLO", "DUET", "TRIO", "KWARTET", "KARAOKE"
        ]
    },
    {
        name: "Kleuren",
        words: [
            "ROOD", "BLAUW", "GROEN", "GEEL", "ORANJE", "PAARS", "ROZE", "BRUIN",
            "ZWART", "GRIJS", "BEIGE", "TURKOOIS", "LILA", "DONKER", "LICHT",
            "HELDER", "ROND", "VIERKANT", "DRIEHOEK", "OVAAL", "CIRKEL", "KUBUS",
            "PIJL", "STREEP", "STIP", "LIJN", "HOEK", "RAND", "VLAK", "PUNT",
            "KRUL", "SPIRAAL", "RUIT", "PATROON", "FIGUUR", "VORM"
        ]
    },
    {
        name: "Stad",
        words: [
            "STAD", "DORP", "WIJK", "BUURT", "STRAAT", "LAAN", "PLEIN", "MARKT",
            "KERK", "MOLEN", "MUSEUM", "THEATER", "BIOSCOOP", "HOTEL", "APOTHEEK",
            "BAKKERIJ", "HAVEN", "KASTEEL", "PALEIS", "TOREN", "STADHUIS",
            "GEMEENTE", "LAND", "REGIO", "GEBIED", "CENTRUM", "FABRIEK",
            "KANTOOR", "WINKEL", "LANTAARN", "TERRAS", "INWONER", "BEWONER",
            "BEZOEKER", "TOERIST", "BUURMAN"
        ]
    },
    {
        name: "Werkwoorden",
        words: [
            "LOPEN", "PRATEN", "SLAPEN", "WERKEN", "MAKEN", "DOEN", "ETEN",
            "DRINKEN", "LEZEN", "GEVEN", "NEMEN", "BRENGEN", "HALEN", "ZOEKEN",
            "VINDEN", "HELPEN", "BELLEN", "SPREKEN", "KIJKEN", "HOREN", "VOELEN",
            "RUIKEN", "PROEVEN", "KOKEN", "BAKKEN", "SNIJDEN", "WASSEN",
            "STRIJKEN", "POETSEN", "WACHTEN", "RUSTEN", "DROMEN", "LACHEN",
            "HUILEN", "ZINGEN", "DANSEN", "TEKENEN", "BOUWEN", "TIMMEREN",
            "WINNEN", "STUREN", "RIJDEN", "VLIEGEN", "LANDEN", "STOPPEN",
            "DRAAIEN", "TILLEN", "DUWEN", "TREKKEN", "GOOIEN", "VANGEN",
            "VALLEN", "GLIJDEN", "KRUIPEN", "SCHUDDEN", "ZWAAIEN", "ROEPEN",
            "VRAGEN", "DENKEN", "WETEN", "LEREN", "STUDEREN", "OEFENEN",
            "VERGETEN", "SNAPPEN", "ZEGGEN", "TELLEN", "REKENEN", "METEN",
            "KOPEN", "BETALEN", "SPAREN", "OPENEN", "SLUITEN", "ZETTEN",
            "LEGGEN", "STAAN", "ZITTEN", "LIGGEN", "BEWEGEN", "ADEMEN", "GAPEN"
        ]
    },
    {
        // "Alles" heeft geen eigen lijst: alle categorieen samen.
        name: "Alles",
        words: []
    }
];

function shuffle(arr) {
    var a = arr.slice();
    for (var i = a.length - 1; i > 0; i--) {
        var j = Math.floor(Math.random() * (i + 1));
        var t = a[i];
        a[i] = a[j];
        a[j] = t;
    }
    return a;
}

function allWords() {
    var out = [];
    for (var i = 0; i < CATEGORIES.length; i++) {
        var w = CATEGORIES[i].words;
        for (var j = 0; j < w.length; j++) {
            if (out.indexOf(w[j]) < 0) out.push(w[j]);
        }
    }
    return out;
}

function pickWords(categoryIndex, count) {
    var pool;
    if (categoryIndex < 0 || categoryIndex >= CATEGORIES.length || CATEGORIES[categoryIndex].words.length === 0) {
        pool = allWords();
    } else {
        pool = CATEGORIES[categoryIndex].words;
    }
    var shuffled = shuffle(pool);
    var picked = [];
    for (var i = 0; i < shuffled.length && picked.length < count; i++) {
        if (picked.indexOf(shuffled[i]) < 0) picked.push(shuffled[i]);
    }
    return picked;
}

// Plaatst de woorden in het rooster (horizontaal, verticaal en diagonaal,
// beide richtingen). Woorden die na veel pogingen niet passen, vervallen.
function generate(cols, rows, wordsIn) {
    var words = wordsIn.slice();
    words.sort(function (a, b) { return b.length - a.length; });

    var dirs = [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]];

    var grid = [];
    for (var r = 0; r < rows; r++) {
        var rowArr = [];
        for (var c = 0; c < cols; c++) rowArr.push("");
        grid.push(rowArr);
    }

    var placements = [];
    for (var w = 0; w < words.length; w++) {
        var word = words[w];
        var placed = false;
        for (var attempt = 0; attempt < 600 && !placed; attempt++) {
            var d = dirs[Math.floor(Math.random() * dirs.length)];
            var dc = d[0];
            var dr = d[1];
            var c0 = Math.floor(Math.random() * cols);
            var r0 = Math.floor(Math.random() * rows);
            var cEnd = c0 + dc * (word.length - 1);
            var rEnd = r0 + dr * (word.length - 1);
            if (cEnd < 0 || cEnd >= cols || rEnd < 0 || rEnd >= rows) continue;

            var ok = true;
            for (var i = 0; i < word.length; i++) {
                var cc = c0 + dc * i;
                var rr = r0 + dr * i;
                var existing = grid[rr][cc];
                if (existing !== "" && existing !== word.charAt(i)) {
                    ok = false;
                    break;
                }
            }
            if (!ok) continue;

            var cells = [];
            for (i = 0; i < word.length; i++) {
                var cc2 = c0 + dc * i;
                var rr2 = r0 + dr * i;
                grid[rr2][cc2] = word.charAt(i);
                cells.push([cc2, rr2]);
            }
            placements.push({ word: word, cells: cells });
            placed = true;
        }
    }

    // Lege vakjes vullen met letters die lijken op de puzzelletters.
    var puzzleLetters = "";
    for (r = 0; r < rows; r++) {
        for (c = 0; c < cols; c++) {
            if (grid[r][c] !== "") puzzleLetters += grid[r][c];
        }
    }
    var filler = "EEENNNAAARRRTTTIIOOOSSLDDGGVVKKMMBBPPUUFFHHJJZZWWCCXXYYQ";
    var pool = puzzleLetters + puzzleLetters + filler;

    for (r = 0; r < rows; r++) {
        for (c = 0; c < cols; c++) {
            if (grid[r][c] === "") {
                grid[r][c] = pool.charAt(Math.floor(Math.random() * pool.length));
            }
        }
    }

    return { grid: grid, placements: placements };
}
