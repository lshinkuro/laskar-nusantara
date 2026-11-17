#!/usr/bin/env python3
"""Bikin sprite pixel art dari peta ASCII ke assets/sprites/*.png.

Edit peta atau palet di bawah, lalu jalankan:  python3 tools/make_sprites.py
Tiap karakter di peta = 1 piksel; '.' = transparan.
"""
import os
import struct
import zlib

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

BASE = {
    "k": "1a120b",  # garis luar
    "s": "c68642",  # kulit
    "S": "9a6532",  # bayangan kulit
    "w": "f3e3c3",  # putih / mata
    "g": "e0b04a",  # emas
    "c": "3b2a1a",  # kain gelap
    "b": "7a4a22",  # kayu / gagang
    "m": "b8c0c8",  # logam terang
    "M": "6b737d",  # logam gelap
    "d": "3a3f47",  # seragam besi
    "r": "e03030",  # merah
    "p": "d9b38c",  # kulit pucat
    "o": "c8742c",  # oranye pala
    "O": "8a4a1c",  # cokelat pala
    "R": "b0201c",  # merah fuli
    "y": "f0d860",  # kuning
    "e": "6a3a14",  # cokelat batu
    "E": "4a2a10",  # cokelat batu gelap
}

# Prajurit Nusantara (menghadap kanan). 'h' = udeng, 'C' = selendang (warna kerajaan).
PRAJURIT = """
................
.....kkkkk......
....khhhhhk.....
...khhhhhhhkk...
...kkssssskhhk..
....ksswskk.k...
....kssssk......
...kkgCCCgkk....
..kskcCCCcksk...
..kskcgcgcks k..
..kk.cCCCck.kmk.
....kccccck.kmk.
....kss.ssk..b..
....kSs.sSk..b..
....kkk.kkk.....
................
"""

KERAJAAN = {
    "majapahit": {"h": "b0201c", "C": "e0b04a"},
    "sriwijaya": {"h": "2a5fb0", "C": "f3e3c3"},
    "mataram":   {"h": "2f7a3a", "C": "e0b04a"},
    "pajajaran": {"h": "6a2f8a", "C": "f0d860"},
}

SERDADU_BESI = """
.......kk.......
......kmmk......
.....kmmmmk.....
....kmmmmmmk....
....kMMMMMMk....
....krrkkrrk....
....kppppppk....
...kkddddddkk...
..kdkdMMMMdkdk..
..kdkdmddmdkdk..
..kk.dddddd.kkkk
.....dMMMMd.kmmk
....kdd..ddk....
....kdd..ddk....
....kkk..kkk....
................
"""

REMPAH = """
..kkkk..
.kRooRk.
kRoooORk
koooOOok
koRoOOok
kRooOORk
.kOOOOk.
..kkkk..
"""

PELURU = {
    "sumpit": """
.......k
kkkkkkwk
.......k
""",
    "batu": """
.kkk.
keeEk
keEEk
kEEEk
.kkk.
""",
    "panah": """
.......kk.
kbbbbbbmmk
.......kk.
""",
    "meriam": """
..kkk..
.kMMMk.
kMmMMMk
kMMMMMk
kMMMMMk
.kMMMk.
..kkk..
""",
    "keris": """
..k.k.k...
kbkmkmkmk.
kbmmmmmmmk
kbkmkmkmk.
..k.k.k...
""",
    "cakra": """
..kkkk..
.kgyygk.
kgk..kgk
kyk..kyk
kyk..kyk
kgk..kgk
.kgyygk.
..kkkk..
""",
    "api": """
..rr..
.ryyr.
ryyyyr
ryyyyr
.rrrr.
""",
}


def png(path, rows, palette):
    rows = [r for r in rows.strip("\n").split("\n")]
    w = max(len(r) for r in rows)
    raw = b""
    for r in rows:
        raw += b"\x00"
        for ch in r.ljust(w, "."):
            if ch in ". ":
                raw += b"\x00\x00\x00\x00"
            else:
                raw += bytes.fromhex(palette[ch]) + b"\xff"

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    data = b"\x89PNG\r\n\x1a\n"
    data += chunk(b"IHDR", struct.pack(">IIBBBBB", w, len(rows), 8, 6, 0, 0, 0))
    data += chunk(b"IDAT", zlib.compress(raw, 9))
    data += chunk(b"IEND", b"")
    with open(path, "wb") as f:
        f.write(data)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, colors in KERAJAAN.items():
        png(os.path.join(OUT, f"prajurit_{name}.png"), PRAJURIT, {**BASE, **colors})
    png(os.path.join(OUT, "serdadu_besi.png"), SERDADU_BESI, BASE)
    png(os.path.join(OUT, "rempah.png"), REMPAH, BASE)
    for name, rows in PELURU.items():
        png(os.path.join(OUT, f"peluru_{name}.png"), rows, BASE)
    print("sprite dibuat di", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
