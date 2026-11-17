#!/usr/bin/env python3
"""Sintesis musik gamelan & efek suara ke assets/audio/*.wav (tanpa aset luar).

Jalankan:  python3 tools/make_sounds.py
Tangga nada slendro (5 nada, ~240 sen). Bilah (saron/bonang) = parsial tidak
harmonis yang meluruh; gong = nada rendah berdenyut; kendang = sinus turun + noise.
"""
import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "audio")
random.seed(7)

SLENDRO = [2 ** (k * 240 / 1200) for k in range(5)]
# Pelog (7 nada, perkiraan sen), terasa lebih "misterius"/tegang.
PELOG = [2 ** (c / 1200) for c in (0, 120, 270, 540, 670, 785, 950)]


def note(base, degree, scale=SLENDRO):
    """Nada ke-`degree` dalam tangga nada (boleh lewat jumlah nada = oktaf berikutnya)."""
    octave, step = divmod(degree, len(scale))
    return base * scale[step] * (2 ** octave)


def silence(sec):
    return [0.0] * int(RATE * sec)


def mix(dst, src, at, gain=1.0):
    start = int(at * RATE)
    if len(dst) < start + len(src):
        dst.extend([0.0] * (start + len(src) - len(dst)))
    for i, v in enumerate(src):
        dst[start + i] += v * gain
    return dst


def bilah(freq, dur=0.6, decay=6.0, bright=1.0):
    """Saron/bonang: parsial 1, 2.76, 5.4 dengan peluruhan berbeda + ketukan awal."""
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        v = math.sin(2 * math.pi * freq * t) * math.exp(-decay * t)
        v += 0.4 * bright * math.sin(2 * math.pi * freq * 2.76 * t) * math.exp(-decay * 2.2 * t)
        v += 0.2 * bright * math.sin(2 * math.pi * freq * 5.4 * t) * math.exp(-decay * 4 * t)
        if t < 0.004:
            v += (random.random() * 2 - 1) * 0.3 * (1 - t / 0.004)
        out.append(v * 0.5)
    return out


def gong(freq=62.0, dur=2.5, gain=1.0):
    n = int(RATE * dur)
    out = []
    for i in range(n):
        t = i / RATE
        env = math.exp(-1.6 * t / dur * 2.5) * min(1.0, t / 0.01)
        v = math.sin(2 * math.pi * freq * t) + 0.9 * math.sin(2 * math.pi * (freq + 1.3) * t)  # denyut "ombak"
        v += 0.35 * math.sin(2 * math.pi * freq * 2.02 * t) * math.exp(-2 * t)
        v += 0.15 * math.sin(2 * math.pi * freq * 3.1 * t) * math.exp(-3 * t)
        out.append(v * env * 0.35 * gain)
    return out


def suling(freq, dur, gain=1.0):
    """Suling bambu: sinus + harmonik lembut, vibrato, desah napas."""
    out, phase, lp = [], 0.0, 0.0
    n = int(RATE * dur)
    for i in range(n):
        t = i / RATE
        f = freq * (1 + 0.006 * math.sin(2 * math.pi * 5.2 * t) * min(1.0, t / 0.25))
        phase += 2 * math.pi * f / RATE
        env = min(1.0, t / 0.06) * min(1.0, (dur - t) / 0.08)
        lp += 0.2 * ((random.random() * 2 - 1) - lp)
        v = math.sin(phase) + 0.18 * math.sin(2 * phase) + 0.06 * math.sin(3 * phase) + 0.08 * lp
        out.append(v * env * 0.35 * gain)
    return out


def angklung(freq, dur=0.5):
    """Angklung: bilah bambu yang bergetar cepat (tremolo)."""
    base = bilah(freq, dur, 5.0, 0.5)
    return [v * (0.6 + 0.4 * math.sin(2 * math.pi * 13 * i / RATE)) for i, v in enumerate(base)]


def gender(freq, dur=1.2):
    """Gender: bilah lembut berdengung panjang."""
    return bilah(freq, dur, 2.2, 0.35)


def rebana(dur=0.12):
    """Rebana: pukulan kulit + gemerincing kecrek."""
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        v = math.sin(2 * math.pi * (180 + 60 * math.exp(-40 * t)) * t) * math.exp(-25 * t) * 0.6
        v += (random.random() * 2 - 1) * 0.25 * math.exp(-18 * t) * (0.5 + 0.5 * math.sin(2 * math.pi * 3100 * t))
        out.append(v)
    return out


