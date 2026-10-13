"""Decorations: ASCII silhouettes with per-region colour ramps, plus a few procedural pieces.

  uv run --with pillow tools/spritegen/decor.py

Writes art/decor/<id>.png and art/previews/decor_sheet.png.

Lighting follows the style guide: light from above (slightly left), coloured outlines,
regions touching a region above them get its shadow (overhangs read as depth).
"""

import math
import os
import random

from PIL import Image

import scene
from build import PREVIEWS, ROOT
from palette import rgba
from render import upscale

OUT = os.path.join(ROOT, "art", "decor")

STONE = {"outline": "navy", "shadow": "dusk", "mid": "slate", "light": "steel", "highlight": "silver"}
ROOF = {"outline": "umber", "shadow": "crimson", "mid": "red", "light": "salmon", "highlight": "peach"}
WOOD = {"outline": "umber", "shadow": "bark", "mid": "wood", "light": "tan", "highlight": "peach"}
GOLD = {"outline": "bark", "shadow": "clay", "mid": "amber", "light": "lemon", "highlight": "white"}
BRASS = {"outline": "bark", "shadow": "clay", "mid": "sand", "light": "amber", "highlight": "lemon"}
CANVAS = {"outline": "navy", "shadow": "slate", "mid": "steel", "light": "silver", "highlight": "white"}
GLASS = {"outline": "navy", "shadow": "navy", "mid": "deep_blue", "light": "sky", "highlight": "cyan"}
SHELL = {"outline": "tan", "shadow": "peach", "mid": "cream", "light": "white", "highlight": "white"}
STRIPE = {"outline": "tan", "shadow": "salmon", "mid": "salmon", "light": "peach", "highlight": "peach"}
SANDSTONE = {"outline": "bark", "shadow": "wood", "mid": "tan", "light": "sand", "highlight": "cream"}


def render_solid(rows, ramps, textures=None):
    """rows: ASCII art; ramps: letter -> ramp dict or flat palette name; textures: letter -> fn(x, y) -> bool (shadow)."""
    h = len(rows)
    w = max(len(r) for r in rows)
    grid = [r.ljust(w, ".") for r in rows]
    textures = textures or {}
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))

    def at(x, y):
        return grid[y][x] if 0 <= x < w and 0 <= y < h else "."

    for y in range(h):
        for x in range(w):
            ch = grid[y][x]
            if ch == ".":
                continue
            ramp = ramps[ch]
            if isinstance(ramp, str):
                img.putpixel((x, y), rgba(ramp))
                continue
            nb = [at(x + 1, y), at(x - 1, y), at(x, y + 1), at(x, y - 1)]
            if "." in nb:
                tone = "outline"
            elif at(x, y - 1) != ch:
                tone = "shadow"  # something sits on top of us
            elif ch in textures and textures[ch](x, y):
                tone = "shadow"
            else:
                s = 0.4 * x / w + 0.8 * y / h
                tone = "highlight" if s < 0.12 else "light" if s < 0.4 else "mid" if s < 0.78 else "shadow"
            img.putpixel((x, y), rgba(ramp[tone]))
    return img


