"""Mock tank scene for judging fish against water, decor and glass.

Not game code: the real tank is assembled in Godot. This only previews the look.

  uv run --with pillow tools/spritegen/scene.py
"""

import math
import os
import random

from PIL import Image

from build import PREVIEWS, build_sprites
from palette import rgba
from render import flipped, upscale

W, H = 192, 120
WATER_TOP = 10
GRAVEL_TOP = 104


def put(img, x, y, c):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), c)


BAYER4 = [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


def dithered(x, y, amount):
    """True for `amount` (0..1) of pixels, in a stable 4x4 ordered pattern."""
    return BAYER4[y % 4][x % 4] < amount * 16


def water(img):
    # Banded gradient; each band blends into the next with ordered dithering (no smooth gradients).
    bands = [(WATER_TOP, "sky"), (WATER_TOP + 3, "deep_blue"), (78, "dusk"), (GRAVEL_TOP + 8, "dusk")]
    blend = 14
    for (y0, c0), (y1, c1) in zip(bands, bands[1:]):
        for y in range(y0, y1):
            amount = max(0.0, (y - (y1 - blend)) / blend) if c1 != c0 and y1 - y0 > blend else 0.0
            for x in range(W):
                put(img, x, y, rgba(c1 if dithered(x, y, amount) else c0))
    for x in range(W):
        put(img, x, WATER_TOP, rgba("cyan" if (x // 6) % 3 == 0 else "sky"))
    # Light shafts: slanted stripes that fade out with depth.
    for sx, width in ((28, 5), (92, 3), (146, 6)):
        for y in range(WATER_TOP + 1, 78):
            fade = 0.5 * (1 - (y - WATER_TOP) / (78 - WATER_TOP))
            for k in range(width):
                x = sx + k + (y - WATER_TOP) // 3
                if dithered(x, y, fade) and img.getpixel((x % W, y))[:3] == rgba("deep_blue")[:3]:
                    put(img, x, y, rgba("sky"))


def gravel(img):
    tones = ["sand", "wood", "tan", "cream", "bark", "clay"]
    weights = [5, 4, 4, 1, 2, 2]
    for x in range(W):
        top = GRAVEL_TOP + round(2 * math.sin(x / 13) + math.sin(x / 5))
        for y in range(top, H):
            c = random.choices(tones, weights)[0]
            if y == top:
                c = random.choice(["cream", "sand"])
            if y > H - 4:
                c = random.choice(["bark", "wood"])
            put(img, x, y, rgba(c))


def plant(img, base_x, height, lean, ramp):
    """Ribbon plant: a few curved blades, darker toward the base."""
    for blade in range(4):
        bx = base_x + blade * 2 - 3
        hgt = height - blade * 7 + random.randint(-3, 3)
        for i in range(hgt):
            y = GRAVEL_TOP + 2 - i
            x = bx + round(lean * math.sin(i / 9 + blade))
            colour = ramp[0] if i < hgt * 0.25 else ramp[1] if i < hgt * 0.7 else ramp[2]
            put(img, x, y, rgba(colour))
            put(img, x + 1, y, rgba(ramp[0] if (i // 2) % 2 else colour))


def rock(img, cx, w, h):
    for y in range(h):
        for x in range(-w, w + 1):
            if (x / w) ** 2 + ((h - y) / h) ** 2 <= 1:
                edge = (abs(x) / w) ** 2 + ((h - y + 1) / h) ** 2 > 1 or y == h - 1
                light = -w * 0.6 < x < w * 0.1 and (h - y) > h * 0.55
                top = (h - y) > h * 0.85 and abs(x) < w * 0.4
                colour = "navy" if edge else ("silver" if top and x < 0 else "steel" if light else
                                              "dusk" if x > w * 0.5 else "slate")
                put(img, cx + x, GRAVEL_TOP + 4 - h + y, rgba(colour))


def bubbles(img, x0, rise=0):
    for i, y in enumerate(range(GRAVEL_TOP - 4, WATER_TOP + 2, -9)):
        y = WATER_TOP + 3 + (y - WATER_TOP - 3 - rise) % (GRAVEL_TOP - WATER_TOP - 7)
        x = x0 + round(2 * math.sin(i * 1.3 + rise / 5))
        r = 1 if i % 3 else 2
        if r == 1:
            for dx, dy in ((0, -1), (-1, 0), (1, 0), (0, 1)):
                put(img, x + dx, y + dy, rgba("silver"))
            put(img, x, y, rgba("deep_blue"))
        else:
            for dx in range(-2, 3):
                for dy in range(-2, 3):
                    if abs(dx) + abs(dy) in (2, 3) and not (abs(dx) == 2 and abs(dy) == 2):
                        put(img, x + dx, y + dy, rgba("silver"))
            put(img, x - 1, y - 1, rgba("white"))


def frame(img):
    # Glass edges and a dark rim, so the tank reads as an object when floating on a desktop.
    for y in range(H):
        put(img, 0, y, rgba("silver", 200)); put(img, W - 1, y, rgba("silver", 200))
    for x in range(W):
        put(img, x, H - 1, rgba("slate"))
        for y in range(3):
            put(img, x, y, rgba("navy" if y else "slate"))
    for y in range(3, WATER_TOP):  # air gap above water: faint glass tint
        for x in range(1, W - 1):
            put(img, x, y, rgba("silver", 40))


def wobble(sprite, phase, amp=1.2, waves=0.35):
    """Swim wobble, as the Godot shader will do it: columns bob more toward the tail.

    `sprite` faces right, so the tail is at x=0.
    """
    out = Image.new("RGBA", (sprite.width, sprite.height + 4), (0, 0, 0, 0))
    for x in range(sprite.width):
        tailness = (1 - x / sprite.width) ** 1.6
        dy = round(amp * tailness * math.sin(phase - x * waves))
        out.paste(sprite.crop((x, 0, x + 1, sprite.height)), (x, 2 + dy))
    return out


def background():
    random.seed(7)
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    water(img)
    plant(img, 22, 60, 2, ["pine", "moss", "leaf"])
    plant(img, 172, 48, 3, ["pine", "moss", "leaf"])
    plant(img, 120, 30, 1, ["abyss_green", "pine", "moss"])
    gravel(img)
    rock(img, 62, 15, 13)
    return img


# name, x, y, facing_left, speed (px/frame), wobble rate
CAST = [
    ("goldfish", 70, 40, False, 0.5, 0.45),
    ("betta", 130, 22, True, 0.3, 0.3),
    ("goldfish_calico", 24, 60, True, 0.4, 0.4),
    ("betta_royal_blue", 128, 66, False, 0.25, 0.3),
] + [("neon_tetra", x, y, i == 4, 0.9, 0.9)
     for i, (x, y) in enumerate([(100, 50), (110, 46), (108, 55), (119, 51), (96, 58), (116, 60)])]


def compose(bg, fish, t):
    img = bg.copy()
    bubbles(img, 182, rise=t)
    for name, x, y, left, speed, rate in CAST:
        s = wobble(fish[name], t * rate * 2 * math.pi / 8 + x)
        if left:
            s = flipped(s)
        dx = round(speed * t) * (-1 if left else 1)
        bob = round(math.sin(t / 6 + x))
        img.alpha_composite(s, ((x + dx) % (W + 40) - 20, y - 2 + bob))
    frame(img)
    return img


def main():
    fish = build_sprites()
    bg = background()
    os.makedirs(PREVIEWS, exist_ok=True)

    still = compose(bg, fish, 0)
    upscale(still, 5).save(os.path.join(PREVIEWS, "tank_preview.png"))
    still.save(os.path.join(PREVIEWS, "tank_preview_1x.png"))

    frames = [upscale(compose(bg, fish, t), 4) for t in range(48)]
    on_desk = []
    for f in frames:  # flatten transparency onto a neutral "desktop" colour for the GIF
        d = Image.new("RGBA", f.size, rgba("navy"))
        d.alpha_composite(f)
        on_desk.append(d.convert("P", palette=Image.Palette.ADAPTIVE, colors=64))
    on_desk[0].save(os.path.join(PREVIEWS, "tank_swim.gif"), save_all=True,
                    append_images=on_desk[1:], duration=90, loop=0, disposal=2)


if __name__ == "__main__":
    main()
