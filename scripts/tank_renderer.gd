class_name TankRenderer
## Draws the tank's water, gravel and glass for any tank size (docs/style-guide.md section 9).
##
## Everything is deterministic: gravel uses a per-pixel hash rather than a random sequence,
## so resizing the tank doesn't reshuffle the gravel that was already visible.

const WATER_TOP := 10
const GRAVEL_DEPTH := 16  # gravel band at the bottom, including the part decor sinks into

## ENDESGA 32 (same names as tools/spritegen/palette.py).
const C := {
	"rust": Color("be4a2f"), "clay": Color("d77643"), "cream": Color("ead4aa"), "sand": Color("e4a672"),
	"wood": Color("b86f50"), "bark": Color("733e39"), "umber": Color("3e2731"), "crimson": Color("a22633"),
	"red": Color("e43b44"), "orange": Color("f77622"), "amber": Color("feae34"), "lemon": Color("fee761"),
	"leaf": Color("63c74d"), "moss": Color("3e8948"), "pine": Color("265c42"), "abyss_green": Color("193c3e"),
	"deep_blue": Color("124e89"), "sky": Color("0099db"), "cyan": Color("2ce8f5"), "white": Color("ffffff"),
	"silver": Color("c0cbdc"), "steel": Color("8b9bb4"), "slate": Color("5a6988"), "dusk": Color("3a4466"),
	"navy": Color("262b44"), "ink": Color("181425"), "neon_pink": Color("ff0044"), "plum": Color("68386c"),
	"orchid": Color("b55088"), "salmon": Color("f6757a"), "peach": Color("e8b796"), "tan": Color("c28569"),
}
## One step darker, for pebble edges and the deepest gravel.
const DARKER := {
	"red": "crimson", "amber": "clay", "leaf": "moss", "sky": "deep_blue", "orchid": "plum", "cyan": "sky",
	"lemon": "amber", "white": "silver", "neon_pink": "crimson", "steel": "slate", "slate": "dusk",
	"tan": "wood", "sand": "tan", "silver": "steel", "wood": "bark", "moss": "pine", "pine": "abyss_green",
	"cream": "sand", "peach": "tan", "salmon": "orchid", "ink": "ink", "navy": "ink", "dusk": "navy",
	"clay": "rust", "bark": "umber", "orange": "rust", "plum": "navy", "abyss_green": "ink",
}

## Floor options. style: "speckle" (mixed grains), "sand" (fine, rippled), "pebbles" (individual stones).
const SUBSTRATES := {
	"gravel": {"name": "Natural Gravel", "style": "speckle",
		"tones": {"sand": 5, "wood": 4, "tan": 4, "cream": 1, "bark": 2, "clay": 2}, "top": ["cream", "sand"]},
	"sand": {"name": "Fine Sand", "style": "sand",
		"tones": {"cream": 5, "sand": 3, "peach": 3}, "top": ["cream", "white"]},
	"coral_sand": {"name": "Coral Sand", "style": "sand",
		"tones": {"white": 3, "cream": 4, "peach": 3, "salmon": 1}, "top": ["white", "cream"]},
	"black_sand": {"name": "Black Sand", "style": "speckle",
		"tones": {"navy": 5, "ink": 3, "dusk": 3, "slate": 1, "silver": 0.3}, "top": ["dusk", "slate"]},
	"river_pebbles": {"name": "River Pebbles", "style": "pebbles",
		"tones": {"steel": 3, "slate": 2, "tan": 3, "sand": 2, "silver": 2, "wood": 2}, "top": []},
	"rainbow": {"name": "Rainbow Gravel", "style": "pebbles",
		"tones": {"red": 2, "amber": 2, "lemon": 2, "leaf": 2, "sky": 2, "cyan": 1, "orchid": 2, "white": 1, "neon_pink": 1}, "top": []},
	"jade": {"name": "Jade Pebbles", "style": "pebbles",
		"tones": {"leaf": 2, "moss": 3, "pine": 2, "cyan": 1, "silver": 1}, "top": []},
}
const BAYER4 := [[0, 8, 2, 10], [12, 4, 14, 6], [3, 11, 1, 9], [15, 7, 13, 5]]


static func gravel_top(size: Vector2i) -> int:
	return size.y - GRAVEL_DEPTH


