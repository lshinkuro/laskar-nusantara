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
    "G": "6aa040",  # hijau janur
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

# Seragam per kerajaan: h = udeng, C = selendang, c = kain/celana.
KERAJAAN = {
    "majapahit":     {"h": "b0201c", "C": "e0b04a"},
    "sriwijaya":     {"h": "2a5fb0", "C": "f3e3c3"},
    "mataram":       {"h": "2f7a3a", "C": "e0b04a"},
    "pajajaran":     {"h": "6a2f8a", "C": "f0d860"},
    "samudra_pasai": {"h": "1a1a1a", "C": "c02828", "c": "2a2a2a"},
    "gowa":          {"h": "e0b04a", "C": "8a1a6a", "c": "5a1440"},
    "kutai":         {"h": "e07a20", "C": "1a1a1a", "c": "7a3a14"},
    "ternate":       {"h": "f3e3c3", "C": "2a8a8a", "c": "1a4a5a"},
}

# Potret karakter (menu pilih karakter): template PRAJURIT dengan penutup kepala sendiri
# (4 baris teratas diganti) dan warna sendiri. h = penutup kepala, C = selendang, c = kain,
# s/S = kulit, m = bilah senjata.
KEPALA = {
    "udeng": None,  # pakai baris asli PRAJURIT
    "caping": ["......kkkk......", "....khhhhhhk....", ".kkhhhhhhhhhhkk.", "...kkssssskk...."],
    "songkok": ["....kkkkkk......", "....khhhhhk.....", "....khhhhhk.....", "...kkssssskk...."],
    "sanggul": ["......kkk.......", "....kkhhhkrk....", "...khhhhhhkrk...", "...kkssssshhk..."],
    "bulu": ["....k.k.k.......", "...kwkwkwk......", "...khhhhhhkk....", "...kkssssskk...."],
    "mahkota": ["....k.k.k.......", "...kgkgkgk......", "...khhhhhhk.....", "...kkssssskk...."],
}

KARAKTER = {
    "pendekar_silat":      ("udeng",   {"h": "1a1a1a", "C": "b0201c", "c": "2a2a2a"}),
    "petani":              ("caping",  {"h": "d8b860", "C": "6aa040", "c": "5a4a2a", "m": "8a8a8a"}),
    "dukun":               ("udeng",   {"h": "4a2a5a", "C": "9a4ab0", "c": "2a1a2a", "m": "f07a20"}),
    "pelaut_bugis":        ("songkok", {"h": "c02828", "C": "f3e3c3", "c": "2a4a7a"}),
    "penari_jaipong":      ("sanggul", {"h": "1a1a1a", "C": "e04a8a", "c": "d0306a", "s": "d9a070"}),
    "pemburu_dayak":       ("bulu",    {"h": "c02828", "C": "1a1a1a", "c": "6a2a1a", "s": "a86a32"}),
    "pecalang_bali":       ("udeng",   {"h": "f3e3c3", "C": "1a1a1a", "c": "3a3a3a"}),
    "saudagar_minang":     ("songkok", {"h": "e0b04a", "C": "8a1a1a", "c": "3a1a10"}),
    "jawara_betawi":       ("songkok", {"h": "1a1a1a", "C": "c02828", "c": "1a1a1a", "S": "7a4a22"}),
    "senopati_majapahit":  ("mahkota", {"h": "b0201c", "C": "e0b04a", "c": "5a1414"}),
}


def potret(kepala):
    rows = PRAJURIT.strip("\n").split("\n")
    if KEPALA[kepala]:
        rows[1:5] = KEPALA[kepala]
        rows[5] = rows[5][:11] + "....."  # buang ekor udeng
    return "\n".join(rows)


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

