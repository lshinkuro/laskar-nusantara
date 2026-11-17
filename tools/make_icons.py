#!/usr/bin/env python3
"""Ikon item 16x16 (pixel art) ke assets/icons/*.png, digambar dari bentuk sederhana
lalu diberi garis luar hitam otomatis supaya gayanya seragam.

Jalankan:  python3 tools/make_icons.py   (lalu python3 tools/link_icons.py untuk memasang ke .tres)
"""
import math
import os
import struct
import zlib

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icons")
N = 16
OUTLINE = (26, 18, 11)


def hexc(h):
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


class Canvas:
    def __init__(self):
        self.px = [[None] * N for _ in range(N)]

    def set(self, x, y, c):
        if 0 <= x < N and 0 <= y < N:
            self.px[y][x] = hexc(c) if isinstance(c, str) else c

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.set(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(N):
            for x in range(N):
                if ((x + 0.5 - cx) / rx) ** 2 + ((y + 0.5 - cy) / ry) ** 2 <= 1.0:
                    self.set(x, y, c)

    def line(self, x0, y0, x1, y1, c):
        steps = max(abs(x1 - x0), abs(y1 - y0), 1)
        for i in range(steps + 1):
            self.set(round(x0 + (x1 - x0) * i / steps), round(y0 + (y1 - y0) * i / steps), c)

    def poly(self, pts, c):
        ys = [p[1] for p in pts]
        for y in range(min(ys), max(ys) + 1):
            xs = []
            for i in range(len(pts)):
                (xa, ya), (xb, yb) = pts[i], pts[(i + 1) % len(pts)]
                if ya != yb and min(ya, yb) <= y + 0.5 < max(ya, yb):
                    xs.append(xa + (y + 0.5 - ya) * (xb - xa) / (yb - ya))
            xs.sort()
            for a, b in zip(xs[::2], xs[1::2]):
                for x in range(math.ceil(a - 0.5), math.floor(b - 0.5) + 1):
                    self.set(x, y, c)

    def save(self, name):
        # Garis luar: piksel kosong yang bertetangga dengan isi.
        out = [row[:] for row in self.px]
        for y in range(N):
            for x in range(N):
                if self.px[y][x] is None and any(
                        0 <= x + dx < N and 0 <= y + dy < N and self.px[y + dy][x + dx] not in (None, OUTLINE)
                        for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))):
                    out[y][x] = OUTLINE
        raw = b""
        for row in out:
            raw += b"\x00" + b"".join(bytes(c) + b"\xff" if c else b"\x00\x00\x00\x00" for c in row)

        def chunk(tag, data):
            return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

        with open(os.path.join(OUT, name + ".png"), "wb") as f:
            f.write(b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N, N, 8, 6, 0, 0, 0))
                    + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b""))


# --- Templat ---------------------------------------------------------------------

def piring(food, food2=None, kind="blob"):
    c = Canvas()
    c.ellipse(8, 11, 7, 3.2, "f3ecdc")
    c.ellipse(8, 11, 5, 2, "d8d0c0")
    if kind == "blob":
        c.ellipse(8, 8.5, 4.5, 3.2, food)
        c.ellipse(6.5, 7.5, 1.8, 1.2, food2 or food)
    elif kind == "tempe":
        for i, x in enumerate((3, 7, 10)):
            c.rect(x, 6 + i % 2, x + 3, 9 + i % 2, food)
            c.set(x + 1, 7 + i % 2, food2)
    elif kind == "sate":
        for i in range(3):
            c.line(3, 10 - i * 2, 13, 4 - i * 2 + 2, "c8a060")
            for k in range(3):
                c.ellipse(6 + k * 2.5, 8.5 - i * 2 - k * 1.1 + 0.6, 1.4, 1.2, food)
    return c


def gelas(liquid, top=None, dots=None):
    c = Canvas()
    c.poly([(4, 3), (12, 3), (11, 14), (5, 14)], "dfeff2")
    c.poly([(5, 6), (11, 6), (10, 13), (6, 13)], liquid)
    c.rect(5, 6, 10, 6, top or liquid)
    if dots:
        for x, y in ((6, 9), (8, 11), (9, 8), (7, 12)):
            c.set(x, y, dots)
    c.line(5, 4, 5, 12, "ffffff")
    return c


