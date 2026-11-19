#!/usr/bin/env python3
"""Bikin semua gambar game (gaya flat berdetail) sebagai SVG ke assets/sprites & assets/icons.

Jalankan:  python3 tools/make_art.py

Tiap gambar punya ukuran logis (mis. 16x16, sama dengan sprite pixel lama) dan digambar di
viewBox 4x lebih besar. Godot mengimpor SVG dengan svg/scale=4 (lihat file .import), jadi
teksturnya 4x lebih tajam; node yang menggambar sprite membagi skala dengan Art.SCALE.
Semua sprite menghadap ke kanan.
"""
import colorsys
import hashlib
import math
import os
import random
import re

ROOT = os.path.join(os.path.dirname(__file__), "..")
SPRITES = os.path.join(ROOT, "assets", "sprites")
ICONS = os.path.join(ROOT, "assets", "icons")
SCALE = 4
INK = "#1b1d2a"
O = f'stroke="{INK}" stroke-width="2.2" stroke-linejoin="round" stroke-linecap="round"'
O1 = f'stroke="{INK}" stroke-width="1.4" stroke-linejoin="round" stroke-linecap="round"'
GOLD = "#f2c94c"
SKIN = "#d9935a"
PALE = "#f0cfae"

_defs = {}  # id gradasi -> definisi; id unik global, tiap file hanya menyertakan yang dipakainya


def shade(c, f):
    r, g, b = (int(c[i:i + 2], 16) / 255 for i in (1, 3, 5))
    h, l, s = colorsys.rgb_to_hls(r, g, b)
    r, g, b = colorsys.hls_to_rgb(h, max(0.0, min(1.0, l * f)), s)
    return "#%02x%02x%02x" % (round(r * 255), round(g * 255), round(b * 255))


def grad(c, light=1.3, dark=0.7, vertical=True):
    gid = f"g{len(_defs)}"
    x2, y2 = ("0", "1") if vertical else ("1", "0")
    _defs[gid] = (f'<linearGradient id="{gid}" x1="0" y1="0" x2="{x2}" y2="{y2}">'
                 f'<stop offset="0" stop-color="{shade(c, light)}"/><stop offset="1" stop-color="{shade(c, dark)}"/></linearGradient>')
    return f"url(#{gid})"


def rgrad(c):
    gid = f"g{len(_defs)}"
    _defs[gid] = (f'<radialGradient id="{gid}" cx="0.35" cy="0.3" r="0.8"><stop offset="0" stop-color="{shade(c, 1.35)}"/>'
                 f'<stop offset="0.6" stop-color="{c}"/><stop offset="1" stop-color="{shade(c, 0.65)}"/></radialGradient>')
    return f"url(#{gid})"


def save(folder, name, w, h, body, unit=SCALE, import_scale=SCALE):
    """w, h = ukuran logis; body digambar di koordinat 0..w*unit, 0..h*unit; diimpor import_scale kali."""
    d = "".join(_defs[g] for g in dict.fromkeys(re.findall(r"url\(#(g\d+)\)", body)))
    path = os.path.join(folder, name + ".svg")
    with open(path, "w") as f:
        f.write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w * unit} {h * unit}">'
                f'<defs>{d}</defs>{body}</svg>')
    _write_import(path, import_scale)


IMPORT = """[remap]

importer="texture"
type="CompressedTexture2D"
path="res://.godot/imported/{name}-{md5}.ctex"
metadata={{
"vram_texture": false
}}

[deps]

source_file="{res}"
dest_files=["res://.godot/imported/{name}-{md5}.ctex"]

[params]

compress/mode=0
compress/high_quality=false
compress/lossy_quality=0.7
compress/uastc_level=0
compress/rdo_quality_loss=0.0
compress/hdr_compression=1
compress/normal_map=0
compress/channel_pack=0
mipmaps/generate=false
mipmaps/limit=-1
roughness/mode=0
roughness/src_normal=""
process/channel_remap/red=0
process/channel_remap/green=1
process/channel_remap/blue=2
process/channel_remap/alpha=3
process/fix_alpha_border=true
process/premult_alpha=false
process/normal_map_invert_y=false
process/hdr_as_srgb=false
process/hdr_clamp_exposure=false
process/size_limit=0
detect_3d/compress_to=1
svg/scale={scale}.0
editor/scale_with_editor_scale=false
editor/convert_colors_with_editor_theme=false
"""


def _write_import(path, scale):
    rel = os.path.relpath(path, ROOT).replace(os.sep, "/")
    res = "res://" + rel
    name = os.path.basename(path)
    md5 = hashlib.md5(res.encode()).hexdigest()
    imp = path + ".import"
    if os.path.exists(imp):  # jangan ganti uid yang sudah dibuat Godot
        return
    with open(imp, "w") as f:
        f.write(IMPORT.format(name=name, md5=md5, res=res, scale=scale))


# --- Orang (prajurit, karakter, serdadu, boss, warga) -----------------------------
# Koordinat 64x64: kepala (32,18) r12.5, badan 17..47 x 26..48, tangan kanan (49,35).

def kepala_udeng(h):
    return f'''<path d="M19 15 C19 2 45 2 45 15 Q32 11 19 15 Z" fill="{grad(h)}" {O}/>
<path d="M21 13 Q32 9 43 13" fill="none" stroke="{shade(h, 1.7)}" stroke-width="1.3" opacity="0.8"/>
<path d="M23 8 L26 11 M29 6 L31 10 M36 6 L35 10" stroke="{GOLD}" stroke-width="1.2" stroke-linecap="round"/>
<path d="M20 12 L10 7 L11 13 L8 18 L20 16 Z" fill="{grad(h, 1.2, 0.75, False)}" {O}/>
<ellipse cx="26" cy="6.5" rx="4" ry="1.5" fill="#ffffff" opacity="0.35"/>'''


def kepala_caping(h):
    return f'''<path d="M5 15 L32 0 L59 15 Q32 20 5 15 Z" fill="{grad(h, 1.25, 0.75)}" {O}/>
<path d="M32 1 L20 15.5 M32 1 L44 15.5 M32 1 L32 17" stroke="{shade(h, 0.6)}" stroke-width="1" opacity="0.7"/>
<path d="M12 14 Q32 8 52 14" fill="none" stroke="{shade(h, 1.5)}" stroke-width="1.2" opacity="0.7"/>
<path d="M26 18 L22 30 M38 18 L42 30" stroke="#8a5a2a" stroke-width="1" opacity="0.8"/>'''


def kepala_songkok(h):
    return f'''<path d="M20 13 L21 1 Q32 -1 43 1 L44 13 Q32 10 20 13 Z" fill="{grad(h)}" {O}/>
<path d="M20.5 10 Q32 7.5 43.5 10" fill="none" stroke="{GOLD}" stroke-width="2"/>
<path d="M24 3 Q30 2 33 2.5" stroke="#ffffff" stroke-width="1.4" opacity="0.4" stroke-linecap="round"/>'''


def kepala_sanggul(h):
    return f'''<circle cx="17" cy="11" r="6" fill="{rgrad(h)}" {O}/>
<path d="M19.5 18 C18 3 46 2 44.5 15 Q36 9 26 12 Q22 14 19.5 18 Z" fill="{grad(h, 1.4, 0.7)}" {O}/>
<path d="M25 7 Q32 4 39 6" fill="none" stroke="#ffffff" stroke-width="1.2" opacity="0.35"/>
<g {O1}><circle cx="14" cy="6" r="2.6" fill="#ff6fa5"/><circle cx="18.5" cy="4.5" r="2.6" fill="#ff8fba"/><circle cx="12" cy="10" r="2.6" fill="#ff6fa5"/></g>
<circle cx="15" cy="7" r="1.2" fill="{GOLD}"/>
<path d="M21 9 L13 16" stroke="{GOLD}" stroke-width="1.6" stroke-linecap="round"/>'''


def kepala_bulu(h):
    bulu = "".join(f'<path d="M{x} 9 Q{x - 3} {y + 5} {x + d} {y} Q{x + 3} {y + 6} {x + 2} 9 Z" fill="#ffffff" {O1}/>'
                   f'<path d="M{x + d} {y} Q{x + d - 1} {y + 3} {x + d + 0.5} {y + 4}" stroke="{INK}" stroke-width="2"/>'
                   for x, y, d in ((22, -6, -2), (29, -9, 0), (36, -7, 2)))
    return f'''{bulu}
<path d="M19 15 C19 7 45 7 45 15 Q32 12 19 15 Z" fill="{grad(h)}" {O}/>
<path d="M20 11.5 L44 11.5" stroke="{GOLD}" stroke-width="1.5" stroke-dasharray="2 2"/>'''


def kepala_mahkota(h):
    return f'''<path d="M18 15 L19 3 L24 9 L28 0 L32 7 L36 0 L40 9 L45 3 L46 15 Q32 12 18 15 Z" fill="{grad(GOLD, 1.25, 0.7)}" {O}/>
<path d="M19 12 Q32 9.5 45 12" fill="none" stroke="{h}" stroke-width="2.5"/>
<circle cx="32" cy="9.5" r="2.4" fill="{rgrad("#e03a3a")}" {O1}/>
<circle cx="24" cy="11" r="1.4" fill="#3ac0e0"/><circle cx="40" cy="11" r="1.4" fill="#3ac0e0"/>
<circle cx="28" cy="0" r="1.2" fill="#ffffff"/><circle cx="36" cy="0" r="1.2" fill="#ffffff"/>'''


def kepala_helm(c="#b8c2d0", jambul="#e03030"):
    return f'''<path d="M19 17 C19 3 45 3 45 17 L48 17 Q48 21 44 21 L20 21 Q16 21 16 17 Z" fill="{grad(c, 1.25, 0.65)}" {O}/>
<path d="M22 12 Q26 6 32 6" fill="none" stroke="#ffffff" stroke-width="2" stroke-linecap="round" opacity="0.6"/>
<rect x="29" y="10" width="6" height="5" rx="1" fill="{GOLD}" stroke="#7a5a10" stroke-width="0.8"/>
<path d="M32 4 Q28 -1 33 -2 Q38 0 34 4 Z" fill="{jambul}" {O}/>'''


def kepala_shako(c="#2e3550"):
    return f'''<path d="M21 17 L22 1 Q32 -1 42 1 L43 17 Z" fill="{grad(c, 1.4, 0.7)}" {O}/>
<path d="M20 17 L46 17 Q47 20 44 20.5 L20 20.5 Z" fill="#1b1d2a"/>
<path d="M22 4 L42 4" stroke="{GOLD}" stroke-width="1.6"/>
<circle cx="32" cy="10" r="3" fill="{rgrad(GOLD)}" stroke="#7a5a10" stroke-width="0.8"/>
<path d="M40 2 Q44 -4 46 -1 Q44 2 41 3 Z" fill="#e03030" {O1}/>'''


def kepala_topi_boss(c="#2e3550", hias="#ffffff"):
    return f'''<path d="M17 16 L32 2 L47 16 Q48 20 44 20 L20 20 Q16 20 17 16 Z" fill="{grad(c, 1.4, 0.7)}" {O}/>
<path d="M19 17 L45 17" stroke="{GOLD}" stroke-width="1.6"/>
<circle cx="32" cy="11" r="3.4" fill="{rgrad(GOLD)}" stroke="#7a5a10" stroke-width="0.8"/>
<path d="M32 2 Q27 -4 34 -4 Q40 -2 33 3" fill="{hias}" {O1}/>'''


def kepala_fedora(c="#6a4a2a"):
    return f'''<path d="M12 16 Q32 11 52 16 Q50 19 32 19 Q14 19 12 16 Z" fill="{grad(c, 1.1, 0.6)}" {O}/>
<path d="M21 15 L22 5 Q32 1 42 5 L43 15 Q32 13 21 15 Z" fill="{grad(c, 1.3, 0.75)}" {O}/>
<path d="M21.5 12 Q32 10 42.5 12" fill="none" stroke="#2a1a10" stroke-width="2.2"/>'''


def kepala_tabib():
    return f'''<path d="M19 15 C19 3 45 3 45 15 Q32 12 19 15 Z" fill="{grad("#eef2f6", 1.05, 0.8)}" {O}/>
<rect x="29.5" y="5" width="5" height="9" rx="0.8" fill="#e03030"/><rect x="27.5" y="7" width="9" height="5" rx="0.8" fill="#e03030"/>'''


def kepala_kerudung(c):
    return f'''<path d="M18 22 C16 2 48 2 46 22 Q44 10 32 9 Q20 10 18 22 Z" fill="{grad(c, 1.3, 0.75)}" {O}/>
<path d="M18 22 Q14 30 20 34 L22 25 Z" fill="{grad(c, 1.1, 0.7)}" {O1}/>'''


def kepala_helm_raksasa():
    return f'''<path d="M17 24 C15 0 49 0 47 24 L44 30 L20 30 Z" fill="{grad("#7d8696", 1.3, 0.6)}" {O}/>
<rect x="22" y="16" width="22" height="4" rx="2" fill="#1b1d2a"/>
<rect x="34" y="16.5" width="7" height="3" rx="1.5" fill="#ff5a3a"/>
<path d="M32 2 L32 14" stroke="#5d6575" stroke-width="3"/>
<g fill="#cfd6de" stroke="#1b1d2a" stroke-width="0.6"><circle cx="21" cy="24" r="1.2"/><circle cx="27" cy="26" r="1.2"/><circle cx="37" cy="26" r="1.2"/><circle cx="43" cy="24" r="1.2"/></g>
<path d="M22 8 Q27 3 33 3" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.5" stroke-linecap="round"/>'''


KEPALA = {"udeng": kepala_udeng, "caping": kepala_caping, "songkok": kepala_songkok, "sanggul": kepala_sanggul,
          "bulu": kepala_bulu, "mahkota": kepala_mahkota}


