"""Species silhouettes and colour ramps. Legend lives in render.py.

Silhouettes face RIGHT. Colour variants reuse a silhouette with a different ramp set.
`fin_roots` maps a fin letter to the point(s) its rays radiate from (usually where
the fin meets the body).
"""

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
}
