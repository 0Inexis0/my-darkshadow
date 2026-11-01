#!/usr/bin/env python3
"""Builds the interface sounds in sounds/sfx/ (our own synthesis, free to use: CC0).

  python3 install/tools/make-sfx.py        needs numpy; ffmpeg for the music (.ogg)

sounds/sfx/<pack>/<event>.wav   packs: soft, crystal, bubble
                                events: click switch-on switch-off slide type open close select done
sounds/sfx/intro/*.wav          the welcome intro: night, reveal, open
sounds/sfx/music/calm.ogg       quiet music for the welcome intro and the Settings tour
"""
import os
import shutil
import subprocess
import wave

import numpy as np

SR = 44100
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..", "sounds", "sfx")
rng = np.random.default_rng(7)


def t(sec):
    return np.arange(int(SR * sec)) / SR


def env(n, attack=0.002, decay=0.05):
    x = np.arange(n) / SR
    a = np.clip(x / max(attack, 1e-4), 0, 1)
    a = a * a * (3 - 2 * a)
    return a * np.exp(-x / decay)


def onepole(x, cutoff, high=False):
    a = np.exp(-2 * np.pi * cutoff / SR)
    y = np.empty_like(x)
    acc = 0.0
    for i, v in enumerate(x):
        acc = (1 - a) * v + a * acc
        y[i] = acc
    return x - y if high else y


def fade_end(s, sec=0.012):
    n = min(len(s), int(SR * sec))
    s = s.copy()
    s[-n:] *= np.linspace(1, 0, n) ** 2
    return s


def tone(freq, dur, decay, attack=0.002, partials=((1, 1),), glide=0.0):
    x = t(dur)
    f = freq * (1 + glide * x / dur) if glide else np.full_like(x, freq)
    ph = 2 * np.pi * np.cumsum(f) / SR
    s = sum(g * np.sin(ph * r) for r, g in partials)
    return s * env(len(x), attack, decay)


def noise(dur, decay, lo=None, hi=None, attack=0.001):
    x = rng.standard_normal(int(SR * dur))
    if hi:
        x = onepole(x, hi)
    if lo:
        x = onepole(x, lo, high=True)
    return x * env(len(x), attack, decay)


def mix(*parts):
    n = max(len(p) for p in parts)
    out = np.zeros(n)
    for p in parts:
        out[:len(p)] += p
    return out


def seq(*items):
    """(signal, start_seconds) ..."""
    n = max(int(s * SR) + len(p) for p, s in items)
    out = np.zeros(n)
    for p, s in items:
        i = int(s * SR)
        out[i:i + len(p)] += p
    return out


def norm(s, peak):
    m = np.max(np.abs(s)) or 1
    return fade_end(s / m * peak)


