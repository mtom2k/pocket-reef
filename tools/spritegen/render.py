"""Turns an ASCII silhouette + colour ramps into a shaded, outlined sprite.

Silhouette legend (fish face RIGHT):
  .  empty
  b  body            (auto-shaded: rounded light from the upper front)
  B  belly           (countershading: paler underside)
  1  pattern A       (auto-shaded like body, own ramp)
  2  pattern B
  f  back fins       (caudal / tail)                  - drawn behind everything
  g  middle fins     (dorsal, anal)                   - behind the body
  h  front fins      (pectoral, pelvic)               - in front of the body
  F  fin accent      (hand-placed tips / spots, never outlined)
  e  eye             w  eye highlight
  m  mouth / gill    (drawn in the body shadow colour)

Shared rules (see docs/style-guide.md):
  * Light comes from the water surface: brightest spot is upper-front of the body.
  * Any pixel touching empty space becomes its region's outline colour.
  * A layer touching a layer behind it gets an outline, so overlapping fins stay readable.
    The body is outlined where a fin sits above/below it, but not at the tail join.
  * Fins get 1px rays radiating from their root points (species `fin_roots`,
    letter -> list of points; each pixel uses the nearest root).
"""

import math

from PIL import Image

from palette import rgba

BODYISH = set("bB12ewm")
FIN_LAYER = {"f": 0, "g": 1, "h": 3}
BODY_LAYER = 2


def _c(spec):
    """Ramp entries are a palette name or (name, alpha)."""
    if isinstance(spec, tuple):
        return rgba(*spec)
    return rgba(spec)


def _layer(ch):
    if ch in FIN_LAYER:
        return FIN_LAYER[ch]
    if ch in BODYISH:
        return BODY_LAYER
    return None


def render(rows: list[str], ramps: dict, fin_roots: dict | None = None,
           ray_step: float = 0.32) -> Image.Image:
    h = len(rows)
    w = max(len(r) for r in rows)
    grid = [r.ljust(w, ".") for r in rows]
    fin_roots = fin_roots or {}

    def at(x, y):
        if 0 <= x < w and 0 <= y < h:
            return grid[y][x]
        return "."

    def neighbours(x, y):
        return [at(x + dx, y + dy) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1))]

    # Body bounding box for the lighting model.
    body_px = [(x, y) for y in range(h) for x in range(w) if grid[y][x] in BODYISH]
    bx0 = min(p[0] for p in body_px); bx1 = max(p[0] for p in body_px)
    by0 = min(p[1] for p in body_px); by1 = max(p[1] for p in body_px)
    col_extent = {}
    for x, y in body_px:
        lo, hi = col_extent.get(x, (y, y))
        col_extent[x] = (min(lo, y), max(hi, y))

    def root_of(ch, x, y):
        """Nearest root point for this fin letter (a letter may cover several fins)."""
        return min(fin_roots[ch], key=lambda r: math.hypot(x - r[0], y - r[1]))

    # Farthest pixel of each fin from its root, for inner/outer tone.
    fin_reach = {}
    for y in range(h):
        for x in range(w):
            ch = grid[y][x]
            if ch in fin_roots:
                root = root_of(ch, x, y)
                fin_reach[root] = max(fin_reach.get(root, 1.0), math.hypot(x - root[0], y - root[1]))

    body = ramps["body"]
    fin = ramps["fin"]
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()

    for y in range(h):
        for x in range(w):
            ch = grid[y][x]
            if ch == ".":
                continue
            nb = neighbours(x, y)
            edge = "." in nb
            layer = _layer(ch)
            over_lower = layer is not None and any(
                _layer(n) is not None and _layer(n) < layer and n not in BODYISH for n in nb)

            if ch == "e":
                px[x, y] = _c(ramps.get("eye", "ink"))
            elif ch == "w":
                px[x, y] = _c("white")
            elif ch == "m":
                px[x, y] = _c(body["shadow"])
            elif ch == "F":
                px[x, y] = _c(fin["accent"])
            elif ch in FIN_LAYER:
                front_of_body = ch == "h" and any(n in BODYISH for n in nb)
                if edge or over_lower or front_of_body:
                    px[x, y] = _c(fin["outline"])
                    continue
                tone = "mid"
                if ch in fin_roots:
                    rx, ry = root = root_of(ch, x, y)
                    r = math.hypot(x - rx, y - ry)
                    ang = math.atan2(y - ry, x - rx)
                    k = round(ang / ray_step)
                    perp = abs(ang - k * ray_step) * r
                    if r > 2 and perp < 0.5:
                        tone = "ray"
                    elif r < fin_reach[root] * 0.35:
                        tone = "inner"
                px[x, y] = _c(fin.get(tone, fin["mid"]))
            else:  # body, belly, patterns
                if edge:
                    px[x, y] = _c(body["outline"])
                    continue
                ramp = {"b": body, "B": ramps.get("belly", body),
                        "1": ramps.get("p1", body), "2": ramps.get("p2", body)}[ch]
                top, bot = col_extent[x]
                t = (y - top) / max(1, bot - top)
                u = (x - bx0) / max(1, bx1 - bx0)
                v = (y - by0) / max(1, by1 - by0)
                d = math.hypot((u - 0.65) / 0.7, (v - 0.28) / 0.6)
                fin_above_below = any(at(x, y + dy) in FIN_LAYER and FIN_LAYER[at(x, y + dy)] < BODY_LAYER
                                      for dy in (-1, 1))
                if fin_above_below:
                    px[x, y] = _c(body["outline"])
                    continue
                if t >= 0.85:
                    tone = "shadow"
                elif d < 0.22 and ch == "b":
                    tone = "highlight"
                elif d < 0.62:
                    tone = "light"
                elif d < 1.05:
                    tone = "mid"
                else:
                    tone = "shadow"
                px[x, y] = _c(ramp.get(tone, ramp["mid"]))
    return img


def flipped(img: Image.Image) -> Image.Image:
    return img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)


def upscale(img: Image.Image, k: int) -> Image.Image:
    return img.resize((img.width * k, img.height * k), Image.Resampling.NEAREST)