def senjata(kind):
    """Senjata di tangan kanan (49,35). Digambar sebelum badan supaya tangan menutupi gagang."""
    if kind == "tombak":
        return f'''<line x1="51" y1="12" x2="51" y2="58" stroke="#5a3214" stroke-width="4" stroke-linecap="round"/>
<line x1="51" y1="12" x2="51" y2="58" stroke="#a8692e" stroke-width="2" stroke-linecap="round"/>
<path d="M51 2 L56 13 L51 16 L46 13 Z" fill="{grad("#d8e0ea", 1.15, 0.7, False)}" {O}/>
<path d="M47 16 L55 16" stroke="{GOLD}" stroke-width="2.5" stroke-linecap="round"/>
<path d="M49 17 Q46 22 49 24 Q51 21 52 24 Q55 22 53 17 Z" fill="#e03a3a"/>'''
    if kind == "tombak_emas":
        return senjata("tombak").replace("#d8e0ea", GOLD).replace("#e03a3a", "#ffffff")
    if kind == "senapan":
        return f'''<rect x="38" y="34" width="22" height="4" rx="1.5" fill="{grad("#5a6270")}" {O}/>
<rect x="38" y="35" width="9" height="6" rx="2" fill="#7a4a22" {O1}/>
<path d="M58 32 L62 30" stroke="#cfd6de" stroke-width="2" stroke-linecap="round"/>'''
    if kind == "keris":
        return f'''<path d="M50 32 Q47 27 50 23 Q53 19 50 15 Q48 11 51 5 Q55 11 53 15 Q56 20 53 24 Q51 28 53 32 Z" fill="{grad("#c8d0da", 1.2, 0.6, False)}" {O1}/>
<rect x="46" y="31" width="9" height="3" rx="1.5" fill="{GOLD}" {O1}/>'''
    if kind == "golok":
        return f'''<path d="M49 32 L49 10 Q57 12 57 22 L53 32 Z" fill="{grad("#d8e0ea", 1.15, 0.6, False)}" {O1}/>
<path d="M50.5 30 L50.5 13" stroke="#ffffff" stroke-width="1" opacity="0.6"/>
<rect x="47" y="31" width="8" height="3" rx="1.5" fill="#7a4a22" {O1}/>'''
    if kind == "kujang":
        return f'''<path d="M50 32 Q44 22 48 8 Q53 3 58 6 Q52 9 53 15 L57 17 L53 19 Q53 26 55 32 Z" fill="{grad("#d8e0ea", 1.15, 0.6, False)}" {O1}/>
<circle cx="51" cy="12" r="1.2" fill="{INK}"/><circle cx="51" cy="17" r="1.2" fill="{INK}"/>'''
    if kind == "busur":
        return f'''<path d="M50 6 Q62 30 50 56" fill="none" stroke="#5a3214" stroke-width="4.5" stroke-linecap="round"/>
<path d="M50 6 Q62 30 50 56" fill="none" stroke="#c8873a" stroke-width="2.5" stroke-linecap="round"/>
<line x1="50" y1="6" x2="50" y2="56" stroke="#f3e3c3" stroke-width="1"/>
<path d="M44 34 L62 34 M60 31 L63 34 L60 37" stroke="{INK}" stroke-width="1.4" fill="none"/>'''
    if kind == "sumpit":
        return f'''<path d="M42 44 L62 14" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>
<path d="M42 44 L62 14" stroke="#7a9a3a" stroke-width="3" stroke-linecap="round"/>
<path d="M46 38 L48 35 M54 26 L56 23" stroke="{GOLD}" stroke-width="2.5"/>'''
    if kind == "ketapel":
        return f'''<path d="M50 40 L50 30 L45 20 M50 30 L56 20" fill="none" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>
<path d="M50 40 L50 30 L45 20 M50 30 L56 20" fill="none" stroke="#a8692e" stroke-width="2.5" stroke-linecap="round"/>
<path d="M45 20 Q50 26 56 20" fill="none" stroke="#c0392b" stroke-width="1.4"/>'''
    if kind == "api":
        return f'''<path d="M50 30 Q42 22 48 12 Q49 18 52 18 Q51 10 56 6 Q55 14 60 18 Q62 26 54 30 Z" fill="{grad("#ff9a2a", 1.3, 0.8)}" {O1}/>
<path d="M52 28 Q48 23 51 18 Q53 22 55 21 Q57 25 52 28 Z" fill="#ffe36a"/>'''
    if kind == "cakra":
        return f'''<circle cx="52" cy="22" r="9" fill="{rgrad(GOLD)}" {O1}/><circle cx="52" cy="22" r="4" fill="#5a2a14" {O1}/>
<path d="M52 11 L52 9 M63 22 L65 22 M52 33 L52 35 M41 22 L39 22 M60 14 L61.5 12.5 M44 14 L42.5 12.5" stroke="{INK}" stroke-width="2"/>'''
    if kind == "granat":
        return f'''<circle cx="52" cy="30" r="6" fill="{rgrad("#3a3f4b")}" {O1}/>
<path d="M53 24 Q56 18 60 20" fill="none" stroke="#c8a060" stroke-width="1.6"/>
<circle cx="60" cy="19.5" r="2" fill="#ffd23f"/><circle cx="60" cy="19.5" r="1" fill="#ff5a2a"/>'''
    if kind == "botol":
        return f'''<rect x="48" y="20" width="8" height="13" rx="3" fill="{grad("#5ac08a", 1.3, 0.7)}" {O1}/>
<rect x="50" y="16" width="4" height="5" rx="1" fill="#a8692e" {O1}/>
<rect x="49.5" y="24" width="5" height="5" fill="#ffffff" opacity="0.8"/><path d="M52 25 L52 28 M50.5 26.5 L53.5 26.5" stroke="#e03030" stroke-width="1"/>'''
    if kind == "sekop":
        return f'''<line x1="51" y1="10" x2="51" y2="50" stroke="#5a3214" stroke-width="3.5" stroke-linecap="round"/>
<path d="M46 50 L56 50 L55 58 Q51 62 47 58 Z" fill="{grad("#9aa3b2")}" {O1}/>'''
    if kind == "cambuk":
        return f'''<path d="M50 34 Q60 30 58 18 Q56 8 62 4" fill="none" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>
<path d="M50 34 Q60 30 58 18 Q56 8 62 4" fill="none" stroke="#8a5a2a" stroke-width="1.6" stroke-linecap="round"/>
<rect x="46" y="33" width="7" height="4" rx="2" fill="#3a2a1a"/>'''
    if kind == "pedang":
        return f'''<path d="M50 32 L52 6 Q54 4 55 6 L54 32 Z" fill="{grad("#e8eef4", 1.1, 0.65, False)}" {O1}/>
<path d="M46 32 L58 32" stroke="{GOLD}" stroke-width="3" stroke-linecap="round"/>'''
    if kind == "selendang":
        return f'''<path d="M49 34 Q60 26 56 14 Q62 20 63 30 Q60 42 48 40 Z" fill="{grad("#ff6fa5", 1.25, 0.8)}" {O1}/>
<path d="M52 36 Q59 30 58 20" fill="none" stroke="{GOLD}" stroke-width="1"/>'''
    return ""


def orang(skin=SKIN, kepala="", warna_kepala="#d0322a", baju="#5a2a14", selendang=None, celana=None, motif="titik", senjata_=None,
          sabuk=GOLD, jubah=None, pangkat=False, kancing=False, perisai=None, mata="biasa", kumis=False,
          janggut=False, pipi=True, gemuk=False):
    celana = celana or skin
    kaki_x = (19, 35) if gemuk else (21, 33)
    badan = "M14 31 Q14 25 22 25 L42 25 Q50 25 50 31 L51 49 Q32 54 13 49 Z" if gemuk else \
        "M18 30 Q18 26 24 26 L40 26 Q46 26 46 30 L47 48 Q32 52 17 48 Z"
    s = senjata(senjata_) if senjata_ else ""
    if jubah:
        s = f'<path d="M14 28 Q8 44 12 58 L52 58 Q56 44 50 28 Z" fill="{grad(jubah, 1.3, 0.6)}" {O}/>' + s
    s += f'''<rect x="{kaki_x[0]}" y="44" width="10" height="14" rx="4" fill="{grad(celana)}" {O}/>
<rect x="{kaki_x[1]}" y="44" width="10" height="14" rx="4" fill="{grad(celana)}" {O}/>
<path d="M{kaki_x[0] - 1} 56 L{kaki_x[0] + 11} 56 L{kaki_x[0] + 11} 60 L{kaki_x[0] - 1} 60 Z M{kaki_x[1] - 1} 56 L{kaki_x[1] + 11} 56 L{kaki_x[1] + 11} 60 L{kaki_x[1] - 1} 60 Z" fill="#2e2018" {O1}/>
<path d="{badan}" fill="{grad(baju)}" {O}/>'''
    if motif == "titik":
        s += f'''<g fill="{shade(baju, 1.9)}" opacity="0.55"><circle cx="23" cy="44" r="1.3"/><circle cx="28" cy="46" r="1.3"/><circle cx="33" cy="47" r="1.3"/><circle cx="38" cy="46" r="1.3"/><circle cx="43" cy="44" r="1.3"/>
<path d="M21 41 Q24 39 27 41 Q30 43 33 41 Q36 39 39 41 Q42 43 45 41" fill="none" stroke="{shade(baju, 1.9)}" stroke-width="1.2"/></g>'''
    elif motif == "garis":
        s += f'<g stroke="{shade(baju, 1.8)}" stroke-width="1.3" opacity="0.5"><path d="M24 27 L24 48 M29 27 L29 49 M35 27 L35 49 M40 27 L40 48"/></g>'
    elif motif == "kotak":
        s += f'<g fill="{shade(baju, 2.2)}" opacity="0.45"><rect x="20" y="40" width="4" height="4"/><rect x="28" y="40" width="4" height="4"/><rect x="36" y="40" width="4" height="4"/><rect x="24" y="44" width="4" height="4"/><rect x="32" y="44" width="4" height="4"/><rect x="40" y="44" width="4" height="4"/></g>'
    if kancing:
        s += f'''<path d="M32 26 L32 48" stroke="{shade(baju, 0.6)}" stroke-width="1.2"/>
<g fill="{GOLD}" stroke="#7a5a10" stroke-width="0.6"><circle cx="29" cy="31" r="1.4"/><circle cx="29" cy="36" r="1.4"/><circle cx="35" cy="31" r="1.4"/><circle cx="35" cy="36" r="1.4"/></g>'''
    if sabuk:
        s += f'''<rect x="17.5" y="38" width="29" height="4" rx="1.5" fill="{grad(sabuk, 1.2, 0.8)}" {O1}/>
<circle cx="32" cy="40" r="2.4" fill="#e03a3a" stroke="#7a1a10" stroke-width="1"/>'''
    if selendang:
        s += f'''<path d="M20 28 L44 40 L44 34 L26 26 Z" fill="{grad(selendang, 1.25, 0.8, False)}" {O1}/>
<path d="M22 29 L43 39" stroke="#ffffff" stroke-width="0.8" opacity="0.5"/>'''
    if pangkat:
        s += f'''<path d="M11 29 Q16 24 24 27 L22 33 Q15 31 11 29 Z M53 29 Q48 24 40 27 L42 33 Q49 31 53 29 Z" fill="{grad(GOLD, 1.2, 0.7)}" {O1}/>
<path d="M12 30 L10 34 M15 31 L14 35 M52 30 L54 34 M49 31 L50 35" stroke="{GOLD}" stroke-width="1.2" stroke-linecap="round"/>
<path d="M40 30 L45 30 L42.5 35 Z" fill="#c0c8d4" stroke="{INK}" stroke-width="0.8"/>'''
    if perisai:
        s += f'''<path d="M8 27 L26 27 L26 44 Q17 54 8 44 Z" fill="{grad(perisai, 1.3, 0.65)}" {O}/>
<path d="M11 30 L23 30 L23 43 Q17 49 11 43 Z" fill="none" stroke="{GOLD}" stroke-width="1.2"/>
<circle cx="17" cy="37" r="3" fill="{rgrad("#e03030")}" {O1}/>'''
    else:
        s += f'<circle cx="15" cy="38" r="4.2" fill="{rgrad(skin)}" {O}/>'
    s += f'<circle cx="49" cy="35" r="4.5" fill="{rgrad(skin)}" {O}/>'
    if kepala == "helm_raksasa":
        return s + kepala_helm_raksasa()
    s += f'<circle cx="32" cy="18" r="12.5" fill="{rgrad(skin)}" {O}/>'
    if pipi:
        s += '<ellipse cx="41" cy="23" rx="2.6" ry="1.6" fill="#ff7a7a" opacity="0.5"/>'
    if mata == "marah":
        s += f'''<circle cx="38.5" cy="18.5" r="2.8" fill="#ffffff" stroke="{INK}" stroke-width="1"/><circle cx="39.3" cy="19" r="1.5" fill="{INK}"/>
<path d="M34.5 14 L42 16.5" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>
<path d="M35.5 25.5 L41.5 25" stroke="#5a2a1a" stroke-width="1.6" stroke-linecap="round"/>'''
    elif mata == "takut":
        s += f'''<circle cx="38.5" cy="18" r="3" fill="#ffffff" stroke="{INK}" stroke-width="1"/><circle cx="38.5" cy="18.5" r="1.3" fill="{INK}"/>
<path d="M35 13.5 L41 12" stroke="#2a1a10" stroke-width="1.4" stroke-linecap="round"/>
<ellipse cx="39" cy="25" rx="2" ry="1.6" fill="#5a1a1a"/>
<path d="M45 14 Q46.5 17 45 18 Q43.5 17 45 14 Z" fill="#7ac8f0"/>'''
    else:
        s += f'''<circle cx="38.5" cy="18.5" r="3" fill="#ffffff" stroke="{INK}" stroke-width="1"/>
<circle cx="39.5" cy="18.8" r="1.7" fill="#2a1a10"/><circle cx="40.1" cy="18" r="0.6" fill="#ffffff"/>
<path d="M35 14.5 L41.5 13.5" stroke="#2a1a10" stroke-width="1.6" stroke-linecap="round"/>
<path d="M36 25 Q39.5 27 42 24.5" fill="none" stroke="#7a2a1a" stroke-width="1.5" stroke-linecap="round"/>'''
    if kumis:
        s += f'<path d="M31 23.5 Q37 21 44 24 Q39 26.5 33 25 Z" fill="#3a2418" stroke="{INK}" stroke-width="0.8"/>'
    if janggut:
        s += f'<path d="M24 25 Q32 36 43 26 Q40 32 33 33 Q27 32 24 25 Z" fill="#e8e8e8" stroke="{INK}" stroke-width="0.8"/>'
    if kepala in KEPALA:
        s += KEPALA[kepala](warna_kepala)
    elif kepala:
        s += kepala
    return s


# --- Prajurit (8 seragam kerajaan) & karakter -----------------------------------

KERAJAAN = {
    "majapahit":     dict(h="#d0322a", C=GOLD, c="#5a2a14"),
    "sriwijaya":     dict(h="#2e7de0", C="#f3e3c3", c="#1e3a6a"),
    "mataram":       dict(h="#2f9a4a", C=GOLD, c="#3a2a1a"),
    "pajajaran":     dict(h="#8a3ab0", C="#f0d860", c="#3a1a4a"),
    "samudra_pasai": dict(h="#2a2a2a", C="#d02828", c="#2a2a2a"),
    "gowa":          dict(h=GOLD, C="#a8287a", c="#5a1440"),
    "kutai":         dict(h="#f07a20", C="#2a2a2a", c="#7a3a14"),
    "ternate":       dict(h="#f3e3c3", C="#2aa0a0", c="#1a4a5a"),
}

KARAKTER = {
    "pendekar_silat":     dict(kepala="udeng", warna_kepala="#2a2a2a", baju="#2a2a2a", selendang="#d0322a", senjata_="keris", mata="marah"),
    "petani":             dict(kepala="caping", warna_kepala="#e8c46a", baju="#6a8a3a", selendang=None, senjata_="ketapel", motif="garis", sabuk="#a8692e"),
    "pemburu_dayak":      dict(kepala="bulu", warna_kepala="#d0322a", baju="#1a1a1a", selendang="#e8c46a", senjata_="sumpit", skin="#b8783e", motif="kotak"),
    "dukun":              dict(kepala="udeng", warna_kepala="#5a2a7a", baju="#2a1a3a", selendang="#a85ad0", senjata_="api", janggut=True),
    "pecalang_bali":      dict(kepala="udeng", warna_kepala="#f3f3f3", baju="#2a2a2a", selendang="#f3f3f3", senjata_="tombak", motif="kotak"),
    "pelaut_bugis":       dict(kepala="songkok", warna_kepala="#d02828", baju="#1e3a6a", selendang="#f3e3c3", senjata_="busur", motif="garis"),
    "saudagar_minang":    dict(kepala="songkok", warna_kepala="#c8961e", baju="#7a1a1a", selendang=GOLD, senjata_="kujang", kumis=True),
    "penari_jaipong":     dict(kepala="sanggul", warna_kepala="#1a1a1a", baju="#d03a7a", selendang=GOLD, senjata_="selendang", skin="#e0a070"),
    "jawara_betawi":      dict(kepala="songkok", warna_kepala="#1a1a1a", baju="#1a1a1a", selendang="#d02828", senjata_="golok", kumis=True, gemuk=True, mata="marah"),
    "senopati_majapahit": dict(kepala="mahkota", warna_kepala="#d0322a", baju="#7a1414", selendang=GOLD, senjata_="tombak_emas", jubah="#d0322a"),
}


def prajurit(h, C, c):
    return orang(kepala="udeng", warna_kepala=h, baju=c, selendang=C, senjata_="tombak")


# --- Musuh Kekaisaran Besi --------------------------------------------------------

BESI = "#4e5a72"


def kavaleri():
    kuda = f'''<path d="M6 30 Q0 24 4 16" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>
<path d="M6 30 Q0 24 4 16" fill="none" stroke="#3a2418" stroke-width="3" stroke-linecap="round"/>
<rect x="10" y="40" width="6" height="16" rx="3" fill="{grad("#7a4a2a")}" {O1}/>
<rect x="40" y="40" width="6" height="16" rx="3" fill="{grad("#7a4a2a")}" {O1}/>
<rect x="6" y="28" width="44" height="18" rx="9" fill="{grad("#9a6034", 1.25, 0.7)}" {O}/>
<path d="M44 30 L52 12 Q56 8 62 12 L63 18 Q60 20 56 18 L52 32 Z" fill="{grad("#9a6034", 1.2, 0.7)}" {O}/>
<path d="M50 14 Q46 18 46 26" fill="none" stroke="#3a2418" stroke-width="3"/>
<circle cx="57" cy="13" r="1.4" fill="{INK}"/>
<rect x="18" y="30" width="18" height="12" rx="3" fill="{grad("#b0201c")}" {O1}/>
<path d="M18 36 L36 36" stroke="{GOLD}" stroke-width="1.5"/>
<path d="M50 20 L58 22" stroke="#cfd6de" stroke-width="2"/>'''
    penunggang = f'''<g transform="translate(6,-14) scale(0.72)">{orang(skin=PALE, kepala=kepala_helm(), baju=BESI, celana="#3a4152",
                                                                   motif="", kancing=True, sabuk="#2c1e14", senjata_="pedang", mata="marah", kumis=True)}</g>'''
    return penunggang + kuda


