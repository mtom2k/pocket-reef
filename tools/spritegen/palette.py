"""Project palette: ENDESGA 32 (https://lospec.com/palette-list/endesga-32).

Every sprite must use only these colours. Names are ours, for readability.
"""

PALETTE = {
    "rust":        "be4a2f",
    "clay":        "d77643",
    "cream":       "ead4aa",
    "sand":        "e4a672",
    "wood":        "b86f50",
    "bark":        "733e39",
    "umber":       "3e2731",
    "crimson":     "a22633",
    "red":         "e43b44",
    "orange":      "f77622",
    "amber":       "feae34",
    "lemon":       "fee761",
    "leaf":        "63c74d",
    "moss":        "3e8948",
    "pine":        "265c42",
    "abyss_green": "193c3e",
    "deep_blue":   "124e89",
    "sky":         "0099db",
    "cyan":        "2ce8f5",
    "white":       "ffffff",
    "silver":      "c0cbdc",
    "steel":       "8b9bb4",
    "slate":       "5a6988",
    "dusk":        "3a4466",
    "navy":        "262b44",
    "ink":         "181425",
    "neon_pink":   "ff0044",
    "plum":        "68386c",
    "orchid":      "b55088",
    "salmon":      "f6757a",
    "peach":       "e8b796",
    "tan":         "c28569",
}


def rgba(name: str, alpha: int = 255) -> tuple[int, int, int, int]:
    h = PALETTE[name]
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), alpha)


def write_gpl(path: str) -> None:
    """GIMP palette, loadable in Aseprite (Palette > Load) and most editors."""
    lines = ["GIMP Palette", "Name: Fishtank (ENDESGA 32)", "Columns: 8", "#"]
    for name, h in PALETTE.items():
        r, g, b = (int(h[i:i + 2], 16) for i in (0, 2, 4))
        lines.append(f"{r:3d} {g:3d} {b:3d}\t{name}")
    with open(path, "w") as f:
        f.write("\n".join(lines) + "\n")
