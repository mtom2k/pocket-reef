class_name DecorDB
## Decoration catalogue. Sprites come from tools/spritegen/decor.py (art/decor/).
##
## sway:    plant sway amplitude in pixels (0 = static)
## sink:    pixels buried in the gravel
## bubbles: emitter at a point relative to the sprite (0..1); "stream" = constant, "burst" = every few seconds

const MAX_ITEMS := 24

## Catalogue order and grouping (Settings > Decor).
const CATEGORIES := [
	["Plants", ["plant_tall", "plant_medium", "plant_short", "plant_sword", "anubias", "java_fern",
		"red_ludwigia", "moss_ball"]],
	["Rocks & wood", ["rock", "pebbles", "lava_rock", "crystals", "rock_arch", "driftwood",
		"driftwood_log", "spiderwood"]],
	["Ornaments", ["castle", "sunken_ship", "treasure_chest", "diver", "terracotta_pot", "bubble_clam",
		"coral", "anemone", "shell", "starfish", "air_stone"]],
]

const DECOR := {
	# Plants
	"plant_tall": {"name": "Ribbon Plant (tall)", "sway": 2.0, "sink": 3},
	"plant_medium": {"name": "Ribbon Plant", "sway": 2.0, "sink": 3},
	"plant_short": {"name": "Hairgrass", "sway": 1.0, "sink": 3},
	"plant_sword": {"name": "Amazon Sword", "sway": 1.0, "sink": 3},
	"anubias": {"name": "Anubias", "sway": 0.5, "sink": 2},
	"java_fern": {"name": "Java Fern", "sway": 1.0, "sink": 2},
	"red_ludwigia": {"name": "Red Ludwigia", "sway": 1.5, "sink": 3},
	"moss_ball": {"name": "Moss Ball", "sink": 1},
	# Rocks & wood
	"rock": {"name": "Boulder", "sink": 2},
	"pebbles": {"name": "Pebbles", "sink": 2},
	"lava_rock": {"name": "Lava Rock", "sink": 2},
	"crystals": {"name": "Amethyst", "sink": 2},
	"rock_arch": {"name": "Rock Arch", "sink": 2},
	"driftwood": {"name": "Driftwood", "sink": 3},
	"driftwood_log": {"name": "Hollow Log", "sink": 3},
	"spiderwood": {"name": "Spider Wood", "sink": 3},
	# Ornaments
	"castle": {"name": "Castle", "sink": 2},
	"sunken_ship": {"name": "Sunken Ship", "sink": 4,
		"bubbles": {"at": Vector2(0.3, 0.55), "mode": "burst"}},
	"treasure_chest": {"name": "Treasure Chest", "sink": 2,
		"bubbles": {"at": Vector2(0.5, 0.0), "mode": "burst"}},
	"diver": {"name": "Diver", "sink": 2,
		"bubbles": {"at": Vector2(0.5, 0.0), "mode": "burst"}},
	"terracotta_pot": {"name": "Clay Pot Cave", "sink": 2},
	"bubble_clam": {"name": "Bubbling Clam", "sink": 1,
		"bubbles": {"at": Vector2(0.5, 0.4), "mode": "burst"}},
	"coral": {"name": "Pink Coral", "sink": 2},
	"anemone": {"name": "Anemone", "sway": 1.0, "sink": 1},  # clownfish make it their home
	"shell": {"name": "Conch Shell", "sink": 1},
	"starfish": {"name": "Starfish", "sink": 1},
	"air_stone": {"name": "Air Stone", "sink": 1,
		"bubbles": {"at": Vector2(0.5, 0.0), "mode": "stream"}},
}

## A new tank's layout (x is a fraction of the tank width, so it survives resizing).
const DEFAULT_LAYOUT := [
	["plant_tall", 0.12], ["rock", 0.33], ["plant_short", 0.63], ["plant_medium", 0.88], ["air_stone", 0.95],
]


static func texture_path(type: String) -> String:
	return "res://art/decor/%s.png" % type
