// test_logic.js - snelle test van de spellogica met Node.js.
// Gebruik: node tools/test_logic.js
"use strict";

const fs = require("fs");
const path = require("path");

const ROOT = path.join(__dirname, "..");

function loadModule(file) {
    const src = fs.readFileSync(file, "utf8");
    const factory = new Function(
        src +
        "\nreturn {" +
        " CATEGORIES: typeof CATEGORIES !== 'undefined' ? CATEGORIES : null," +
        " WORDS: typeof WORDS !== 'undefined' ? WORDS : null," +
        " generate: typeof generate !== 'undefined' ? generate : null," +
        " pickWords: typeof pickWords !== 'undefined' ? pickWords : null," +
        " pickWord: typeof pickWord !== 'undefined' ? pickWord : null," +
        " score: typeof score !== 'undefined' ? score : null," +
        "};"
    );
    return factory();
}

const ZL = loadModule(path.join(ROOT, "app", "ui", "WoordzoekerLogic.js"));
const WL = loadModule(path.join(ROOT, "app", "ui", "WoordleLogic.js"));

let failures = 0;
function check(cond, msg) {
    if (!cond) {
        failures++;
        console.log("FOUT: " + msg);
    }
}

function sameMarks(a, b) {
    if (a.length !== b.length) return false;
    for (let i = 0; i < a.length; i++) if (a[i] !== b[i]) return false;
    return true;
}

// ---- Woordle score ----
check(sameMarks(WL.score("APPEL", "APPEL"), [2, 2, 2, 2, 2]), "score APPEL/APPEL");
check(sameMarks(WL.score("PAARD", "AAPJE"), [1, 2, 1, 0, 0]), "score PAARD/AAPJE");
check(sameMarks(WL.score("APPEL", "PALEN"), [1, 1, 1, 2, 0]), "score APPEL/PALEN");
check(sameMarks(WL.score("BROOD", "DROOM"), [1, 2, 2, 2, 0]), "score BROOD/DROOM");
check(WL.WORDS.length >= 400, "Woordle-lijst heeft minstens 400 woorden");
check(WL.WORDS.every(w => w.length === 5), "alle Woordle-woorden zijn 5 letters");

// ---- Woordzoeker: elke categorie ----
for (let cat = 0; cat < ZL.CATEGORIES.length; cat++) {
    const name = ZL.CATEGORIES[cat].name;
    if (cat < ZL.CATEGORIES.length - 1) {
        check(ZL.CATEGORIES[cat].words.length >= 30,
              name + ": minstens 30 woorden in de categorie");
    }

    for (let run = 0; run < 40; run++) {
        const words = ZL.pickWords(cat, 12);
        check(words.length === 12, name + ": pickWords geeft 12 woorden");

        const puzzle = ZL.generate(10, 12, words);
        check(puzzle.grid.length === 12 && puzzle.grid[0].length === 10,
              name + ": rooster is 10x12");
        check(puzzle.placements.length >= 10,
              name + ": minstens 10 woorden geplaatst (was " + puzzle.placements.length + ")");

        const seen = {};
        for (const p of puzzle.placements) {
            check(words.indexOf(p.word) >= 0, name + ": geplaatst woord komt uit de lijst");
            check(!seen[p.word], name + ": woord maar een keer geplaatst: " + p.word);
            seen[p.word] = true;

            // letters op de juiste plek?
            for (let i = 0; i < p.word.length; i++) {
                const c = p.cells[i][0], r = p.cells[i][1];
                check(puzzle.grid[r][c] === p.word.charAt(i),
                      name + ": lettercontrole " + p.word);
            }
            // cellen in het rooster?
            for (const cell of p.cells) {
                check(cell[0] >= 0 && cell[0] < 10 && cell[1] >= 0 && cell[1] < 12,
                      name + ": cel binnen het rooster");
            }
        }
        // geen lege cellen?
        for (let r = 0; r < 12; r++) {
            for (let c = 0; c < 10; c++) {
                check(puzzle.grid[r][c] !== "", name + ": geen lege cellen");
            }
        }
    }
}

console.log(ZL.CATEGORIES.length + " categorieen, 40 puzzels per categorie getest.");
console.log(WL.WORDS.length + " Woordle-woorden gecontroleerd.");

if (failures > 0) {
    console.log("\n" + failures + " probleem(en) gevonden.");
    process.exit(1);
} else {
    console.log("\nAlle tests geslaagd.");
}
