class_name SpeciesDB
## Static species data. Sprites come from tools/spritegen (art/sprites/fish/).

## habit: "swim" (open water), "bottom" (forages near the gravel, dashes up for air now and then),
##        "crawl" (walks along the gravel, never swims).
const SPECIES := {
	"neon_tetra": {
		"name": "Neon Tetra",
		"variants": {"default": "Classic"},
		"habit": "swim",
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
		"variants": {"default": "Orange", "sarasa": "Sarasa (red & white)", "calico": "Calico", "black": "Black"},
		"habit": "swim",
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
		"habit": "swim",
		"speed": 9.0,
		"bioload": 3,
		"max": 1,
		"depth": Vector2(0.05, 0.5),
		"schooling": false,
		"wobble": 0.3,
		"blurb": "Territorial: only one betta per tank. Likes the surface.",
	},
	"guppy": {
		"name": "Guppy",
		"variants": {"default": "Rainbow", "blue": "Blue Moscow", "red": "Red Cobra"},
		"habit": "swim",
		"speed": 16.0,
		"bioload": 1,
		"max": 10,
		"depth": Vector2(0.1, 0.6),
		"schooling": false,
		"wobble": 0.8,
		"blurb": "Lively and colourful, with a big flowing tail.",
	},
	"corydoras": {
		"name": "Corydoras",
		"variants": {"default": "Bronze", "albino": "Albino"},
		"habit": "bottom",
		"speed": 11.0,
		"bioload": 1,
		"max": 8,
		"depth": Vector2(0.9, 1.0),
		"schooling": false,
		"wobble": 0.7,
		"blurb": "A busy little catfish that hoovers up food from the gravel.",
	},
	"angelfish": {
		"name": "Angelfish",
		"variants": {"default": "Silver", "gold": "Gold"},
		"habit": "swim",
		"speed": 8.0,
		"bioload": 5,
		"max": 2,
		"depth": Vector2(0.2, 0.7),
		"schooling": false,
		"wobble": 0.25,
		"blurb": "Tall and graceful. Needs a tank with some height.",
	},
	"oranda": {
		"name": "Oranda Goldfish",
		"variants": {"default": "Red Cap", "tricolor": "Tricolor", "orange": "Orange", "panda": "Panda",
			"black": "Black"},
		"habit": "swim",
		"speed": 8.0,
		"bioload": 6,
		"max": 3,
		"depth": Vector2(0.2, 0.8),
		"schooling": false,
		"wobble": 0.4,
		"blurb": "A fancy goldfish with a bumpy hood (the 'wen'). Slow, round and wobbly.",
	},
	"clownfish": {
		"name": "Clownfish",
		"variants": {"default": "Ocellaris", "black": "Black & White", "maroon": "Maroon"},
		"habit": "swim",
		"speed": 14.0,
		"bioload": 2,
		"max": 4,
		"depth": Vector2(0.3, 0.85),
		"schooling": false,
		"wobble": 1.0,
		"host": "anemone",
		"blurb": "Add an anemone (Decor > Ornaments) and they'll move in.",
	},
	"hillstream_loach": {
		"name": "Hillstream Loach",
		"variants": {"default": "Spotted", "golden": "Golden"},
		"habit": "glass",
		"speed": 5.0,
		"bioload": 1,
		"max": 6,
		"depth": Vector2(0.05, 0.95),
		"schooling": false,
		"wobble": 0.0,
		"food_sight": 25.0,
		"blurb": "Clings to the glass and glides around like a tiny stingray.",
	},
	"snail": {
		"name": "Snail",
		"variants": {"default": "Gold Mystery", "blue": "Blue Mystery", "zebra": "Zebra Nerite"},
		"habit": "crawl",
		"speed": 1.5,
		"bioload": 1,
		"max": 6,
		"depth": Vector2(1.0, 1.0),
		"schooling": false,
		"wobble": 0.0,
		"blurb": "Slow and steady. Tidies up food that reaches the gravel.",
	},
	"cherry_shrimp": {
		"name": "Cherry Shrimp",
		"variants": {"default": "Cherry", "blue": "Blue Dream"},
		"habit": "crawl",
		"speed": 4.0,
		"bioload": 0,
		"max": 10,
		"depth": Vector2(1.0, 1.0),
		"schooling": false,
		"wobble": 0.0,
		"blurb": "Tiny clean-up crew. Picks at the gravel all day.",
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