def bedug(dur=0.6):
    """Bedug: tabuh besar yang dalam."""
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        f = 48 + 30 * math.exp(-18 * t)
        out.append((math.sin(2 * math.pi * f * t) + 0.3 * math.sin(2 * math.pi * f * 2.1 * t)) * math.exp(-5 * t) * 0.9)
    return out


def dentang(freq, dur=0.4):
    """Dentang logam (benteng): parsial tidak harmonis yang tajam."""
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        v = sum(math.sin(2 * math.pi * freq * r * t) * math.exp(-d * t) for r, d in ((1, 9), (2.41, 14), (3.93, 20), (5.6, 30)))
        out.append(v * 0.25)
    return out


def track(bpm, bars, layers):
    """Susun lagu dari lapisan [(alat(waktu_ketuk) -> sampel, pola, langkah_ketuk, gain)].
    Pola: list nada/kode per langkah; None = diam. Hasil dipotong pas supaya loop mulus."""
    beat = 60 / bpm
    total = bars * 4 * beat
    out = silence(total + 3.0)
    for make, pattern, step, gain in layers:
        steps = int(round(bars * 4 / step))
        for i in range(steps):
            v = pattern[i % len(pattern)]
            if v is None:
                continue
            mix(out, make(v), i * step * beat, gain)
    # Ekor yang lewat batas digabung ke awal supaya sambungan loop tidak terpotong.
    n = int(total * RATE)
    for i in range(len(out) - n):
        out[i] += out[n + i]
    return out[:n]


def kendang_dung(dur=0.25):
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        f = 70 + 80 * math.exp(-30 * t)
        out.append(math.sin(2 * math.pi * f * t) * math.exp(-14 * t) * 0.8)
    return out


def kendang_tak(dur=0.08):
    out, lp = [], 0.0
    for i in range(int(RATE * dur)):
        t = i / RATE
        lp += 0.5 * ((random.random() * 2 - 1) - lp)
        out.append((lp * 0.7 + 0.3 * math.sin(2 * math.pi * 420 * t)) * math.exp(-45 * t) * 0.6)
    return out


def noise(dur, decay, gain=1.0, smooth=0.3):
    out, lp = [], 0.0
    for i in range(int(RATE * dur)):
        t = i / RATE
        lp += smooth * ((random.random() * 2 - 1) - lp)
        out.append(lp * math.exp(-decay * t) * gain)
    return out


def sweep(f0, f1, dur, decay, gain=1.0, square=False):
    out, phase = [], 0.0
    for i in range(int(RATE * dur)):
        t = i / RATE
        f = f0 + (f1 - f0) * (t / dur)
        phase += 2 * math.pi * f / RATE
        v = math.sin(phase)
        if square:
            v = 1.0 if v > 0 else -1.0
        out.append(v * math.exp(-decay * t) * gain)
    return out


def save(name, samples, peak=0.9, rms=None):
    m = max(1e-6, max(abs(s) for s in samples))
    scale = peak / m
    if rms:
        # Musik: samakan kerasnya antar lagu (RMS), puncak dijinakkan dengan soft-clip.
        cur = math.sqrt(sum(x * x for x in samples) / len(samples))
        samples = [math.tanh(x * rms / cur * 1.6) / 1.6 for x in samples]
        scale = 1.0
    # Fade out pendek supaya tidak "klik" di akhir.
    fade = min(len(samples), int(RATE * 0.01))
    for i in range(fade):
        samples[-1 - i] *= i / fade
    path = os.path.join(OUT, name + ".wav")
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, s * scale)) * 32767)) for s in samples))


_ = None  # penanda diam di pola


MAYOR = [2 ** (st / 12) for st in (0, 2, 4, 5, 7, 9, 11)]
MINOR = [2 ** (st / 12) for st in (0, 2, 3, 5, 7, 8, 11)]  # minor harmonis: akor V tetap mayor


def bas(freq, dur=0.5):
    """Bas petik lembut (seperti betot kroncong)."""
    out = []
    for i in range(int(RATE * dur)):
        t = i / RATE
        v = math.sin(2 * math.pi * freq * t) + 0.35 * math.sin(4 * math.pi * freq * t) * math.exp(-8 * t)
        out.append(v * math.exp(-3.5 * t) * min(1.0, t / 0.005) * 0.6)
    return out


def legato(mel):
    """Pola melodi -> [(nada, panjang_langkah)]: nada ditahan sampai nada berikutnya (maks 4 langkah)."""
    out = []
    for i, d in enumerate(mel):
        if d is None:
            out.append(None)
            continue
        n = 1
        while n < 4 and mel[(i + n) % len(mel)] is None:
            n += 1
        out.append((d, n))
    return out


