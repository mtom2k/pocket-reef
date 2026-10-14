"""Species silhouettes and colour ramps. Legend lives in render.py.

Silhouettes face RIGHT. Colour variants reuse a silhouette with a different ramp set.
`fin_roots` maps a fin letter to the point(s) its rays radiate from (usually where
the fin meets the body).
"""

import math

NEON_TETRA = [
    ".......F........",
    "F.....ggF.......",
    "FF..bbbbbbbbbb..",
    ".Fbb111111111eb.",
    ".fbb2222BBBBBBbb",
    "FF..bb222BBBBm..",
    "F......gg..h....",
]

GOLDFISH = [
    "...ff...........gg",
    ".fffff.........gggg",
    "..fffff.......gggggg",
    "..ffffff......ggggggg",
    "..ffffff.....ggggggggg",
    "...ffffff...ggggbbbbbbb",
    "...fffffff.ggbbbbbbbbbbbb",
    "....ffffffffbbbbbbbbbbbbbbb",
    ".....fffffffbbbbbbbbbbbbbeeb",
    ".....fffffffbbbbbbbbbbbbbewbb",
    "......ffffffbbbbbbbbbbbbbbbbbm",
    ".....fffffffbbbbbbbbbbbbbbbbb",
    ".....fffffffbbbbbbbbhbbbbbbbb",
    "....ffffffffBBBBBBBhhhBBBBBB",
    "...fffffff..BBBBBhhhhBBBBB",
    "...ffffff....BBBBBBBBBBBB",
    "..ffffff.....gBBBBBBBBBh",
    "..ffffff.....gggBBBBBhhh",
    "..fffff.....ggg......hhh",
    ".fffff......gg.......hh",
    "...ff",
]

BETTA = [
    "........gg",
    ".....gggggggg",
    ".....gggggggggg",
    ".F....ggggggggg",
    ".fff...gggggggg",
    ".fffff..ggggggg",
    ".fffffff.ggggggg",
    "ffffffffffggggggg",
    "fffffffffffffgggbbbbb",
    "ffffffffffffffbbbbbbbbbbbb",
    "ffffffffffffffbbbbbbbbbbbewb",
    "ffffffffffffffbbbbbbbbbbbeebb",
    "ffffffffffffffbbbbbbbbbbbbbbbm",
    "ffffffffffffffBBBBBBBhBBBBBB",
    "fffffffffffffgggBBBBhhhBBB",
    "ffffffffffgggggggghhhB",
    ".fffffffgggggggggggg",
    ".fffffgggggggggggg",
    ".fffgggggggggggggg",
    ".f.gggggggggggggg",
    "...ggggggggggggg",
    "....gggggggggggg",
    ".........ggggg",
]

GUPPY = [
    "fff..............",
    "fFff.............",
    "ffFff.....gg.....",
    "fFfFff..gggbbb...",
    "ffffFffbbbbbbbbb.",
    "fFfffffbbbbbbebbb",
    "ffFfffbBBBBBBBbbm",
    "fFfFff..BBBBBbb..",
    "ffFff.....h......",
    "fFff.............",
    "fff..............",
]

CORYDORAS = [
    "........g......",
    ".......ggg.....",
    "ff....gggbbb...",
    "fff.bbbbbbbbbb.",
    "ffbbbbbbbbbbbeb",
    "fffbBBBBBBBBBbb",
    "ff..BBBBBBBBBm.",
    ".....h....h....",
]


def _angelfish():
    rows = [
        "..........g",
        ".........gg",
        "........ggg",
        ".......gggg",
        "......ggggg",
        ".....gggggg",
        ".....ggggggg",
        "....gggggggbbb",
        "....ggggggbbbbbb",
        "..f..gggggbbbbbbbb",
        ".fff.ggggbbbbbbbbbb",
        ".ffffgggbbbbbbbbbewb",
        ".ffffffbbbbbbbbbbeebb",
        ".fffffbbbbbbbbbbbbbbbm",
        ".ffffffbbbbbbbbbbbbbb",
        ".ffffgggBBBBBBBBBBBB",
        ".fff.ggggBBBBBBBBBB",
        "..f..gggggBBBBBBBB",
        "....ggggggBBBBBB",
        "....gggggggBhBh",
        ".....ggggggg.h.h",
        ".....gggggg..h..h",
        "......ggggg..h..h",
        "......gggg...h..h",
        ".......ggg...h...h",
        "........gg...h",
        ".........g",
    ]
    # Three dark vertical bars: through the eye, mid-body, and rear body into the fins.
    grid = [list(r) for r in rows]
    for x in (8, 9, 13, 14, 19):
        for y, row in enumerate(grid):
            if x < len(row) and row[x] in "bB":
                row[x] = "1"
            elif x in (8, 9) and x < len(row) and row[x] == "g":
                row[x] = "F"
    return ["".join(r) for r in grid]


ANGELFISH = _angelfish()

SHRIMP = [
    ".....bbbbbb.......",
    "...bbbbbbbbbb..FFF",
    ".bbbbbbbbbbbbebF..",
    "fbbbbbbbbbbbbbbm..",
    "ff..h.h.h.h.h.....",
    "f...h.h.h.h.h.....",
]


def _oranda():
    """A fancy goldfish with a 'wen': a bumpy hood over the whole head, eye peeking through."""
    g = [list(r.ljust(31, ".")) for r in GOLDFISH]
    # The hood bulges above and in front of the head...
    for y, x0, x1 in ((2, 21, 25), (3, 19, 27), (4, 18, 28), (5, 23, 29), (6, 25, 30), (7, 27, 30), (8, 28, 30),
                      (9, 29, 30), (10, 29, 30), (11, 28, 29)):
        for x in range(x0, x1 + 1):
            if g[y][x] in ".b":
                g[y][x] = "W"
    # ...and covers the head itself (everything forward of the gills), except the eye and mouth.
    for y in range(3, 13):
        for x in range(21, 31):
            if g[y][x] == "b" and not (y >= 11 and x < 24):
                g[y][x] = "W"
    return ["".join(r).rstrip(".") for r in g]


ORANDA = _oranda()


def _clownfish():
    rows = [
        ".......gg.........",
        "......ggggg.......",
        "ff...bbbbbbbbb....",
        "fff.bbbbbbbbbbbb..",
        "ffffbbbbbbbbbbebb.",
        "ffffbbbbbbbbbbbbbm",
        "fff.bBBBBBBBBBBBb.",
        "ff...BBBBBBBBBBB..",
        "......hh...hh.....",
    ]
    grid = [list(r) for r in rows]
    # Three white bands (pattern 1) edged in black (pattern 2): behind the head, mid-body, tail.
    for band, edges in (((12, 13), (11, 14)), ((8,), (7, 9)), ((5,), (4,))):
        for y, row in enumerate(grid):
            for x in band:
                if row[x] in "bB":
                    row[x] = "1"
            for x in edges:
                if row[x] in "bB":
                    row[x] = "2"
    return ["".join(r) for r in grid]


CLOWNFISH = _clownfish()

# Seen from above, stuck to the front glass the way hillstream loaches are in real tanks.
LOACH = [
    "........ffff........",
    ".....ffffffffff.....",
    "...fffbbbbbbbbfff...",
    "F.ffbbb1bb1bbbbbff..",
    "FFfbbbbbbbbbbbebbbf.",
    "FFfbb1bbb1bbbbbbbbbm",
    "FFfbbbbbbbbbbbebbbf.",
    "F.ffbbb1bb1bbbbbff..",
    "...fffbbbbbbbbfff...",
    ".....ffffffffff.....",
    "........ffff........",
]

SNAIL = [
    "...bbbbb......",
    ".bbbbbbbbb....",
    "bbb111bbbbb...",
    "bb1bbb1bbbb...",
    "bb1b1bb1bbb..F",
    "bbb11bbbbbb.F.",
    ".bbbbbbbbbBBF.",
    "BBBBBBBBBBBBBe",
]


# --- v0.6 ------------------------------------------------------------------------------------
# Morph markings are painted onto a base silhouette with _mark, so a species' morphs share one
# outline and differ only in pattern (see the "shape" key on a variant).

def _mark(rows: list[str], ch: str, where, only: str = "bB") -> list[str]:
    """Repaints the `only` pixels where where(x, y) is true as `ch`."""
    return ["".join(ch if c in only and where(x, y) else c for x, c in enumerate(r)) for y, r in enumerate(rows)]


def _at(cells):
    cells = set(cells)
    return lambda x, y: (x, y) in cells


