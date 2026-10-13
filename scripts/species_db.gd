class_name SpeciesDB
## Static species data. Sprites come from tools/spritegen (art/sprites/fish/).

const SPECIES := {
	"neon_tetra": {
		"name": "Neon Tetra",
		"variants": {"default": "Classic"},
		"speed": 20.0,
		"bioload": 1,
		"max": 12,
		"depth": Vector2(0.25, 0.75),  # preferred band, 0 = surface, 1 = gravel
		"schooling": true,
		"wobble": 0.9,
		"blurb": "Peaceful schooling fish. Happiest in groups of six or more.",
	},
	"goldfish": {
		"name": "Goldfish",
		"variants": {"default": "Orange", "calico": "Calico"},
		"speed": 12.0,
		"bioload": 6,
		"max": 3,
		"depth": Vector2(0.2, 0.85),
		"schooling": false,
		"wobble": 0.45,
		"blurb": "Friendly and always hungry. Needs plenty of space.",
	},
	"betta": {
		"name": "Betta",
		"variants": {"default": "Red", "royal_blue": "Royal Blue"},
		"speed": 9.0,
		"bioload": 3,
		"max": 1,
		"depth": Vector2(0.05, 0.5),
		"schooling": false,
		"wobble": 0.3,
		"blurb": "Territorial: only one betta per tank. Likes the surface.",
	},
}

const NAMES := [
	"Bubbles", "Goldie", "Splash", "Pebble", "Sunny", "Coral", "Ziggy", "Mochi", "Biscuit",
	"Pip", "Noodle", "Kiwi", "Ember", "Poppy", "Marble", "Comet", "Tango", "Olive", "Skipper",
	"Dot", "Basil", "Pudding", "Rocket", "Waffles", "Sprout", "Fig", "Jellybean", "Clementine",
]

static var _texture_cache := {}


static func texture_path(species: String, variant: String) -> String:
	var file := species if variant == "default" else "%s_%s" % [species, variant]
	return "res://art/sprites/fish/%s.png" % file


static func clear_cache() -> void:
	_texture_cache.clear()


static func random_name() -> String:
	return NAMES.pick_random()


## Returns the texture with transparent padding, so shader wobble/sway never clips.
static func padded_texture(path: String, pad: Vector2i) -> Texture2D:
	var key := "%s|%s" % [path, pad]
	if _texture_cache.has(key):
		return _texture_cache[key]
	var src: Image = load(path).get_image()
	src.convert(Image.FORMAT_RGBA8)
	var out := Image.create_empty(src.get_width() + pad.x * 2, src.get_height() + pad.y * 2, false, Image.FORMAT_RGBA8)
	out.blit_rect(src, Rect2i(Vector2i.ZERO, src.get_size()), pad)
	var tex := ImageTexture.create_from_image(out)
	_texture_cache[key] = tex
	return tex