# Musuh tambahan Kekaisaran Besi.
ANJING = """
................
................
................
................
...........kk...
..........kMMk..
.k........kMrMk.
kMk.......kMMMMk
.kMkkkkkkkkMMkk.
..kMMMMMMMMMMk..
..kMMMMMMMMMk...
..kMkMk..kMkMk..
..kMkMk..kMkMk..
..kkkkk..kkkkk..
................
................
"""

PENEMBAK = """
................
.....kkkkk......
....kddddddk....
...kkkkkkkkkk...
....krrkkrrk....
....kppppppk....
...kkddddddkk...
..kdkdMMMMdkkkkkk
..kdkdmddmdkMMMMk
..kk.ddddddkkkkkk
.....dMMMMd.....
....kdd..ddk....
....kdd..ddk....
....kdd..ddk....
....kkk..kkk....
................
"""

PERISAI = """
................
......kkkk......
.....kmmmmk.....
....kmmmmmmk....
....kMMMMMMk....
....krrkkrrk..k.
...kkppppppk.kmk
..kddddddddkkmMk
..kdddMMMddkmmMk
..kdddddddkkmyMk
..kdddMMMddkmmMk
..kddddddddkkmMk
...kdd..ddk..kmk
...kdd..ddk...k.
...kkk..kkk.....
................
"""

TUKANG_RANJAU = """
................
.....kkkkk......
....kmmmmmk.....
....kMMMMMk.....
....krrkkrk.....
....kppppk......
...kkddddkk.....
..kdkddddkdk....
..kdkdMMdkdk....
..kk.dddd.kk....
.kOOk.dd..kk....
kOooOk.dd.......
kOooOkdd.dd.....
.kOOk.kk.kk.....
................
................
"""

RANJAU = """
...kk...
..krrk..
.kMMMMk.
kMmMMmMk
kMMMMMMk
.kMMMMk.
..kkkk..
"""

KOMANDAN = """
.......kk.......
......kggk......
.....kggggk.....
....kggggggk....
....kMMMMMMk....
....krrkkrrk....
....kppppppk....
...kkRRRRRRkk...
..kdkRgRRgRkdk..
..kdkRRRRRRkdk..
..kk.RRRRRR.kkkk
.....dMMMMd.kmmk
....kdd..ddk....
....kdd..ddk....
....kkk..kkk....
................
"""

MANDOR = """
................
...kkkkkkkkkk...
....kOOOOOOk....
.....kOOOOk.....
....kppppppk....
....kpkppkpk....
....kppkkppk....
...kkwwwwwwkk...
..kpkwwwwwwkpk.k
..kpkwwkkwwkpkek
..kk.wwwwwwkkek.
.....OOOOOO.ke..
....kOO..OOkk...
....kOO..OOk....
....kkk..kkk....
................
"""

GUBERNUR = """
......rrr.......
.....rrrrk......
......kgk.......
.....kgggk......
....kMMMMMk.....
....krrkkrrk....
....kppppppk....
....kpkkkkpk....
.kRRkddddddkRRk.
kRRkdgdyydgdkRRk
kRRkdddyydddkRRk
kRRkdgddddgdkRRk
kRRk.dddddd.kRRk
.kk.kdd..ddk.kk.
....kdd..ddk....
....kkk..kkk....
"""

WAYANG = """
....kk....
...kggk...
..kgyygk..
..kgkkgk..
...kggk...
..kRRRRk..
.kRgRRgRk.
kgkRRRRkgk
kgkRgRRkgk
.k.kRRk.k.
...kRRk...
...kRRk...
..kgk.kgk.
..kgk.kgk.
...k...k..
"""

WARGA = """
................
.....kkkkkk.....
...kkOOOOOOkk...
..kOOOOOOOOOOk..
...kkkssskkk....
....ksswssk.....
....kssssk......
...kkwwwwwkk....
..kskwRwRwksk...
..kskwwwwwksk...
..kk.wRwRw.kk...
.....wwwww......
....kcc.cck.....
....kss.ssk.....
....kkk.kkk.....
................
"""

