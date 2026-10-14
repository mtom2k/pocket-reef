extends Node2D
## Decorations sitting on the gravel: mirrors TankState.decor, hit-tests for decorate mode,
## and reports bubble emitter points (air stone, chest, diver).

const SWAY_SHADER := preload("res://shaders/sway.gdshader")
const SWAY_PAD := Vector2i(3, 0)

var tank_size := TankState.DEFAULT_TANK
var _sprites := {}  # decor id -> Sprite2D
var _emitters: Array[Dictionary] = []
var _sway: Array[ShaderMaterial] = []
var _time := 0.0


func sync(size: Vector2i) -> void:
	tank_size = size
	for child in get_children():
		child.free()
	_sprites.clear()
	_sway.clear()
	var items := TankState.decor.duplicate()
	# Tall pieces at the back so they never hide the small ones.
	items.sort_custom(func(a, b): return _texture_height(a.type) > _texture_height(b.type))
	for d in items:
		_add(d)
	_emitters = _find_emitters()


## Plant sway, on the tank's clock (main.gd _tick).
func step(dt: float) -> void:
	_time += dt
	for mat in _sway:
		mat.set_shader_parameter("time", _time)


## Moves a piece visually while it's being dragged; TankState is updated on release.
func preview_move(id: int, x_fraction: float) -> void:
	if _sprites.has(id):
		var s: Sprite2D = _sprites[id]
		s.position.x = _left_edge(x_fraction, _visible_size(s).x, s.material != null)
		_emitters = _find_emitters()


## Topmost decoration under `p` (tank pixels), or -1.
func item_at(p: Vector2) -> int:
	for i in range(get_child_count() - 1, -1, -1):
		var s: Sprite2D = get_child(i)
		if item_rect(s.get_meta("id")).grow(1).has_point(p):
			return s.get_meta("id")
	return -1


func item_rect(id: int) -> Rect2:
	if not _sprites.has(id):
		return Rect2()
	var s: Sprite2D = _sprites[id]
	var pad := float(SWAY_PAD.x) if s.material else 0.0
	var size := _visible_size(s)
	return Rect2(s.position + Vector2(pad, 0), size - Vector2(pad * 2, 0))


## The first placed decoration of `type` (its visible rect), or an empty Rect2.
func find_type(type: String) -> Rect2:
	for id in _sprites:
		if _sprites[id].get_meta("type") == type:
			return item_rect(id)
	return Rect2()


## [{id, position, mode}] for every decoration that makes bubbles (cached on sync).
func emitters() -> Array[Dictionary]:
	return _emitters


func _find_emitters() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in _sprites:
		var s: Sprite2D = _sprites[id]
		var info: Dictionary = DecorDB.DECOR[s.get_meta("type")]
		if info.has("bubbles"):
			var r := item_rect(id)
			out.append({"id": id, "position": r.position + r.size * info.bubbles.at, "mode": info.bubbles.mode})
	return out


func _add(d: Dictionary) -> void:
	var info: Dictionary = DecorDB.DECOR[d.type]
	var path := DecorDB.texture_path(d.type)
	var sway: float = info.get("sway", 0.0)
	var s := Sprite2D.new()
	s.centered = false
	s.flip_h = d.flip
	if sway > 0.0:
		s.texture = SpeciesDB.padded_texture(path, SWAY_PAD)
		var mat := ShaderMaterial.new()
		mat.shader = SWAY_SHADER
		mat.set_shader_parameter("amplitude", sway)
		mat.set_shader_parameter("seed", float(d.id) * 1.7)
		mat.set_shader_parameter("time", _time)
		s.material = mat
		_sway.append(mat)
	else:
		s.texture = load(path)

	var floor_y := TankRenderer.gravel_top(tank_size) + int(info.sink)
	var tex_size := s.texture.get_size()
	# In a short tank, tall plants are trimmed so they just reach the surface.
	var max_height := floor_y - (TankRenderer.WATER_TOP + 1)
	if tex_size.y > max_height:
		s.region_enabled = true
		s.region_rect = Rect2(0, tex_size.y - max_height, tex_size.x, max_height)
	var size := _visible_size(s)
	s.position = Vector2(_left_edge(d.x, size.x, sway > 0.0), floor_y - size.y)
	s.set_meta("id", d.id)
	s.set_meta("type", d.type)
	add_child(s)
	_sprites[d.id] = s


func _left_edge(x_fraction: float, width: float, padded: bool) -> float:
	var pad := float(SWAY_PAD.x) if padded else 0.0
	var left := roundf(x_fraction * tank_size.x - width / 2.0)
	return clampf(left, 1.0 - pad, tank_size.x - 1.0 - width + pad)


func _visible_size(s: Sprite2D) -> Vector2:
	return s.region_rect.size if s.region_enabled else s.texture.get_size()


func _texture_height(type: String) -> int:
	return load(DecorDB.texture_path(type)).get_height()
