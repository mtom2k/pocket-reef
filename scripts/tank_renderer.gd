class_name TankRenderer
## Draws the tank's water, gravel and glass for any tank size (docs/style-guide.md section 9).
##
## Everything is deterministic: gravel uses a per-pixel hash rather than a random sequence,
## so resizing the tank doesn't reshuffle the gravel that was already visible.

const WATER_TOP := 10
const GRAVEL_DEPTH := 16  # gravel band at the bottom, including the part decor sinks into

const C := {
	"cyan": Color("2ce8f5"), "sky": Color("0099db"), "deep_blue": Color("124e89"),
	"dusk": Color("3a4466"), "navy": Color("262b44"), "slate": Color("5a6988"),
	"silver": Color("c0cbdc"), "sand": Color("e4a672"), "wood": Color("b86f50"),
	"tan": Color("c28569"), "cream": Color("ead4aa"), "bark": Color("733e39"),
	"clay": Color("d77643"), "amber": Color("feae34"),
}
const GRAVEL_TONES := ["sand", "wood", "tan", "cream", "bark", "clay"]
const GRAVEL_WEIGHTS := [5, 4, 4, 1, 2, 2]
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


static func gravel(size: Vector2i) -> Image:
	var img := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var base := gravel_top(size)
	var total := 0
	for w in GRAVEL_WEIGHTS:
		total += w
	for x in size.x:
		var top := base + roundi(2.0 * sin(x / 13.0) + sin(x / 5.0))
		for y in range(top, size.y):
			var r := _hash(x, y)
			var tone: String
			if y == top:
				tone = "cream" if r < 0.5 else "sand"
			elif y > size.y - 4:
				tone = "bark" if r < 0.5 else "wood"
			else:
				var pick := int(r * total)
				for i in GRAVEL_TONES.size():
					pick -= GRAVEL_WEIGHTS[i]
					if pick < 0:
						tone = GRAVEL_TONES[i]
						break
			img.set_pixel(x, y, C[tone])
	return img


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