def write(path, s, stereo=False):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    s = np.clip(s, -1, 1)
    data = (s * 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2 if stereo else 1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(data.tobytes())


# ---------------------------------------------------------------- packs
def soft():
    """quiet wooden taps and airy swishes"""
    wood = ((1, 1), (2.7, 0.25), (5.1, 0.08))
    return {
        "click": mix(tone(520, 0.06, 0.012, partials=wood) * 0.9, noise(0.03, 0.004, lo=900, hi=5000) * 0.25),
        "switch-on": seq((tone(620, 0.08, 0.025, partials=wood), 0), (tone(930, 0.1, 0.03, partials=wood), 0.045)),
        "switch-off": seq((tone(930, 0.08, 0.025, partials=wood), 0), (tone(620, 0.1, 0.03, partials=wood), 0.045)),
        "slide": tone(1650, 0.025, 0.006, partials=((1, 1), (2, 0.2))) * 0.6,
        "type": mix(noise(0.02, 0.003, lo=1500, hi=7000) * 0.6, tone(380, 0.02, 0.004) * 0.4),
        "open": mix(noise(0.32, 0.12, lo=500, hi=3500, attack=0.08) * 0.35, tone(420, 0.3, 0.1, attack=0.03, glide=0.6) * 0.5),
        "close": mix(noise(0.26, 0.08, lo=500, hi=3000, attack=0.02) * 0.3, tone(640, 0.24, 0.07, attack=0.01, glide=-0.4) * 0.45),
        "select": tone(780, 0.14, 0.04, partials=((1, 1), (2, 0.3), (3, 0.1))),
        "done": seq((tone(784, 0.5, 0.18, partials=((1, 1), (2, 0.2))), 0), (tone(1047, 0.6, 0.22, partials=((1, 1), (2, 0.2))), 0.09)),
    }


def crystal():
    """small glass bells"""
    glass = ((1, 1), (2.76, 0.35), (5.4, 0.12), (8.9, 0.04))
    return {
        "click": tone(1760, 0.09, 0.02, partials=glass),
        "switch-on": seq((tone(1318, 0.12, 0.04, partials=glass), 0), (tone(1976, 0.16, 0.05, partials=glass), 0.05)),
        "switch-off": seq((tone(1976, 0.12, 0.04, partials=glass), 0), (tone(1318, 0.16, 0.05, partials=glass), 0.05)),
        "slide": tone(2637, 0.03, 0.006, partials=glass) * 0.6,
        "type": tone(3136, 0.025, 0.004, partials=glass) * 0.5,
        "open": seq(*[(tone(f, 0.3, 0.12, partials=glass) * 0.7, i * 0.045) for i, f in enumerate((1047, 1319, 1568, 2093))]),
        "close": seq(*[(tone(f, 0.25, 0.09, partials=glass) * 0.7, i * 0.04) for i, f in enumerate((2093, 1568, 1319))]),
        "select": tone(1568, 0.2, 0.06, partials=glass),
        "done": seq((tone(1568, 0.7, 0.25, partials=glass), 0), (tone(2093, 0.8, 0.3, partials=glass), 0.1), (tone(2637, 0.9, 0.35, partials=glass) * 0.7, 0.2)),
    }


def bubble():
    """soft round pops"""
    def pop(f, d=0.07, g=-0.45):
        return tone(f, d, d * 0.35, attack=0.003, glide=g)
    return {
        "click": pop(700),
        "switch-on": pop(560, 0.1, 0.7),
        "switch-off": pop(900, 0.1, -0.5),
        "slide": pop(1400, 0.03, -0.3) * 0.6,
        "type": pop(1100, 0.03, -0.3) * 0.5,
        "open": seq((pop(420, 0.12, 0.8), 0), (pop(640, 0.12, 0.8), 0.07)),
        "close": seq((pop(640, 0.12, -0.6), 0), (pop(420, 0.12, -0.6), 0.07)),
        "select": pop(820, 0.1, 0.3),
        "done": seq((pop(523, 0.16, 0.2), 0), (pop(659, 0.16, 0.2), 0.08), (pop(784, 0.22, 0.2), 0.16)),
    }


PEAK = {"click": 0.45, "switch-on": 0.5, "switch-off": 0.45, "slide": 0.25, "type": 0.22,
        "open": 0.4, "close": 0.35, "select": 0.45, "done": 0.5}


# ---------------------------------------------------------------- intro
def intro():
    # night falls: a slow, soft airy swell that settles
    x = t(2.2)
    swell = noise(2.2, 3.0, lo=150, hi=1800, attack=0.9) * 0.25
    pad = sum(np.sin(2 * np.pi * f * x) * g for f, g in ((110, 0.5), (164.8, 0.3), (220, 0.25)))
    pad *= np.clip(x / 0.9, 0, 1) ** 2 * np.exp(-np.clip(x - 1.2, 0, None) / 0.5)
    night = norm(swell + pad * 0.6, 0.35)
    # the moon draws itself in: a slow arpeggio of small bells
    glass = ((1, 1), (2.76, 0.25), (5.4, 0.07))
    notes = (523.3, 659.3, 784.0, 987.8, 1174.7, 1568.0)
    reveal = norm(seq(*[(tone(f, 1.6, 0.6, attack=0.004, partials=glass) * (0.9 - i * 0.08), i * 0.16) for i, f in enumerate(notes)]), 0.4)
    # "Take a look": a bright, open whoosh
    x = t(1.1)
    w = noise(1.1, 0.45, lo=700, hi=6000, attack=0.18) * 0.4
    shimmer = sum(tone(f, 1.0, 0.4, attack=0.06, partials=glass) * 0.3 for f in (1046.5, 1318.5, 1568.0))
    opening = norm(mix(w, shimmer), 0.4)
    return {"night": night, "reveal": reveal, "open": opening}


# ---------------------------------------------------------------- music
def calm(seconds=64):
    """slow warm chords with small bells on top, quiet and friendly (C major, 72 bpm feel)"""
    x = t(seconds)
    out = np.zeros_like(x)
    chords = [  # Cmaj9, Am9, Fmaj7, G6sus  (Hz)
        (130.8, 196.0, 246.9, 293.7, 329.6),
        (110.0, 164.8, 246.9, 261.6, 329.6),
        (87.3, 174.6, 220.0, 261.6, 329.6),
        (98.0, 196.0, 261.6, 293.7, 329.6),
    ]
    bar = 4.0
    for k in range(int(seconds / bar) + 1):
        ch = chords[k % 4]
        start = k * bar
        i0 = int(start * SR)
        n = int((bar + 2.5) * SR)
        xx = np.arange(n) / SR
        e = np.clip(xx / 1.2, 0, 1) ** 2 * np.exp(-np.clip(xx - bar, 0, None) / 1.0)
        tone_ = np.zeros(n)
        for j, f in enumerate(ch):
            for d in (-0.0025, 0.0025):           # two slightly detuned voices: warm
                tone_ += np.sin(2 * np.pi * f * (1 + d) * xx + j) * (0.5 if j == 0 else 0.28)
        tone_ *= e
        end = min(len(out), i0 + n)
        out[i0:end] += tone_[:end - i0]
    out = onepole(out, 1400)
    # small bells: a gentle melody, one note every two beats
    melody = [659.3, 784.0, 659.3, 587.3, 523.3, 587.3, 659.3, 784.0, 880.0, 784.0, 659.3, 587.3, 659.3, 523.3, 587.3, 523.3]
    glass = ((1, 1), (2.76, 0.18), (5.4, 0.05))
    step = 1.66
    k = 0
    tt = 2.0
    while tt < seconds - 3:
        f = melody[k % len(melody)]
        b = tone(f, 2.4, 0.9, attack=0.01, partials=glass) * 0.22
        i = int(tt * SR)
        end = min(len(out), i + len(b))
        out[i:end] += b[:end - i]
        k += 1
        tt += step * (1.0 if k % 4 else 2.0)
    # a simple room: a few soft echoes
    room = out.copy()
    for d, g in ((0.11, 0.35), (0.23, 0.25), (0.37, 0.18), (0.53, 0.12)):
        i = int(d * SR)
        room[i:] += out[:-i] * g
    room = onepole(room, 3000)
    # fade in and out
    fi = np.clip(x / 3.0, 0, 1)
    fo = np.clip((seconds - x) / 5.0, 0, 1)
    return norm(room * fi * fo, 0.5)


def main():
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    for name, fn in (("soft", soft), ("crystal", crystal), ("bubble", bubble)):
        for ev, s in fn().items():
            write(os.path.join(OUT, name, ev + ".wav"), norm(s, PEAK[ev]))
    for ev, s in intro().items():
        write(os.path.join(OUT, "intro", ev + ".wav"), s)
    music = calm()
    wav = os.path.join(OUT, "music", "calm.wav")
    write(wav, music)
    if shutil.which("ffmpeg"):
        ogg = os.path.join(OUT, "music", "calm.ogg")
        subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "3", ogg], check=True)
        os.remove(wav)
    print("sounds written to", os.path.normpath(OUT))


if __name__ == "__main__":
    main()