def anjing():
    return f'''<path d="M10 30 Q2 24 7 15" fill="none" stroke="{INK}" stroke-width="6" stroke-linecap="round"/>
<path d="M10 30 Q2 24 7 15" fill="none" stroke="#7d8696" stroke-width="3.5" stroke-linecap="round"/>
<rect x="14" y="40" width="7" height="15" rx="3.5" fill="{grad("#5d6575")}" {O}/>
<rect x="38" y="40" width="7" height="15" rx="3.5" fill="{grad("#5d6575")}" {O}/>
<rect x="9" y="26" width="40" height="19" rx="9.5" fill="{grad("#8a93a3", 1.2, 0.65)}" {O}/>
<path d="M14 30 Q22 27 30 30" fill="none" stroke="#ffffff" stroke-width="1.8" opacity="0.45" stroke-linecap="round"/>
<path d="M20 26 L22 36 L26 26 M28 26 L30 34 L33 26" fill="#4a5262" stroke="{INK}" stroke-width="1"/>
<rect x="36" y="28" width="12" height="5" rx="2" fill="#c0392b" stroke="{INK}" stroke-width="1.2"/>
<circle cx="42" cy="35" r="2.2" fill="{GOLD}" stroke="#7a5a10" stroke-width="0.8"/>
<circle cx="48" cy="22" r="10.5" fill="{rgrad("#8a93a3")}" {O}/>
<path d="M43 14 L40 2 L51 11 Z" fill="{grad("#5d6575")}" {O}/>
<path d="M44 11 L42.5 6 L47 10 Z" fill="#e88a9a"/>
<path d="M52 22 L62 23 Q64 28 60 30 L52 29 Z" fill="{grad("#7d8696")}" {O}/>
<circle cx="61.5" cy="24.5" r="2.2" fill="{INK}"/>
<path d="M53 29 L55 31 L57 29 L59 31" fill="none" stroke="#ffffff" stroke-width="1.2"/>
<circle cx="50" cy="19" r="3" fill="#ffd23f" stroke="{INK}" stroke-width="1"/>
<circle cx="50.8" cy="19" r="1.5" fill="#c0392b"/>
<path d="M46 15 L53 16.5" stroke="{INK}" stroke-width="1.6" stroke-linecap="round"/>'''


MUSUH = {
    "serdadu_besi": lambda: orang(skin=PALE, kepala=kepala_helm(), baju=BESI, celana="#3a4152", motif="", kancing=True,
                                  sabuk="#2c1e14", senjata_="senapan", kumis=True),
    "penembak": lambda: orang(skin=PALE, kepala=kepala_shako(), baju="#3a5a8a", celana="#2a3550", motif="", kancing=True,
                              sabuk="#f3f3f3", selendang="#f3f3f3", senjata_="senapan", mata="marah"),
    "serdadu_perisai": lambda: orang(skin=PALE, kepala=kepala_helm("#8a93a3", "#2a2a2a"), baju="#3a4152", celana="#2a3040",
                                     motif="garis", sabuk="#2c1e14", perisai="#6b7a90", senjata_="pedang", mata="marah", gemuk=True),
    "tukang_ranjau": lambda: orang(skin=PALE, kepala=kepala_helm("#7a8a5a", "#e0b04a"), baju="#5a6a3a", celana="#3a4a2a",
                                   motif="", sabuk="#2c1e14", senjata_="sekop", selendang="#e0b04a"),
    "pelempar_granat": lambda: orang(skin=PALE, kepala=kepala_helm("#9a7a5a", "#e03030"), baju="#6a4a3a", celana="#3a2a20",
                                     motif="", kancing=True, sabuk="#2c1e14", senjata_="granat", kumis=True, mata="marah"),
    "tabib_besi": lambda: orang(skin=PALE, kepala=kepala_tabib(), baju="#e8eef4", celana="#8a93a3", motif="", sabuk="#e03030",
                                senjata_="botol", selendang="#e03030"),
    "raksasa_baja": lambda: orang(skin="#8a93a3", kepala="helm_raksasa", baju="#5d6575", celana="#3a4152", motif="garis",
                                  sabuk="#2c1e14", senjata_="cambuk", gemuk=True, kancing=True),
    "komandan_besi": lambda: orang(skin=PALE, kepala=kepala_topi_boss(), baju="#2e3550", celana="#22252e", motif="", kancing=True,
                                   sabuk=None, selendang="#c0392b", jubah="#8a1a2a", pangkat=True, senjata_="pedang", kumis=True, mata="marah"),
    "laksamana_besi": lambda: orang(skin=PALE, kepala=kepala_topi_boss("#1a2a5a", GOLD), baju="#1a2a5a", celana="#f3f3f3", motif="",
                                    kancing=True, sabuk=GOLD, jubah="#1a3a7a", pangkat=True, senjata_="pedang", janggut=True, mata="marah"),
    "mandor_kejam": lambda: orang(skin="#e8b890", kepala=kepala_fedora(), baju="#8a6a3a", celana="#4a3a2a", motif="garis",
                                  sabuk="#2c1e14", senjata_="cambuk", kumis=True, mata="marah", gemuk=True),
    "gubernur_jenderal": lambda: orang(skin=PALE, kepala=kepala_topi_boss("#f3f3f3", "#e03030"), baju="#f3f3f3", celana="#2e3550",
                                       motif="", kancing=True, sabuk=GOLD, selendang="#c0392b", jubah="#6a0a1a", pangkat=True,
                                       senjata_="pedang", kumis=True, mata="marah", gemuk=True),
}


# --- Benda kecil & peluru -----------------------------------------------------------

def warga():
    return orang(skin=SKIN, kepala=kepala_kerudung("#2aa070"), baju="#e8c46a", celana="#8a4a2a", motif="kotak",
                 sabuk=None, mata="takut")


WAYANG = f'''<path d="M20 4 Q26 2 28 8 L24 10 Z" fill="{GOLD}" {O1}/>
<circle cx="22" cy="12" r="6" fill="{grad("#2a2a2a")}" {O1}/>
<path d="M24 12 L31 13 L25 15 Z" fill="#2a2a2a" {O1}/>
<circle cx="23.5" cy="11" r="1" fill="#ffffff"/>
<path d="M14 20 Q20 16 28 20 L30 40 L12 40 Z" fill="{grad("#c0392b", 1.3, 0.7)}" {O1}/>
<path d="M15 24 L27 24 M14 30 L28 30 M13 36 L29 36" stroke="{GOLD}" stroke-width="1.6"/>
<path d="M28 21 L36 30 L34 32 L27 25" fill="{GOLD}" {O1}/>
<path d="M14 21 L6 32 L8 34 L15 26" fill="{GOLD}" {O1}/>
<path d="M14 40 L12 56 M28 40 L30 56" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>
<path d="M14 40 L12 56 M28 40 L30 56" stroke="{GOLD}" stroke-width="1.5" stroke-linecap="round"/>
<path d="M21 40 L21 60" stroke="#8a5a2a" stroke-width="2"/>'''

PETI = f'''<rect x="3" y="16" width="42" height="22" rx="3" fill="{grad("#a8692e", 1.25, 0.7)}" {O}/>
<path d="M3 18 Q3 4 24 4 Q45 4 45 18 Z" fill="{grad("#c8873a", 1.3, 0.75)}" {O}/>
<path d="M3 16 L45 16" stroke="{GOLD}" stroke-width="3"/>
<path d="M12 5 L12 38 M36 5 L36 38" stroke="{GOLD}" stroke-width="2.5"/>
<rect x="20" y="13" width="8" height="10" rx="2" fill="{grad(GOLD)}" {O1}/>
<circle cx="24" cy="18" r="1.4" fill="{INK}"/>
<path d="M9 9 Q16 6 22 7" fill="none" stroke="#ffffff" stroke-width="1.5" opacity="0.45" stroke-linecap="round"/>
<path d="M40 2 L41 5 L44 6 L41 7 L40 10 L39 7 L36 6 L39 5 Z" fill="#fff6c0"/>'''

KETUPAT = f'''<path d="M16 2 L30 16 L16 30 L2 16 Z" fill="{grad("#7ac04a", 1.25, 0.7)}" {O}/>
<path d="M9 9 L23 23 M23 9 L9 23 M12.5 5.5 L26.5 19.5 M19.5 5.5 L5.5 19.5 M5.5 12.5 L19.5 26.5 M26.5 12.5 L12.5 26.5" stroke="#3c7020" stroke-width="1"/>
<path d="M16 2 Q18 -1 22 1" fill="none" stroke="#3c7020" stroke-width="1.5"/>
<path d="M10 8 L14 4" stroke="#ffffff" stroke-width="1.4" opacity="0.6" stroke-linecap="round"/>'''

REMPAH = {
    "rempah": f'''<circle cx="16" cy="17" r="12" fill="{rgrad("#d4823a")}" {O}/>
<path d="M8 12 Q16 6 24 12 Q20 16 22 22 Q17 20 14 26 Q13 20 8 19 Q11 16 8 12 Z" fill="{grad("#d0281c", 1.2, 0.7)}" stroke="#7a1010" stroke-width="0.8"/>
<path d="M15 6 Q16 2 20 1 Q19 5 16 7 Z" fill="#6aa040" {O1}/>
<ellipse cx="11.5" cy="13" rx="3" ry="1.8" fill="#ffffff" opacity="0.5"/>''',
    "rempah_cengkeh": f'''<path d="M16 14 L16 30" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>
<path d="M16 14 L16 30" stroke="#8a4a1c" stroke-width="3" stroke-linecap="round"/>
<path d="M8 10 L16 15 L24 10 L20 4 L12 4 Z" fill="{grad("#a85a24", 1.3, 0.7)}" {O1}/>
<circle cx="16" cy="7" r="4" fill="{rgrad("#c8742c")}" {O1}/>
<path d="M15 18 L15 27" stroke="#c8873a" stroke-width="1" opacity="0.8"/>''',
    "rempah_lada": f'''<circle cx="10" cy="10" r="6.5" fill="{rgrad("#3a3a3a")}" {O1}/>
<circle cx="22" cy="14" r="6.5" fill="{rgrad("#4a3a2a")}" {O1}/>
<circle cx="13" cy="23" r="6.5" fill="{rgrad("#2a2a2a")}" {O1}/>
<path d="M8 8 Q10 6 12 7 M20 12 Q22 10 24 11 M11 21 Q13 19 15 20" stroke="#ffffff" stroke-width="1.2" opacity="0.55" fill="none"/>''',
    "rempah_kayu_manis": f'''<rect x="3" y="8" width="26" height="16" rx="8" fill="{grad("#b8682a", 1.3, 0.7)}" {O}/>
<circle cx="25" cy="16" r="7" fill="{rgrad("#d4823a")}" {O1}/>
<path d="M25 16 m-4 0 a4 4 0 1 1 4 4 a2.5 2.5 0 1 1 -2 -3" fill="none" stroke="#7a3a14" stroke-width="1.2"/>
<path d="M6 12 L20 12" stroke="#ffffff" stroke-width="1.4" opacity="0.4" stroke-linecap="round"/>''',
    "rempah_bunga_lawang": f'''<path d="M16 1 L19 12 L30 9 L21 17 L28 27 L16 21 L4 27 L11 17 L2 9 L13 12 Z" fill="{grad("#a8562a", 1.3, 0.7)}" {O1}/>
<circle cx="16" cy="15" r="3" fill="#5a2a10"/>
<g fill="#e8b070"><circle cx="16" cy="7" r="1.3"/><circle cx="24" cy="12" r="1.3"/><circle cx="22" cy="22" r="1.3"/><circle cx="10" cy="22" r="1.3"/><circle cx="8" cy="12" r="1.3"/></g>''',
    "rempah_kepeng": f'''<circle cx="16" cy="16" r="13" fill="{rgrad(GOLD)}" {O}/>
<circle cx="16" cy="16" r="9.5" fill="none" stroke="#b8861e" stroke-width="1.2"/>
<rect x="12.5" y="12.5" width="7" height="7" rx="1" fill="#3a2a10" stroke="#7a5a10" stroke-width="1"/>
<path d="M9 7 Q13 4 18 4" fill="none" stroke="#ffffff" stroke-width="1.6" opacity="0.6" stroke-linecap="round"/>
<path d="M16 6 L16 9 M16 23 L16 26 M6 16 L9 16 M23 16 L26 16" stroke="#b8861e" stroke-width="1.4"/>''',
}

RANJAU = f'''<path d="M3 24 Q3 6 16 6 Q29 6 29 24 Z" fill="{grad("#4a5262", 1.3, 0.6)}" {O}/>
<path d="M1 24 L31 24" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>
<path d="M8 10 L4 5 M16 6 L16 1 M24 10 L28 5" stroke="{INK}" stroke-width="2" stroke-linecap="round"/>
<circle cx="16" cy="15" r="3.4" fill="#ff3a2a" stroke="{INK}" stroke-width="1"/>
<circle cx="15" cy="14" r="1.1" fill="#ffd0c0"/>'''

MERIAM_JAGA = f'''<path d="M14 8 L52 6 Q55 6 55 10 L55 16 Q55 20 52 20 L14 22 Q8 22 8 15 Q8 8 14 8 Z" fill="{grad("#7d8696", 1.35, 0.6)}" {O}/>
<rect x="50" y="5" width="5" height="16" rx="2" fill="{grad(GOLD)}" {O1}/>
<path d="M20 10 L20 20 M28 9.5 L28 20.5" stroke="{GOLD}" stroke-width="2.2"/>
<path d="M14 11 Q30 9 46 9" fill="none" stroke="#ffffff" stroke-width="1.6" opacity="0.5" stroke-linecap="round"/>
<path d="M8 22 L44 22 L40 32 L12 32 Z" fill="{grad("#a8692e", 1.25, 0.7)}" {O}/>
<circle cx="16" cy="34" r="7" fill="{rgrad("#7a4a22")}" {O1}/><circle cx="16" cy="34" r="2" fill="{GOLD}"/>
<circle cx="38" cy="34" r="7" fill="{rgrad("#7a4a22")}" {O1}/><circle cx="38" cy="34" r="2" fill="{GOLD}"/>
<path d="M4 18 Q1 14 4 10" fill="none" stroke="#e03030" stroke-width="2" stroke-linecap="round"/>'''

# Peluru: (nama, w, h, gambar). Menghadap kanan.
PELURU = {
    "api": (6, 5, f'''<path d="M2 10 Q0 2 10 2 Q16 0 23 6 Q24 10 22 12 Q16 20 8 18 Q2 16 2 10 Z" fill="{grad("#ff7a1a", 1.35, 0.85)}" {O1}/>
<path d="M8 12 Q8 7 14 7 Q19 8 19 11 Q16 15 11 15 Z" fill="#ffe36a"/>'''),
    "bambu_runcing": (14, 3, f'''<rect x="2" y="3" width="44" height="6" rx="3" fill="{grad("#8ab04a", 1.3, 0.7)}" {O1}/>
<path d="M16 3 L16 9 M30 3 L30 9" stroke="#4a6a20" stroke-width="1.4"/>
<path d="M44 2 L55 6 L44 10 Z" fill="{grad("#c8d870")}" {O1}/>'''),
    "batu": (5, 5, f'''<path d="M3 10 Q2 3 10 2 Q18 3 18 10 Q17 18 10 18 Q3 17 3 10 Z" fill="{rgrad("#a89a8a")}" {O1}/>
<ellipse cx="8" cy="7" rx="2.5" ry="1.5" fill="#ffffff" opacity="0.5"/>'''),
    "bintang": (7, 6, f'''<path d="M14 1 L17.5 8.5 L26 9 L19.5 14.5 L21.5 23 L14 18.5 L6.5 23 L8.5 14.5 L2 9 L10.5 8.5 Z" fill="{rgrad(GOLD)}" {O1}/>
<circle cx="14" cy="12" r="2" fill="#fff6c0"/>'''),
    "cakra": (8, 8, f'''<circle cx="16" cy="16" r="13" fill="{rgrad(GOLD)}" {O1}/>
<circle cx="16" cy="16" r="5.5" fill="#5a2a14" {O1}/>
<path d="M16 1 L16 -1 M31 16 L33 16 M16 31 L16 33 M1 16 L-1 16 M27 5 L28.5 3.5 M5 27 L3.5 28.5 M27 27 L28.5 28.5 M5 5 L3.5 3.5" stroke="{INK}" stroke-width="2.5"/>
<path d="M8 9 Q12 5 17 5" fill="none" stroke="#ffffff" stroke-width="1.4" opacity="0.6"/>'''),
    "golok": (12, 4, f'''<path d="M12 3 L42 2 Q48 6 42 13 L12 11 Z" fill="{grad("#d8e0ea", 1.2, 0.6)}" {O1}/>
<rect x="1" y="4" width="12" height="6" rx="3" fill="#7a4a22" {O1}/>
<path d="M14 5 L40 4" stroke="#ffffff" stroke-width="1" opacity="0.7"/>'''),
    "keris": (10, 5, f'''<path d="M10 7 Q15 3 20 7 Q25 11 30 6 Q34 3 39 10 Q34 14 30 12 Q25 9 20 13 Q15 16 10 13 Z" fill="{grad("#c8d0da", 1.2, 0.6)}" {O1}/>
<rect x="1" y="6" width="9" height="8" rx="3" fill="{GOLD}" {O1}/>'''),
    "kujang": (10, 8, f'''<path d="M4 26 Q14 10 32 4 Q38 3 38 8 Q30 10 28 16 L33 18 L26 21 Q20 24 14 30 Z" fill="{grad("#d8e0ea", 1.2, 0.6)}" {O1}/>
<circle cx="22" cy="14" r="1.4" fill="{INK}"/><circle cx="17" cy="19" r="1.4" fill="{INK}"/>'''),
    "kunai": (11, 6, f'''<path d="M18 4 L42 12 L18 20 Q14 12 18 4 Z" fill="{grad("#c8d0da", 1.2, 0.55)}" {O1}/>
<rect x="6" y="9" width="12" height="6" rx="1.5" fill="#2a2a2a" {O1}/>
<circle cx="4" cy="12" r="3" fill="none" stroke="{INK}" stroke-width="1.6"/>
<path d="M8 10 L16 14" stroke="#d02828" stroke-width="1"/>'''),
    "meriam": (7, 7, f'''<circle cx="14" cy="14" r="12" fill="{rgrad("#3a3f4b")}" {O1}/>
<ellipse cx="10" cy="9" rx="4" ry="2.5" fill="#ffffff" opacity="0.45"/>'''),
    "musuh": (5, 5, f'''<circle cx="10" cy="10" r="8.5" fill="{rgrad("#ff3a2a")}" {O1}/>
<circle cx="8" cy="8" r="3" fill="#ffd0c0"/>'''),
    "panah": (10, 3, f'''<path d="M2 6 L32 6" stroke="{INK}" stroke-width="3.2" stroke-linecap="round"/>
<path d="M2 6 L32 6" stroke="#c8873a" stroke-width="1.8" stroke-linecap="round"/>
<path d="M30 1 L39 6 L30 11 Z" fill="{grad("#d8e0ea")}" {O1}/>
<path d="M1 1 L8 6 L1 11 L5 6 Z" fill="#e03a3a" {O1}/>'''),
    "shuriken": (10, 10, f'''<path d="M20 1 L24 16 L39 20 L24 24 L20 39 L16 24 L1 20 L16 16 Z" fill="{grad("#c8d0da", 1.3, 0.55)}" {O1}/>
<circle cx="20" cy="20" r="3.5" fill="#2a2a2a" {O1}/>
<path d="M18 6 L19.5 15" stroke="#ffffff" stroke-width="1" opacity="0.7"/>'''),
    "sumpit": (8, 3, f'''<path d="M4 6 L24 6" stroke="{INK}" stroke-width="2.6" stroke-linecap="round"/>
<path d="M4 6 L24 6" stroke="#c8d0da" stroke-width="1.2"/>
<path d="M22 3 L31 6 L22 9 Z" fill="#7ac04a" {O1}/>
<path d="M1 2 Q6 6 1 10 Q4 6 1 2 Z" fill="#f3e3c3" {O1}/>'''),
    "tombak": (18, 4, f'''<path d="M2 8 L54 8" stroke="{INK}" stroke-width="4.5" stroke-linecap="round"/>
<path d="M2 8 L54 8" stroke="#a8692e" stroke-width="2.5" stroke-linecap="round"/>
<path d="M52 2 L71 8 L52 14 L55 8 Z" fill="{grad("#d8e0ea")}" {O1}/>
<path d="M50 3 Q46 8 50 13" fill="none" stroke="#e03a3a" stroke-width="2.5"/>'''),
}