PETI_PUSAKA = """
.kkkkkkkkkk.
kOOOOOOOOOOk
kOggggggggOk
kOOOOOOOOOOk
kkkkkkkkkkkk
kOOOOkkOOOOk
kOOOkyykOOOk
kOOOOkkOOOOk
kggggggggggk
kkkkkkkkkkkk
"""

IKON_HATI = """
.kk.kk.
krrkrrk
krwrrrk
krrrrrk
.krrrk.
..krk..
...k...
"""

IKON_BENDERA = """
kkkkkkk.
krrrrrrk
krrrrrrk
kwwwwwwk
kwwwwwwk
kkkkkkk.
k.......
k.......
"""

IKON_BINTANG = """
...k...
..kyk..
kkyyykk
.kyyyk.
..kyk..
.kk.kk.
"""

KAVALERI = """
......kkk.......
.....kmmmk......
.....krrkk......
.....kppk.......
....kddddk......
...kkdMMdkkkkkk.
..kOOOdddOOOOOOk
.kOOOOOOOOOOOkOk
kOkkOOOOOOOOOkkk
.k.kOOOOOOOOk...
...kOk.kk.kOk...
...kOk....kOk...
...kkk....kkk...
................
"""

GRANAT = """
................
.....kkkkk......
....kmmmmmk.....
....kMMMMMk.....
....krrkrrk.kk..
....kppppk.kMMk.
...kkddddkkkMMk.
..kdkdMMdkdkkk..
..kdkdddddk.....
..kk.dMMd.k.....
.....ddddd......
....kdd.ddk.....
....kdd.ddk.....
....kkk.kkk.....
................
................
"""

TABIB = """
................
.....kkkkk......
....kGGGGGk.....
....kGGGGGk.....
....krrkrrk.....
....kppppk...kk.
...kkGGGGkk.kyyk
..kGkGwwGkGkkyyk
..kGkGwwGkGk.kk.
..kk.GGGG.kk....
.....GGGGG......
....kGG.GGk.....
....kdd.ddk.....
....kkk.kkk.....
................
................
"""

RAKSASA = """
....kkkkkkkk....
...kMMMMMMMMk...
..kMmmmmmmmmMk..
..kMrrkMMkrrMk..
..kMMMMMMMMMMk..
.kkkMMMMMMMMkkk.
kMMkMmMMMMmMkMMk
kMMkMMMMMMMMkMMk
kMMkMmMMMMmMkMMk
kmmkMMMMMMMMkmmk
.kk.kMMMMMMk.kk.
....kMMkkMMk....
...kMMMkkMMMk...
...kMMMkkMMMk...
...kkkkkkkkkk...
................
"""

LAKSAMANA = """
..kkkkkkkkkkk...
.kddddggdddddk..
..kkkkkkkkkkk...
....kppppppk....
....kpkppkpk....
....kppkkppk....
...kkwwwwwwkk...
.kgkddddddddkgk.
kggkdgdwwdgdkggk
.kkkddddddddkkk.
..kpkddyyddkpk..
..kk.dddddd.kk..
....kdd..ddk....
....kdd..ddk....
....kkk..kkk....
................
"""

PELURU_MUSUH = """
.kkk.
krrrk
krykk
krrrk
.kkk.
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

# Variasi rempah yang jatuh dari musuh (nilainya sama, cuma tampilan).
REMPAH_LAIN = {
    "cengkeh": """
.k.kk.k.
kOkOOkOk
.kOOOOk.
..kOOk..
...kOk..
...kOk..
...kOk..
....k...
""",
    "lada": """
.kkk....
kccck...
kcMckkk.
.kkkccck
.kkkcMck
kccckkk.
kcMck...
.kkk....
""",
    "kayu_manis": """
........
.kkkkkk.
kOooooOk
kOOOOOOk
kOooooOk
kOOOOOOk
.kkkkkk.
........
""",
    "bunga_lawang": """
