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


def note(base, degree):
    """Nada slendro ke-`degree` (boleh lewat 5 = oktaf berikutnya)."""
    octave, step = divmod(degree, 5)
    return base * SLENDRO[step] * (2 ** octave)


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


def save(name, samples, peak=0.9):
    m = max(1e-6, max(abs(s) for s in samples))
    scale = peak / m
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


def music():
    """Satu gongan gaya lancaran: 8 birama x 4 ketuk, 104 bpm, loop mulus."""
    bpm = 104
    beat = 60 / bpm
    bars = 8
    total = bars * 4 * beat
    track = silence(total + 0.01)
    base = 220.0
    balungan = [2, 1, 2, 3, 2, 1, 4, 3, 5, 3, 2, 1, 3, 2, 1, 0,
                2, 1, 2, 3, 5, 6, 5, 3, 2, 1, 3, 2, 4, 3, 1, 0]
    for i, deg in enumerate(balungan):  # saron: satu nada per ketuk
        mix(track, bilah(note(base, deg), 0.9, 4.0), i * beat, 0.55)
    for i in range(len(balungan) * 2):  # bonang: imbal setengah ketuk, oktaf atas
        deg = balungan[i // 2] + (2 if i % 2 else 0)
        mix(track, bilah(note(base * 2, deg), 0.35, 9.0, 0.6), i * beat / 2 + beat / 4, 0.18)
    pattern = "D.t.D.tt.tD.t.Dt"  # kendang per setengah ketuk
    for i in range(int(total / (beat / 2))):
        ch = pattern[i % len(pattern)]
        if ch == "D":
            mix(track, kendang_dung(), i * beat / 2, 0.55)
        elif ch == "t":
            mix(track, kendang_tak(), i * beat / 2, 0.4)
    for bar in range(bars):  # kempul tiap birama, gong di akhir gongan
        if bar % 2 == 1:
            mix(track, gong(124, 1.2), bar * 4 * beat + 2 * beat, 0.35)
    mix(track, gong(62, 2.4), 0.0, 0.8)  # gong di awal = akhir gongan sebelumnya saat loop
    return track[: int(total * RATE)]


def main():
    os.makedirs(OUT, exist_ok=True)
    save("music_gamelan", music(), 0.8)
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