def kain(base, stripe, pattern="garis"):
    c = Canvas()
    c.poly([(2, 4), (13, 2), (14, 12), (3, 14)], base)
    if pattern == "garis":
        for y in range(4, 14, 3):
            c.line(3, y, 13, y - 2, stripe)
    elif pattern == "parang":
        for x in range(-2, 14, 4):
            c.line(x, 13, x + 6, 3, stripe)
    elif pattern == "ikat":
        for x, y in ((5, 6), (9, 5), (6, 10), (10, 9)):
            c.poly([(x, y - 2), (x + 2, y), (x, y + 2), (x - 2, y)], stripe)
    elif pattern == "emas":
        for x in range(4, 13, 3):
            for y in range(5, 13, 3):
                c.set(x, y, stripe)
    c.line(13, 2, 14, 12, "ffffff")
    return c


def blangkon():
    c = Canvas()
    c.ellipse(8, 9, 6, 4.5, "4a3220")
    c.ellipse(8, 7.5, 5, 3, "6b4a2c")
    c.line(4, 8, 12, 8, "c8a060")
    c.ellipse(12.5, 12, 2.2, 1.8, "3b2618")
    return c


def peci():
    c = Canvas()
    c.poly([(3, 6), (13, 6), (13, 12), (3, 12)], "1c1c22")
    c.ellipse(8, 6, 5, 1.5, "2c2c34")
    c.line(4, 7, 12, 7, "3c3c48")
    return c


def cabai():
    c = Canvas()
    c.poly([(4, 4), (7, 3), (12, 10), (13, 14), (10, 12)], "d42a1c")
    c.line(5, 4, 11, 11, "ff6a50")
    c.rect(3, 2, 5, 3, "3c8a2c")
    return c


def permata(gem, metal="c8a040"):
    c = Canvas()
    c.ellipse(8, 9, 5.5, 5, metal)
    c.ellipse(8, 9, 3.6, 3.4, gem)
    c.set(6, 7, "ffffff")
    c.set(7, 7, "ffd8d8")
    return c


def asap(base):
    c = Canvas()
    c.rect(5, 11, 11, 14, "8a5a2c")
    c.ellipse(8, 11, 3, 1.2, base)
    for i, (x, y) in enumerate(((8, 8), (7, 5), (9, 2))):
        c.ellipse(x, y, 1.6 - i * 0.2, 1.4, "d8d4cc")
    return c


def kerupuk():
    c = Canvas()
    c.ellipse(8, 8, 6.5, 6, "f6e6a0")
    for x, y in ((5, 6), (9, 5), (11, 9), (6, 10), (8, 8)):
        c.set(x, y, "e0c060")
    return c


def gulungan(paper="e8d8a0"):
    c = Canvas()
    c.rect(3, 4, 13, 11, paper)
    c.ellipse(3, 7.5, 1.5, 4, "b89050")
    c.ellipse(13, 7.5, 1.5, 4, "b89050")
    for y in (6, 8, 10):
        c.line(5, y, 11, y, "6a4a2a")
    return c


def busur():
    c = Canvas()
    for t in range(13):
        a = -1.1 + t * 2.2 / 12
        c.set(round(5 + math.cos(a) * 6), round(8 + math.sin(a) * 6), "e0b040")
        c.set(round(5 + math.cos(a) * 6) - 1, round(8 + math.sin(a) * 6), "a07020")
    c.line(8, 2, 8, 14, "f3ecdc")
    c.line(2, 8, 14, 8, "8a5a2c")
    c.poly([(14, 8), (11, 6), (11, 10)], "c8c8d0")
    return c


def kalung():
    c = Canvas()
    for t in range(15):
        a = math.pi * t / 14
        c.set(round(8 + math.cos(a) * 6), round(4 + math.sin(a) * 6), "8a5a2c")
    c.poly([(7, 10), (10, 10), (8, 15)], "f3ecdc")
    c.set(8, 11, "c8c0b0")
    return c


def obor():
    c = Canvas()
    c.line(7, 15, 9, 7, "8a5a2c")
    c.line(8, 15, 10, 7, "6a4020")
    c.ellipse(9.5, 5, 3, 3.5, "f08020")
    c.ellipse(9.5, 5.5, 1.6, 2.2, "ffe060")
    return c


def gelang():
    c = Canvas()
    c.ellipse(8, 8, 6, 5, "202024")
    c.ellipse(8, 8, 3.6, 2.8, None)
    for x, y in ((3, 8), (13, 8), (8, 3)):
        c.set(x, y, "6a6a72")
    return c


