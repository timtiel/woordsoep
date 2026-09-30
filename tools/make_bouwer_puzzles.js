// Genereert Woordbouwer-puzzels uit de Woordzoeker-woordenlijsten.
// Gebruik:  node tools/make_bouwer_puzzles.js
//
// Een puzzel = een basiswoord (6-7 letters) plus alle woorden uit de
// lijsten die met die letters te maken zijn (minstens 4 letters).
// Alleen puzzels met 6 t/m 18 te vinden woorden worden bewaard.

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

function counts(word) {
    const m = {};
    for (const ch of word) m[ch] = (m[ch] || 0) + 1;
    return m;
}

function fits(word, base) {
    const b = counts(base);
    const m = counts(word);
    for (const ch in m) {
        if ((b[ch] || 0) < m[ch]) return false;
    }
    return true;
}

const candidates = [];
for (const base of all) {
    if (base.length < 5 || base.length > 8) continue;
    const words = all.filter(w => w.length >= 4 && fits(w, base));
    if (words.length < 6 || words.length > 18) continue;
    words.sort((a, b) => a.length - b.length || a.localeCompare(b));
    candidates.push({ letters: base, words });
}

// de rijkste puzzels eerst, dan schudden en een mooie selectie nemen
candidates.sort((a, b) => b.words.length - a.words.length);
const top = candidates.slice(0, 120);
for (let i = top.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [top[i], top[j]] = [top[j], top[i]];
}
const picked = top.slice(0, 60);

const out = "// Automatisch gegenereerd met tools/make_bouwer_puzzles.js - niet handmatig aanpassen.\n"
    + "var BOUWER_PUZZLES = " + JSON.stringify(picked) + ";\n";
fs.writeFileSync(path.join(root, "app/ui/WoordbouwerPuzzles.js"), out);

const totalWords = picked.reduce((s, p) => s + p.words.length, 0);
console.log("Kandidaten:", candidates.length, "| gekozen:", picked.length,
            "| woorden per puzzel:", (totalWords / picked.length).toFixed(1), "gemiddeld");
console.log("Voorbeeld:", picked[0].letters, "->", picked[0].words.join(", "));
