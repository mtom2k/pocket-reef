"""Builds all fish sprites and a review sheet.

  uv run --with pillow tools/spritegen/build.py
"""

import os

from PIL import Image

from palette import rgba, write_gpl
from render import render, upscale
from species import SPECIES

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
SPRITES = os.path.join(ROOT, "art", "sprites", "fish")
PREVIEWS = os.path.join(ROOT, "art", "previews")


def build_sprites() -> dict[str, Image.Image]:
    os.makedirs(SPRITES, exist_ok=True)
    out = {}
    for name, sp in SPECIES.items():
        for variant, ramps in sp["variants"].items():
            # A morph may bring its own silhouette (same outline, different markings).
            img = render(ramps.get("shape", sp["shape"]), ramps, sp.get("fin_roots"))
            key = name if variant == "default" else f"{name}_{variant}"
            img.save(os.path.join(SPRITES, f"{key}.png"))
            out[key] = img
    return out


def sheet(sprites: dict[str, Image.Image], scale: int = 8, pad: int = 4) -> Image.Image:
    cell_w = max(s.width for s in sprites.values()) + pad * 2
    cell_h = max(s.height for s in sprites.values()) + pad * 2
    cols = 6
    rows = -(-len(sprites) // cols)
    img = Image.new("RGBA", (cell_w * cols, cell_h * rows), rgba("deep_blue"))
    for i, s in enumerate(sprites.values()):
        cx, cy = (i % cols) * cell_w, (i // cols) * cell_h
        img.alpha_composite(s, (cx + (cell_w - s.width) // 2, cy + (cell_h - s.height) // 2))
    return upscale(img, scale)


if __name__ == "__main__":
    os.makedirs(PREVIEWS, exist_ok=True)
    os.makedirs(os.path.join(ROOT, "art", "palette"), exist_ok=True)
    write_gpl(os.path.join(ROOT, "art", "palette", "pocketreef.gpl"))
    sprites = build_sprites()
    sheet(sprites).save(os.path.join(PREVIEWS, "fish_sheet.png"))
    print("built:", ", ".join(sprites))