def bricks(x, y):
    return y % 4 == 3 or (x + 3 * ((y // 4) % 2)) % 6 == 0


def planks(x, y):
    return y % 3 == 2


# --- Hand-drawn pieces ---------------------------------------------------------

CASTLE = [
    "....R...............R....",
    "...RRR.............RRR...",
    "...RRR.............RRR...",
    "..RRRRR...........RRRRR..",
    "..RRRRR...........RRRRR..",
    ".RRRRRRR.........RRRRRRR.",
    "RRRRRRRRR.......RRRRRRRRR",
    ".sssssss.........sssssss.",
    ".sssssss.s.s.s.s.sssssss.",
    ".sssdsssssssssssssssdsss.",
    ".sssdsssssssssssssssdsss.",
    ".sssssssssssssssssssssss.",
    ".sssssssssssssssssssssss.",
    ".ssssssssssdddssssssssss.",
    ".sssssssssdddddsssssssss.",
    ".sssdsssssdddddsssssdsss.",
    ".sssdsssssdddddsssssdsss.",
    ".sssssssssdddddsssssssss.",
    ".sssssssssdddddsssssssss.",
    "sssssssssssssssssssssssss",
]

CHEST = [
    "..wwwwwwwwwwww..",
    ".wwwwwwwwwwwwww.",
    "wwwwwwwwwwwwwwww",
    "GGGGGGGGGGGGGGGG",
    "wwwwwwwGGwwwwwww",
    "wwwwwwGddGwwwwww",
    "wwwwwwwGGwwwwwww",
    "wwwwwwwwwwwwwwww",
    "GwwwwwwwwwwwwwwG",
    "GwwwwwwwwwwwwwwG",
    "GGGGGGGGGGGGGGGG",
]

DIVER = [
    "....hhhh....",
    "..hhhhhhhh..",
    ".hhhhhhhhhh.",
    ".hhhggggghh.",
    "hhhggggggghh",
    "hhhggggggghh",
    "hhhhgggggghh",
    ".hhhhhhhhhh.",
    "..hhhhhhhh..",
    "..ssssssss..",
    ".ssssssssss.",
    "sssssssssss.",
    "ss.ssssss.ss",
    "ss.ssssss.ss",
    "kk.ssssss.kk",
    "...ssssss...",
    "...sss.sss..",
    "...sss.sss..",
    "...sss.sss..",
    "..kkkk.kkkk.",
]

SHELL_ART = [
    "......sss...",
    "....sssssss.",
    "..sssqsssqss",
    ".ssqssqssqss",
    "sssssssssss.",
    ".sqsssqsss..",
    "..ssssss....",
]

DRIFTWOOD = [
    "............................ww....",
    "..........................www.....",
    "...www..................wwww......",
    "..wwwwww..............wwwww.......",
    ".wwwwwwwwww......wwwwwwwww........",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwww......",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwww...",
    ".wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww.",
    "..wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwww",
    "...wwwwwwwww.....wwwwwwwwww...www.",
    "....wwwww..........wwwww..........",
]

AIR_STONE = [
    ".aaaa.",
    "aaaaaa",
    "aaaaaa",
]


# --- Procedural pieces -----------------------------------------------------------

def dome_rows(w, h, ch="r", bumps=0.0, seed=0):
    rnd = random.Random(seed)
    jitter = [rnd.uniform(-bumps, bumps) for _ in range(w)]
    rows = []
    for y in range(h):
        row = ""
        for x in range(w):
            dx = (x - (w - 1) / 2) / (w / 2)
            dy = (h - y) / h
            row += ch if dx * dx + dy * dy <= 1 + jitter[x] * dy else "."
        rows.append(row)
    return rows


def arch_rows(w=30, h=18):
    outer = dome_rows(w, h, "r", bumps=0.08, seed=3)
    rows = []
    for y, row in enumerate(outer):
        out = ""
        for x, c in enumerate(row):
            dx = (x - (w - 1) / 2) / 8.0
            dy = (h - y) / 11.0
            out += "." if dx * dx + dy * dy <= 1 else c
        rows.append(out)
    return rows


def pebbles():
    img = Image.new("RGBA", (24, 7), (0, 0, 0, 0))
    for x0, w, h, ramp in ((0, 10, 6, STONE), (8, 8, 5, SANDSTONE), (14, 10, 7, STONE)):
        p = render_solid(dome_rows(w, h, "r", seed=x0), {"r": ramp})
        img.alpha_composite(p, (x0, 7 - h))
    return img


def moss_ball():
    img = Image.new("RGBA", (9, 9), (0, 0, 0, 0))
    for y in range(9):
        for x in range(9):
            d = math.hypot(x - 4, y - 4)
            if d <= 4.3:
                if d > 3.4:
                    c = "pine"
                elif (x + y) % 2 == 0 and d < 2.6 and x < 5 and y < 5:
                    c = "leaf"
                else:
                    c = "moss" if (x * 3 + y * 5) % 4 else "pine"
                img.putpixel((x, y), rgba(c))
    return img


def sword_plant():
    w, h = 23, 26
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    base = (w // 2, h - 1)
    for ang, length, width in ((-58, 13, 3.0), (58, 13, 3.0), (-32, 19, 3.4), (32, 19, 3.4),
                               (-12, 24, 3.6), (12, 22, 3.4), (0, 25, 3.0)):
        a = math.radians(ang)
        ux, uy = math.sin(a), -math.cos(a)  # along the leaf
        for y in range(h):
            for x in range(w):
                rx, ry = x - base[0], y - base[1]
                t = rx * ux + ry * uy
                s = rx * -uy + ry * ux  # across the leaf
                if 0 <= t <= length:
                    half = width * math.sin(math.pi * min(1.0, t / length) ** 0.8)
                    if abs(s) <= half:
                        edge = abs(s) > half - 1
                        c = "pine" if abs(s) < 0.5 or edge else ("leaf" if s < 0 else "moss")
                        img.putpixel((x, y), rgba(c))
    return img


def ribbon(height, lean, ramp):
    canvas = Image.new("RGBA", (scene.W, scene.H), (0, 0, 0, 0))
    scene.plant(canvas, scene.W // 2, height, lean, ramp)
    return canvas.crop(canvas.getbbox())


def build():
    random.seed(7)
    items = {
        "plant_tall": ribbon(60, 2, ["pine", "moss", "leaf"]),
        "plant_medium": ribbon(48, 3, ["pine", "moss", "leaf"]),
        "plant_short": ribbon(30, 1, ["abyss_green", "pine", "moss"]),
        "plant_sword": sword_plant(),
        "moss_ball": moss_ball(),
        "rock": render_solid(dome_rows(31, 13, "r", bumps=0.05, seed=1), {"r": STONE}),
        "pebbles": pebbles(),
        "rock_arch": render_solid(arch_rows(), {"r": SANDSTONE}),
        "driftwood": render_solid(DRIFTWOOD, {"w": WOOD}, {"w": lambda x, y: (x * 7 + y * 13) % 11 == 0}),
        "castle": render_solid(CASTLE, {"s": STONE, "R": ROOF, "d": "ink"}, {"s": bricks}),
        "treasure_chest": render_solid(CHEST, {"w": WOOD, "G": GOLD, "d": "ink"}, {"w": planks}),
        "diver": render_solid(DIVER, {"h": BRASS, "g": GLASS, "s": CANVAS, "k": "dusk"}),
        "shell": render_solid(SHELL_ART, {"s": SHELL, "q": STRIPE}),
        "air_stone": render_solid(AIR_STONE, {"a": STONE}),
    }
    os.makedirs(OUT, exist_ok=True)
    for name, img in items.items():
        img.save(os.path.join(OUT, f"{name}.png"))
    return items


def sheet(items, scale=5, pad=4):
    cols = 5
    cell_w = max(i.width for i in items.values()) + pad * 2
    cell_h = max(i.height for i in items.values()) + pad * 2
    rows = -(-len(items) // cols)
    img = Image.new("RGBA", (cell_w * cols, cell_h * rows), rgba("deep_blue"))
    for n, it in enumerate(items.values()):
        cx, cy = (n % cols) * cell_w, (n // cols) * cell_h
        for x in range(cell_w):  # gravel strip so pieces read as sitting on the floor
            img.putpixel((cx + x, cy + cell_h - 3), rgba("sand"))
        img.alpha_composite(it, (cx + (cell_w - it.width) // 2, cy + cell_h - 3 - it.height))
    return upscale(img, scale)


if __name__ == "__main__":
    items = build()
    os.makedirs(PREVIEWS, exist_ok=True)
    sheet(items).save(os.path.join(PREVIEWS, "decor_sheet.png"))
    print("built:", ", ".join(items))