IKON = {
    "ikon_hati": (7, 7, f'''<path d="M14 26 L3 14 Q-1 7 5 3 Q11 0 14 7 Q17 0 23 3 Q29 7 25 14 Z" fill="{rgrad("#ff4a5a")}" {O1}/>
<ellipse cx="8" cy="8" rx="2.5" ry="1.6" fill="#ffffff" opacity="0.6"/>'''),
    "ikon_bendera": (8, 8, f'''<path d="M5 3 L5 31" stroke="{INK}" stroke-width="2.5" stroke-linecap="round"/>
<path d="M6 4 Q16 1 29 5 L29 12 Q16 9 6 12 Z" fill="#e8283a" {O1}/>
<path d="M6 12 Q16 9 29 12 L29 19 Q16 16 6 20 Z" fill="#ffffff" {O1}/>
<circle cx="5" cy="3" r="2" fill="{GOLD}"/>'''),
    "ikon_bintang": (7, 6, PELURU["bintang"][2]),
}


# --- Ikon item 16x16 (viewBox 64) ----------------------------------------------------

def piring(food, food2=None, kind="blob"):
    s = f'''<ellipse cx="32" cy="42" rx="28" ry="13" fill="{grad("#f6f8fb", 1.0, 0.82)}" {O}/>
<ellipse cx="32" cy="41" rx="20" ry="8" fill="none" stroke="#5a8ad0" stroke-width="1.5" opacity="0.7"/>'''
    if kind == "sate":
        for i, y in enumerate((22, 30, 38)):
            s += f'''<path d="M8 {y + 8} L56 {y - 6}" stroke="#c8a060" stroke-width="2" stroke-linecap="round"/>
''' + "".join(f'<rect x="{18 + j * 9}" y="{y - 2 - j * 2.6 - 3}" width="8" height="8" rx="2.5" fill="{grad(food)}" {O1} transform="rotate(-16 {22 + j * 9} {y - j * 2.6})"/>' for j in range(3))
        return s + '<path d="M20 44 Q32 50 46 44" fill="none" stroke="#6a3a10" stroke-width="3" opacity="0.6"/>'
    if kind == "tempe":
        for x, y in ((14, 28), (30, 24), (24, 36)):
            s += f'''<rect x="{x}" y="{y}" width="20" height="12" rx="4" fill="{grad(food, 1.15, 0.8)}" {O1}/>
<g fill="{food2}"><circle cx="{x + 5}" cy="{y + 4}" r="1.2"/><circle cx="{x + 11}" cy="{y + 7}" r="1.2"/><circle cx="{x + 15}" cy="{y + 4}" r="1.2"/></g>'''
        return s
    s += f'''<path d="M12 40 Q14 22 32 20 Q50 22 52 40 Q32 48 12 40 Z" fill="{grad(food, 1.35, 0.75)}" {O1}/>
<path d="M18 32 Q24 26 32 26" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.35" stroke-linecap="round"/>'''
    if food2:
        s += f'<g fill="{food2}" {O1}><circle cx="24" cy="34" r="3.5"/><circle cx="37" cy="30" r="3.5"/><circle cx="40" cy="38" r="3"/></g>'
    s += '<path d="M44 16 Q46 10 43 6 M50 18 Q53 12 50 8" fill="none" stroke="#ffffff" stroke-width="1.6" opacity="0.5" stroke-linecap="round"/>'
    return s


def gelas(liquid, top=None, dots=None):
    s = f'''<path d="M16 10 L48 10 L44 58 Q32 62 20 58 Z" fill="#dff1ff" fill-opacity="0.35" {O}/>
<path d="M18 22 L46 22 L43.5 56 Q32 60 20.5 56 Z" fill="{grad(liquid, 1.25, 0.75)}"/>'''
    if top:
        s += f'<path d="M18 22 L46 22 L45.2 30 L18.8 30 Z" fill="{top}"/>'
    if dots:
        s += f'<g fill="{dots}"><circle cx="26" cy="40" r="2"/><circle cx="34" cy="46" r="2"/><circle cx="38" cy="38" r="2"/><circle cx="30" cy="52" r="2"/></g>'
    return s + f'''<path d="M16 10 L48 10 L44 58 Q32 62 20 58 Z" fill="none" {O}/>
<path d="M21 14 L23 54" stroke="#ffffff" stroke-width="2.5" opacity="0.6" stroke-linecap="round"/>
<path d="M38 2 L34 30" stroke="#e03a3a" stroke-width="3" stroke-linecap="round"/>'''


def kain(base, stripe, pattern="garis"):
    s = f'''<path d="M6 16 L50 8 L58 48 L14 56 Z" fill="{grad(base, 1.3, 0.75)}" {O}/>'''
    if pattern == "garis":
        s += "".join(f'<path d="M{8 + i * 9} {15 - i * 1.6} L{16 + i * 9} {55 - i * 1.6}" stroke="{stripe}" stroke-width="2.6"/>' for i in range(5))
    elif pattern == "parang":
        s += "".join(f'<path d="M{6 + i * 10} {28 - i * 2} Q{12 + i * 10} {18 - i * 2} {18 + i * 10} {24 - i * 2} Q{24 + i * 10} {30 - i * 2} {30 + i * 10} {22 - i * 2}" fill="none" stroke="{stripe}" stroke-width="2.4"/>'
                     f'<path d="M{10 + i * 10} {46 - i * 2} Q{16 + i * 10} {36 - i * 2} {22 + i * 10} {42 - i * 2}" fill="none" stroke="{stripe}" stroke-width="2.4"/>' for i in range(4))
    elif pattern == "ikat":
        s += "".join(f'<path d="M{x} {y - 6} L{x + 6} {y} L{x} {y + 6} L{x - 6} {y} Z" fill="{stripe}" stroke="{INK}" stroke-width="0.8"/>'
                     for x, y in ((20, 20), (36, 17), (24, 36), (40, 33), (28, 50), (44, 48)))
    elif pattern == "emas":
        s += "".join(f'<path d="M{8 + i * 2} {22 + i * 10} L{52 + i * 2} {14 + i * 10}" stroke="{stripe}" stroke-width="2" stroke-dasharray="4 2"/>' for i in range(4))
        s += f'<g fill="{stripe}"><circle cx="24" cy="32" r="2.5"/><circle cx="40" cy="29" r="2.5"/></g>'
    return s + f'''<path d="M6 16 L50 8 L58 48 L14 56 Z" fill="none" {O}/>
<path d="M50 8 L58 48 L62 44 L54 6 Z" fill="{shade(base, 0.55)}" {O1}/>
<path d="M10 20 L46 13" stroke="#ffffff" stroke-width="2" opacity="0.35" stroke-linecap="round"/>'''


def ikon_item(name):
    if name in ITEM_SIMPLE:
        return ITEM_SIMPLE[name]()
    return ITEM_CUSTOM[name]


ITEM_SIMPLE = {
    "jamu_kunyit": lambda: gelas("#e8b020", "#f8d040"),
    "rendang": lambda: piring("#6a2a10", "#8a3a18"),
    "batik_parang": lambda: kain("#8a5a2a", "#3b2010", "parang"),
    "kopi_tubruk": lambda: gelas("#4a2a10", "#7a5030"),
    "kain_ikat": lambda: kain("#c0281c", "#f0d060", "ikat"),
    "tempe_mendoan": lambda: piring("#d9b38c", "#8a6a40", "tempe"),
    "sate_madura": lambda: piring("#9a4a1c", None, "sate"),
    "es_dawet": lambda: gelas("#f3ecdc", "#7ac04a", "#3c7020"),
    "gudeg": lambda: piring("#8a4a1c", "#e0c070"),
    "lurik": lambda: kain("#6a5a4a", "#d8c0a0", "garis"),
    "songket": lambda: kain("#7a1a2a", GOLD, "emas"),
    "ulos": lambda: kain("#9a1a1a", "#1a1a1a", "garis"),
}

ITEM_CUSTOM = {
    "blangkon": f'''<path d="M8 40 C6 12 58 12 56 40 Q32 48 8 40 Z" fill="{grad("#8a5a2a", 1.3, 0.7)}" {O}/>
<path d="M12 30 Q32 22 52 30 M10 36 Q32 28 54 36" fill="none" stroke="#3b2010" stroke-width="2.2"/>
<path d="M14 24 Q20 22 24 26 M30 20 Q36 18 40 22" fill="none" stroke="{GOLD}" stroke-width="1.6"/>
<circle cx="10" cy="44" r="8" fill="{rgrad("#5a3418")}" {O}/>
<path d="M18 18 Q26 14 34 15" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.4" stroke-linecap="round"/>''',
    "peci_hitam": f'''<path d="M8 46 L12 18 Q32 12 52 18 L56 46 Q32 52 8 46 Z" fill="{grad("#3a3a3a", 1.5, 0.6)}" {O}/>
<path d="M12 18 Q32 26 52 18" fill="none" stroke="#1a1a1a" stroke-width="2"/>
<path d="M10 40 Q32 45 54 40" fill="none" stroke="{GOLD}" stroke-width="2"/>
<path d="M16 22 L14 40" stroke="#ffffff" stroke-width="2" opacity="0.3" stroke-linecap="round"/>''',
    "kemenyan": f'''<path d="M16 44 L48 44 L44 58 L20 58 Z" fill="{grad("#c8873a", 1.25, 0.7)}" {O}/>
<path d="M12 40 L52 40 L52 46 L12 46 Z" fill="{grad(GOLD)}" {O1}/>
<ellipse cx="32" cy="40" rx="12" ry="3" fill="#8a2a10"/>
<path d="M28 36 Q22 28 30 22 Q38 16 30 8 M36 36 Q44 28 36 20 Q32 14 38 6" fill="none" stroke="#e8e0f0" stroke-width="3.5" stroke-linecap="round" opacity="0.85"/>
<circle cx="32" cy="39" r="2" fill="#ff7a2a"/>''',
    "sambal_matah": f'''<path d="M8 36 Q32 66 56 36 Z" fill="{grad("#e8eef4", 1.05, 0.75)}" {O}/>
<ellipse cx="32" cy="36" rx="24" ry="5" fill="{grad("#e03a1a", 1.3, 0.8)}" {O1}/>
<g fill="#f3e3c3"><circle cx="22" cy="35" r="2"/><circle cx="36" cy="37" r="2"/><circle cx="42" cy="34" r="1.6"/></g>
<path d="M30 30 Q38 6 52 8 Q48 14 44 16 Q38 22 34 32 Z" fill="{grad("#e8281a", 1.3, 0.8)}" {O}/>
<path d="M50 8 Q54 4 58 6" fill="none" stroke="#3c7020" stroke-width="3" stroke-linecap="round"/>
<path d="M36 22 Q40 14 46 12" fill="none" stroke="#ffffff" stroke-width="1.6" opacity="0.5"/>''',
    "gula_aren": f'''<path d="M8 40 L22 32 L40 38 L26 48 Z" fill="{grad("#a8562a", 1.4, 0.8)}" {O}/>
<path d="M8 40 L26 48 L26 58 L8 50 Z" fill="{grad("#7a3a14")}" {O}/>
<path d="M26 48 L40 38 L40 48 L26 58 Z" fill="{grad("#5a2a10")}" {O}/>
<path d="M28 26 L42 18 L58 24 L44 32 Z" fill="{grad("#b8682a", 1.4, 0.8)}" {O}/>
<path d="M28 26 L44 32 L44 42 L28 36 Z" fill="{grad("#8a4a1c")}" {O}/>
<path d="M44 32 L58 24 L58 34 L44 42 Z" fill="{grad("#6a3010")}" {O}/>
<path d="M14 40 L22 36" stroke="#ffffff" stroke-width="1.6" opacity="0.45" stroke-linecap="round"/>''',
    "lontar_sakti": f'''<rect x="6" y="18" width="52" height="28" rx="4" fill="{grad("#e8d8a0", 1.1, 0.8)}" {O}/>
<path d="M12 26 L52 26 M12 32 L46 32 M12 38 L50 38" stroke="#7a4a22" stroke-width="2" stroke-dasharray="5 2"/>
<rect x="2" y="14" width="8" height="36" rx="3" fill="{grad("#a8692e")}" {O1}/>
<rect x="54" y="14" width="8" height="36" rx="3" fill="{grad("#a8692e")}" {O1}/>
<path d="M32 46 L32 58" stroke="#d02828" stroke-width="2.5"/><circle cx="32" cy="58" r="3" fill="#d02828"/>
<path d="M44 8 L46 13 L51 14 L46 15 L44 20 L42 15 L37 14 L42 13 Z" fill="#fff6c0"/>''',
    "busur_arjuna": f'''<path d="M18 4 Q54 32 18 60" fill="none" stroke="{INK}" stroke-width="7" stroke-linecap="round"/>
<path d="M18 4 Q54 32 18 60" fill="none" stroke="{GOLD}" stroke-width="4" stroke-linecap="round"/>
<line x1="18" y1="4" x2="18" y2="60" stroke="#f3e3c3" stroke-width="1.6"/>
<path d="M8 32 L56 32" stroke="{INK}" stroke-width="3" stroke-linecap="round"/>
<path d="M8 32 L56 32" stroke="#c8873a" stroke-width="1.6"/>
<path d="M52 26 L62 32 L52 38 Z" fill="#d8e0ea" {O1}/>
<circle cx="36" cy="32" r="3" fill="#3ac0e0" {O1}/>''',
    "teropong_rampasan": f'''<g transform="rotate(-25 32 32)">
<rect x="4" y="24" width="20" height="16" rx="3" fill="{grad("#7a4a22", 1.3, 0.7)}" {O}/>
<rect x="22" y="26" width="18" height="12" rx="2" fill="{grad(GOLD, 1.2, 0.7)}" {O}/>
<rect x="38" y="28" width="22" height="8" rx="2" fill="{grad("#7d8696", 1.3, 0.6)}" {O}/>
<ellipse cx="60" cy="32" rx="2" ry="4" fill="#7ac8f0" {O1}/>
<path d="M8 27 L20 27" stroke="#ffffff" stroke-width="1.6" opacity="0.45"/></g>''',
    "sepatu_pelaut": f'''<path d="M6 30 L6 50 L56 50 Q60 42 50 38 L32 34 L28 18 L10 18 Z" fill="{grad("#8a4a1c", 1.35, 0.7)}" {O}/>
<path d="M4 50 L58 50 L58 56 L4 56 Z" fill="#2a1a10" {O1}/>
<path d="M28 24 L36 28 M30 30 L38 32" stroke="#f3e3c3" stroke-width="2" stroke-linecap="round"/>
<path d="M10 22 L10 42" stroke="#ffffff" stroke-width="2" opacity="0.35" stroke-linecap="round"/>
<circle cx="44" cy="44" r="2" fill="{GOLD}"/>''',
    "batu_akik": f'''<ellipse cx="32" cy="46" rx="16" ry="10" fill="none" stroke="{INK}" stroke-width="7"/>
<ellipse cx="32" cy="46" rx="16" ry="10" fill="none" stroke="{GOLD}" stroke-width="4"/>
<path d="M18 30 L32 14 L46 30 L32 42 Z" fill="{grad("#d0201c", 1.5, 0.6)}" {O}/>
<path d="M18 30 L46 30 M32 14 L26 30 L32 42 M32 14 L38 30" stroke="#ffffff" stroke-width="1" opacity="0.4"/>
<path d="M24 26 L30 20" stroke="#ffffff" stroke-width="2.2" opacity="0.7" stroke-linecap="round"/>''',
    "wayang_kulit": f'<g transform="translate(10,2)">{WAYANG}</g>',
    "kalung_taring": f'''<path d="M8 10 Q32 52 56 10" fill="none" stroke="#7a4a22" stroke-width="3"/>
''' + "".join(f'<path d="M{x - 4} {y} Q{x} {y + 18} {x + 4} {y} Z" fill="{grad("#f6efe0", 1.0, 0.75)}" {O1} transform="rotate({r} {x} {y})"/>'
              for x, y, r in ((18, 26, 25), (32, 32, 0), (46, 26, -25))) + f'''
<g fill="#d02828" {O1}><circle cx="12" cy="18" r="2.5"/><circle cx="25" cy="30" r="2.5"/><circle cx="39" cy="30" r="2.5"/><circle cx="52" cy="18" r="2.5"/></g>''',
    "obor_bambu": f'''<rect x="27" y="26" width="10" height="36" rx="3" fill="{grad("#8ab04a", 1.3, 0.7)}" {O}/>
<path d="M27 40 L37 40 M27 52 L37 52" stroke="#4a6a20" stroke-width="2"/>
<path d="M22 26 L42 26 L40 32 L24 32 Z" fill="#7a4a22" {O1}/>
<path d="M32 2 Q20 14 24 24 L40 24 Q44 14 32 2 Z" fill="{grad("#ff7a1a", 1.3, 0.85)}" {O1}/>
<path d="M32 10 Q26 18 28 23 L36 23 Q38 18 32 10 Z" fill="#ffe36a"/>''',
    "gelang_akar_bahar": f'''<ellipse cx="32" cy="34" rx="24" ry="18" fill="none" stroke="{INK}" stroke-width="10"/>
<ellipse cx="32" cy="34" rx="24" ry="18" fill="none" stroke="#2a1a14" stroke-width="7"/>
<ellipse cx="32" cy="34" rx="24" ry="18" fill="none" stroke="#6a3a2a" stroke-width="3" stroke-dasharray="6 4"/>
<path d="M14 24 Q22 16 32 16" fill="none" stroke="#ffffff" stroke-width="2" opacity="0.4" stroke-linecap="round"/>
<circle cx="32" cy="52" r="4" fill="{rgrad(GOLD)}" {O1}/>''',
    "kentongan": f'''<path d="M32 2 L32 10" stroke="#5a3214" stroke-width="3"/>
<rect x="20" y="10" width="24" height="50" rx="10" fill="{grad("#b8732e", 1.35, 0.7)}" {O}/>
<rect x="29" y="20" width="6" height="30" rx="3" fill="#2a1a10"/>
<path d="M20 22 L44 22 M20 48 L44 48" stroke="{GOLD}" stroke-width="2.4"/>
<path d="M24 14 L24 56" stroke="#ffffff" stroke-width="2" opacity="0.35"/>
<path d="M50 12 L60 4" stroke="#7a4a22" stroke-width="4" stroke-linecap="round"/>
<path d="M50 30 Q56 32 50 36 M54 26 Q62 32 54 40" fill="none" stroke="{GOLD}" stroke-width="1.8"/>''',
    "jimat_rajah": f'''<path d="M14 6 L50 6 L50 54 L32 60 L14 54 Z" fill="{grad("#f3e3b0", 1.05, 0.82)}" {O}/>
<circle cx="32" cy="24" r="10" fill="none" stroke="#d02828" stroke-width="2"/>
<path d="M32 14 L32 34 M22 24 L42 24 M25 17 L39 31 M39 17 L25 31" stroke="#d02828" stroke-width="1.6"/>
<path d="M20 40 L44 40 M22 46 L40 46" stroke="#7a1a10" stroke-width="2" stroke-dasharray="3 2"/>
<path d="M32 0 L32 6" stroke="#d02828" stroke-width="2"/>''',
    "lumbung_padi": f'''<path d="M4 30 L32 4 L60 30 Q32 26 4 30 Z" fill="{grad("#c8a040", 1.3, 0.75)}" {O}/>
<path d="M10 26 L32 8 M20 28 L32 12 M44 28 L32 12 M54 26 L32 8" stroke="#8a6a20" stroke-width="1.3"/>
<rect x="14" y="30" width="36" height="20" rx="2" fill="{grad("#a8692e", 1.3, 0.7)}" {O}/>
<path d="M14 36 L50 36 M14 43 L50 43" stroke="#6a3a14" stroke-width="1.4"/>
<path d="M18 50 L18 60 M46 50 L46 60" stroke="{INK}" stroke-width="4" stroke-linecap="round"/>
<path d="M18 50 L18 60 M46 50 L46 60" stroke="#7a4a22" stroke-width="2" stroke-linecap="round"/>
<g fill="{GOLD}"><ellipse cx="27" cy="40" rx="2" ry="3"/><ellipse cx="32" cy="38" rx="2" ry="3"/><ellipse cx="37" cy="40" rx="2" ry="3"/></g>''',
    "kerupuk": f'''<path d="M32 6 Q42 6 46 12 Q56 14 56 24 Q62 32 56 40 Q58 50 46 52 Q42 60 32 58 Q22 60 18 52 Q6 50 8 40 Q2 32 8 24 Q8 14 18 12 Q22 6 32 6 Z" fill="{grad("#f6e8c0", 1.05, 0.8)}" {O}/>
<g fill="none" stroke="#d8b878" stroke-width="1.5"><circle cx="32" cy="32" r="16"/><circle cx="32" cy="32" r="9"/></g>
<g fill="#e8a040"><circle cx="24" cy="22" r="1.6"/><circle cx="40" cy="26" r="1.6"/><circle cx="36" cy="42" r="1.6"/><circle cx="22" cy="38" r="1.6"/></g>''',
}


