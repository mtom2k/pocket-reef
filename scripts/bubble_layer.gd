extends Node2D
## All rising bubbles, drawn by this one node (no node per bubble, so nothing is created or
## freed while the tank runs).

signal surfaced(big: bool)

const SMALL := preload("res://art/sprites/fx/bubble_small.png")
const BIG := preload("res://art/sprites/fx/bubble_big.png")
const MAX_BUBBLES := 160

var surface_y := 12.0

var _pos := PackedVector2Array()
var _wobble := PackedFloat32Array()
var _big: Array[bool] = []


func spawn(at: Vector2, big: bool) -> void:
	if _pos.size() >= MAX_BUBBLES:
		return
	_pos.append(at + Vector2(randf_range(-1, 1), 0))
	_wobble.append(randf() * TAU)
	_big.append(big)


func clear() -> void:
	_pos.clear()
	_wobble.clear()
	_big.clear()
	queue_redraw()


func count() -> int:
	return _pos.size()


func _process(delta: float) -> void:
	var i := 0
	while i < _pos.size():
		_wobble[i] += delta * 4.0
		_pos[i] += Vector2(cos(_wobble[i]) * 4.0, -(22.0 if _big[i] else 16.0)) * delta
		if _pos[i].y < surface_y:
			surfaced.emit(_big[i])
			_remove(i)
		else:
			i += 1
	queue_redraw()


func _draw() -> void:
	for i in _pos.size():
		draw_texture(BIG if _big[i] else SMALL, _pos[i].round())


func _remove(i: int) -> void:
	# Swap-remove: order doesn't matter, and it avoids shifting the arrays.
	var last := _pos.size() - 1
	_pos[i] = _pos[last]
	_wobble[i] = _wobble[last]
	_big[i] = _big[last]
	_pos.resize(last)
	_wobble.resize(last)
	_big.resize(last)
