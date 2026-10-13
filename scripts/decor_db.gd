class_name DecorDB
## Decoration catalogue. Sprites come from tools/spritegen/decor.py (art/decor/).
##
## sway:    plant sway amplitude in pixels (0 = static)
## sink:    pixels buried in the gravel
## bubbles: emitter at a point relative to the sprite (0..1); "stream" = constant, "burst" = every few seconds

const MAX_ITEMS := 16

const DECOR := {
	"plant_tall": {"name": "Ribbon Plant (tall)", "sway": 2.0, "sink": 3},
	"plant_medium": {"name": "Ribbon Plant", "sway": 2.0, "sink": 3},
	"plant_short": {"name": "Hairgrass", "sway": 1.0, "sink": 3},
	"plant_sword": {"name": "Amazon Sword", "sway": 1.0, "sink": 3},
	"moss_ball": {"name": "Moss Ball", "sink": 1},
	"rock": {"name": "Boulder", "sink": 2},
	"pebbles": {"name": "Pebbles", "sink": 2},
	"rock_arch": {"name": "Rock Arch", "sink": 2},
	"driftwood": {"name": "Driftwood", "sink": 3},
	"castle": {"name": "Castle", "sink": 2},
	"treasure_chest": {"name": "Treasure Chest", "sink": 2,
		"bubbles": {"at": Vector2(0.5, 0.0), "mode": "burst"}},
	"diver": {"name": "Diver", "sink": 2,
		"bubbles": {"at": Vector2(0.5, 0.0), "mode": "burst"}},
	"shell": {"name": "Conch Shell", "sink": 1},
	"air_stone": {"name": "Air Stone", "sink": 1,
		"bubbles": {"at": Vector2(0.5, 0.0), "mode": "stream"}},
}

## A new tank's layout (x is a fraction of the tank width, so it survives resizing).
const DEFAULT_LAYOUT := [
	["plant_tall", 0.12], ["rock", 0.33], ["plant_short", 0.63], ["plant_medium", 0.88], ["air_stone", 0.95],
]


static func texture_path(type: String) -> String:
	return "res://art/decor/%s.png" % type