# --- Medan: Lembah Sungai -------------------------------------------------------------
# Koordinat dunia 960x540. Sungai, jalan, terasering, & jembatan memakai rumus yang sama
# dengan scripts/map.gd supaya objek & penghalang tetap pas di atasnya.

ARENA = (960, 540)
TERASERING = [((190, 140), (150, 110), 1.0), ((260, 450), (140, 95), 2.5), ((880, 470), (120, 90), 4.0)]


def _sungai():
    pts = []
    for i in range(31):
        y = -20.0 + i * 20.0
        pts.append((640 + 50 * math.sin(y * 0.012) + 22 * math.sin(y * 0.031), y))
    return pts


def _jalan():
    return [(i * 60.0, 300 + math.sin(i * 0.7) * 40 - i * 3) for i in range(17)]


def _halus(pts, tutup=False):
    """Path kurva mulus (Catmull-Rom -> Bezier) lewat titik-titik."""
    n = len(pts)
    get = (lambda i: pts[i % n]) if tutup else (lambda i: pts[max(0, min(n - 1, i))])
    d = f"M{pts[0][0]:.1f} {pts[0][1]:.1f}"
    for i in range(n if tutup else n - 1):
        p0, p1, p2, p3 = get(i - 1), get(i), get(i + 1), get(i + 2)
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f" C{c1[0]:.1f} {c1[1]:.1f} {c2[0]:.1f} {c2[1]:.1f} {p2[0]:.1f} {p2[1]:.1f}"
    return d + (" Z" if tutup else "")


def _cincin(c, r, k, sv):
    pts = []
    for i in range(48):
        a = math.tau * i / 48
        w = 1.0 + 0.09 * math.sin(3 * a + sv) + 0.05 * math.sin(5 * a + sv * 2)
        pts.append((c[0] + math.cos(a) * r[0] * k * w, c[1] + math.sin(a) * r[1] * k * w))
    return pts


def medan_lembah():
    rnd = random.Random(7)
    W, H = ARENA
    s = f'<rect width="{W}" height="{H}" fill="{grad("#78c25e", 1.08, 0.92)}"/>'
    for _ in range(26):  # bercak rumput lembut
        x, y, r = rnd.uniform(0, W), rnd.uniform(0, H), rnd.uniform(50, 130)
        c = rnd.choice(["#8fd46c", "#64ac4c", "#9ad877"])
        s += f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{r:.0f}" ry="{r * 0.6:.0f}" fill="{c}" opacity="0.35"/>'
    # Sawah terasering: lapis bertingkat dengan bayangan undakan, hijau padi & air
    warna = ["#9ccf5a", "#7dbd4a", "#a8d8c8", "#8cc850", "#b4dc6a"]
    for c, r, sv in TERASERING:
        s += f'<path d="{_halus(_cincin((c[0] + 4, c[1] + 6), r, 1.04, sv), True)}" fill="#3e7a34" opacity="0.35"/>'
        for i in range(6):
            k = 1.0 - i * 0.15
            ring = _cincin(c, r, k, sv)
            col = warna[(i + int(sv)) % len(warna)]
            s += f'<path d="{_halus([(x, y + 3) for x, y in ring], True)}" fill="{shade(col, 0.72)}"/>'
            s += f'<path d="{_halus(ring, True)}" fill="{col}" stroke="#e8f0b0" stroke-width="2.5"/>'
            if col == "#a8d8c8":  # kilau air sawah
                for _ in range(6):
                    a = rnd.uniform(0, math.tau)
                    x = c[0] + math.cos(a) * r[0] * (k - 0.07)
                    y = c[1] + math.sin(a) * r[1] * (k - 0.07)
                    s += f'<path d="M{x:.0f} {y:.0f} l10 0" stroke="#ffffff" stroke-width="2" opacity="0.7" stroke-linecap="round"/>'
            else:  # barisan padi
                for _ in range(int(40 * k)):
                    a = rnd.uniform(0, math.tau)
                    x = c[0] + math.cos(a) * r[0] * (k - 0.07)
                    y = c[1] + math.sin(a) * r[1] * (k - 0.07)
                    s += f'<path d="M{x:.0f} {y:.0f} l-2 -5 M{x:.0f} {y:.0f} l2 -5" stroke="{shade(col, 0.6)}" stroke-width="1.4" stroke-linecap="round"/>'
    # Jalan setapak tanah
    jalan = _halus(_jalan())
    s += (f'<path d="{jalan}" fill="none" stroke="#9a6c3c" stroke-width="22" stroke-linecap="round"/>'
          f'<path d="{jalan}" fill="none" stroke="#d8b07a" stroke-width="16" stroke-linecap="round"/>'
          f'<path d="{jalan}" fill="none" stroke="#e8c896" stroke-width="5" stroke-linecap="round" stroke-dasharray="14 22" opacity="0.8"/>')
    for x, y in _jalan():
        for _ in range(3):
            s += f'<circle cx="{x + rnd.uniform(-25, 25):.0f}" cy="{y + rnd.uniform(-5, 5):.0f}" r="{rnd.uniform(1.2, 2.2):.1f}" fill="#b08a5a"/>'
    # Sungai: tepian pasir, air bergradasi, kilau, teratai, batu tepi
    sungai = _halus(_sungai())
    for width, col, extra in ((58, "#c8a868", ""), (50, "#efdca0", ""), (38, "#3a86b0", ""), (28, "#56a8cc", ""),
                              (10, "#7cc4e0", ' opacity="0.7"')):
        s += f'<path d="{sungai}" fill="none" stroke="{col}" stroke-width="{width}" stroke-linecap="round"{extra}/>'
    for i, (x, y) in enumerate(_sungai()):
        if i % 2 == 0:
            s += f'<path d="M{x - 10 + (i % 3) * 6:.0f} {y:.0f} q6 -3 12 0" fill="none" stroke="#e8f8ff" stroke-width="2" opacity="0.8" stroke-linecap="round"/>'
        if i % 5 == 1:
            px = x + (12 if i % 2 else -12)
            s += (f'<ellipse cx="{px:.0f}" cy="{y + 6:.0f}" rx="6" ry="4" fill="#5ab04a" stroke="#2e6a2a" stroke-width="1"/>'
                  f'<circle cx="{px + 2:.0f}" cy="{y + 5:.0f}" r="2" fill="#ff8fba"/>')
        if i % 4 == 2:
            for side in (-27, 27):
                s += f'<ellipse cx="{x + side:.0f}" cy="{y:.0f}" rx="{rnd.uniform(3, 5):.1f}" ry="2.5" fill="#a89a8a" stroke="#6a5a4a" stroke-width="0.8"/>'
    # Jembatan kayu di tempat jalan menyeberang (sama dengan map.gd)
    by = 300 + math.sin(640 / 60.0 * 0.7) * 40 - 640 / 60.0 * 3
    bx = 640 + 50 * math.sin(by * 0.012) + 22 * math.sin(by * 0.031)
    s += f'<rect x="{bx - 32:.1f}" y="{by - 10:.1f}" width="64" height="26" rx="3" fill="#000" opacity="0.2"/>'
    papan = grad("#b07a40", 1.2, 0.8)
    for k in range(10):
        s += f'<rect x="{bx - 30 + k * 6:.1f}" y="{by - 11:.1f}" width="5.4" height="22" rx="1" fill="{papan}" stroke="#5a3214" stroke-width="0.8"/>'
    for y in (by - 12, by + 11):
        s += f'<path d="M{bx - 33:.1f} {y:.1f} L{bx + 33:.1f} {y:.1f}" stroke="#5a3214" stroke-width="3.2" stroke-linecap="round"/>'
        s += f'<path d="M{bx - 33:.1f} {y:.1f} L{bx + 33:.1f} {y:.1f}" stroke="#c8873a" stroke-width="1.6" stroke-linecap="round"/>'
    # Rumput & bunga liar (di luar sungai)
    sungai_pts = _sungai()
    for _ in range(260):
        x, y = rnd.uniform(4, W - 4), rnd.uniform(6, H - 4)
        if any(abs(x - sx) < 32 and abs(y - sy) < 14 for sx, sy in sungai_pts):
            continue
        if rnd.random() < 0.18:
            c = rnd.choice(["#ff6a6a", "#ffffff", "#ffd23f", "#c890ff"])
            s += "".join(f'<circle cx="{x + 2.2 * math.cos(a):.1f}" cy="{y + 2.2 * math.sin(a):.1f}" r="1.6" fill="{c}"/>' for a in (0, 1.26, 2.51, 3.77, 5.03))
            s += f'<circle cx="{x:.1f}" cy="{y:.1f}" r="1.2" fill="#f2a020"/>'
        else:
            c = rnd.choice(["#4e9a3e", "#5aa846", "#a8e080"])
            s += f'<path d="M{x:.0f} {y:.0f} l-3 -6 M{x:.0f} {y:.0f} l0 -7 M{x:.0f} {y:.0f} l3 -6" stroke="{c}" stroke-width="1.5" stroke-linecap="round"/>'
    s += f'<rect x="1.5" y="1.5" width="{W - 3}" height="{H - 3}" fill="none" stroke="#3e7a34" stroke-width="3" rx="4"/>'
    return s


# Objek medan (dipakai obstacle.gd): kaki objek = tengah bawah gambar, 3 piksel di atas tepi bawah.
def _bayang(cx, cy, rx, ry=None):
    return f'<ellipse cx="{cx}" cy="{cy}" rx="{rx}" ry="{ry or rx * 0.3}" fill="#000" opacity="0.22"/>'


def objek_semak():
    return _bayang(48, 56, 40) + (
        f'<circle cx="28" cy="40" r="17" fill="{rgrad("#4e9a3e")}" {O}/>'
        f'<circle cx="68" cy="40" r="17" fill="{rgrad("#4e9a3e")}" {O}/>'
        f'<circle cx="48" cy="30" r="20" fill="{rgrad("#64b04c")}" {O}/>'
        '<path d="M36 22 Q44 14 54 16" fill="none" stroke="#ffffff" stroke-width="3" opacity="0.35" stroke-linecap="round"/>'
        f'<g fill="#ff6a8a" stroke="{INK}" stroke-width="1"><circle cx="32" cy="34" r="3"/><circle cx="60" cy="26" r="3"/><circle cx="70" cy="42" r="3"/></g>')


