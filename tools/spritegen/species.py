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
}