def kentongan():
    c = Canvas()
    c.rect(5, 2, 11, 14, "a0602a")
    c.rect(7, 4, 9, 12, "3b2010")
    c.line(5, 2, 11, 2, "c8844a")
    c.line(12, 3, 14, 1, "c8a060")
    return c


def jimat():
    c = Canvas()
    c.rect(4, 2, 12, 14, "e8d8a0")
    c.rect(4, 2, 12, 3, "c02a1c")
    c.line(6, 6, 10, 10, "c02a1c")
    c.line(10, 6, 6, 10, "c02a1c")
    c.ellipse(8, 8, 1.4, 1.4, "c02a1c")
    c.line(7, 12, 9, 12, "c02a1c")
    return c


def lumbung():
    c = Canvas()
    c.rect(4, 8, 12, 12, "8a5a2c")
    c.poly([(2, 9), (14, 9), (11, 3), (8, 1), (5, 3)], "c8a050")
    for x in (5, 11):
        c.line(x, 13, x, 15, "5a3a1c")
    c.ellipse(8, 10.5, 1.2, 1.2, "f0d060")
    return c


def teropong():
    c = Canvas()
    c.poly([(2, 12), (4, 14), (12, 6), (10, 4)], "8a8e96")
    c.poly([(9, 3), (13, 7), (14, 6), (10, 2)], "c8a040")
    c.line(3, 12, 11, 4, "b8bcc4")
    return c


def sepatu():
    c = Canvas()
    c.poly([(3, 5), (7, 5), (8, 9), (14, 10), (14, 13), (3, 13)], "2a5fb0")
    c.rect(3, 12, 14, 13, "f3ecdc")
    c.line(5, 7, 7, 7, "f3ecdc")
    return c


def gula_aren():
    c = Canvas()
    c.ellipse(8, 10, 5.5, 3.5, "6a3a14")
    c.ellipse(8, 8.5, 5, 3, "8a5020")
    c.ellipse(6.5, 7.5, 1.4, 0.8, "b07030")
    return c


def wayang_kecil():
    c = Canvas()
    c.ellipse(8, 3.5, 2, 2, "e0b040")
    c.poly([(5, 6), (11, 6), (12, 12), (4, 12)], "b02a1c")
    c.line(8, 12, 8, 15, "8a5a2c")
    c.line(3, 7, 5, 10, "e0b040")
    c.line(13, 7, 11, 10, "e0b040")
    c.set(8, 8, "e0b040")
    return c


ICONS = {
    "jamu_kunyit": gelas("e8b020", "f8d040"),
    "rendang": piring("6a2a10", "8a3a18"),
    "batik_parang": kain("8a5a2a", "3b2010", "parang"),
    "kopi_tubruk": gelas("3b2010", "6a4020"),
    "kemenyan": asap("c8c0b0"),
    "sambal_matah": cabai(),
    "gula_aren": gula_aren(),
    "kain_ikat": kain("b0201c", "f0d060", "ikat"),
    "tempe_mendoan": piring("d9b38c", "8a6a40", "tempe"),
    "blangkon": blangkon(),
    "peci_hitam": peci(),
    "lontar_sakti": gulungan(),
    "busur_arjuna": busur(),
    "sate_madura": piring("8a3a18", None, "sate"),
    "es_dawet": gelas("6aa040", "f3ecdc", "3c7020"),
    "gudeg": piring("8a4a1c", "c8742c"),
    "kerupuk": kerupuk(),
    "lurik": kain("5a4a3a", "c8b090", "garis"),
    "songket": kain("6a1a2a", "f0c040", "emas"),
    "ulos": kain("8a1a1a", "1a1a1a", "garis"),
    "teropong_rampasan": teropong(),
    "sepatu_pelaut": sepatu(),
    "batu_akik": permata("c0201c"),
    "wayang_kulit": wayang_kecil(),
    "kalung_taring": kalung(),
    "obor_bambu": obor(),
    "gelang_akar_bahar": gelang(),
    "kentongan": kentongan(),
    "jimat_rajah": jimat(),
    "lumbung_padi": lumbung(),
}


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, canvas in ICONS.items():
        canvas.save(name)
    print(len(ICONS), "ikon dibuat di", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