def objek_batu():
    return _bayang(48, 56, 40) + (
        f'<path d="M8 54 L14 30 L34 14 L62 16 L84 34 L88 54 Z" fill="{grad("#a8a49c", 1.25, 0.7)}" {O}/>'
        '<path d="M14 30 L34 14 L46 30 L30 40 Z" fill="#cfcac0" opacity="0.8"/>'
        '<path d="M46 30 L62 16 L84 34 L64 40 Z" fill="#8a8680" opacity="0.6"/>'
        f'<path d="M30 40 L46 30 L64 40 L60 54" fill="none" stroke="{INK}" stroke-width="1.4" opacity="0.5"/>'
        '<path d="M16 44 Q30 38 40 46 Q30 52 16 50 Z" fill="#6aa040" opacity="0.85"/>')


def objek_kelapa():
    s = _bayang(80, 232, 34)
    s += f'<path d="M78 232 Q76 150 96 64" fill="none" stroke="{INK}" stroke-width="14" stroke-linecap="round"/>'
    s += f'<path d="M78 232 Q76 150 96 64" fill="none" stroke="{grad("#a8692e", 1.3, 0.8, False)}" stroke-width="10" stroke-linecap="round"/>'
    for t in range(20, 160, 16):
        s += f'<path d="M{70 + t * 0.06:.0f} {232 - t:.0f} l12 -2" stroke="#6a3a14" stroke-width="2"/>'
    for a in (math.pi + 0.3, math.pi + 1.1, math.pi + 1.6, -0.9, -0.2, 0.5, 2.4):
        ex, ey = 96 + math.cos(a) * 72, 60 + math.sin(a) * 40 + 14
        c1 = (96 + math.cos(a) * 40, 60 + math.sin(a) * 24 - 16)
        c2 = (96 + math.cos(a) * 44, 60 + math.sin(a) * 24 + 2)
        s += (f'<path d="M96 60 Q{c1[0]:.0f} {c1[1]:.0f} {ex:.0f} {ey:.0f} Q{c2[0]:.0f} {c2[1]:.0f} 96 64 Z" fill="{grad("#4ea83a", 1.3, 0.75)}" {O1}/>'
              f'<path d="M96 62 Q{c1[0]:.0f} {c1[1] + 6:.0f} {ex:.0f} {ey - 2:.0f}" fill="none" stroke="#2e6a2a" stroke-width="1.4"/>')
    s += (f'<g {O1}><circle cx="88" cy="70" r="7" fill="{rgrad("#7a5a2a")}"/><circle cx="102" cy="72" r="7" fill="{rgrad("#6a4a1a")}"/>'
          f'<circle cx="95" cy="78" r="7" fill="{rgrad("#8a6a3a")}"/></g>')
    return s


def objek_pisang():
    return _bayang(64, 152, 30) + (
        f'<rect x="56" y="80" width="16" height="74" rx="7" fill="{grad("#8ab04a", 1.3, 0.7, False)}" {O}/>'
        '<path d="M60 96 L68 92 M60 116 L68 112 M60 136 L68 132" stroke="#5a7a2a" stroke-width="2"/>'
        f'<path d="M64 84 Q20 70 6 100 Q34 102 64 90 Z" fill="{grad("#5ab83e", 1.3, 0.75)}" {O1}/>'
        f'<path d="M64 84 Q108 60 124 92 Q94 98 64 90 Z" fill="{grad("#4ea83a", 1.3, 0.75)}" {O1}/>'
        f'<path d="M64 84 Q40 30 64 4 Q84 40 66 86 Z" fill="{grad("#6ac84a", 1.3, 0.75)}" {O1}/>'
        f'<path d="M64 84 Q92 40 120 34 Q106 70 68 88 Z" fill="{grad("#58b03e", 1.3, 0.75)}" {O1}/>'
        f'<path d="M64 84 Q36 38 10 40 Q22 70 60 88 Z" fill="{grad("#4ea83a", 1.25, 0.75)}" {O1}/>'
        '<path d="M64 84 Q60 46 64 8 M64 86 Q96 56 118 38 M64 86 Q34 56 12 42" fill="none" stroke="#2e6a2a" stroke-width="1.4"/>'
        f'<g {O1}><path d="M76 98 Q90 102 92 116 Q82 112 76 104 Z" fill="#f2d84c"/><path d="M76 104 Q92 112 90 126 Q80 120 76 110 Z" fill="#e8c83a"/></g>'
        '<path d="M74 94 Q80 92 78 100" fill="none" stroke="#7a3a20" stroke-width="2.5"/>')


def objek_gubuk():
    s = _bayang(96, 162, 80, 14)
    s += f'<g stroke="{INK}" stroke-width="2" fill="#8a5a2a"><rect x="30" y="110" width="8" height="54"/><rect x="154" y="110" width="8" height="54"/><rect x="92" y="110" width="8" height="54"/></g>'
    s += f'<rect x="22" y="104" width="148" height="10" rx="2" fill="{grad("#b07a40")}" {O}/>'
    s += f'<rect x="34" y="62" width="124" height="44" fill="{grad("#e0c080", 1.15, 0.8)}" {O}/>'
    s += "".join(f'<path d="M{x} 64 L{x} 104" stroke="#b08a50" stroke-width="2"/>' for x in range(42, 156, 8))
    s += f'<rect x="84" y="70" width="26" height="36" rx="2" fill="{grad("#6a3a14")}" {O1}/>'
    s += f'<rect x="44" y="72" width="24" height="18" rx="2" fill="#3a2410" {O1}/><path d="M56 72 L56 90 M44 81 L68 81" stroke="#b08a50" stroke-width="2"/>'
    s += f'<path d="M8 66 L60 14 L132 14 L184 66 Z" fill="{grad("#d8a84a", 1.25, 0.7)}" {O}/>'
    s += "".join(f'<path d="M{20 + i * 12} 64 L{62 + i * 5} 18" stroke="#a87a2a" stroke-width="1.6" opacity="0.8"/>' for i in range(14))
    s += '<path d="M8 66 ' + " ".join(f"Q{14 + i * 12} 72 {20 + i * 12} 66" for i in range(14)) + '" fill="none" stroke="#a87a2a" stroke-width="3"/>'
    s += f'<path d="M60 14 L132 14" stroke="{INK}" stroke-width="5" stroke-linecap="round"/><path d="M60 14 L132 14" stroke="#8a5a2a" stroke-width="3" stroke-linecap="round"/>'
    s += '<path d="M26 56 L64 20" stroke="#ffffff" stroke-width="3" opacity="0.3" stroke-linecap="round"/>'
    return s


def objek_orang_orangan():
    return _bayang(48, 136, 20) + (
        f'<path d="M48 136 L48 40" stroke="{INK}" stroke-width="7" stroke-linecap="round"/><path d="M48 136 L48 40" stroke="#a8692e" stroke-width="4" stroke-linecap="round"/>'
        f'<path d="M14 64 L82 64" stroke="{INK}" stroke-width="6" stroke-linecap="round"/><path d="M14 64 L82 64" stroke="#a8692e" stroke-width="3" stroke-linecap="round"/>'
        f'<path d="M30 58 L66 58 L70 100 Q48 106 26 100 Z" fill="{grad("#d04a3a", 1.25, 0.75)}" {O}/>'
        f'<rect x="34" y="74" width="10" height="10" fill="#f2c94c" {O1}/><rect x="52" y="84" width="10" height="9" fill="#5a8ad0" {O1}/>'
        '<path d="M14 64 l-6 6 M14 64 l-6 -2 M82 64 l6 6 M82 64 l6 -2 M40 102 l-2 8 M48 104 l0 8 M56 102 l2 8" stroke="#e8c46a" stroke-width="2.5" stroke-linecap="round"/>'
        f'<circle cx="48" cy="44" r="13" fill="{rgrad("#e8d8a0")}" {O}/>'
        f'<path d="M42 42 l4 4 M46 42 l-4 4 M52 42 l4 4 M56 42 l-4 4" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M42 51 Q48 54 54 51" fill="none" stroke="{INK}" stroke-width="1.6"/>'
        f'<path d="M18 38 L48 18 L78 38 Q48 44 18 38 Z" fill="{grad("#e8c46a", 1.25, 0.75)}" {O}/>'
        '<path d="M48 18 L38 39 M48 18 L58 39" stroke="#a87a2a" stroke-width="1.2"/>')


def objek_bebek():
    return ('<ellipse cx="32" cy="40" rx="26" ry="6" fill="#3a86b0" opacity="0.5"/>'
            f'<path d="M8 32 Q8 20 24 20 L40 22 Q50 24 48 34 Q40 44 22 42 Q8 40 8 32 Z" fill="{grad("#ffffff", 1.0, 0.82)}" {O}/>'
            f'<path d="M4 26 L12 30 L8 34 Z" fill="#f3f3f3" {O1}/>'
            '<path d="M18 30 Q28 26 36 32" fill="none" stroke="#c8ccd4" stroke-width="2"/>'
            f'<circle cx="44" cy="16" r="9" fill="{rgrad("#ffffff")}" {O}/>'
            f'<path d="M51 16 L62 18 L52 22 Z" fill="#f5a020" {O1}/>'
            f'<circle cx="46" cy="14" r="1.8" fill="{INK}"/>')


# nama: (lebar, tinggi logis, fungsi gambar)
OBJEK = {"semak": (24, 16, objek_semak), "batu": (24, 16, objek_batu), "kelapa": (40, 60, objek_kelapa),
         "pisang": (32, 40, objek_pisang), "gubuk": (48, 42, objek_gubuk), "orang_orangan": (24, 36, objek_orang_orangan),
         "bebek": (16, 12, objek_bebek)}


# --- Medan lain: Hutan, Desa, Pelabuhan, Benteng --------------------------------------
# Angka posisi (dermaga, laut, alun-alun, jalan) sama dengan scripts/map.gd.

SEA_TOP = 445


def _rumput(rnd, n, warna, hindari=lambda x, y: False):
    s = ""
    W, H = ARENA
    for _ in range(n):
        x, y = rnd.uniform(4, W - 4), rnd.uniform(6, H - 4)
        if hindari(x, y):
            continue
        c = rnd.choice(warna)
        s += f'<path d="M{x:.0f} {y:.0f} l-3 -6 M{x:.0f} {y:.0f} l0 -7 M{x:.0f} {y:.0f} l3 -6" stroke="{c}" stroke-width="1.5" stroke-linecap="round"/>'
    return s


def _bercak(rnd, n, warna, rmin, rmax, op=0.35):
    W, H = ARENA
    s = ""
    for _ in range(n):
        x, y, r = rnd.uniform(0, W), rnd.uniform(0, H), rnd.uniform(rmin, rmax)
        s += f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{r:.0f}" ry="{r * 0.6:.0f}" fill="{rnd.choice(warna)}" opacity="{op}"/>'
    return s


def medan_hutan():
    rnd = random.Random(11)
    W, H = ARENA
    s = f'<rect width="{W}" height="{H}" fill="{grad("#3f7a3a", 1.05, 0.85)}"/>'
    s += _bercak(rnd, 30, ["#4e8e40", "#2f6a30", "#5a9a44"], 40, 110)
    for _ in range(12):  # sinar matahari menembus kanopi
        x, y, r = rnd.uniform(0, W), rnd.uniform(0, H), rnd.uniform(30, 70)
        s += f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="{r:.0f}" ry="{r * 0.55:.0f}" fill="#e8f0a0" opacity="0.18"/>'
    jalan = _halus([(i * 60.0, H / 2 + math.sin(i * 0.8) * 70) for i in range(17)])
    s += (f'<path d="{jalan}" fill="none" stroke="#5a3e22" stroke-width="26" stroke-linecap="round"/>'
          f'<path d="{jalan}" fill="none" stroke="#8a6438" stroke-width="20" stroke-linecap="round"/>'
          f'<path d="{jalan}" fill="none" stroke="#a07a48" stroke-width="6" stroke-linecap="round" stroke-dasharray="10 26" opacity="0.8"/>')
    for _ in range(6):  # genangan air
        x, y = rnd.uniform(60, W - 60), rnd.uniform(60, H - 60)
        s += (f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="22" ry="10" fill="#2e5a6a" stroke="#1e3a2a" stroke-width="2"/>'
              f'<path d="M{x - 10:.0f} {y - 3:.0f} q6 -3 12 0" stroke="#a8d8e8" stroke-width="2" fill="none" opacity="0.7"/>')
    for _ in range(120):  # pakis & daun gugur
        x, y = rnd.uniform(4, W - 4), rnd.uniform(6, H - 4)
        if rnd.random() < 0.45:
            c = rnd.choice(["#d88a2a", "#c0502a", "#e8b040"])
            s += f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="3.5" ry="2" fill="{c}" transform="rotate({rnd.uniform(0, 180):.0f} {x:.0f} {y:.0f})"/>'
        else:
            s += "".join(f'<path d="M{x:.0f} {y:.0f} q{d * 5} -6 {d * 10} -4" stroke="#6ab84a" stroke-width="2" fill="none" stroke-linecap="round"/>' for d in (-1, 1))
            s += f'<path d="M{x:.0f} {y:.0f} l0 -10" stroke="#6ab84a" stroke-width="2" stroke-linecap="round"/>'
    for _ in range(10):  # jamur
        x, y = rnd.uniform(20, W - 20), rnd.uniform(20, H - 20)
        s += (f'<rect x="{x - 1.5:.0f}" y="{y - 4:.0f}" width="3" height="5" fill="#f3e3c3"/>'
              f'<path d="M{x - 5:.0f} {y - 3:.0f} Q{x:.0f} {y - 11:.0f} {x + 5:.0f} {y - 3:.0f} Z" fill="#e0402a" stroke="{INK}" stroke-width="0.8"/>'
              f'<circle cx="{x - 1:.0f}" cy="{y - 6:.0f}" r="1" fill="#ffffff"/>')
    s += _rumput(rnd, 160, ["#2a5a26", "#5aa846", "#3e7a34"])
    s += f'<rect x="1.5" y="1.5" width="{W - 3}" height="{H - 3}" fill="none" stroke="#1e3a1e" stroke-width="3" rx="4"/>'
    return s


def medan_desa():
    rnd = random.Random(13)
    W, H = ARENA
    s = f'<rect width="{W}" height="{H}" fill="{grad("#c8a46a", 1.08, 0.9)}"/>'
    s += _bercak(rnd, 24, ["#a8c860", "#8ab04a", "#d8b880"], 50, 120, 0.4)
    jalan = "#e0c48e"
    s += (f'<rect x="0" y="{H / 2 - 22}" width="{W}" height="44" fill="#a8844e"/><rect x="0" y="{H / 2 - 19}" width="{W}" height="38" fill="{jalan}"/>'
          f'<rect x="{W / 2 - 22}" y="0" width="44" height="{H}" fill="#a8844e"/><rect x="{W / 2 - 19}" y="0" width="38" height="{H}" fill="{jalan}"/>')
    for _ in range(80):  # kerikil di jalan
        if rnd.random() < 0.5:
            x, y = rnd.uniform(0, W), H / 2 + rnd.uniform(-16, 16)
        else:
            x, y = W / 2 + rnd.uniform(-16, 16), rnd.uniform(0, H)
        s += f'<circle cx="{x:.0f}" cy="{y:.0f}" r="{rnd.uniform(1, 2):.1f}" fill="#b89a6a"/>'
    px, py, pw, ph = W / 2 - 150, H / 2 - 90, 300, 180
    s += f'<rect x="{px - 4}" y="{py + 2}" width="{pw + 8}" height="{ph + 6}" rx="10" fill="#000" opacity="0.15"/>'
    s += f'<rect x="{px}" y="{py}" width="{pw}" height="{ph}" rx="8" fill="{grad("#b8b0a0", 1.1, 0.85)}" stroke="#6a6052" stroke-width="3"/>'
    for gx in range(int(px) + 4, int(px + pw) - 4, 20):  # ubin batu alun-alun
        for gy in range(int(py) + 4, int(py + ph) - 4, 20):
            c = rnd.choice(["#c8c0b0", "#bab2a2", "#d0c8b8"])
            s += f'<rect x="{gx}" y="{gy}" width="18" height="18" rx="3" fill="{c}"/>'
    cx, cy = W / 2, H / 2
    s += f'<circle cx="{cx}" cy="{cy}" r="56" fill="#a89a84" stroke="#6a6052" stroke-width="2"/>'
    for i in range(8):  # motif kawung di tengah alun-alun
        a = math.tau * i / 8
        x, y = cx + math.cos(a) * 34, cy + math.sin(a) * 34
        s += f'<ellipse cx="{x:.1f}" cy="{y:.1f}" rx="14" ry="8" fill="#c8a46a" stroke="#6a4a2a" stroke-width="1.5" transform="rotate({math.degrees(a):.0f} {x:.1f} {y:.1f})"/>'
    s += f'<circle cx="{cx}" cy="{cy}" r="14" fill="{rgrad(GOLD)}" stroke="#6a4a2a" stroke-width="2"/>'
    for _ in range(26):  # bunga kecil di luar alun-alun
        x, y = rnd.uniform(10, W - 10), rnd.uniform(10, H - 10)
        if px - 10 < x < px + pw + 10 and py - 10 < y < py + ph + 10:
            continue
        c = rnd.choice(["#ff6a6a", "#ffffff", "#ffd23f", "#ff8fba"])
        s += "".join(f'<circle cx="{x + 2.2 * math.cos(a):.1f}" cy="{y + 2.2 * math.sin(a):.1f}" r="1.6" fill="{c}"/>' for a in (0, 1.26, 2.51, 3.77, 5.03))
    s += _rumput(rnd, 200, ["#6a9a3a", "#8ab04a", "#5a8a32"],
                 lambda x, y: (px - 6 < x < px + pw + 6 and py - 6 < y < py + ph + 6) or abs(y - H / 2) < 24 or abs(x - W / 2) < 24)
    s += f'<rect x="1.5" y="1.5" width="{W - 3}" height="{H - 3}" fill="none" stroke="#7a5a32" stroke-width="3" rx="4"/>'
    return s


