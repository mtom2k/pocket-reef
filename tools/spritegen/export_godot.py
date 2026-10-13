"""Exports the tank as separate layers + icons for the Godot project.

  uv run --with pillow tools/spritegen/export_godot.py

Writes:
  art/tank/water.png, gravel.png, frame.png     full-tank layers (192x120)
  art/tank/plant_*.png                           cropped plants (base = bottom centre)
  art/sprites/fx/bubble_small.png, bubble_big.png
  art/icons/tray.png (32px), app_icon.png (256px)
"""

import json
import os
import random

from PIL import Image, ImageDraw

import scene
from build import ROOT, build_sprites
from palette import rgba
from render import render, upscale
from species import SPECIES

TANK = os.path.join(ROOT, "art", "tank")
FX = os.path.join(ROOT, "art", "sprites", "fx")
ICONS = os.path.join(ROOT, "art", "icons")

PLANTS = {
    # name: (height, lean, ramp)
    "plant_tall": (60, 2, ["pine", "moss", "leaf"]),
    "plant_medium": (48, 3, ["pine", "moss", "leaf"]),
    "plant_short": (30, 1, ["abyss_green", "pine", "moss"]),
}

ICON_FISH = [
    "......gg",
    ".....gggg",
    "ff..bbbbbbb",
    "fffbbbbbbbbbb",
    ".ffbbbbbbbbbewb",
    "..fbbbbbbbbbeebb",
    "..fbbbbbbbbbbbbbm",
    ".ffBBBBBBBBBBBBb",
    "fffBBBBBBBBBBBb",
    "ff..BBBBBBBBb",
    "......hh",
]


def blank():
    return Image.new("RGBA", (scene.W, scene.H), (0, 0, 0, 0))


def export_layers():
    os.makedirs(TANK, exist_ok=True)
    random.seed(7)

    water = blank()
    scene.water(water)
    water.save(os.path.join(TANK, "water.png"))

    gravel = blank()
    scene.gravel(gravel)
    scene.rock(gravel, 62, 15, 13)
    gravel.save(os.path.join(TANK, "gravel.png"))

    frame = blank()
    scene.frame(frame)
    frame.save(os.path.join(TANK, "frame.png"))

    for name, (height, lean, ramp) in PLANTS.items():
        canvas = blank()
        scene.plant(canvas, scene.W // 2, height, lean, ramp)
        canvas.crop(canvas.getbbox()).save(os.path.join(TANK, f"{name}.png"))

    # Layout constants the game needs, so they live in one place.
    with open(os.path.join(TANK, "layout.json"), "w") as f:
        json.dump({"width": scene.W, "height": scene.H, "water_top": scene.WATER_TOP,
                   "gravel_top": scene.GRAVEL_TOP}, f, indent=2)


def export_fx():
    os.makedirs(FX, exist_ok=True)
    small = Image.new("RGBA", (3, 3), (0, 0, 0, 0))
    for x, y in ((1, 0), (0, 1), (2, 1), (1, 2)):
        small.putpixel((x, y), rgba("silver"))
    small.save(os.path.join(FX, "bubble_small.png"))

    big = Image.new("RGBA", (5, 5), (0, 0, 0, 0))
    for x in range(5):
        for y in range(5):
            d = abs(x - 2) + abs(y - 2)
            if d in (2, 3) and not (abs(x - 2) == 2 and abs(y - 2) == 2):
                big.putpixel((x, y), rgba("silver"))
    big.putpixel((1, 1), rgba("white"))
    big.save(os.path.join(FX, "bubble_big.png"))


def export_icons():
    os.makedirs(ICONS, exist_ok=True)
    ramps = SPECIES["goldfish"]["variants"]["default"]
    fish = render(ICON_FISH, ramps, {"f": [(3, 5)], "g": [(7, 2)], "h": [(7, 9)]})

    tray = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    tray.alpha_composite(fish, ((16 - fish.width) // 2, (16 - fish.height) // 2))
    upscale(tray, 2).save(os.path.join(ICONS, "tray.png"))

    # App icon: fish on a rounded water tile.
    tile = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    d = ImageDraw.Draw(tile)
    d.rounded_rectangle((1, 1, 30, 30), radius=6, fill=rgba("deep_blue"), outline=rgba("navy"))
    d.line((4, 7, 27, 7), fill=rgba("sky"))
    d.rectangle((3, 25, 28, 28), fill=rgba("sand"))
    tile.alpha_composite(fish, ((32 - fish.width) // 2, (32 - fish.height) // 2 + 1))
    upscale(tile, 8).save(os.path.join(ICONS, "app_icon.png"))


if __name__ == "__main__":
    build_sprites()
    export_layers()
    export_fx()
    export_icons()
    print("exported tank layers, fx and icons")