PLATY = _mark([
    "..........gg....",
    "f........gggg...",
    "ff....bbbbbbbb..",
    "fff..bbbbbbbbbb.",
    "ffffbbbbbbbbbbeb",
    "ffffbbbbbbbbbbbm",
    "fff.bBBBBBBBBBb.",
    "ff...BBBBBBBB...",
    "f.....g...h.....",
], "1", _at([(5, 4), (5, 5), (6, 5), (5, 6), (4, 4)]))  # "Mickey Mouse" spot at the tail root
PLATY_SUNSET = _mark(PLATY, "2", lambda x, y: x <= 9)  # yellow front, red back

MOLLY = [
    "..........gggg....",
    "........ggggggg...",
    "ff.....ggbbbbbbb..",
    "fff..bbbbbbbbbbbb.",
    "ffffbbbbbbbbbbbbeb",
    "fffffbbbbbbbbbbbbm",
    "ffffbBBBBBBBBBBBb.",
    "fff..BBBBBBBBBBB..",
    "ff.....gg...h.....",
]

ZEBRA_DANIO = _mark([
    ".........gg.......",
    "f...bbbbbbbbbbb...",
    "Ff.bbbbbbbbbbbbbb.",
    "fFFbbbbbbbbbbbbbeb",
    "Ffbbbbbbbbbbbbbbbm",
    "f..BBBBBBBBBBBBBb.",
    ".....g.....h......",
], "1", lambda x, y: y in (2, 4) and x <= 13)  # two blue stripes
LEOPARD_DANIO = _mark(_mark(ZEBRA_DANIO, "b", lambda x, y: True, "1"), "1",
                      lambda x, y: 2 <= y <= 4 and x <= 14 and (x + 2 * y) % 3 == 0)

CHERRY_BARB = _mark([
    "......ggg......",
    "ff...gbbbbbb...",
    "fff.bbbbbbbbbb.",
    "ffffbbbbbbbbbeb",
    "ffffbbbbbbbbbbm",
    "fff.BBBBBBBBBbb",
    "ff...BBBBBBBB..",
    "......g...h....",
], "1", lambda x, y: y == 4 and x <= 12)  # the dark line along the side

CARDINAL_TETRA = [  # like the neon, but the red runs the whole length
    ".......F........",
    "F.....ggF.......",
    "FF..bbbbbbbbbb..",
    ".Fbb111111111eb.",
    ".fbb2222222222bb",
    "FF..b2222222Bm..",
    "F......gg..h....",
]

RUMMYNOSE = [  # red nose, black-and-white striped tail
    "........g.......",
    "FF.....ggg......",
    "ff..bbbbbbbbb2..",
    "FFFbbbbbbbbb2e2.",
    "ff.bbbbbbbbb222m",
    "FF..BBBBBBBB22..",
    "........g..h....",
]


def _discus():
    """A round disc with a fringe of fin all the way round, and wavy lines across the body."""
    w, h = 23, 21
    cx, cy = 11.5, 10.0
    rows = []
    for y in range(h):
        row = ""
        for x in range(w):
            body = ((x - cx) / 8.2) ** 2 + ((y - cy) / 7.6) ** 2 <= 1.0
            fin = ((x - cx + 0.5) / 9.8) ** 2 + ((y - cy) / 10.2) ** 2 <= 1.0 and x < 18
            tail = x <= 3 and abs(y - cy) <= 3 - (x == 0)
            if body:
                ch = "B" if y >= cy + 3 else "b"
                if ch == "b" and x <= 15 and (y + round(1.3 * math.sin(x / 1.6))) % 3 == 0 and y > 3:
                    ch = "2"
                row += ch
            elif tail:
                row += "f"
            elif fin:
                row += "g"
            else:
                row += "."
        rows.append(row)
    g = [list(r) for r in rows]
    g[8][16], g[8][17], g[9][16], g[9][17] = "e", "w", "e", "e"
    g[10][19] = "m"
    for y, x in ((14, 14), (15, 13), (16, 13)):  # pelvic fins
        g[y][x] = "h"
    return ["".join(r).rstrip(".") for r in g]


DISCUS = _discus()

