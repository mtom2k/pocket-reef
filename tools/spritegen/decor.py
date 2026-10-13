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
DARKWOOD = {"outline": "umber", "shadow": "umber", "mid": "bark", "light": "wood", "highlight": "tan"}
TERRACOTTA = {"outline": "bark", "shadow": "rust", "mid": "clay", "light": "sand", "highlight": "peach"}
CORAL = {"outline": "plum", "shadow": "orchid", "mid": "salmon", "light": "peach", "highlight": "cream"}
AMETHYST = {"outline": "navy", "shadow": "plum", "mid": "orchid", "light": "salmon", "highlight": "white"}
LAVA = {"outline": "umber", "shadow": "umber", "mid": "bark", "light": "rust", "highlight": "clay"}
STARFISH = {"outline": "rust", "shadow": "clay", "mid": "orange", "light": "amber", "highlight": "lemon"}
CLAM = {"outline": "dusk", "shadow": "slate", "mid": "steel", "light": "silver", "highlight": "white"}
HULL = {"outline": "umber", "shadow": "bark", "mid": "wood", "light": "tan", "highlight": "peach"}


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


# --- Procedural helpers for the v0.3 pieces ------------------------------------------------

def grid_rows(grid):
    return ["".join(r) for r in grid]


def stamp_disc(grid, cx, cy, r, ch):
    for y in range(int(cy - r - 1), int(cy + r + 2)):
        for x in range(int(cx - r - 1), int(cx + r + 2)):
            if 0 <= y < len(grid) and 0 <= x < len(grid[0]) and (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                grid[y][x] = ch


def branches(w, h, seed, ch, trunk=2.2, tip_blob=0.0, spread=0.55, levels=4):
    """Tree-like growth from the bottom centre: driftwood ("spider wood") and coral."""
    rnd = random.Random(seed)
    grid = [["."] * w for _ in range(h)]

    def grow(x, y, ang, length, thick, level):
        steps = int(length)
        for i in range(steps):
            x += math.sin(ang)
            y -= math.cos(ang)
            ang += rnd.uniform(-0.12, 0.12)
            stamp_disc(grid, x, y, max(0.6, thick * (1 - 0.5 * i / steps)), ch)
        if tip_blob:
            stamp_disc(grid, x, y, tip_blob, ch)
        if level < levels:
            for side in (-1, 1):
                if level <= 2 or rnd.random() < 0.8:  # main limbs always fork; twigs are random
                    grow(x, y, ang + side * rnd.uniform(0.25, spread), length * rnd.uniform(0.55, 0.75),
                         thick * 0.7, level + 1)

    grow(w / 2, h - 1, rnd.uniform(-0.15, 0.15), h * 0.38, trunk, 1)
    return grid_rows(grid)


def leafy(w, h, leaves, colours, rib="pine", edge="pine"):
    """Leaves as lens shapes from a base point: (angle deg, length, width, colour index)."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    base = (w // 2, h - 1)
    for ang, length, width, ci in leaves:
        a = math.radians(ang)
        ux, uy = math.sin(a), -math.cos(a)
        for y in range(h):
            for x in range(w):
                rx, ry = x - base[0], y - base[1]
                t = rx * ux + ry * uy
                sd = rx * -uy + ry * ux
                if 2 <= t <= length:
                    half = width * math.sin(math.pi * min(1.0, (t - 2) / (length - 2)))
                    if abs(sd) <= half:
                        on_edge = abs(sd) > half - 1
                        c = rib if abs(sd) < 0.5 else (edge if on_edge else colours[ci][0 if sd < 0 else 1])
                        img.putpixel((x, y), rgba(c))
        for t in range(0, 3):  # short stem
            img.putpixel((base[0] + round(ux * t), base[1] + round(uy * t)), rgba(rib))
    return img


def stem_plant(h, seed):
    """Red ludwigia: a stem with pairs of red/orange leaves, redder toward the top."""
    rnd = random.Random(seed)
    w = 13
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx = w // 2
    for y in range(h):
        img.putpixel((cx, y), rgba("moss" if y > h * 0.4 else "rust"))
    for y in range(h - 3, 1, -3):
        top = 1 - y / h
        light, dark = (("salmon", "red") if top > 0.6 else ("orange", "rust") if top > 0.3 else ("leaf", "moss"))
        for side in (-1, 1):
            length = rnd.randint(3, 5)
            for i in range(1, length + 1):
                lx = cx + side * i
                ly = y - (1 if i > 2 else 0)
                if 0 <= lx < w:
                    img.putpixel((lx, ly), rgba(dark if i == length else light))
                    if i < length and ly + 1 < h:
                        img.putpixel((lx, ly + 1), rgba(dark))
    return img


def pitted_dome(w, h, seed, ramp, pits=8):
    rows = [list(r) for r in dome_rows(w, h, "r", bumps=0.12, seed=seed)]
    rnd = random.Random(seed)
    for _ in range(pits):
        x, y = rnd.randrange(2, w - 2), rnd.randrange(h // 3, h - 1)
        if rows[y][x] == "r" and rows[y - 1][x] == "r":
            rows[y][x] = "p"
    return render_solid(grid_rows(rows), {"r": ramp, "p": "ink"})


LOG = [
    "....wwwwwwwwwwwwwwwwwwwwwwwwwwww....",
    "..wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwRR..",
    ".wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwRddR.",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwRddddR",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwRddddR",
    "wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwRddddR",
    ".wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwRddR.",
    "..wwwwwwwwwwwwwwwwwwwwwwwwwwwwwwRR..",
    "....wwwwwwwwwwwwwwwwwwwwwwwwwwww....",
]

POT = [
    ".....tttttttttttt.....",
    "...tttttttttttttttRR..",
    "..ttttttttttttttttRdR.",
    ".tttttttttttttttttRddR",
    "ttttttttttttttttttRddR",
    "ttttttttttttttttttRddR",
    "ttttttttttttttttttRddR",
    "ttttttttttttttttttRddR",
    ".tttttttttttttttttRddR",
    "..ttttttttttttttttRdR.",
    "...tttttttttttttttRR..",
    ".....tttttttttttt.....",
]

SHIP = [
    "........................mm................",
    "........................mmSS..............",
    "........................mmSSS.............",
    "........................mmSSSS............",
    "........................mmSSS.............",
    "........................mmSS..............",
    "...rrrrrrr..............mm................",
    "...rrprrpr..............mm................",
    "..hhhhhhhhh.............mm.............hh.",
    "..hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh.",
    "..hhhphhhhhhphhhhhhphhhhhhhphhhhhhhhhhhh..",
    "...hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh..",
    "....hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh...",
    ".....hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh....",
    "......hhhhhhhhhhhhhhhhhhhhhhhhhhhhhhh.....",
    ".......hhhhhhhhhhhhhhhhhhhhhhhhhhhhh......",
]

CLAM_ART = [
    "...ccccccccc...",
    ".ccccccccccccc.",
    "ccccccccccccccc",
    "cccccccccccccc.",
    ".dddddwwddddd..",
    "cccccccccccccc.",
    "ccccccccccccccc",
    ".ccccccccccccc.",
]

CRYSTALS = [
    "..........a...........",
    ".........aaa..........",
    ".........aaa..........",
    "....a....aaa.....a....",
    "...aaa...aaa....aaa...",
    "...aaa..aaaaa...aaa...",
    "...aaa..aaaaa...aaa.a.",
    ".a.aaa..aaaaa..aaaaaaa",
    "aaaaaa.aaaaaaa.aaaaaaa",
    "aaaaaaaaaaaaaaaaaaaaaa",
    "aaaaaaaaaaaaaaaaaaaaaa",
    ".rrrrrrrrrrrrrrrrrrrr.",
    "..rrrrrrrrrrrrrrrrrr..",
]

STAR = [
    ".....s.....",
    ".....s.....",
    "....sss....",
    "sssssssssss",
    ".sssssssss.",
    "..sssssss..",
    "..sss.sss..",
    ".sss...sss.",
    ".ss.....ss.",
]


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
        # v0.3
        "spiderwood": render_solid(branches(34, 40, seed=11, ch="w", trunk=3.2, spread=0.7, levels=4),
                                   {"w": DARKWOOD}, {"w": lambda x, y: (x * 5 + y * 3) % 9 == 0}),
        "driftwood_log": render_solid(LOG, {"w": WOOD, "R": SANDSTONE, "d": "umber"},
                                      {"w": lambda x, y: y % 3 == 1 and (x * 7) % 5 != 0}),
        "terracotta_pot": render_solid(POT, {"t": TERRACOTTA, "R": SANDSTONE, "d": "umber"},
                                       {"t": lambda x, y: x % 6 == 5}),
        "anubias": leafy(22, 16, [(-62, 11, 3.2, 0), (-30, 14, 3.6, 0), (5, 15, 3.8, 0), (35, 13, 3.4, 0), (65, 10, 3.0, 0)],
                         [("moss", "pine")], rib="abyss_green", edge="abyss_green"),
        "java_fern": leafy(20, 28, [(-28, 22, 2.4, 0), (-10, 27, 2.6, 0), (12, 25, 2.5, 0), (30, 20, 2.3, 0), (-45, 14, 2.0, 0)],
                           [("moss", "pine")], rib="pine", edge="abyss_green"),
        "red_ludwigia": stem_plant(36, seed=4),
        "sunken_ship": render_solid(SHIP, {"h": HULL, "r": DARKWOOD, "m": DARKWOOD, "S": CANVAS, "p": "ink"},
                                    {"h": lambda x, y: y % 2 == 0 and x % 7 == 3}),
        "bubble_clam": render_solid(CLAM_ART, {"c": CLAM, "d": "umber", "w": "white"},
                                    {"c": lambda x, y: x % 3 == 0}),
        "coral": render_solid(branches(28, 26, seed=5, ch="c", trunk=2.6, tip_blob=2.0, spread=0.9, levels=4),
                              {"c": CORAL}),
        "crystals": render_solid(CRYSTALS, {"a": AMETHYST, "r": STONE}),
        "lava_rock": pitted_dome(22, 11, seed=9, ramp=LAVA),
        "starfish": render_solid(STAR, {"s": STARFISH}, {"s": lambda x, y: (x + y) % 4 == 0}),
    }
    os.makedirs(OUT, exist_ok=True)
    for name, img in items.items():
        img.save(os.path.join(OUT, f"{name}.png"))
    return items


def sheet(items, scale=5, pad=4):
    cols = 7
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