def medan_pelabuhan():
    rnd = random.Random(17)
    W, H = ARENA
    s = f'<rect width="{W}" height="{H}" fill="{grad("#f0d8a0", 1.05, 0.9)}"/>'
    s += _bercak(rnd, 20, ["#e8cc90", "#f8e4b0", "#d8bc80"], 40, 100, 0.5)
    for _ in range(90):  # kerang & jejak di pasir
        x, y = rnd.uniform(8, W - 8), rnd.uniform(8, SEA_TOP - 12)
        if 60 < x < 900 and 225 < y < 405:
            continue
        if rnd.random() < 0.3:
            s += f'<path d="M{x - 3:.0f} {y:.0f} Q{x:.0f} {y - 6:.0f} {x + 3:.0f} {y:.0f} Z" fill="#ffd8c8" stroke="#b8786a" stroke-width="0.8"/>'
        else:
            s += f'<ellipse cx="{x:.0f}" cy="{y:.0f}" rx="2" ry="1.4" fill="#c8a870"/>'
    # Laut dengan gradasi, buih, & ombak
    s += f'<rect x="0" y="{SEA_TOP}" width="{W}" height="{H - SEA_TOP}" fill="{grad("#3aa0c8", 1.15, 0.75)}"/>'
    buih = "M0 %d " % (SEA_TOP + 2) + " ".join(f"Q{x + 15} {SEA_TOP + (8 if (x // 30) % 2 else -2)} {x + 30} {SEA_TOP + 2}" for x in range(0, W, 30))
    s += f'<path d="{buih}" fill="none" stroke="#ffffff" stroke-width="5" stroke-linecap="round"/>'
    s += f'<rect x="0" y="{SEA_TOP - 10}" width="{W}" height="10" fill="#d8b878" opacity="0.6"/>'
    for _ in range(60):
        x, y = rnd.uniform(0, W), rnd.uniform(SEA_TOP + 14, H - 6)
        s += f'<path d="M{x:.0f} {y:.0f} q6 -4 12 0 q6 4 12 0" fill="none" stroke="#bfe8f8" stroke-width="2" opacity="0.7" stroke-linecap="round"/>'
    # Tiang dermaga menjorok ke laut
    for x in (280, 640):
        s += f'<rect x="{x - 2}" y="{SEA_TOP - 4}" width="30" height="64" fill="#000" opacity="0.18"/>'
        s += f'<rect x="{x}" y="{SEA_TOP - 6}" width="26" height="62" rx="2" fill="{grad("#a8703a", 1.2, 0.8)}" stroke="#4a2a10" stroke-width="1.5"/>'
        s += "".join(f'<path d="M{x} {y} L{x + 26} {y}" stroke="#6a4020" stroke-width="1.2"/>' for y in range(SEA_TOP + 2, SEA_TOP + 56, 8))
        s += f'<rect x="{x - 3}" y="{SEA_TOP + 52}" width="6" height="12" fill="#4a2a10"/><rect x="{x + 23}" y="{SEA_TOP + 52}" width="6" height="12" fill="#4a2a10"/>'
    # Lantai dermaga kayu
    dx, dy, dw, dh = 60, 230, 840, 170
    s += f'<rect x="{dx - 2}" y="{dy + 4}" width="{dw + 4}" height="{dh + 4}" rx="4" fill="#000" opacity="0.2"/>'
    s += f'<rect x="{dx}" y="{dy}" width="{dw}" height="{dh}" rx="4" fill="{grad("#b47c44", 1.15, 0.85)}" stroke="#4a2a10" stroke-width="3"/>'
    for i, y in enumerate(range(dy, dy + dh, 12)):
        s += f'<path d="M{dx} {y} L{dx + dw} {y}" stroke="#6a4020" stroke-width="1.4"/>'
        for x in range(dx + (i % 2) * 36, dx + dw, 72):
            s += f'<path d="M{x} {y} L{x} {y + 12}" stroke="#6a4020" stroke-width="1.2"/><circle cx="{x + 4}" cy="{y + 6}" r="1" fill="#3a2010"/>'
        if i % 3 == 1:
            s += f'<path d="M{dx + 4} {y + 3} L{dx + dw - 4} {y + 3}" stroke="#d8a868" stroke-width="1.2" opacity="0.5"/>'
    for x, y in ((140, 250), (820, 380), (470, 390)):  # gulungan tambang
        s += (f'<circle cx="{x}" cy="{y}" r="9" fill="#d8b878" stroke="#7a5a2a" stroke-width="1.5"/>'
              f'<circle cx="{x}" cy="{y}" r="5" fill="none" stroke="#7a5a2a" stroke-width="1.5"/>')
    s += f'<rect x="1.5" y="1.5" width="{W - 3}" height="{H - 3}" fill="none" stroke="#a8844e" stroke-width="3" rx="4"/>'
    return s


def medan_benteng():
    rnd = random.Random(19)
    W, H = ARENA
    s = f'<rect width="{W}" height="{H}" fill="#3a3a44"/>'
    for x in range(0, W, 40):  # ubin batu besar dengan nat
        for y in range(0, H, 40):
            v = rnd.uniform(0.9, 1.1)
            s += f'<rect x="{x + 1.5}" y="{y + 1.5}" width="37" height="37" rx="4" fill="{grad(shade("#6a6a76", v), 1.12, 0.88)}"/>'
            if rnd.random() < 0.2:
                s += f'<path d="M{x + 8} {y + 10} l8 6 l-2 8 l6 6" fill="none" stroke="#2e2e36" stroke-width="1.4"/>'
            if rnd.random() < 0.12:
                s += f'<ellipse cx="{x + 20}" cy="{y + 22}" rx="{rnd.uniform(4, 9):.0f}" ry="4" fill="#8a4a2a" opacity="0.45"/>'
    # Karpet merah lambang Kekaisaran menuju tengah
    for r in ((W / 2 - 16, 0, 32, H), (0, H / 2 - 16, W, 32)):
        s += f'<rect x="{r[0]}" y="{r[1]}" width="{r[2]}" height="{r[3]}" fill="#7a1e1a"/>'
    s += f'<rect x="{W / 2 - 13}" y="0" width="26" height="{H}" fill="#a82a22"/><rect x="0" y="{H / 2 - 13}" width="{W}" height="26" fill="#a82a22"/>'
    s += f'<path d="M{W / 2 - 9} 0 L{W / 2 - 9} {H} M{W / 2 + 9} 0 L{W / 2 + 9} {H} M0 {H / 2 - 9} L{W} {H / 2 - 9} M0 {H / 2 + 9} L{W} {H / 2 + 9}" stroke="{GOLD}" stroke-width="1.5" opacity="0.8"/>'
    cx, cy = W / 2, H / 2
    s += f'<circle cx="{cx}" cy="{cy}" r="66" fill="{rgrad("#4a4a56")}" stroke="#1e1e26" stroke-width="3"/>'
    s += f'<circle cx="{cx}" cy="{cy}" r="58" fill="none" stroke="#9aa0ac" stroke-width="3"/>'
    gigi = " ".join(f"M{cx + math.cos(a) * 40:.1f} {cy + math.sin(a) * 40:.1f} L{cx + math.cos(a) * 50:.1f} {cy + math.sin(a) * 50:.1f}"
                    for a in (math.tau * i / 16 for i in range(16)))
    s += f'<path d="{gigi}" stroke="#7a7e8a" stroke-width="7"/>'
    s += f'<circle cx="{cx}" cy="{cy}" r="40" fill="{rgrad("#7a7e8a")}" stroke="#1e1e26" stroke-width="2"/>'
    s += f'<circle cx="{cx}" cy="{cy}" r="22" fill="{rgrad("#c0302a")}" stroke="#1e1e26" stroke-width="2"/>'
    s += f'<path d="M{cx} {cy - 14} L{cx + 12} {cy + 8} L{cx - 12} {cy + 8} Z" fill="#2e2e36"/>'
    for x, y in ((40, 40), (W - 40, 40), (40, H - 40), (W - 40, H - 40)):  # pelat besi berpaku di sudut
        s += f'<rect x="{x - 26}" y="{y - 26}" width="52" height="52" rx="4" fill="{grad("#7a7e8a", 1.2, 0.75)}" stroke="#1e1e26" stroke-width="2"/>'
        s += "".join(f'<circle cx="{x + dx}" cy="{y + dy}" r="2.5" fill="#c8ccd4" stroke="#1e1e26" stroke-width="0.8"/>' for dx in (-18, 18) for dy in (-18, 18))
    s += f'<rect x="1.5" y="1.5" width="{W - 3}" height="{H - 3}" fill="none" stroke="#1e1e26" stroke-width="4" rx="4"/>'
    return s


# --- Objek medan lain ---------------------------------------------------------------

def objek_pohon():
    s = _bayang(64, 182, 44)
    s += f'<path d="M56 182 L58 116 Q64 110 70 116 L72 182 Z" fill="{grad("#8a5a2a", 1.3, 0.75, False)}" {O}/>'
    s += f'<path d="M62 150 Q50 136 44 120 M66 140 Q78 128 86 118" fill="none" stroke="{INK}" stroke-width="6" stroke-linecap="round"/>'
    s += f'<path d="M62 150 Q50 136 44 120 M66 140 Q78 128 86 118" fill="none" stroke="#8a5a2a" stroke-width="3.5" stroke-linecap="round"/>'
    for cx, cy, r, c in ((40, 100, 30, "#3e8a34"), (88, 98, 30, "#3e8a34"), (64, 70, 44, "#4ea83a"),
                         (44, 64, 26, "#5ab83e"), (84, 58, 24, "#5ab83e"), (64, 40, 22, "#6ac84a")):
        s += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{rgrad(c)}" {O}/>'
    s += '<path d="M44 34 Q54 22 68 24" fill="none" stroke="#ffffff" stroke-width="4" opacity="0.35" stroke-linecap="round"/>'
    s += f'<g {O1}><circle cx="52" cy="92" r="5" fill="#f2a020"/><circle cx="80" cy="80" r="5" fill="#f2a020"/><circle cx="70" cy="104" r="5" fill="#f2a020"/></g>'
    return s


def objek_beringin():
    s = _bayang(136, 294, 110, 22)
    s += f'<path d="M108 294 Q114 230 116 190 L156 190 Q158 230 164 294 Z" fill="{grad("#7a4a22", 1.3, 0.7, False)}" {O}/>'
    s += "".join(f'<path d="M{x} 294 Q{x + 8} 260 {x + 14} 240" fill="none" stroke="#5a3214" stroke-width="5" stroke-linecap="round"/>' for x in (100, 150, 170))
    for x in (54, 76, 96, 178, 198, 220):  # akar gantung
        s += f'<path d="M{x} 150 Q{x + 4} 220 {x} 290" fill="none" stroke="#5a3214" stroke-width="2.5"/>'
    for cx, cy, r, c in ((60, 140, 56, "#2f7a2e"), (212, 140, 56, "#2f7a2e"), (136, 120, 92, "#3e8a34"), (78, 96, 50, "#4ea83a"),
                         (196, 92, 50, "#4ea83a"), (136, 66, 60, "#5ab83e"), (110, 40, 32, "#6ac84a"), (170, 44, 30, "#6ac84a")):
        s += f'<circle cx="{cx}" cy="{cy}" r="{r}" fill="{rgrad(c)}" {O}/>'
    s += '<path d="M90 30 Q110 12 140 14" fill="none" stroke="#ffffff" stroke-width="6" opacity="0.3" stroke-linecap="round"/>'
    return s


def objek_joglo():
    s = _bayang(136, 198, 120, 16)
    s += f'<rect x="44" y="128" width="184" height="68" fill="{grad("#f3e3c0", 1.05, 0.85)}" {O}/>'
    for x in (44, 96, 168, 220):
        s += f'<rect x="{x}" y="128" width="8" height="68" fill="{grad("#7a4a22", 1.2, 0.8, False)}" {O1}/>'
    s += f'<rect x="120" y="148" width="32" height="48" rx="2" fill="{grad("#8a4a1c", 1.2, 0.75)}" {O1}/><circle cx="146" cy="174" r="2" fill="{GOLD}"/>'
    for x in (62, 186):
        s += f'<rect x="{x}" y="146" width="24" height="22" rx="2" fill="#4a2a14" {O1}/>'
        s += f'<path d="M{x} 157 L{x + 24} 157 M{x + 12} 146 L{x + 12} 168" stroke="#c8873a" stroke-width="2"/>'
    s += f'<rect x="36" y="192" width="200" height="8" rx="2" fill="#a89a84" {O1}/>'
    s += f'<path d="M12 140 L260 140 L212 84 L60 84 Z" fill="{grad("#c0502a", 1.25, 0.75)}" {O}/>'
    s += "".join(f'<path d="M{24 + i * 8} {132 - i * 9} L{248 - i * 8} {132 - i * 9}" stroke="#8a3218" stroke-width="2"/>' for i in range(5))
    s += f'<path d="M76 88 L196 88 L164 24 L108 24 Z" fill="{grad("#a8401e", 1.3, 0.75)}" {O}/>'
    s += "".join(f'<path d="M{88 + i * 6} {78 - i * 12} L{184 - i * 6} {78 - i * 12}" stroke="#7a2a12" stroke-width="2"/>' for i in range(4))
    s += f'<path d="M104 24 L168 24" stroke="{INK}" stroke-width="6" stroke-linecap="round"/><path d="M104 24 L168 24" stroke="{GOLD}" stroke-width="3.5" stroke-linecap="round"/>'
    s += f'<path d="M100 24 Q96 12 106 10 M172 24 Q176 12 166 10" fill="none" stroke="{GOLD}" stroke-width="3" stroke-linecap="round"/>'
    s += '<path d="M24 134 L66 92" stroke="#ffffff" stroke-width="3" opacity="0.3" stroke-linecap="round"/>'
    return s


def objek_lumbung():
    s = _bayang(64, 174, 50, 10)
    for x in (34, 54, 74, 94):
        s += f'<rect x="{x - 3}" y="136" width="6" height="38" fill="#5a3214" {O1}/>'
        s += f'<ellipse cx="{x}" cy="138" rx="7" ry="3" fill="#8a8680" {O1}/>'
    s += f'<rect x="26" y="88" width="76" height="50" rx="3" fill="{grad("#b07a40", 1.25, 0.75)}" {O}/>'
    s += "".join(f'<path d="M26 {y} L102 {y}" stroke="#6a3a14" stroke-width="1.6"/>' for y in (100, 112, 124))
    s += f'<rect x="54" y="100" width="20" height="24" rx="2" fill="#4a2a10" {O1}/>'
    s += f'<path d="M10 96 Q64 104 118 96 L96 22 Q64 0 32 22 Z" fill="{grad("#e0b050", 1.25, 0.7)}" {O}/>'
    s += "".join(f'<path d="M{20 + i * 10} 98 Q{40 + i * 3} 50 {50 + i * 2} 14" fill="none" stroke="#a87a2a" stroke-width="1.6" opacity="0.8"/>' for i in range(9))
    s += f'<g fill="{GOLD}" {O1}><ellipse cx="18" cy="160" rx="6" ry="10"/><ellipse cx="110" cy="160" rx="6" ry="10"/></g>'
    s += '<path d="M28 80 Q36 40 52 24" fill="none" stroke="#ffffff" stroke-width="3" opacity="0.3" stroke-linecap="round"/>'
    return s


def objek_peti():
    s = _bayang(48, 70, 40)
    s += f'<rect x="10" y="12" width="76" height="58" rx="3" fill="{grad("#c08a4a", 1.25, 0.75)}" {O}/>'
    s += "".join(f'<path d="M10 {y} L86 {y}" stroke="#7a4a20" stroke-width="1.6"/>' for y in (26, 41, 56))
    s += f'<path d="M14 16 L82 66 M82 16 L14 66" stroke="#7a4a20" stroke-width="5"/>'
    s += "".join(f'<rect x="{x}" y="{y}" width="10" height="10" fill="#7d8696" {O1}/>' for x in (10, 76) for y in (12, 60))
    s += '<path d="M18 18 L48 18" stroke="#ffffff" stroke-width="2.5" opacity="0.35" stroke-linecap="round"/>'
    s += f'<rect x="36" y="32" width="24" height="14" rx="2" fill="#f3e3c3" {O1}/><path d="M40 39 L56 39" stroke="#d02828" stroke-width="2"/>'
    return s


