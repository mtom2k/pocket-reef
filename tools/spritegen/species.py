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
}