def lagu(bpm, base, scale, chords, mel, lead, arp_inst, beat, gain_lead=0.8):
    """Lagu diatonis: melodi (per 1/8 ketuk) + arpeggio akor + bas + kendang + gong per 4 birama.
    chords: akar akor (derajat tangga nada) per birama; mel: 8 langkah per birama."""
    bars = len(chords)
    step = 60 / bpm / 2
    arp = []
    for r in chords:
        arp += [r, r + 2, r + 4, r + 2, r + 7, r + 4, r + 2, r + 4]
    bass = []
    for r in chords:
        bass += [r, _, r + 4, _]
    drums = {"D": kendang_dung, "t": kendang_tak, "R": rebana, "B": bedug}
    return track(bpm, bars, [
        (lambda dn: lead(note(base * 2, dn[0], scale), dn[1] * step * 0.95), legato(mel), 0.5, gain_lead),
        (lambda d: arp_inst(note(base, d, scale)), arp, 0.5, 0.22),
        (lambda d: bas(note(base / 4, d, scale), 0.9), bass, 1, 0.55),
        (lambda c: drums[c](), [None if c == "." else c for c in beat], 0.5, 0.45),
        (lambda _d: gong(base / 4, 2.4), [1], 16, 0.55),
    ])


def angklung_lead(freq, dur):
    return angklung(freq, max(0.35, dur))


def bilah_lead(freq, dur):
    return bilah(freq, max(0.4, dur), 3.5, 0.6)


def angklung_arp(freq):
    return angklung(freq, 0.4)


def bilah_arp(freq):
    return bilah(freq, 0.4, 7.0, 0.4)


def music_menu():
    # Gundul Pacul (lagu daerah Jawa, domain publik)
    mel = [0, 2, 0, 2, 3, 4, 4, _,  6, 7, 6, 4, _, _, _, _,
           0, 2, 0, 2, 3, 4, 4, _,  6, 4, 3, 2, _, _, _, _,
           3, 4, 3, 2, 0, 3, 2, 0,  3, 4, 3, 2, 0, _, _, _,
           3, 4, 3, 2, 0, 3, 2, 0,  1, 2, 0, _, _, _, _, _]
    return lagu(100, 262.0, MAYOR, [0, 4, 0, 4, 3, 0, 4, 0], mel, suling, angklung_arp, "D...t...D.t.t...")


def music_lembah():
    mel = [4, _, 2, 4, 7, _, 6, 4,  5, _, 4, _, 1, _, _, _,
           2, _, 0, 2, 5, _, 4, 2,  3, _, 2, 1, 3, _, _, _,
           4, _, 2, 4, 7, _, 9, 7,  8, _, 7, 6, 4, _, _, _,
           5, 6, 7, _, 6, 4, 2, _,  3, _, 1, _, 2, _, _, _]
    return lagu(112, 262.0, MAYOR, [0, 4, 5, 3, 0, 4, 5, 3], mel, angklung_lead, bilah_arp, "D.t.D.tt.tD.t.Dt")


def music_hutan():
    mel = [0, _, 2, 4, 7, _, 4, _,  5, _, 4, 2, 0, _, _, _,
           2, _, 4, 6, 9, _, 7, 6,  6, _, _, 4, 1, _, _, _,
           7, _, 6, 7, 9, _, 7, _,  5, _, 4, 5, 7, _, 5, _,
           4, _, 2, 4, 6, _, 4, 2,  1, _, _, _, _, _, _, _]
    return lagu(96, 220.0, MINOR, [0, 5, 2, 6, 0, 5, 2, 4], mel, suling, angklung_arp, "D..t..D...t.D...")


def music_pelabuhan():
    mel = [0, 2, 4, _, 4, _, 2, _,  3, 5, 7, _, 7, _, 5, _,
           4, _, 6, _, 8, _, 6, 4,  7, _, _, _, 4, _, _, _,
           0, 2, 4, _, 4, _, 2, _,  3, 5, 7, _, 7, _, 9, _,
           8, _, 7, _, 6, _, 4, _,  7, _, _, _, _, _, _, _]
    return lagu(120, 294.0, MAYOR, [0, 3, 4, 0, 0, 3, 4, 0], mel, suling, bilah_arp, "R.ttR.t.R.ttR.tt")


