"""Synthesises the tank's bubble sounds (no third-party audio, no licensing questions).

  python3 tools/audiogen/bubbles.py

Each bubble is modelled as a Minnaert resonance: a damped sine whose pitch rises
slightly as it decays. Small bubbles are higher and shorter.

Writes 16-bit mono WAVs to assets/audio/:
  bubbler_loop.wav   seamless ambient loop (air stone + faint water hum)
  pop_1..4.wav       single bubbles for occasional accents / surface pops
"""

import math
import os
import random
import struct
import wave

RATE = 22050
OUT = os.path.join(os.path.dirname(__file__), "..", "..", "assets", "audio")


def bubble(buf, start, freq, dur, amp, wrap=False):
    n = int(dur * RATE)
    tau = dur / 4.5
    rise = 0.12 * freq  # Hz per second of pitch rise
    phase = 0.0
    for i in range(n):
        t = i / RATE
        f = freq + rise * t * 10
        phase += 2 * math.pi * f / RATE
        env = math.exp(-t / tau) * min(1.0, t * RATE / 40)  # 40-sample attack, avoids clicks
        idx = start + i
        if wrap:
            idx %= len(buf)
        elif idx >= len(buf):
            break
        buf[idx] += amp * env * math.sin(phase)


def hum(buf, amp):
    """Very quiet low-passed noise: the 'water' bed under the bubbles."""
    y = 0.0
    for i in range(len(buf)):
        y += 0.02 * (random.uniform(-1, 1) - y)
        buf[i] += amp * y
    # Crossfade the end into the start so the loop point is inaudible.
    fade = RATE // 2
    for i in range(fade):
        k = i / fade
        buf[i] = buf[i] * k + buf[len(buf) - fade + i] * (1 - k)


def write(path, buf, peak=0.55):
    m = max(1e-9, max(abs(s) for s in buf))
    with wave.open(path, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(s / m * peak * 32767)) for s in buf))


def bubbler_loop(seconds=12.0):
    buf = [0.0] * int(seconds * RATE)
    t = 0.0
    while t < seconds:
        # An air stone: steady stream of small bubbles, with occasional bigger ones.
        big = random.random() < 0.08
        freq = random.uniform(380, 700) if big else random.uniform(900, 2200)
        dur = random.uniform(0.07, 0.14) if big else random.uniform(0.025, 0.06)
        amp = random.uniform(0.6, 1.0) if big else random.uniform(0.15, 0.4)
        bubble(buf, int(t * RATE), freq, dur, amp, wrap=True)
        t += random.expovariate(22)
    hum(buf, 0.35)
    return buf


def pop(seed):
    random.seed(seed)
    buf = [0.0] * int(0.35 * RATE)
    for k in range(random.randint(1, 3)):
        bubble(buf, int(k * random.uniform(0.03, 0.08) * RATE), random.uniform(350, 900),
               random.uniform(0.09, 0.2), 1.0 - k * 0.3)
    return buf


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    random.seed(42)
    write(os.path.join(OUT, "bubbler_loop.wav"), bubbler_loop(), peak=0.45)
    for i in range(1, 5):
        write(os.path.join(OUT, f"pop_{i}.wav"), pop(i), peak=0.6)
    print("wrote", sorted(os.listdir(OUT)))
