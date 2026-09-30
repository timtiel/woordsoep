#!/usr/bin/env python3
"""Genereert het app-icoon (app/icon.png) - puur met de standaardbibliotheek.

Het icoon: een donkere tegel met een kom lettersoep (romige soep met gouden
rand) waar twee gouden letterblokjes met een W en een S uit komen - passend
bij de naam Woordsoep.
"""
import os
import struct
import zlib

SIZE = 256
SS = 3                      # supersampling voor gladde randen
INK = (32, 32, 28, 255)
CREAM = (246, 243, 236, 255)
GOLD = (201, 162, 39, 255)

GLYPH_W = [
    "#...#",
    "#...#",
    "#.#.#",
    "#.#.#",
    "#.#.#",
    "##.##",
    "#...#",
]
GLYPH_S = [
    ".###.",
    "#...#",
    "#....",
    ".###.",
    "....#",
    "#...#",
    ".###.",
]


def rounded_contains(x, y, x0, y0, x1, y1, r):
    if x < x0 or x > x1 or y < y0 or y > y1:
        return False
    cx = min(max(x, x0 + r), x1 - r)
    cy = min(max(y, y0 + r), y1 - r)
    dx = x - cx
    dy = y - cy
    return dx * dx + dy * dy <= r * r


def sample(x, y):
    """Kleur van één subsample-pixel van het icoon."""
    # gouden letterblokjes (met donkere rand) liggen bovenop de kom
    for tx, ty, glyph in ((48, 78, GLYPH_W), (150, 60, GLYPH_S)):
        if rounded_contains(x, y, tx, ty, tx + 57, ty + 57, 16):
            if not rounded_contains(x, y, tx + 4, ty + 4, tx + 53, ty + 53, 12):
                return INK
            s = 6
            gx = tx + (58 - 5 * s) // 2
            gy = ty + (58 - 7 * s) // 2
            col = (x - gx) // s
            row = (y - gy) // s
            if 0 <= col < 5 and 0 <= row < 7 and glyph[int(row)][int(col)] == "#":
                return INK
            return GOLD

    # gouden rand van de kom
    if rounded_contains(x, y, 36, 120, 220, 144, 12):
        return GOLD

    # soep: onderste deel van een ellips (het kommetje)
    if y >= 134 and ((x - 128) / 86) ** 2 + ((y - 146) / 72) ** 2 <= 1:
        return CREAM

    # donkere tegel als achtergrond
    if rounded_contains(x, y, 1, 1, SIZE - 2, SIZE - 2, 54):
        return INK

    return (0, 0, 0, 0)


def make_icon_pixels():
    img = [(0, 0, 0, 0)] * (SIZE * SIZE)
    n = SS * SS
    for py in range(SIZE):
        for px in range(SIZE):
            r = g = b = a = 0
            for sy in range(SS):
                for sx in range(SS):
                    c = sample(px + (sx + 0.5) / SS, py + (sy + 0.5) / SS)
                    r += c[0]
                    g += c[1]
                    b += c[2]
                    a += c[3]
            img[py * SIZE + px] = (r // n, g // n, b // n, a // n)
    return img


def write_png(path, pixels, size):
    raw = bytearray()
    for y in range(size):
        raw.append(0)  # filter: none
        row = pixels[y * size:(y + 1) * size]
        for p in row:
            raw.extend(p)

    def chunk(tag, data):
        out = struct.pack(">I", len(data)) + tag + data
        return out + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", size, size, 8, 6, 0, 0, 0)
    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", ihdr)
    png += chunk(b"IDAT", zlib.compress(bytes(raw), 9))
    png += chunk(b"IEND", b"")

    with open(path, "wb") as f:
        f.write(png)


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    out = os.path.join(root, "app", "icon.png")
    write_png(out, make_icon_pixels(), SIZE)
    print("Icoon geschreven naar %s" % out)


if __name__ == "__main__":
    main()
