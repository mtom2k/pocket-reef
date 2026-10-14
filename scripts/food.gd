class_name Food
extends Node2D
## A food flake: sinks with a little drift, settles on the gravel, then dissolves.

const SINK_SPEED := 7.0
const LIFETIME_ON_GRAVEL := 25.0
const COLOURS := [Color("feae34"), Color("d77643"), Color("b86f50")]

var floor_y := 100.0
var exact_pos := Vector2.ZERO
var _colour: Color = COLOURS.pick_random()
var _drift := randf() * TAU
var _resting := 0.0


func _ready() -> void:
	exact_pos = position


## Called by the tank's clock (main.gd _tick).
func step(delta: float) -> void:
	if exact_pos.y < floor_y:
		_drift += delta * 2.0
		exact_pos += Vector2(sin(_drift) * 3.0, SINK_SPEED * randf_range(0.7, 1.2)) * delta
	else:
		_resting += delta
		if _resting > LIFETIME_ON_GRAVEL:
			queue_free()
		elif _resting > LIFETIME_ON_GRAVEL - 3.0:
			visible = int(_resting * 4.0) % 2 == 0  # blink before dissolving
	position = exact_pos.round()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 1, 1), _colour)