def objek_tong():
    s = _bayang(36, 70, 28)
    s += f'<path d="M12 14 Q6 40 12 66 Q36 74 60 66 Q66 40 60 14 Q36 6 12 14 Z" fill="{grad("#a8602a", 1.3, 0.7, False)}" {O}/>'
    s += "".join(f'<path d="M{x} 12 Q{x + (x - 36) * 0.12:.0f} 40 {x} 68" fill="none" stroke="#6a3a14" stroke-width="1.4"/>' for x in (22, 36, 50))
    for y in (22, 56):
        s += f'<path d="M9 {y} Q36 {y + 6} 63 {y}" fill="none" stroke="{INK}" stroke-width="6"/><path d="M9 {y} Q36 {y + 6} 63 {y}" fill="none" stroke="#9aa3b2" stroke-width="3.5"/>'
    s += f'<ellipse cx="36" cy="13" rx="24" ry="6" fill="{grad("#8a4a1c")}" {O1}/>'
    s += '<path d="M18 26 L18 52" stroke="#ffffff" stroke-width="3" opacity="0.3" stroke-linecap="round"/>'
    return s


def objek_mercusuar():
    s = _bayang(80, 326, 62, 14)
    s += f'<path d="M32 324 L128 324 L112 92 L48 92 Z" fill="{grad("#f6f2ea", 1.05, 0.8, False)}" {O}/>'
    for i in range(3):
        y0, y1 = 280 - i * 72, 250 - i * 72
        w0, w1 = 48 - (324 - y0) * 16 / 232, 48 - (324 - y1) * 16 / 232
        s += f'<path d="M{80 - w0:.1f} {y0} L{80 + w0:.1f} {y0} L{80 + w1:.1f} {y1} L{80 - w1:.1f} {y1} Z" fill="{grad("#d0322a", 1.2, 0.8, False)}"/>'
    s += f'<path d="M32 324 L128 324 L112 92 L48 92 Z" fill="none" {O}/>'
    s += f'<rect x="68" y="290" width="24" height="34" rx="10" fill="#4a2a14" {O1}/>'
    s += f'<rect x="72" y="200" width="16" height="20" rx="6" fill="#7ac8f0" {O1}/>'
    s += f'<rect x="36" y="84" width="88" height="10" rx="2" fill="#4a4f5c" {O}/>'
    s += f'<circle cx="80" cy="60" r="44" fill="#fff6a0" opacity="0.25"/>'
    s += f'<rect x="52" y="44" width="56" height="40" rx="4" fill="{rgrad("#ffe36a")}" {O}/>'
    s += f'<path d="M66 44 L66 84 M80 44 L80 84 M94 44 L94 84" stroke="{INK}" stroke-width="2"/>'
    s += f'<path d="M44 46 L116 46 L80 8 Z" fill="{grad("#d0322a", 1.3, 0.7)}" {O}/>'
    s += f'<circle cx="80" cy="6" r="4" fill="{GOLD}" {O1}/>'
    s += '<path d="M56 300 L62 110" stroke="#ffffff" stroke-width="4" opacity="0.4" stroke-linecap="round"/>'
    return s


def objek_pinisi():
    s = '<ellipse cx="160" cy="268" rx="150" ry="14" fill="#1e5a7a" opacity="0.45"/>'
    for m, top in ((116, 30), (204, 46)):
        s += f'<path d="M{m} 226 L{m} {top}" stroke="{INK}" stroke-width="7" stroke-linecap="round"/><path d="M{m} 226 L{m} {top}" stroke="#8a5a2a" stroke-width="4" stroke-linecap="round"/>'
        s += f'<path d="M{m + 4} {top + 10} Q{m + 66} {top + 70} {m + 60} {top + 150} L{m + 4} {top + 160} Z" fill="{grad("#fbf4e4", 1.0, 0.82, False)}" {O1}/>'
        s += f'<path d="M{m - 4} {top + 16} Q{m - 50} {top + 80} {m - 44} {top + 150} L{m - 4} {top + 154} Z" fill="{grad("#efe4cc", 1.0, 0.82, False)}" {O1}/>'
        s += f'<path d="M{m} {top} L{m} {top - 14}" stroke="{INK}" stroke-width="2"/><rect x="{m + 1}" y="{top - 14}" width="16" height="6" fill="#e8283a"/><rect x="{m + 1}" y="{top - 8}" width="16" height="6" fill="#ffffff"/>'
    s += f'<path d="M260 196 L314 150" stroke="{INK}" stroke-width="4"/><path d="M262 196 L312 152" stroke="#8a5a2a" stroke-width="2"/>'
    s += f'<path d="M14 196 L300 186 Q316 186 312 198 L284 256 Q160 272 44 258 Z" fill="{grad("#8a4a1c", 1.3, 0.7)}" {O}/>'
    s += f'<path d="M18 206 L304 196" stroke="{GOLD}" stroke-width="4"/><path d="M28 226 L296 216" stroke="#c0502a" stroke-width="3"/>'
    s += "".join(f'<circle cx="{x}" cy="{238 - (x - 60) * 0.03:.0f}" r="4" fill="#4a2a10" {O1}/>' for x in range(70, 280, 30))
    s += f'<path d="M14 196 Q4 180 20 172" fill="none" stroke="#8a4a1c" stroke-width="6" stroke-linecap="round"/>'
    s += '<path d="M30 262 q20 -8 40 0 q20 8 40 0 M200 264 q20 -8 40 0 q20 8 40 0" fill="none" stroke="#ffffff" stroke-width="3" opacity="0.7" stroke-linecap="round"/>'
    return s


def _bata(x0, y0, x1, y1, c="#7a7e8a", h=12, w=24):
    s = f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" fill="{grad(c, 1.2, 0.75)}" {O}/>'
    for i, y in enumerate(range(y0 + h, y1, h)):
        s += f'<path d="M{x0} {y} L{x1} {y}" stroke="#3a3e48" stroke-width="1.4"/>'
    for i, y in enumerate(range(y0, y1 - 2, h)):
        for x in range(x0 + (i % 2) * w // 2 + w, x1, w):
            s += f'<path d="M{x} {y} L{x} {min(y + h, y1)}" stroke="#3a3e48" stroke-width="1.2"/>'
    return s


def objek_tembok():
    s = _bayang(176, 134, 170, 12)
    s += _bata(16, 44, 336, 132)
    for x in range(16, 336, 40):
        s += f'<rect x="{x}" y="22" width="24" height="24" fill="{grad("#8a8e9a", 1.2, 0.8)}" {O1}/>'
    s += f'<rect x="16" y="104" width="320" height="10" fill="#a82a22" stroke="{INK}" stroke-width="1.2"/>'
    s += "".join(f'<circle cx="{x}" cy="109" r="2.5" fill="#d8dce4"/>' for x in range(36, 336, 40))
    s += '<path d="M24 52 L328 52" stroke="#ffffff" stroke-width="3" opacity="0.25"/>'
    return s


def objek_tembok_v():
    s = _bayang(32, 294, 26, 8)
    s += _bata(10, 24, 54, 292, "#6a6e7a", 16, 22)
    s += f'<rect x="4" y="10" width="56" height="18" rx="2" fill="{grad("#8a8e9a", 1.2, 0.8)}" {O}/>'
    s += f'<rect x="10" y="244" width="44" height="48" fill="{grad("#7a7e8a", 1.25, 0.8)}" {O1}/>'
    s += f'<rect x="10" y="236" width="44" height="8" fill="#a82a22" stroke="{INK}" stroke-width="1"/>'
    return s


def objek_meriam_benteng():
    s = _bayang(80, 94, 60, 8)
    s += f'<g transform="rotate(-18 60 54)"><path d="M30 42 L140 34 Q150 34 150 44 L150 58 Q150 66 140 66 L30 64 Q18 64 18 53 Q18 42 30 42 Z" fill="{grad("#4a4f5c", 1.4, 0.6)}" {O}/>'
    s += f'<rect x="138" y="30" width="12" height="40" rx="3" fill="{grad("#4a4f5c", 1.3, 0.7)}" {O1}/><circle cx="18" cy="53" r="8" fill="#2a2e38" {O1}/>'
    s += f'<path d="M50 40 L50 66 M80 38 L80 66" stroke="#a82a22" stroke-width="4"/><path d="M34 46 Q80 40 130 40" fill="none" stroke="#ffffff" stroke-width="3" opacity="0.35" stroke-linecap="round"/></g>'
    s += f'<path d="M20 64 L120 64 L110 86 L28 86 Z" fill="{grad("#8a5a2a", 1.25, 0.75)}" {O}/>'
    for x in (40, 104):
        s += f'<circle cx="{x}" cy="84" r="12" fill="{rgrad("#6a4020")}" {O}/><circle cx="{x}" cy="84" r="4" fill="#9aa3b2" {O1}/>'
    s += f'<g {O1}><circle cx="140" cy="88" r="6" fill="{rgrad("#3a3f4b")}"/><circle cx="150" cy="80" r="6" fill="{rgrad("#3a3f4b")}"/></g>'
    return s


def objek_menara():
    s = _bayang(80, 334, 64, 14)
    s += _bata(28, 96, 132, 332, "#6a6e7a", 14, 26)
    s += f'<rect x="64" y="288" width="32" height="44" rx="14" fill="#1e1e26" {O1}/>'
    s += "".join(f'<rect x="76" y="{y}" width="8" height="20" rx="3" fill="#1e1e26"/>' for y in (150, 210))
    s += f'<rect x="16" y="76" width="128" height="22" rx="2" fill="{grad("#8a8e9a", 1.25, 0.8)}" {O}/>'
    for x in range(16, 144, 26):
        s += f'<rect x="{x}" y="56" width="18" height="22" fill="{grad("#8a8e9a", 1.2, 0.8)}" {O1}/>'
    s += f'<rect x="28" y="120" width="104" height="8" fill="#a82a22"/>'
    s += f'<path d="M80 56 L80 6" stroke="{INK}" stroke-width="4"/>'
    s += f'<path d="M82 8 L130 18 Q120 24 130 32 L82 40 Z" fill="{grad("#c0302a", 1.25, 0.75)}" {O1}/>'
    s += f'<circle cx="100" cy="24" r="6" fill="#9aa3b2" stroke="{INK}" stroke-width="1"/>'
    s += '<path d="M36 104 L36 320" stroke="#ffffff" stroke-width="4" opacity="0.2"/>'
    return s


def objek_panji():
    s = _bayang(40, 174, 14)
    s += f'<path d="M30 174 L50 174 L46 164 L34 164 Z" fill="#4a4f5c" {O1}/>'
    s += f'<path d="M40 166 L40 12" stroke="{INK}" stroke-width="6" stroke-linecap="round"/><path d="M40 166 L40 12" stroke="#7a7e8a" stroke-width="3.5" stroke-linecap="round"/>'
    s += f'<circle cx="40" cy="10" r="5" fill="{rgrad(GOLD)}" {O1}/>'
    s += f'<path d="M42 18 L76 18 L76 92 L59 80 L42 92 Z" fill="{grad("#c0302a", 1.25, 0.7)}" {O1}/>'
    s += f'<circle cx="59" cy="48" r="11" fill="#9aa3b2" stroke="{INK}" stroke-width="1.2"/><circle cx="59" cy="48" r="5" fill="#4a4f5c"/>'
    s += f'<path d="M42 24 L76 24" stroke="{GOLD}" stroke-width="2"/>'
    return s


def objek_candi():
    s = _bayang(168, 366, 160, 18)
    batu = "#9a8a7a"
    for i, (x0, x1, y0, y1) in enumerate(((24, 312, 324, 364), (52, 284, 284, 324), (80, 256, 244, 284))):
        s += f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" fill="{grad(shade(batu, 1 + i * 0.05), 1.2, 0.75)}" {O}/>'
        s += f'<path d="M{x0} {y0 + 10} L{x1} {y0 + 10}" stroke="#5a4e44" stroke-width="1.6"/>'
        s += "".join(f'<rect x="{x}" y="{y0 + 16}" width="16" height="16" rx="2" fill="#7a6e62" stroke="#5a4e44" stroke-width="1"/>' for x in range(x0 + 12, x1 - 20, 34))
    s += f'<rect x="108" y="140" width="120" height="104" fill="{grad(batu, 1.25, 0.75)}" {O}/>'
    s += f'<path d="M140 244 L140 172 Q168 146 196 172 L196 244 Z" fill="#2a2420" {O1}/>'
    s += f'<path d="M140 172 Q168 134 196 172" fill="none" stroke="{GOLD}" stroke-width="2.5"/>'
    s += f'<circle cx="168" cy="152" r="8" fill="#b8a898" stroke="#5a4e44" stroke-width="1.4"/><circle cx="165" cy="150" r="1.5" fill="{INK}"/><circle cx="171" cy="150" r="1.5" fill="{INK}"/>'
    for i, (x0, x1, y0, y1) in enumerate(((100, 236, 116, 140), (116, 220, 92, 116), (132, 204, 70, 92))):
        s += f'<rect x="{x0}" y="{y0}" width="{x1 - x0}" height="{y1 - y0}" fill="{grad(shade(batu, 1.08), 1.2, 0.8)}" {O1}/>'
        s += "".join(f'<path d="M{x} {y0} Q{x + 6} {y0 - 12} {x + 12} {y0}" fill="{shade(batu, 1.1)}" stroke="{INK}" stroke-width="1.2"/>' for x in range(x0 + 4, x1 - 10, 22))
    s += f'<path d="M144 70 Q144 30 168 26 Q192 30 192 70 Z" fill="{grad(batu, 1.3, 0.75)}" {O}/>'
    s += f'<path d="M168 26 L168 4" stroke="{INK}" stroke-width="5" stroke-linecap="round"/><path d="M168 26 L168 4" stroke="#b8a898" stroke-width="3" stroke-linecap="round"/>'
    s += f'<path d="M144 364 L192 364 L188 244 L148 244 Z" fill="{grad("#8a7a6a", 1.1, 0.8)}" {O1}/>'
    s += "".join(f'<path d="M{146 + (364 - y) * 0.03:.0f} {y} L{190 - (364 - y) * 0.03:.0f} {y}" stroke="#5a4e44" stroke-width="1.4"/>' for y in range(256, 364, 10))
    s += "".join(f'<path d="M{x} {y} q6 -4 12 0" fill="#6aa040" opacity="0.8"/>' for x, y in ((30, 330), (270, 292), (90, 252), (230, 130), (120, 120)))
    s += '<path d="M116 150 L116 236" stroke="#ffffff" stroke-width="4" opacity="0.25" stroke-linecap="round"/>'
    return s


OBJEK.update({"pohon": (32, 48, objek_pohon), "beringin": (68, 76, objek_beringin), "joglo": (68, 52, objek_joglo),
              "lumbung": (32, 46, objek_lumbung), "peti": (24, 20, objek_peti), "tong": (18, 20, objek_tong),
              "mercusuar": (40, 84, objek_mercusuar), "pinisi": (80, 70, objek_pinisi), "tembok": (88, 36, objek_tembok),
              "tembok_v": (16, 76, objek_tembok_v), "meriam_benteng": (40, 26, objek_meriam_benteng),
              "menara": (40, 86, objek_menara), "panji": (20, 46, objek_panji), "candi": (84, 94, objek_candi)})
MEDAN = {"lembah": medan_lembah, "hutan": medan_hutan, "desa": medan_desa, "pelabuhan": medan_pelabuhan, "benteng": medan_benteng}


def main():
    os.makedirs(SPRITES, exist_ok=True)
    os.makedirs(ICONS, exist_ok=True)
    for name, k in KERAJAAN.items():
        save(SPRITES, f"prajurit_{name}", 16, 16, prajurit(**k))
    for name, k in KARAKTER.items():
        save(SPRITES, f"karakter_{name}", 16, 16, orang(**k))
    for name, fn in MUSUH.items():
        save(SPRITES, name, 16, 16, fn())
    save(SPRITES, "anjing_pelacak", 16, 16, anjing())
    save(SPRITES, "kavaleri_besi", 16, 16, kavaleri())
    save(SPRITES, "warga", 16, 16, warga())
    save(SPRITES, "wayang", 10, 15, WAYANG)
    save(SPRITES, "peti_pusaka", 12, 10, PETI)
    save(SPRITES, "ketupat", 8, 8, KETUPAT)
    save(SPRITES, "ranjau", 8, 7, RANJAU)
    save(SPRITES, "meriam_jaga", 16, 11, MERIAM_JAGA)
    for name, body in REMPAH.items():
        save(SPRITES, name, 8, 8, body)
    for name, (w, h, body) in PELURU.items():
        save(SPRITES, f"peluru_{name}", w, h, body)
    for name, (w, h, body) in IKON.items():
        save(SPRITES, name, w, h, body)
    for name, fn in MEDAN.items():
        save(SPRITES, f"medan_{name}", *ARENA, fn(), unit=1, import_scale=2)
    for name, (w, h, fn) in OBJEK.items():
        save(SPRITES, f"objek_{name}", w, h, fn())
    names = list(ITEM_SIMPLE) + list(ITEM_CUSTOM)
    for name in names:
        save(ICONS, name, 16, 16, ikon_item(name))
    print("gambar dibuat di", os.path.normpath(SPRITES), "dan", os.path.normpath(ICONS))


if __name__ == "__main__":
    main()
