// Genereert Woordladder-puzzels uit de Woordzoeker-woordenlijsten.
// Gebruik:  node tools/make_ladder_puzzles.js
//
// Een ladder: van het ene woord naar het andere, elke stap precies één
// letter veranderen, alles binnen de woordenlijsten. Er worden paren
// gezocht met een kortste route van 3 t/m 5 stappen.

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const src = fs.readFileSync(path.join(root, "app/ui/WoordzoekerLogic.js"), "utf8");
const categories = new Function(src + "\nreturn CATEGORIES;")();

const all = [];
for (const cat of categories) {
    for (const w of cat.words) {
        if (all.indexOf(w) < 0) all.push(w);
    }
}

function diff(a, b) {
    let n = 0;
    for (let i = 0; i < a.length; i++) {
        if (a[i] !== b[i]) n++;
    }
    return n;
}

function buildGraph(len) {
    const words = all.filter(w => w.length === len);
    const adj = new Map(words.map(w => [w, []]));
    for (let i = 0; i < words.length; i++) {
        for (let j = i + 1; j < words.length; j++) {
            if (diff(words[i], words[j]) === 1) {
                adj.get(words[i]).push(words[j]);
                adj.get(words[j]).push(words[i]);
            }
        }
    }
    return { words, adj };
}

function bfsPath(adj, from, to) {
    const prev = new Map([[from, null]]);
    const queue = [from];
    while (queue.length) {
        const w = queue.shift();
        if (w === to) {
            const p = [];
            let c = w;
            while (c !== null) {
                p.push(c);
                c = prev.get(c);
            }
            return p.reverse();
        }
        for (const n of adj.get(w)) {
            if (!prev.has(n)) {
                prev.set(n, w);
                queue.push(n);
            }
        }
    }
    return null;
}

function shuffleArray(a) {
    for (let i = a.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [a[i], a[j]] = [a[j], a[i]];
    }
    return a;
}

function pickPairs(graph, len, count) {
    const words = shuffleArray(graph.words.slice());
    const out = [];
    const seen = new Set();
    const minDist = len === 5 ? 2 : 3;
    for (const a of words) {
        const others = shuffleArray(graph.words.filter(b => b !== a));
        for (const b of others) {
            const key = [a, b].sort().join("-");
            if (seen.has(key)) continue;
            const p = bfsPath(graph.adj, a, b);
            if (p && p.length - 1 >= minDist && p.length - 1 <= 5) {
                seen.add(key);
                out.push({ len, from: a, to: b });
                break;
            }
        }
        if (out.length >= count) break;
    }
    return out;
}

const g4 = buildGraph(4);
const g5 = buildGraph(5);

const puzzles = [];
puzzles.push(...pickPairs(g4, 4, 30));
puzzles.push(...pickPairs(g5, 5, 15));

const out = "// Automatisch gegenereerd met tools/make_ladder_puzzles.js - niet handmatig aanpassen.\n"
    + "var LADDER_WORDS_4 = " + JSON.stringify(g4.words) + ";\n"
    + "var LADDER_WORDS_5 = " + JSON.stringify(g5.words) + ";\n"
    + "var LADDER_PUZZLES = " + JSON.stringify(puzzles) + ";\n";
fs.writeFileSync(path.join(root, "app/ui/WoordladderPuzzles.js"), out);

console.log("4-letterwoorden:", g4.words.length, "| 5-letterwoorden:", g5.words.length);
console.log("Puzzels:", puzzles.length);
console.log("Voorbeeld:", JSON.stringify(puzzles[0]));