def music_desa():
    mel = [7, _, 7, 6, 4, _, 2, _,  2, _, 4, _, 5, _, _, _,
           3, _, 5, _, 7, _, 5, 3,  4, _, _, _, 6, _, _, _,
           7, _, 7, 6, 4, _, 7, _,  9, _, 7, _, 5, _, _, _,
           3, 4, 5, _, 5, 4, 3, _,  4, _, 1, _, _, _, _, _]
    return lagu(108, 220.0, MAYOR, [0, 5, 3, 4, 0, 5, 3, 4], mel, bilah_lead, angklung_arp, "D.tDt.tD.tDt.Dtt")


def music_benteng():
    mel = [0, _, _, 0, 2, _, 4, _,  3, _, _, 3, 5, _, 7, _,
           4, _, 6, _, 8, _, 6, _,  7, _, _, _, _, _, _, _,
           7, _, 6, 5, 4, _, 2, _,  5, _, 4, 3, 2, _, 0, _,
           1, _, 4, _, 6, _, 4, _,  0, _, _, _, _, _, _, _]
    return lagu(100, 196.0, MINOR, [0, 3, 4, 0, 0, 3, 4, 0], mel, bilah_lead, bilah_arp, "B.t.B.ttB.t.BBtt")


def music_boss():
    mel = [7, 6, 7, 4, 7, 6, 7, 2,  5, 4, 5, 0, 5, 4, 5, 2,
           3, 2, 3, 0, 5, 3, 2, 0,  1, _, 4, _, 6, _, 8, _,
           7, 6, 7, 9, 10, 9, 7, 6,  5, 7, 9, _, 8, 7, 5, _,
           3, 5, 7, _, 5, 3, 2, 1,  6, _, 4, _, 1, _, _, _]
    return lagu(140, 147.0, MINOR, [0, 5, 3, 4, 0, 5, 3, 4], mel, suling, bilah_arp, "DttDtDttDtDDttDt", 0.7)


def music_pasar():
    mel = [4, _, _, 2, 4, _, _, _,  5, _, 4, 2, 0, _, _, _,
           1, _, 3, _, 5, _, 4, 3,  1, _, _, _, _, _, _, _,
           4, _, _, 2, 4, _, 7, _,  7, _, 5, _, 7, _, 9, _,
           8, _, 7, 5, 3, _, 1, _,  4, _, 6, _, 8, _, _, _]
    return lagu(88, 262.0, MAYOR, [0, 5, 1, 4, 0, 5, 1, 4], mel, suling, angklung_arp, ".R.R.R.R", 0.7)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, fn in [("menu", music_menu), ("lembah", music_lembah), ("hutan", music_hutan),
                     ("pelabuhan", music_pelabuhan), ("desa", music_desa), ("benteng", music_benteng),
                     ("boss", music_boss), ("pasar", music_pasar)]:
        save("music_" + name, fn(), rms=0.12)
    save("shoot", mix(sweep(1400, 500, 0.07, 30, 0.6), noise(0.05, 60, 0.4, 0.6), 0))
    save("hit", mix(noise(0.05, 70, 0.8, 0.5), sweep(260, 140, 0.06, 40, 0.7), 0))
    save("enemy_die", mix(mix(bilah(520, 0.3, 14, 1.5), bilah(733, 0.25, 18, 1.2), 0, 0.6), noise(0.12, 30, 0.5), 0))
    save("pickup", bilah(note(880, 2), 0.25, 14))
    save("buy", mix(bilah(note(660, 0), 0.2, 16), bilah(note(660, 3), 0.3, 12), 0.07))
    save("heal", mix(bilah(note(440, 1), 0.3, 10), bilah(note(440, 4), 0.45, 8), 0.1))
    lv = []
    for i, d in enumerate([0, 2, 3, 5, 7]):
        mix(lv, bilah(note(440, d), 0.5, 7), i * 0.08)
    save("levelup", lv)
    save("hurt", mix(sweep(300, 90, 0.18, 14, 0.7, square=True), noise(0.1, 30, 0.5), 0))
    save("click", mix(bilah(1500, 0.06, 60, 0.5), kendang_tak(0.03), 0, 0.5))
    ws = mix(mix(kendang_dung(), kendang_tak(), 0.18), kendang_dung(), 0.3)
    save("wave_start", mix(ws, gong(124, 1.2), 0.45, 0.8))
    save("wave_end", gong(93, 1.6))
    save("game_over", mix(gong(55, 3.2), bilah(note(220, 0), 1.5, 2), 0.2, 0.3))
    vic = []
    for i, d in enumerate([0, 2, 3, 5, 3, 5, 7, 10]):
        mix(vic, bilah(note(440, d), 0.6, 5), i * 0.16)
    save("victory", mix(vic, gong(62, 2.5), 1.3, 0.8))
    print("suara dibuat di", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