DWARF_GOURAMI = _mark([
    ".........gggg......",
    ".......gggggggg....",
    "ff....ggbbbbbbbb...",
    "fff..gbbbbbbbbbbb..",
    "ffff.bbbbbbbbbbbeb.",
    "fffffbbbbbbbbbbbbbm",
    "ffff.bBBBBBBBBBBBb.",
    "fff..gBBBBBBBBBBh..",
    "ff...ggBBBBBBBB.h..",
    "......gggggggg...h.",
    ".......gggggg....h.",
    "................h..",
], "1", lambda x, y: 6 <= x <= 14 and (x - y // 2) % 4 == 0)  # slanting red bands

BRISTLENOSE = _mark([  # from above, sucked onto the front glass
    "...........ff.......",
    "..........ffff......",
    "F.......bbbbbbbbbF..",
    "FF.fffbbbbbbbbbbbbbF",
    "FFfbbbbbbbbbbbbebbbF",
    "FFfbbbbbbbbbbbbbbbbm",
    "FFfbbbbbbbbbbbbebbbF",
    "FF.fffbbbbbbbbbbbbbF",
    "F.......bbbbbbbbbF..",
    "..........ffff......",
    "...........ff.......",
], "1", lambda x, y: x <= 16 and (3 * x + 5 * y) % 7 == 0)  # pale spots

RAM = [  # yellow face, black bar through the eye, black spot mid-flank
    "......gFgg......",
    "f....Fggggg.....",
    "ff..bbbbbbbbb2..",
    "fff.bbbbbbb11211",
    "ffffbbb2bbb11e1.",
    "fffbbb22bbb1121m",
    "ffffBBBBBBB112..",
    "fff.BBBBBBBB2...",
    "ff....ggg..h....",
    "......ggg..h....",
]


def _blue_tang(palette=True):
    rows = [
        ".........gggg.......",
        "......ggggggggg.....",
        "f...ggbbbbbbbbbb....",
        "ff.gbbbbbbbbbbbbbb..",
        "fffbbbbbbbbbbbbbebb.",
        "fffbbbbbbbbbbbbbbbbm",
        "fffbbbbbbbbbbbbbbbb.",
        "ff.gBBBBBBBBBBBBBb..",
        "f...ggBBBBBBBBBB....",
        "......gggggggggh....",
        ".........gggg..h....",
    ]
    if palette:  # the black "painter's palette" from the eye back to the tail
        rows = _mark(rows, "2", _at([(x, 3) for x in range(9, 15)] + [(x, 4) for x in (6, 7, 8, 9, 14, 15)]
                                    + [(x, 5) for x in (4, 5, 6, 11, 12)] + [(3, 6), (4, 6)]))
    return rows


BLUE_TANG = _blue_tang()
POWDER_BLUE_TANG = _mark(_mark(_blue_tang(False), "1", lambda x, y: x >= 15, "b"), "2",
                         lambda x, y: x >= 13, "B")  # black face, white throat

YELLOW_TANG = [
    "........gg........",
    "......ggggg.......",
    ".....gggggggg.....",
    "....gggggggggg....",
    "....ggggbbbbbbb...",
    "f...gbbbbbbbbbbb..",
    "ff.gbbbbbbbbbbbebb",
    "fffbbbbbbbbbbbbbbbm",
    "fff1bbbbbbbbbbbbbb",
    "ff.gBBBBBBBBBBBBB.",
    "f...gBBBBBBBBBBh..",
    "....ggggBBBBBBh...",
    "....gggggggggg....",
    ".....gggggggg.....",
    "......ggggg.......",
    "........gg........",
]

ROYAL_GRAMMA = [
    "......gFgggg.....",
    "f....gggggggg....",
    "ff.222222bbbbbb..",
    "fff222222bbbb1e1.",
    "fff222222bbbbbb1m",
    "ff.222222BBBBBb..",
    "f.....ggggg..h...",
]

MANDARIN = _mark([
    "....ggg.gggg....",
    "...ggggggggggg..",
    "ff.gggbbbbbbbb..",
    "fffbbbbbbbbbbeb.",
    "fffbbbbbbbbbbbbm",
    "fffbBBBBBBBBBBbb",
    "ff..hhBBBBBBhh..",
    "....hhh....hhh..",
], "1", lambda x, y: x <= 12 and (x + 2 * (y % 2)) % 4 == 0)  # orange squiggles
SPOTTED_MANDARIN = _mark(_mark(MANDARIN, "b", lambda x, y: True, "1"), "1",
                         lambda x, y: x <= 12 and (2 * x + 3 * y) % 5 == 0)

PEA_PUFFER = _mark([
    ".....gg.....",
    "....bbbbbb..",
    "f..bbbbbbbb.",
    "ffbbbbbbbewb",
    "ffbbbbbbbeeb",
    "f.bBBBBBBBBm",
    "...BBBBBBB..",
    "....g..h....",
], "1", _at([(4, 2), (6, 2), (5, 3), (3, 3), (7, 3), (4, 4), (6, 4)]))
AMAZON_PUFFER = _mark(_mark(PEA_PUFFER, "b", lambda x, y: True, "1"), "1", lambda x, y: x in (3, 4, 7))

KUHLI_LOACH = _mark([
    "..........g.........",
    "f...bbbbbbbbbbbbbb..",
    "ffbbbbbbbbbbbbbbbbe.",
    "ffbbBBBBBBBBBBBBBBBm",
    "f...BBBBBBBBBBBBBB..",
    "..........g....h....",
], "1", lambda x, y: 3 <= x <= 16 and x % 3 == 0, "bB")  # dark saddles

AXOLOTL = [
    "...............F.F....",
    "ff.............FF.F...",
    "ffff..........bbbbbb..",
    "fffffbbbbbbbbbbbbbbbb.",
    ".fffbbbbbbbbbbbbbbebbb",
    "ffffbBBBBBBBBBBBBBBBbm",
    "fff....hBBBBB..hBBBB..",
    "ff.....hh......hh.F...",
    ".......hh.....hh......",
]

GHOST_SHRIMP = [  # see-through: the body is drawn on the (translucent) fin layer; F = coloured dots
    ".....gggggg.......",
    "...ggggggFgg...ggg",
    ".ggFggggggggegg...",
    "fggggggFggggggm...",
    "ff..h.h.h.h.h.....",
    "f...h.h.h.h.h.....",
]
AMANO_SHRIMP = _mark(_mark(GHOST_SHRIMP, "g", lambda x, y: True, "F"), "F",
                     lambda x, y: (y == 1 and 4 <= x <= 10 and x % 3 != 0) or (y == 3 and 3 <= x <= 11 and x % 3 != 1),
                     "g")  # dashed lines along the side

PANDA_CORY = _mark(_mark(CORYDORAS, "1", lambda x, y: x in (12, 13) or (x == 3 and y in (4, 5))),
                   "F", lambda x, y: True, "g")  # eye mask, tail band, black dorsal


SPECIES = {
    "neon_tetra": {
        "shape": NEON_TETRA,
        "fin_roots": {},
        "variants": {
            "default": {
                "body":  {"outline": "navy", "shadow": "dusk", "mid": "slate", "light": "steel", "highlight": "silver"},
                "belly": {"outline": "navy", "shadow": "steel", "mid": "silver", "light": "white"},
                "p1":    {"shadow": "sky", "mid": "cyan", "light": "cyan"},
                "p2":    {"shadow": "crimson", "mid": "red", "light": "red"},
                "fin":   {"outline": ("silver", 150), "mid": ("silver", 90), "accent": ("silver", 120)},
            },
            "gold": {  # Gold Neon: a golden body with softened stripes
                "body":  {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "lemon", "mid": "cream", "light": "white"},
                "p1":    {"shadow": "sky", "mid": "sky", "light": "cyan"},
                "p2":    {"shadow": "salmon", "mid": "salmon", "light": "salmon"},
                "fin":   {"outline": ("lemon", 150), "mid": ("lemon", 90), "accent": ("lemon", 120)},
            },
            "albino": {  # Albino Neon: pale and see-through, red eyes
                "body":  {"outline": "steel", "shadow": "silver", "mid": "white", "light": "white", "highlight": "white"},
                "belly": {"outline": "steel", "shadow": "silver", "mid": "white", "light": "white"},
                "p1":    {"shadow": "silver", "mid": "cyan", "light": "white"},
                "p2":    {"shadow": "salmon", "mid": "salmon", "light": "peach"},
                "fin":   {"outline": ("silver", 150), "mid": ("silver", 90), "accent": ("silver", 120)},
                "eye": "red",
            },
        },
    },
    "goldfish": {
        "shape": GOLDFISH,
        "fin_roots": {"f": [(12, 10)], "g": [(18, 6), (14, 15)], "h": [(20, 12), (21, 16)]},
        "variants": {
            "default": {
                "body":  {"outline": "crimson", "shadow": "rust", "mid": "orange", "light": "amber", "highlight": "lemon"},
                "belly": {"outline": "crimson", "shadow": "clay", "mid": "amber", "light": "lemon"},
                "fin":   {"outline": ("rust", 235), "inner": ("orange", 220), "mid": ("amber", 190),
                          "ray": ("orange", 220), "accent": ("lemon", 220)},
            },
            "sarasa": {
                "body":  {"outline": "crimson", "shadow": "crimson", "mid": "red", "light": "salmon", "highlight": "peach"},
                "belly": {"outline": "crimson", "shadow": "silver", "mid": "white", "light": "white"},
                "patches": {"seed": 3, "count": 5,
                            "ramp": {"shadow": "silver", "mid": "white", "light": "white", "highlight": "white"}},
                "fin":   {"outline": ("crimson", 235), "inner": ("red", 220), "mid": ("salmon", 190),
                          "ray": ("red", 220), "accent": ("white", 220)},
            },
            "black": {
                "body":  {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk", "highlight": "slate"},
                "belly": {"outline": "ink", "shadow": "navy", "mid": "dusk", "light": "slate"},
                "fin":   {"outline": ("ink", 240), "inner": ("navy", 230), "mid": ("dusk", 200),
                          "ray": ("ink", 230), "accent": ("slate", 220)},
                "eye": "amber",
            },
            "calico": {
                "body":  {"outline": "navy", "shadow": "steel", "mid": "silver", "light": "white", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "steel", "mid": "white", "light": "white"},
                "fin":   {"outline": ("slate", 230), "inner": ("silver", 200), "mid": ("silver", 170),
                          "ray": ("steel", 210), "accent": ("orange", 220)},
            },
        },
    },
    "betta": {
        "shape": BETTA,
        "fin_roots": {"f": [(13, 11)], "g": [(16, 8), (17, 14)], "h": [(22, 13)]},
        "variants": {
            "default": {
                "body":  {"outline": "umber", "shadow": "plum", "mid": "crimson", "light": "red", "highlight": "salmon"},
                "belly": {"outline": "umber", "shadow": "crimson", "mid": "red", "light": "red"},
                "fin":   {"outline": "salmon", "inner": "crimson", "mid": "red", "ray": "crimson", "accent": "salmon"},
            },
            "royal_blue": {
                "body":  {"outline": "ink", "shadow": "navy", "mid": "deep_blue", "light": "sky", "highlight": "cyan"},
                "belly": {"outline": "ink", "shadow": "deep_blue", "mid": "sky", "light": "sky"},
                "fin":   {"outline": "orchid", "inner": "deep_blue", "mid": "sky", "ray": "deep_blue", "accent": "orchid"},
            },
            "koi": {  # white, marbled with red, black-tipped fins
                "body":  {"outline": "crimson", "shadow": "silver", "mid": "white", "light": "white", "highlight": "white"},
                "belly": {"outline": "crimson", "shadow": "silver", "mid": "white", "light": "white"},
                "patches": {"seed": 2, "count": 5,
                            "ramp": {"shadow": "crimson", "mid": "red", "light": "orange", "highlight": "amber"}},
                "fin":   {"outline": "ink", "inner": "red", "mid": "white", "ray": "red", "accent": "ink"},
            },
            "black_orchid": {  # near-black, with steel-blue streaks in the fins
                "body":  {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk", "highlight": "slate"},
                "belly": {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk"},
                "fin":   {"outline": "crimson", "inner": "ink", "mid": "navy", "ray": "sky", "accent": "orchid"},
                "eye": "amber",
            },
        },
    },
    "guppy": {
        "shape": GUPPY,
        "fin_roots": {"f": [(7, 5)], "g": [(10, 3)], "h": [(10, 8)]},
        "variants": {
            "default": {
                "body":  {"outline": "dusk", "shadow": "slate", "mid": "steel", "light": "silver", "highlight": "white"},
                "belly": {"outline": "dusk", "shadow": "steel", "mid": "silver", "light": "white"},
                "fin":   {"outline": "clay", "inner": "orange", "mid": "amber", "ray": "orange", "accent": "sky"},
            },
            "blue": {
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "steel", "mid": "silver", "light": "white"},
                "fin":   {"outline": "cyan", "inner": "sky", "mid": "sky", "ray": "cyan", "accent": "white"},
            },
            "red": {
                "body":  {"outline": "crimson", "shadow": "salmon", "mid": "peach", "light": "cream", "highlight": "white"},
                "belly": {"outline": "crimson", "shadow": "peach", "mid": "cream", "light": "white"},
                "fin":   {"outline": "crimson", "inner": "crimson", "mid": "red", "ray": "crimson", "accent": "salmon"},
            },
        },
    },
    "corydoras": {
        "shape": CORYDORAS,
        "fin_roots": {"f": [(3, 4)], "g": [(8, 3)], "h": [(7, 7)]},
        "variants": {
            "default": {
                "body":  {"outline": "umber", "shadow": "bark", "mid": "wood", "light": "tan", "highlight": "peach"},
                "belly": {"outline": "umber", "shadow": "tan", "mid": "peach", "light": "cream"},
                "fin":   {"outline": ("tan", 200), "mid": ("peach", 140), "ray": ("tan", 180), "accent": ("peach", 160)},
            },
            "albino": {
                "body":  {"outline": "tan", "shadow": "peach", "mid": "cream", "light": "white", "highlight": "white"},
                "belly": {"outline": "tan", "shadow": "peach", "mid": "cream", "light": "white"},
                "fin":   {"outline": ("peach", 200), "mid": ("cream", 140), "ray": ("peach", 180), "accent": ("cream", 160)},
                "eye": "red",
            },
            "panda": {  # Panda Cory: pale, black eye mask, tail band and dorsal
                "shape": PANDA_CORY,
                "body":  {"outline": "tan", "shadow": "peach", "mid": "cream", "light": "white", "highlight": "white"},
                "belly": {"outline": "tan", "shadow": "peach", "mid": "cream", "light": "white"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": ("silver", 200), "mid": ("white", 140), "ray": ("silver", 180), "accent": "ink"},
            },
        },
    },
    "angelfish": {
        "shape": ANGELFISH,
        "fin_roots": {"f": [(7, 13)], "g": [(11, 8), (11, 18)], "h": [(13, 19)]},
        "variants": {
            "default": {
                "body":  {"outline": "dusk", "shadow": "steel", "mid": "silver", "light": "white", "highlight": "white"},
                "belly": {"outline": "dusk", "shadow": "silver", "mid": "white", "light": "white"},
                "p1":    {"shadow": "ink", "mid": "navy", "light": "dusk"},
                "fin":   {"outline": ("steel", 220), "inner": ("silver", 200), "mid": ("silver", 150),
                          "ray": ("steel", 190), "accent": ("navy", 220)},
            },
            "gold": {
                "body":  {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "cream", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "lemon", "mid": "cream", "light": "white"},
                "p1":    {"shadow": "amber", "mid": "lemon", "light": "lemon"},
                "fin":   {"outline": ("amber", 220), "inner": ("lemon", 200), "mid": ("cream", 150),
                          "ray": ("amber", 190), "accent": ("amber", 220)},
            },
            "marble": {  # black swirls on silver instead of bars
                "body":  {"outline": "dusk", "shadow": "steel", "mid": "silver", "light": "white", "highlight": "white"},
                "belly": {"outline": "dusk", "shadow": "silver", "mid": "white", "light": "white"},
                "p1":    {"shadow": "steel", "mid": "silver", "light": "white"},
                "patches": {"seed": 9, "count": 6,
                            "ramp": {"shadow": "ink", "mid": "ink", "light": "navy", "highlight": "dusk"}},
                "fin":   {"outline": ("steel", 220), "inner": ("navy", 200), "mid": ("silver", 150),
                          "ray": ("ink", 200), "accent": ("ink", 220)},
            },
            "black": {
                "body":  {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk", "highlight": "slate"},
                "belly": {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": ("dusk", 230), "inner": ("navy", 220), "mid": ("navy", 190),
                          "ray": ("ink", 220), "accent": ("ink", 230)},
                "eye": "red",
            },
        },
    },
    "cherry_shrimp": {
        "shape": SHRIMP,
        "fin_roots": {},
        "variants": {
            "default": {
                "body":  {"outline": "crimson", "shadow": "crimson", "mid": "red", "light": "salmon", "highlight": "peach"},
                "fin":   {"outline": "crimson", "mid": "red", "accent": ("salmon", 200)},
            },
            "blue": {
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "fin":   {"outline": "sky", "mid": "sky", "accent": ("cyan", 200)},
            },
            "yellow": {  # Yellow Neocaridina
                "body":  {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "lemon", "highlight": "white"},
                "fin":   {"outline": "amber", "mid": "lemon", "accent": ("lemon", 200)},
            },
            "green_jade": {
                "body":  {"outline": "abyss_green", "shadow": "pine", "mid": "moss", "light": "leaf", "highlight": "lemon"},
                "fin":   {"outline": "moss", "mid": "leaf", "accent": ("leaf", 200)},
            },
        },
    },
    "oranda": {
        "shape": ORANDA,
        "fin_roots": {"f": [(12, 10)], "g": [(18, 6), (14, 15)], "h": [(20, 12), (21, 16)]},
        "variants": {
            "default": {  # Red Cap: white body, red hood
                "body":  {"outline": "steel", "shadow": "silver", "mid": "white", "light": "white", "highlight": "white"},
                "belly": {"outline": "steel", "shadow": "silver", "mid": "white", "light": "white"},
                "wen":   {"outline": "crimson", "shadow": "crimson", "mid": "red", "light": "salmon", "highlight": "peach"},
                "fin":   {"outline": ("silver", 220), "inner": ("white", 200), "mid": ("white", 160),
                          "ray": ("silver", 200), "accent": ("white", 220)},
            },
            "tricolor": {  # orange & white body, black fins
                "body":  {"outline": "rust", "shadow": "rust", "mid": "orange", "light": "amber", "highlight": "lemon"},
                "belly": {"outline": "rust", "shadow": "silver", "mid": "white", "light": "white"},
                "patches": {"seed": 7, "count": 5,
                            "ramp": {"shadow": "silver", "mid": "white", "light": "white", "highlight": "white"}},
                "wen":   {"outline": "rust", "shadow": "clay", "mid": "orange", "light": "amber", "highlight": "lemon"},
                "fin":   {"outline": ("ink", 245), "inner": ("navy", 235), "mid": ("dusk", 215),
                          "ray": ("ink", 235), "accent": ("slate", 225)},
            },
            "orange": {
                "body":  {"outline": "crimson", "shadow": "rust", "mid": "orange", "light": "amber", "highlight": "lemon"},
                "belly": {"outline": "crimson", "shadow": "clay", "mid": "amber", "light": "lemon"},
                "wen":   {"outline": "crimson", "shadow": "rust", "mid": "red", "light": "orange", "highlight": "amber"},
                "fin":   {"outline": ("rust", 235), "inner": ("orange", 220), "mid": ("amber", 190),
                          "ray": ("orange", 220), "accent": ("lemon", 220)},
            },
            "panda": {
                "body":  {"outline": "navy", "shadow": "silver", "mid": "white", "light": "white", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "silver", "mid": "white", "light": "white"},
                "patches": {"seed": 11, "count": 4,
                            "ramp": {"shadow": "ink", "mid": "navy", "light": "dusk", "highlight": "slate"}},
                "wen":   {"outline": "steel", "shadow": "silver", "mid": "white", "light": "white", "highlight": "white"},
                "fin":   {"outline": ("ink", 245), "inner": ("navy", 235), "mid": ("dusk", 215),
                          "ray": ("ink", 235), "accent": ("slate", 225)},
            },
            "black": {
                "body":  {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk", "highlight": "slate"},
                "belly": {"outline": "ink", "shadow": "navy", "mid": "dusk", "light": "slate"},
                "wen":   {"outline": "ink", "shadow": "navy", "mid": "dusk", "light": "slate", "highlight": "steel"},
                "fin":   {"outline": ("ink", 245), "inner": ("navy", 235), "mid": ("dusk", 215),
                          "ray": ("ink", 235), "accent": ("slate", 225)},
                "eye": "amber",
            },
        },
    },
    "clownfish": {
        "shape": CLOWNFISH,
        "fin_roots": {"f": [(4, 5)], "g": [(8, 2)], "h": [(8, 8)]},
        "variants": {
            "default": {  # Ocellaris
                "body":  {"outline": "ink", "shadow": "rust", "mid": "orange", "light": "amber", "highlight": "lemon"},
                "belly": {"outline": "ink", "shadow": "clay", "mid": "orange", "light": "amber"},
                "p1":    {"shadow": "silver", "mid": "white", "light": "white"},
                "p2":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": "ink", "inner": "orange", "mid": "orange", "ray": "rust", "accent": "ink"},
            },
            "black": {
                "body":  {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk", "highlight": "slate"},
                "belly": {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk"},
                "p1":    {"shadow": "silver", "mid": "white", "light": "white"},
                "p2":    {"shadow": "ink", "mid": "ink", "light": "ink"},
                "fin":   {"outline": "ink", "inner": "navy", "mid": "dusk", "ray": "ink", "accent": "ink"},
                "eye": "amber",
            },
            "maroon": {
                "body":  {"outline": "umber", "shadow": "umber", "mid": "crimson", "light": "red", "highlight": "salmon"},
                "belly": {"outline": "umber", "shadow": "umber", "mid": "crimson", "light": "red"},
                "p1":    {"shadow": "amber", "mid": "lemon", "light": "lemon"},
                "p2":    {"shadow": "umber", "mid": "umber", "light": "bark"},
                "fin":   {"outline": "umber", "inner": "crimson", "mid": "crimson", "ray": "umber", "accent": "umber"},
            },
        },
    },
    "hillstream_loach": {
        "shape": LOACH,
        "fin_roots": {"f": [(10, 5)]},
        "variants": {
            "default": {
                "body":  {"outline": "umber", "shadow": "bark", "mid": "wood", "light": "tan", "highlight": "peach"},
                "p1":    {"shadow": "umber", "mid": "umber", "light": "bark"},
                "fin":   {"outline": ("bark", 230), "inner": ("wood", 200), "mid": ("tan", 170),
                          "ray": ("bark", 200), "accent": ("bark", 200)},
            },
            "golden": {
                "body":  {"outline": "bark", "shadow": "clay", "mid": "sand", "light": "cream", "highlight": "white"},
                "p1":    {"shadow": "bark", "mid": "wood", "light": "wood"},
                "fin":   {"outline": ("clay", 230), "inner": ("sand", 200), "mid": ("cream", 170),
                          "ray": ("clay", 200), "accent": ("clay", 200)},
            },
            "borneo": {  # Borneo Sucker: dark brown with gold spots
                "body":  {"outline": "ink", "shadow": "umber", "mid": "bark", "light": "wood", "highlight": "tan"},
                "p1":    {"shadow": "sand", "mid": "amber", "light": "lemon"},
                "fin":   {"outline": ("umber", 230), "inner": ("bark", 200), "mid": ("wood", 170),
                          "ray": ("umber", 200), "accent": ("umber", 200)},
            },
        },
    },
    "snail": {
        "shape": SNAIL,
        "fin_roots": {},
        "variants": {
            "default": {  # Gold mystery snail
                "body":  {"outline": "bark", "shadow": "clay", "mid": "amber", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "tan", "shadow": "tan", "mid": "peach", "light": "cream"},
                "p1":    {"shadow": "rust", "mid": "clay", "light": "clay"},
                "fin":   {"outline": "tan", "mid": "peach", "accent": "tan"},
            },
            "blue": {
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "slate", "shadow": "slate", "mid": "steel", "light": "silver"},
                "p1":    {"shadow": "navy", "mid": "deep_blue", "light": "deep_blue"},
                "fin":   {"outline": "slate", "mid": "steel", "accent": "slate"},
            },
            "zebra": {  # Zebra nerite
                "body":  {"outline": "ink", "shadow": "moss", "mid": "lemon", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "slate", "shadow": "steel", "mid": "silver", "light": "white"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "umber"},
                "fin":   {"outline": "steel", "mid": "silver", "accent": "steel"},
            },
        },
    },
    # --- v0.6 ---------------------------------------------------------------------------------
    "platy": {
        "shape": PLATY,
        "fin_roots": {"f": [(4, 5)], "g": [(10, 2)], "h": [(10, 8)]},
        "variants": {
            "default": {  # Red
                "body":  {"outline": "crimson", "shadow": "crimson", "mid": "red", "light": "salmon", "highlight": "peach"},
                "belly": {"outline": "crimson", "shadow": "red", "mid": "salmon", "light": "peach"},
                "fin":   {"outline": ("crimson", 235), "inner": ("red", 220), "mid": ("red", 190),
                          "ray": ("crimson", 220), "accent": ("salmon", 220)},
            },
            "mickey": {  # Mickey Mouse: a black spot with two "ears" at the tail root
                "body":  {"outline": "rust", "shadow": "orange", "mid": "amber", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "rust", "shadow": "amber", "mid": "lemon", "light": "cream"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": ("orange", 235), "inner": ("amber", 220), "mid": ("amber", 180),
                          "ray": ("orange", 210), "accent": ("lemon", 220)},
            },
            "wagtail": {  # Red Wagtail: red body, black fins
                "body":  {"outline": "crimson", "shadow": "crimson", "mid": "red", "light": "salmon", "highlight": "peach"},
                "belly": {"outline": "crimson", "shadow": "red", "mid": "salmon", "light": "peach"},
                "fin":   {"outline": ("ink", 245), "inner": ("navy", 235), "mid": ("ink", 225),
                          "ray": ("navy", 235), "accent": ("ink", 235)},
            },
            "sunset": {  # yellow at the front, red at the back
                "shape": PLATY_SUNSET,
                "body":  {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "cream"},
                "p1":    {"shadow": "crimson", "mid": "red", "light": "red"},
                "p2":    {"shadow": "crimson", "mid": "red", "light": "salmon"},
                "fin":   {"outline": ("crimson", 235), "inner": ("red", 220), "mid": ("red", 190),
                          "ray": ("crimson", 220), "accent": ("lemon", 220)},
            },
        },
    },
    "molly": {
        "shape": MOLLY,
        "fin_roots": {"f": [(5, 5)], "g": [(11, 2), (8, 8)], "h": [(12, 8)]},
        "variants": {
            "default": {  # Black
                "body":  {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk", "highlight": "slate"},
                "belly": {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk"},
                "fin":   {"outline": ("ink", 245), "inner": ("navy", 235), "mid": ("dusk", 215),
                          "ray": ("ink", 235), "accent": ("slate", 225)},
                "eye": "amber",
            },
            "dalmatian": {
                "body":  {"outline": "slate", "shadow": "silver", "mid": "white", "light": "white", "highlight": "white"},
                "belly": {"outline": "slate", "shadow": "silver", "mid": "white", "light": "white"},
                "patches": {"seed": 4, "count": 7,
                            "ramp": {"shadow": "ink", "mid": "ink", "light": "navy", "highlight": "navy"}},
                "fin":   {"outline": ("slate", 230), "inner": ("silver", 200), "mid": ("white", 160),
                          "ray": ("ink", 210), "accent": ("ink", 220)},
            },
            "gold": {
                "body":  {"outline": "clay", "shadow": "orange", "mid": "amber", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "cream"},
                "fin":   {"outline": ("clay", 235), "inner": ("amber", 215), "mid": ("lemon", 180),
                          "ray": ("orange", 210), "accent": ("lemon", 220)},
            },
            "silver": {
                "body":  {"outline": "dusk", "shadow": "steel", "mid": "silver", "light": "white", "highlight": "white"},
                "belly": {"outline": "dusk", "shadow": "silver", "mid": "white", "light": "white"},
                "fin":   {"outline": ("steel", 220), "inner": ("silver", 200), "mid": ("silver", 150),
                          "ray": ("steel", 190), "accent": ("white", 200)},
            },
        },
    },
    "zebra_danio": {
        "shape": ZEBRA_DANIO,
        "fin_roots": {},
        "variants": {
            "default": {  # Classic: silvery gold with deep blue stripes
                "body":  {"outline": "dusk", "shadow": "sand", "mid": "cream", "light": "white", "highlight": "white"},
                "belly": {"outline": "dusk", "shadow": "silver", "mid": "white", "light": "white"},
                "p1":    {"shadow": "navy", "mid": "deep_blue", "light": "deep_blue"},
                "fin":   {"outline": ("steel", 200), "mid": ("silver", 120), "accent": ("deep_blue", 230)},
            },
            "golden": {  # the blue stripes bred out: gold with pale stripes
                "body":  {"outline": "clay", "shadow": "amber", "mid": "amber", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "lemon", "mid": "cream", "light": "white"},
                "p1":    {"shadow": "lemon", "mid": "cream", "light": "white"},
                "fin":   {"outline": ("amber", 200), "mid": ("lemon", 120), "accent": ("cream", 230)},
            },
            "leopard": {  # spots instead of stripes
                "shape": LEOPARD_DANIO,
                "body":  {"outline": "bark", "shadow": "sand", "mid": "sand", "light": "cream", "highlight": "white"},
                "belly": {"outline": "bark", "shadow": "silver", "mid": "cream", "light": "white"},
                "p1":    {"shadow": "dusk", "mid": "slate", "light": "slate"},
                "fin":   {"outline": ("tan", 200), "mid": ("cream", 120), "accent": ("slate", 230)},
            },
        },
    },
    "cherry_barb": {
        "shape": CHERRY_BARB,
        "fin_roots": {"f": [(4, 4)], "g": [(7, 1)], "h": [(10, 7)]},
        "variants": {
            "default": {  # Male: deep cherry red
                "body":  {"outline": "umber", "shadow": "crimson", "mid": "red", "light": "salmon", "highlight": "peach"},
                "belly": {"outline": "umber", "shadow": "red", "mid": "salmon", "light": "peach"},
                "p1":    {"shadow": "umber", "mid": "crimson", "light": "crimson"},
                "fin":   {"outline": ("crimson", 230), "inner": ("red", 210), "mid": ("red", 170),
                          "ray": ("crimson", 210), "accent": ("salmon", 210)},
            },
            "female": {  # fawn with a darker side stripe
                "body":  {"outline": "bark", "shadow": "tan", "mid": "peach", "light": "cream", "highlight": "white"},
                "belly": {"outline": "bark", "shadow": "peach", "mid": "cream", "light": "white"},
                "p1":    {"shadow": "bark", "mid": "wood", "light": "wood"},
                "fin":   {"outline": ("tan", 200), "inner": ("peach", 170), "mid": ("cream", 130),
                          "ray": ("tan", 180), "accent": ("salmon", 200)},
            },
            "albino": {  # pale pink, red eyes
                "body":  {"outline": "crimson", "shadow": "salmon", "mid": "peach", "light": "cream", "highlight": "white"},
                "belly": {"outline": "crimson", "shadow": "peach", "mid": "cream", "light": "white"},
                "p1":    {"shadow": "salmon", "mid": "salmon", "light": "peach"},
                "fin":   {"outline": ("salmon", 210), "inner": ("peach", 180), "mid": ("cream", 140),
                          "ray": ("salmon", 190), "accent": ("salmon", 200)},
                "eye": "red",
            },
        },
    },
    "cardinal_tetra": {
        "shape": CARDINAL_TETRA,
        "fin_roots": {},
        "variants": {
            "default": {  # Classic
                "body":  {"outline": "navy", "shadow": "dusk", "mid": "slate", "light": "steel", "highlight": "silver"},
                "belly": {"outline": "navy", "shadow": "steel", "mid": "silver", "light": "white"},
                "p1":    {"shadow": "sky", "mid": "cyan", "light": "cyan"},
                "p2":    {"shadow": "crimson", "mid": "red", "light": "red"},
                "fin":   {"outline": ("silver", 150), "mid": ("silver", 90), "accent": ("silver", 120)},
            },
            "green_neon": {  # a cousin: blue-green stripe, red only underneath at the back
                "shape": NEON_TETRA,
                "body":  {"outline": "navy", "shadow": "abyss_green", "mid": "pine", "light": "moss", "highlight": "silver"},
                "belly": {"outline": "navy", "shadow": "steel", "mid": "silver", "light": "white"},
                "p1":    {"shadow": "sky", "mid": "cyan", "light": "leaf"},
                "p2":    {"shadow": "crimson", "mid": "red", "light": "red"},
                "fin":   {"outline": ("silver", 150), "mid": ("silver", 90), "accent": ("silver", 120)},
            },
        },
    },
    "rummynose": {
        "shape": RUMMYNOSE,
        "fin_roots": {},
        "variants": {
            "default": {  # Classic: silver, red nose
                "body":  {"outline": "dusk", "shadow": "steel", "mid": "silver", "light": "white", "highlight": "white"},
                "belly": {"outline": "dusk", "shadow": "silver", "mid": "white", "light": "white"},
                "p2":    {"shadow": "crimson", "mid": "red", "light": "salmon"},
                "fin":   {"outline": ("silver", 200), "mid": ("white", 200), "accent": ("ink", 240)},
            },
            "golden": {
                "body":  {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "cream", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "lemon", "mid": "cream", "light": "white"},
                "p2":    {"shadow": "crimson", "mid": "red", "light": "salmon"},
                "fin":   {"outline": ("lemon", 200), "mid": ("cream", 200), "accent": ("ink", 240)},
            },
        },
    },
    "discus": {
        "shape": DISCUS,
        "fin_roots": {"f": [(4, 10)], "g": [(11, 3), (11, 17)], "h": [(14, 13)]},
        "variants": {
            "default": {  # Red Melon: solid red, warming to orange underneath
                "body":  {"outline": "umber", "shadow": "crimson", "mid": "red", "light": "salmon", "highlight": "peach"},
                "belly": {"outline": "umber", "shadow": "crimson", "mid": "red", "light": "orange"},
                "p2":    {"shadow": "crimson", "mid": "crimson", "light": "red"},
                "fin":   {"outline": ("umber", 230), "inner": ("crimson", 220), "mid": ("red", 190),
                          "ray": ("crimson", 215), "accent": ("amber", 220)},
            },
            "blue_diamond": {  # solid blue
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan"},
                "p2":    {"shadow": "deep_blue", "mid": "sky", "light": "sky"},
                "fin":   {"outline": ("deep_blue", 230), "inner": ("crimson", 200), "mid": ("sky", 170),
                          "ray": ("deep_blue", 210), "accent": ("cyan", 220)},
                "eye": "red",
            },
            "pigeon_blood": {  # creamsicle orange with a red mesh, black tail
                "body":  {"outline": "rust", "shadow": "sand", "mid": "peach", "light": "cream", "highlight": "white"},
                "belly": {"outline": "rust", "shadow": "sand", "mid": "amber", "light": "lemon"},
                "p2":    {"shadow": "crimson", "mid": "red", "light": "red"},
                "fin":   {"outline": ("rust", 230), "inner": ("clay", 210), "mid": ("sand", 180),
                          "ray": ("red", 210), "accent": ("red", 220)},
                "tail":  {"outline": ("ink", 240), "inner": ("navy", 230), "mid": ("ink", 220), "ray": ("dusk", 220)},
                "eye": "red",
            },
            "turquoise": {  # blue-green with red-orange lines
                "body":  {"outline": "navy", "shadow": "sky", "mid": "cyan", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "sky", "mid": "cyan", "light": "white"},
                "p2":    {"shadow": "rust", "mid": "clay", "light": "orange"},
                "fin":   {"outline": ("deep_blue", 230), "inner": ("rust", 210), "mid": ("sky", 180),
                          "ray": ("clay", 210), "accent": ("cyan", 220)},
                "eye": "red",
            },
        },
    },
    "dwarf_gourami": {
        "shape": DWARF_GOURAMI,
        "fin_roots": {"f": [(5, 5)], "g": [(11, 2), (10, 8)], "h": [(16, 7)]},
        "variants": {
            "default": {  # Classic: slanting stripes of red and blue
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan"},
                "p1":    {"shadow": "crimson", "mid": "red", "light": "salmon"},
                "fin":   {"outline": ("crimson", 220), "inner": ("sky", 200), "mid": ("sky", 160),
                          "ray": ("red", 210), "accent": ("red", 220)},
            },
            "powder_blue": {  # nearly all blue, the red stripes faded
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "sky", "mid": "cyan", "light": "white"},
                "p1":    {"shadow": "plum", "mid": "orchid", "light": "orchid"},
                "fin":   {"outline": ("deep_blue", 220), "inner": ("sky", 200), "mid": ("cyan", 150),
                          "ray": ("deep_blue", 200), "accent": ("orchid", 220)},
            },
            "flame": {  # red-orange all over, blue dorsal
                "body":  {"outline": "crimson", "shadow": "crimson", "mid": "red", "light": "orange", "highlight": "amber"},
                "belly": {"outline": "crimson", "shadow": "red", "mid": "orange", "light": "amber"},
                "p1":    {"shadow": "crimson", "mid": "red", "light": "orange"},
                "fin":   {"outline": ("sky", 230), "inner": ("red", 210), "mid": ("orange", 180),
                          "ray": ("crimson", 210), "accent": ("sky", 220)},
            },
        },
    },
    "bristlenose": {
        "shape": BRISTLENOSE,
        "fin_roots": {"f": [(12, 2), (12, 8), (5, 5)]},
        "variants": {
            "default": {  # Brown, with pale spots
                "body":  {"outline": "umber", "shadow": "bark", "mid": "bark", "light": "wood", "highlight": "tan"},
                "p1":    {"shadow": "tan", "mid": "sand", "light": "cream"},
                "fin":   {"outline": ("umber", 230), "inner": ("bark", 210), "mid": ("wood", 180),
                          "ray": ("umber", 200), "accent": ("tan", 220)},
            },
            "albino": {  # pale yellow, pink eyes
                "body":  {"outline": "clay", "shadow": "sand", "mid": "peach", "light": "cream", "highlight": "white"},
                "p1":    {"shadow": "cream", "mid": "cream", "light": "white"},
                "fin":   {"outline": ("sand", 220), "inner": ("cream", 200), "mid": ("cream", 170),
                          "ray": ("sand", 190), "accent": ("peach", 220)},
                "eye": "red",
            },
            "super_red": {  # no brown at all
                "body":  {"outline": "crimson", "shadow": "rust", "mid": "clay", "light": "orange", "highlight": "amber"},
                "p1":    {"shadow": "rust", "mid": "clay", "light": "orange"},
                "fin":   {"outline": ("crimson", 230), "inner": ("rust", 210), "mid": ("orange", 180),
                          "ray": ("rust", 200), "accent": ("orange", 220)},
            },
            "calico": {  # orange marbled with black
                "body":  {"outline": "umber", "shadow": "rust", "mid": "orange", "light": "amber", "highlight": "lemon"},
                "p1":    {"shadow": "rust", "mid": "orange", "light": "amber"},
                "patches": {"seed": 5, "count": 5,
                            "ramp": {"shadow": "ink", "mid": "umber", "light": "bark", "highlight": "bark"}},
                "fin":   {"outline": ("umber", 230), "inner": ("rust", 210), "mid": ("orange", 180),
                          "ray": ("umber", 200), "accent": ("bark", 220)},
            },
        },
    },
    "ram": {
        "shape": RAM,
        "fin_roots": {"f": [(4, 5)], "g": [(8, 2), (8, 7)], "h": [(11, 7)]},
        "variants": {
            "default": {  # German Blue: blue spangles, golden face, black eye bar
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "clay", "mid": "orange", "light": "amber"},
                "p1":    {"shadow": "amber", "mid": "lemon", "light": "lemon"},
                "p2":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": ("red", 230), "inner": ("sky", 200), "mid": ("sky", 160),
                          "ray": ("cyan", 200), "accent": ("ink", 235)},
                "eye": "red",
            },
            "electric_blue": {  # all-over metallic blue
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "sky", "mid": "cyan", "light": "white"},
                "p1":    {"shadow": "sky", "mid": "cyan", "light": "cyan"},
                "p2":    {"shadow": "deep_blue", "mid": "deep_blue", "light": "sky"},
                "fin":   {"outline": ("cyan", 220), "inner": ("sky", 200), "mid": ("sky", 160),
                          "ray": ("cyan", 200), "accent": ("deep_blue", 230)},
                "eye": "red",
            },
            "gold": {  # no dark pigment: golden all over
                "body":  {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "orange", "mid": "amber", "light": "lemon"},
                "p1":    {"shadow": "amber", "mid": "lemon", "light": "cream"},
                "p2":    {"shadow": "orange", "mid": "amber", "light": "amber"},
                "fin":   {"outline": ("red", 230), "inner": ("amber", 200), "mid": ("lemon", 160),
                          "ray": ("orange", 200), "accent": ("orange", 230)},
                "eye": "red",
            },
        },
    },
    "blue_tang": {
        "shape": BLUE_TANG,
        "fin_roots": {"f": [(3, 5)], "g": [(10, 2), (10, 8)], "h": [(15, 8)]},
        "variants": {
            "default": {  # Regal: royal blue, black "palette", yellow tail
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "sky"},
                "p2":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": ("ink", 240), "inner": ("deep_blue", 230), "mid": ("sky", 210),
                          "ray": ("deep_blue", 225), "accent": ("lemon", 230)},
                "tail":  {"outline": ("ink", 240), "inner": ("amber", 235), "mid": ("lemon", 230), "ray": ("amber", 230)},
            },
            "yellow_belly": {  # Indian Ocean regals: the yellow spreads onto the belly
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "amber", "mid": "lemon", "light": "lemon"},
                "p2":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": ("ink", 240), "inner": ("deep_blue", 230), "mid": ("sky", 210),
                          "ray": ("deep_blue", 225), "accent": ("lemon", 230)},
                "tail":  {"outline": ("ink", 240), "inner": ("amber", 235), "mid": ("lemon", 230), "ray": ("amber", 230)},
            },
            "powder_blue": {  # a cousin: pale blue, black face, white throat, yellow dorsal
                "shape": POWDER_BLUE_TANG,
                "body":  {"outline": "deep_blue", "shadow": "sky", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "deep_blue", "shadow": "sky", "mid": "sky", "light": "cyan"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "p2":    {"shadow": "silver", "mid": "white", "light": "white"},
                "fin":   {"outline": ("clay", 235), "inner": ("amber", 230), "mid": ("lemon", 220),
                          "ray": ("amber", 225), "accent": ("lemon", 230)},
                "tail":  {"outline": ("ink", 240), "inner": ("silver", 220), "mid": ("white", 210), "ray": ("steel", 220)},
            },
        },
    },
    "yellow_tang": {
        "shape": YELLOW_TANG,
        "fin_roots": {"f": [(3, 7)], "g": [(10, 4), (10, 10)], "h": [(14, 10)]},
        "variants": {
            "default": {  # Yellow, with a white spine at the tail
                "body":  {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "cream"},
                "p1":    {"shadow": "white", "mid": "white", "light": "white"},
                "fin":   {"outline": ("clay", 235), "inner": ("amber", 225), "mid": ("lemon", 215),
                          "ray": ("amber", 220), "accent": ("lemon", 225)},
            },
            "purple": {  # Purple Tang: blue-purple with a yellow tail
                "body":  {"outline": "ink", "shadow": "navy", "mid": "plum", "light": "orchid", "highlight": "salmon"},
                "belly": {"outline": "ink", "shadow": "navy", "mid": "plum", "light": "plum"},
                "p1":    {"shadow": "dusk", "mid": "dusk", "light": "dusk"},
                "fin":   {"outline": ("ink", 240), "inner": ("navy", 230), "mid": ("plum", 220),
                          "ray": ("navy", 225), "accent": ("lemon", 230)},
                "tail":  {"outline": ("clay", 235), "inner": ("amber", 230), "mid": ("lemon", 225), "ray": ("amber", 225)},
            },
            "scopas": {  # Scopas Tang: tan at the front, darkening to the tail
                "body":  {"outline": "umber", "shadow": "bark", "mid": "wood", "light": "tan", "highlight": "peach"},
                "belly": {"outline": "umber", "shadow": "bark", "mid": "wood", "light": "tan"},
                "p1":    {"shadow": "white", "mid": "white", "light": "white"},
                "fin":   {"outline": ("umber", 240), "inner": ("bark", 230), "mid": ("bark", 215),
                          "ray": ("umber", 225), "accent": ("tan", 225)},
                "tail":  {"outline": ("ink", 240), "inner": ("umber", 230), "mid": ("umber", 220), "ray": ("ink", 225)},
            },
        },
    },
    "royal_gramma": {
        "shape": ROYAL_GRAMMA,
        "fin_roots": {"f": [(3, 4)], "g": [(9, 2), (9, 5)], "h": [(13, 5)]},
        "variants": {
            "default": {  # magenta front fading to a golden back, black dot on the dorsal
                "body":  {"outline": "plum", "shadow": "plum", "mid": "orchid", "light": "orchid", "highlight": "salmon"},
                "belly": {"outline": "plum", "shadow": "plum", "mid": "orchid", "light": "orchid"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "ink"},
                "p2":    {"shadow": "amber", "mid": "lemon", "light": "lemon"},
                "fin":   {"outline": ("plum", 230), "inner": ("orchid", 215), "mid": ("orchid", 180),
                          "ray": ("plum", 210), "accent": ("ink", 240)},
                "tail":  {"outline": ("clay", 230), "inner": ("amber", 220), "mid": ("lemon", 200), "ray": ("amber", 215)},
            },
            "orchid": {  # Orchid Dottyback: all purple
                "body":  {"outline": "umber", "shadow": "plum", "mid": "plum", "light": "orchid", "highlight": "salmon"},
                "belly": {"outline": "umber", "shadow": "plum", "mid": "plum", "light": "orchid"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "ink"},
                "p2":    {"shadow": "plum", "mid": "plum", "light": "orchid"},
                "fin":   {"outline": ("umber", 230), "inner": ("plum", 215), "mid": ("orchid", 180),
                          "ray": ("plum", 210), "accent": ("plum", 230)},
            },
            "sunrise": {  # Sunrise Dottyback: blue, with yellow fins
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "sky", "highlight": "cyan"},
                "belly": {"outline": "navy", "shadow": "silver", "mid": "white", "light": "white"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "ink"},
                "p2":    {"shadow": "deep_blue", "mid": "sky", "light": "sky"},
                "fin":   {"outline": ("clay", 230), "inner": ("amber", 215), "mid": ("lemon", 190),
                          "ray": ("amber", 210), "accent": ("lemon", 230)},
                "tail":  {"outline": ("deep_blue", 230), "inner": ("sky", 210), "mid": ("sky", 180), "ray": ("deep_blue", 210)},
            },
        },
    },
    "mandarin": {
        "shape": MANDARIN,
        "fin_roots": {"f": [(3, 4)], "g": [(7, 2)], "h": [(5, 6), (12, 6)]},
        "variants": {
            "default": {  # Classic: electric blue with orange swirls
                "body":  {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan", "highlight": "white"},
                "belly": {"outline": "navy", "shadow": "deep_blue", "mid": "sky", "light": "cyan"},
                "p1":    {"shadow": "rust", "mid": "orange", "light": "amber"},
                "fin":   {"outline": ("orange", 235), "inner": ("deep_blue", 220), "mid": ("sky", 200),
                          "ray": ("orange", 220), "accent": ("cyan", 225)},
                "tail":  {"outline": ("sky", 235), "inner": ("rust", 225), "mid": ("orange", 215), "ray": ("red", 220)},
            },
            "red": {  # the rare red morph: orange-red with blue swirls
                "body":  {"outline": "crimson", "shadow": "rust", "mid": "orange", "light": "amber", "highlight": "lemon"},
                "belly": {"outline": "crimson", "shadow": "rust", "mid": "orange", "light": "amber"},
                "p1":    {"shadow": "deep_blue", "mid": "sky", "light": "cyan"},
                "fin":   {"outline": ("red", 235), "inner": ("rust", 220), "mid": ("orange", 200),
                          "ray": ("crimson", 220), "accent": ("sky", 225)},
                "tail":  {"outline": ("red", 235), "inner": ("crimson", 225), "mid": ("red", 215), "ray": ("crimson", 220)},
            },
            "spotted": {  # Spotted Mandarin: green with dark spots
                "shape": SPOTTED_MANDARIN,
                "body":  {"outline": "abyss_green", "shadow": "pine", "mid": "moss", "light": "leaf", "highlight": "lemon"},
                "belly": {"outline": "abyss_green", "shadow": "moss", "mid": "leaf", "light": "leaf"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": ("orange", 235), "inner": ("pine", 220), "mid": ("moss", 200),
                          "ray": ("ink", 220), "accent": ("sky", 225)},
            },
        },
    },
    "pea_puffer": {
        "shape": PEA_PUFFER,
        "fin_roots": {},
        "variants": {
            "default": {  # Pea Puffer: yellow-green with dark blotches
                "body":  {"outline": "pine", "shadow": "moss", "mid": "lemon", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "pine", "shadow": "silver", "mid": "white", "light": "white"},
                "p1":    {"shadow": "pine", "mid": "moss", "light": "moss"},
                "fin":   {"outline": ("lemon", 170), "mid": ("lemon", 110), "accent": ("lemon", 150)},
            },
            "amazon": {  # Amazon Puffer: green-yellow with black saddles
                "shape": AMAZON_PUFFER,
                "body":  {"outline": "pine", "shadow": "moss", "mid": "leaf", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "pine", "shadow": "silver", "mid": "white", "light": "white"},
                "p1":    {"shadow": "ink", "mid": "ink", "light": "navy"},
                "fin":   {"outline": ("leaf", 170), "mid": ("lemon", 110), "accent": ("leaf", 150)},
            },
            "red_eye": {  # Red-eye Puffer (male): tan, red fins, red eyes
                "body":  {"outline": "bark", "shadow": "wood", "mid": "tan", "light": "peach", "highlight": "cream"},
                "belly": {"outline": "bark", "shadow": "peach", "mid": "cream", "light": "white"},
                "p1":    {"shadow": "wood", "mid": "tan", "light": "peach"},
                "fin":   {"outline": ("crimson", 230), "mid": ("red", 210), "accent": ("red", 220)},
                "tail":  {"outline": ("crimson", 230), "mid": ("red", 210)},
                "eye": "red",
            },
        },
    },
    "kuhli_loach": {
        "shape": KUHLI_LOACH,
        "fin_roots": {},
        "variants": {
            "default": {  # Banded: salmon-orange with dark saddles
                "body":  {"outline": "umber", "shadow": "clay", "mid": "sand", "light": "peach", "highlight": "cream"},
                "belly": {"outline": "umber", "shadow": "sand", "mid": "peach", "light": "cream"},
                "p1":    {"shadow": "umber", "mid": "umber", "light": "bark"},
                "fin":   {"outline": ("tan", 190), "mid": ("peach", 130), "accent": ("tan", 180)},
            },
            "black": {  # Black Kuhli: plain dark brown
                "body":  {"outline": "ink", "shadow": "umber", "mid": "umber", "light": "bark", "highlight": "wood"},
                "belly": {"outline": "ink", "shadow": "umber", "mid": "bark", "light": "wood"},
                "p1":    {"shadow": "umber", "mid": "umber", "light": "bark"},
                "fin":   {"outline": ("bark", 190), "mid": ("wood", 130), "accent": ("bark", 180)},
            },
        },
    },
    "axolotl": {
        "shape": AXOLOTL,
        "fin_roots": {"f": [(6, 4)], "h": [(8, 6), (16, 6)]},
        "variants": {
            "default": {  # Leucistic: pink-white, red gills, dark eyes
                "body":  {"outline": "tan", "shadow": "peach", "mid": "white", "light": "white", "highlight": "white"},
                "belly": {"outline": "tan", "shadow": "peach", "mid": "cream", "light": "white"},
                "fin":   {"outline": ("peach", 210), "inner": ("white", 180), "mid": ("white", 140),
                          "ray": ("peach", 170), "accent": "red"},
            },
            "wild": {  # Wild type: mottled olive
                "body":  {"outline": "ink", "shadow": "abyss_green", "mid": "pine", "light": "moss", "highlight": "leaf"},
                "belly": {"outline": "ink", "shadow": "pine", "mid": "moss", "light": "moss"},
                "patches": {"seed": 6, "count": 6,
                            "ramp": {"shadow": "ink", "mid": "abyss_green", "light": "abyss_green", "highlight": "pine"}},
                "fin":   {"outline": ("pine", 220), "inner": ("moss", 180), "mid": ("moss", 140),
                          "ray": ("pine", 170), "accent": "plum"},
            },
            "golden": {  # Golden albino: gold, pink gills, pale eyes
                "body":  {"outline": "clay", "shadow": "amber", "mid": "lemon", "light": "lemon", "highlight": "white"},
                "belly": {"outline": "clay", "shadow": "amber", "mid": "cream", "light": "white"},
                "fin":   {"outline": ("amber", 210), "inner": ("lemon", 180), "mid": ("cream", 140),
                          "ray": ("amber", 170), "accent": "salmon"},
                "eye": "salmon",
            },
            "melanoid": {  # all black
                "body":  {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk", "highlight": "slate"},
                "belly": {"outline": "ink", "shadow": "ink", "mid": "navy", "light": "dusk"},
                "fin":   {"outline": ("ink", 230), "inner": ("navy", 200), "mid": ("dusk", 160),
                          "ray": ("navy", 190), "accent": "plum"},
            },
        },
    },
    "ghost_shrimp": {
        "shape": GHOST_SHRIMP,
        "fin_roots": {},
        "variants": {
            "default": {  # Ghost Shrimp: clear, with orange dots
                "body":  {"outline": "steel", "shadow": "silver", "mid": "silver", "light": "white"},
                "fin":   {"outline": ("silver", 200), "mid": ("silver", 80), "accent": "orange"},
            },
            "amano": {  # Amano Shrimp: grey-clear with dashed lines
                "shape": AMANO_SHRIMP,
                "body":  {"outline": "slate", "shadow": "steel", "mid": "steel", "light": "silver"},
                "fin":   {"outline": ("steel", 215), "mid": ("steel", 100), "accent": ("dusk", 230)},
            },
        },
    },
}