static func water(size: Vector2i) -> Image:
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var floor_y := gravel_top(size)
	var depth := floor_y - WATER_TOP
	var deep_start := WATER_TOP + roundi(depth * 0.72)
	var blend := clampi(depth / 6, 6, 14)

	img.fill_rect(Rect2i(0, WATER_TOP, size.x, 3), C.sky)
	img.fill_rect(Rect2i(0, WATER_TOP + 3, size.x, deep_start - WATER_TOP - 3), C.deep_blue)
	img.fill_rect(Rect2i(0, deep_start, size.x, size.y - deep_start), C.dusk)
	for y in range(deep_start - blend, deep_start):
		var amount := float(y - (deep_start - blend)) / blend
		for x in size.x:
			if _dithered(x, y, amount):
				img.set_pixel(x, y, C.dusk)
	for x in size.x:
		img.set_pixel(x, WATER_TOP, C.cyan if (x / 6) % 3 == 0 else C.sky)

	# Light shafts: slanted dithered stripes fading with depth.
	for shaft in [[0.15, 5], [0.48, 3], [0.76, 6]]:
		var sx := roundi(size.x * shaft[0])
		for y in range(WATER_TOP + 1, deep_start):
			var fade := 0.5 * (1.0 - float(y - WATER_TOP) / (deep_start - WATER_TOP))
			for k in shaft[1]:
				var x: int = sx + k + (y - WATER_TOP) / 3
				if x < size.x and _dithered(x, y, fade) and img.get_pixel(x, y) == C.deep_blue:
					img.set_pixel(x, y, C.sky)
	return img


static func gravel(size: Vector2i, substrate := "gravel") -> Image:
	var spec: Dictionary = SUBSTRATES.get(substrate, SUBSTRATES.gravel)
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var base := gravel_top(size)
	for x in size.x:
		var top := base + roundi(2.0 * sin(x / 13.0) + sin(x / 5.0))
		for y in range(top, size.y):
			var tone: String
			match spec.style:
				"pebbles":
					tone = _pebble(spec, x, y)
				"sand":
					# Fine grains with soft ripples.
					var ripple := sin(x / 4.0 + y * 1.3) > 0.55
					tone = _pick(spec.tones, _hash(x, y))
					if ripple and _hash(y, x) < 0.6:
						tone = spec.top[0]
					elif y == top:
						tone = spec.top[0] if _hash(x, y) < 0.5 else spec.top[1]
				_:
					tone = _pick(spec.tones, _hash(x, y))
					if y == top:
						tone = spec.top[0] if _hash(x, y) < 0.5 else spec.top[1]
			if y > size.y - 4 and spec.style != "pebbles":
				tone = DARKER.get(tone, tone)  # depth against the glass bottom
			img.set_pixel(x, y, C[tone])
	return img


## Stones laid in staggered 3x2 cells; the bottom and right edge of each stone is a shade darker,
## and some get a 1px highlight, so they read as individual rounded pebbles.
static func _pebble(spec: Dictionary, x: int, y: int) -> String:
	var row := y / 2
	var shifted := x + (row % 2) * 2
	var cell_x := shifted / 3
	var tone := _pick(spec.tones, _hash(cell_x * 7 + 3, row * 13 + 1))
	var in_x := shifted % 3
	var in_y := y % 2
	if in_x == 2 or in_y == 1:
		return DARKER.get(tone, tone)
	if in_x == 0 and in_y == 0 and _hash(cell_x, row) < 0.35:
		return "white" if tone in ["silver", "white", "cyan", "lemon"] else tone
	return tone


static func _pick(weights: Dictionary, r: float) -> String:
	var total := 0.0
	for k in weights:
		total += weights[k]
	var pick := r * total
	for k in weights:
		pick -= weights[k]
		if pick < 0.0:
			return k
	return weights.keys()[-1]


## Glass edges and rim. In decorate mode the rim turns gold so the mode is obvious.
static func frame(size: Vector2i, decorating: bool) -> Image:
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var rim_top: Color = C.amber if decorating else C.slate
	var rim: Color = C.clay if decorating else C.navy
	var glass := Color(C.amber, 0.85) if decorating else Color(C.silver, 0.78)
	img.fill_rect(Rect2i(1, 3, size.x - 2, WATER_TOP - 3), Color(C.silver, 0.16))
	img.fill_rect(Rect2i(0, 0, size.x, 1), rim_top)
	img.fill_rect(Rect2i(0, 1, size.x, 2), rim)
	img.fill_rect(Rect2i(0, size.y - 1, size.x, 1), rim_top)
	img.fill_rect(Rect2i(0, 3, 1, size.y - 4), glass)
	img.fill_rect(Rect2i(size.x - 1, 3, 1, size.y - 4), glass)
	return img


static func _dithered(x: int, y: int, amount: float) -> bool:
	return BAYER4[y % 4][x % 4] < amount * 16.0


static func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h & 0xffff) / 65536.0