...kk...
..kOOk..
kkkOOkkk
kOOooOOk
kOOooOOk
kkkOOkkk
..kOOk..
...kk...
""",
    "kepeng": """
..kkkk..
.kgyygk.
kgyyyygk
kgykkygk
kgykkygk
kgyyyygk
.kggggk.
..kkkk..
""",
}

# Meriam Jaga (item turret): meriam di atas kereta kayu, menghadap kanan.
MERIAM_JAGA = """
..............
.....kkkkkkkk.
...kkMmmmmmmMk
..kMMmmmmmmmMk
..kMMMMMMMMMk.
...kkkkkkkkk..
..kbbbbbbbbk..
.kbkkbbbbkkbk.
.kkEEkkkkEEkk.
..kEEk..kEEk..
...kk....kk...
"""

KETUPAT = """
...kk...
..kgyk..
.kgyygk.
kgyGyygk
kyygyyGk
.kGyygk.
..kgyk..
...kk...
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
    "kunai": """
...........
kk.....kk..
kbkkkkkmmk.
kbbbbbmmmmk
kbkkkkkmmk.
kk.....kk..
""",
    "shuriken": """
....kk....
...kmmk...
...kmmk...
kkkkMMkkkk
kmmMkkMmmk
kmmMkkMmmk
kkkkMMkkkk
...kmmk...
...kmmk...
....kk....
""",
    "tombak": """
..............kk..
kbbbbbbbbbbbkkmmk.
kbbbbbbbbbbbkmmmmk
..............kk..
""",
    "bambu_runcing": """
.............k
kGGkGGGGkGGGGy
kGGkGGGGkGGGGk
""",
    "kujang": """
..kkkk....
.kmmmmkk..
kmmkkmmmk.
kmk..kmmmk
kk....kmmk
.......kbk
.......kbk
........k.
""",
    "golok": """
....kkkkkk..
kkkkmmmmmmk.
kbbkmmmmmmmk
kkkkkkkkkkk.
""",
    "bintang": """
...k...
..kyk..
kkyyykk
.kyyyk.
..kyk..
.kk.kk.
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
    for name, (kepala, colors) in KARAKTER.items():
        png(os.path.join(OUT, f"karakter_{name}.png"), potret(kepala), {**BASE, **colors})
    png(os.path.join(OUT, "serdadu_besi.png"), SERDADU_BESI, BASE)
    for name, rows in {"anjing_pelacak": ANJING, "penembak": PENEMBAK, "serdadu_perisai": PERISAI,
                       "tukang_ranjau": TUKANG_RANJAU, "ranjau": RANJAU, "komandan_besi": KOMANDAN,
                       "mandor_kejam": MANDOR, "gubernur_jenderal": GUBERNUR,
                       "peluru_musuh": PELURU_MUSUH, "wayang": WAYANG, "warga": WARGA,
                       "kavaleri_besi": KAVALERI, "pelempar_granat": GRANAT, "tabib_besi": TABIB,
                       "raksasa_baja": RAKSASA, "laksamana_besi": LAKSAMANA,
                       "peti_pusaka": PETI_PUSAKA, "ikon_hati": IKON_HATI, "ikon_bendera": IKON_BENDERA, "ikon_bintang": IKON_BINTANG}.items():
        png(os.path.join(OUT, f"{name}.png"), rows, BASE)
    png(os.path.join(OUT, "rempah.png"), REMPAH, BASE)
    for name, rows in REMPAH_LAIN.items():
        png(os.path.join(OUT, f"rempah_{name}.png"), rows, BASE)
    png(os.path.join(OUT, "meriam_jaga.png"), MERIAM_JAGA, BASE)
    png(os.path.join(OUT, "ketupat.png"), KETUPAT, {**BASE, "g": "6aa040", "y": "c8d870"})
    for name, rows in PELURU.items():
        png(os.path.join(OUT, f"peluru_{name}.png"), rows, BASE)
    print("sprite dibuat di", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
