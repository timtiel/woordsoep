#!/usr/bin/env python3
"""Controleert de woordenlijsten in app/ui/WoordzoekerLogic.js en WoordleLogic.js.

- Woordzoeker: alle woorden 4-8 letters, alleen A-Z, geen dubbele woorden.
- Woordle: alle woorden precies 5 letters, alleen A-Z, geen dubbele woorden.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ZOEKER = os.path.join(ROOT, "app", "ui", "WoordzoekerLogic.js")
WOORDLE = os.path.join(ROOT, "app", "ui", "WoordleLogic.js")

TOKEN = re.compile(r'"([A-Z]+)"')


def read(path):
    with open(path, "r", encoding="utf-8") as f:
        return f.read()


def main():
    problems = []

    z_src = read(ZOEKER)
    w_src = read(WOORDLE)

    z_tokens = TOKEN.findall(z_src)
    FILLER = "EEENNNAAARRRTTTIIOOOSSLDDGGVVKKMMBBPPUUFFHHJJZZWWCCXXYYQ"
    bad_tokens = sorted({t for t in z_tokens if t != FILLER and (len(t) < 4 or len(t) > 8)})
    if bad_tokens:
        problems.append("Woordzoeker: woorden buiten 4-8 letters: %s" % ", ".join(bad_tokens))
    z_words = [t for t in z_tokens if 4 <= len(t) <= 8]
    dup = sorted({w for w in z_words if z_words.count(w) > 1})
    if dup:
        problems.append("Woordzoeker: dubbele woorden: %s" % ", ".join(dup))

    name_positions = [(m.start(), m.group(1)) for m in re.finditer(r'name:\s*"([^"]+)"', z_src)]
    cat_counts = []
    for i, (pos, nm) in enumerate(name_positions):
        end = name_positions[i + 1][0] if i + 1 < len(name_positions) else len(z_src)
        seg = z_src[pos:end]
        cat_counts.append((nm, len([t for t in TOKEN.findall(seg) if 4 <= len(t) <= 8])))
    for nm, cnt in cat_counts:
        if nm != "Alles" and cnt < 30:
            problems.append("Categorie %s heeft maar %d woorden" % (nm, cnt))

    w_words = TOKEN.findall(w_src)
    for w in w_words:
        if len(w) != 5:
            problems.append("Woordle: woord is geen 5 letters: %s (%d)" % (w, len(w)))
    dupw = sorted({w for w in w_words if w_words.count(w) > 1})
    if dupw:
        problems.append("Woordle: dubbele woorden: %s" % ", ".join(dupw))

    print("Categorieen (%d):" % len(cat_counts))
    for nm, cnt in cat_counts:
        print("  %-12s %3d" % (nm, cnt))
    print("Woordzoeker: %d woorden" % len(z_words))
    print("Woordle:     %d woorden" % len(w_words))

    if problems:
        print("\nPROBLEMEN:")
        for p in problems:
            print(" - " + p)
        sys.exit(1)
    print("\nAlles in orde.")


if __name__ == "__main__":
    main()
