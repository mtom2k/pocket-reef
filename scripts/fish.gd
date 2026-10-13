class_name Fish
extends Node2D
## One fish. Steering-based movement: wander within the species' depth band, school (if the
## species does), avoid crowding, and chase food when hungry. Renders snapped to whole pixels.
##
## Habits (SpeciesDB): "swim" roams open water; "bottom" dashes and rests along the gravel and
## occasionally darts up for air; "crawl" walks on the gravel and never leaves it.

const SWIM_SHADER := preload("res://shaders/swim.gdshader")
const PAD := Vector2i(0, 2)
const FOOD_SIGHT := 110.0
const EAT_RANGE := 3.0
const HUNGER_FOOD_VALUE := 0.25

var data: Dictionary  # roster entry from TankState (shared reference)
var spec: Dictionary
var tank: Node  # main.gd
var velocity := Vector2.ZERO
var exact_pos := Vector2.ZERO

var _sprite: Sprite2D
var _material: ShaderMaterial
var _half: Vector2
var _facing_left := false
var _phase := randf() * TAU
var _target := Vector2.ZERO
var _retarget_in := 0.0
var _pace := 1.0
var _excited := 0.0
var _rest := 0.0
var _air_in := randf_range(40.0, 120.0)
var _going_for_air := false


func setup(entry: Dictionary, tank_node: Node, start: Vector2) -> void:
	data = entry
	tank = tank_node
	spec = SpeciesDB.SPECIES[entry.species]
	exact_pos = start
	position = start.round()

	_material = ShaderMaterial.new()
	_material.shader = SWIM_SHADER
	var amplitude := 0.0 if spec.wobble == 0.0 else (1.0 if spec.bioload <= 1 else 1.4)
	_material.set_shader_parameter("amplitude", amplitude)

	_sprite = Sprite2D.new()
	_sprite.texture = SpeciesDB.padded_texture(SpeciesDB.texture_path(entry.species, entry.variant), PAD)
	_sprite.material = _material
	_sprite.centered = false
	var size := _sprite.texture.get_size()
	_sprite.offset = -(size / 2.0).floor()
	_half = (size - Vector2(PAD) * 2.0) / 2.0
	add_child(_sprite)
	_pick_target()


func _process(delta: float) -> void:
	data.hunger = minf(1.0, data.hunger + TankState.HUNGER_PER_SECOND * delta)
	_excited = maxf(0.0, _excited - delta)

	var desired := _steer(delta)
	velocity = velocity.lerp(desired, clampf(delta * 1.6, 0.0, 1.0))
	exact_pos += velocity * delta
	exact_pos = tank.clamp_to_water(exact_pos, _half)
	if spec.habit == "crawl":
		exact_pos.y = tank.floor_y() - _half.y + 1.0
		# Picking at the gravel: a 1px bob while resting.
		position = exact_pos.round() + Vector2(0, 1 if _rest > 0.0 and int(_phase * 2.0) % 2 == 0 else 0)
	else:
		position = exact_pos.round()

	# Turn only on a clear direction change, so fish don't flicker when hovering.
	if velocity.x < -1.5:
		_facing_left = true
	elif velocity.x > 1.5:
		_facing_left = false
	_sprite.flip_h = _facing_left

	var effort: float = velocity.length() / spec.speed
	_phase += delta * (2.0 + 6.0 * effort * spec.wobble + _excited * 10.0)
	_rest = maxf(0.0, _rest - delta)
	_material.set_shader_parameter("phase", _phase)


func mouth() -> Vector2:
	var front := Vector2(-_half.x if _facing_left else _half.x, 0.0)
	if spec.habit == "crawl":
		front.y = _half.y - 1.0
	return exact_pos + front


func _speed() -> float:
	# Starving fish get sluggish; it's the only "penalty" (fish never die, see design notes).
	return spec.speed * (0.55 if data.hunger > 0.85 else 1.0)


func _steer(delta: float) -> Vector2:
	var speed := _speed()

	if data.hunger > 0.12:
		var food: Node2D = tank.nearest_food(mouth(), FOOD_SIGHT, spec.habit == "crawl")
		if food:
			var reach := food.position - mouth()
			var close := absf(reach.x) <= _half.x and absf(reach.y) <= 6.0 if spec.habit == "crawl" \
				else reach.length() <= EAT_RANGE
			if close:
				tank.eat(food)
				data.hunger = maxf(0.0, data.hunger - HUNGER_FOOD_VALUE)
				_excited = 0.6
				_rest = 0.8
			if spec.habit == "crawl":
				return Vector2(signf(reach.x) * speed * 1.5, 0.0)
			return reach.normalized() * speed * 1.7

	match spec.habit:
		"crawl":
			return _steer_crawl(delta, speed)
		"bottom":
			return _steer_bottom(delta, speed)

	var desired: Vector2
	if spec.schooling:
		desired = (tank.school_target(data.species) - exact_pos).limit_length(speed) * _pace
	else:
		_retarget_in -= delta
		if _retarget_in <= 0.0 or exact_pos.distance_to(_target) < 3.0:
			_pick_target()
		var to_target := _target - exact_pos
		# Arrive: ease off near the target instead of overshooting.
		desired = to_target.normalized() * speed * _pace * clampf(to_target.length() / 20.0, 0.15, 1.0)

	return desired + _separation(speed) + (_alignment(speed) if spec.schooling else Vector2.ZERO)


## Walk a little way along the gravel, then stop and pick at it.
func _steer_crawl(delta: float, speed: float) -> Vector2:
	if _rest > 0.0:
		return Vector2.ZERO
	_retarget_in -= delta
	if _retarget_in <= 0.0 or absf(_target.x - exact_pos.x) < 1.5:
		if _retarget_in > 0.0:
			_rest = randf_range(2.0, 6.0)
		_target = Vector2(exact_pos.x + randf_range(-30.0, 30.0), exact_pos.y)
		_retarget_in = randf_range(4.0, 10.0)
		_pace = randf_range(0.5, 1.0)
	return Vector2(signf(_target.x - exact_pos.x) * speed * _pace, 0.0) + Vector2(_separation(speed).x, 0.0)


## Dash along the bottom, rest, repeat; every minute or two, dart up for a gulp of air.
func _steer_bottom(delta: float, speed: float) -> Vector2:
	_air_in -= delta
	if _air_in <= 0.0 and not _going_for_air:
		_going_for_air = true
		_target = Vector2(exact_pos.x + randf_range(-10.0, 10.0), tank.water_top() + 4.0)
	if _going_for_air:
		if exact_pos.y <= tank.water_top() + 6.0:
			_going_for_air = false
			_air_in = randf_range(45.0, 120.0)
			_pick_target()
		return (_target - exact_pos).normalized() * speed * 2.0
	if _rest > 0.0:
		return _separation(speed)
	_retarget_in -= delta
	if _retarget_in <= 0.0 or exact_pos.distance_to(_target) < 3.0:
		_rest = randf_range(1.0, 4.0)
		_pick_target()
	return (_target - exact_pos).normalized() * speed * _pace * 1.4 + _separation(speed)


func _pick_target() -> void:
	_target = tank.random_point_in_band(spec.depth)
	_retarget_in = randf_range(3.0, 9.0)
	_pace = randf_range(0.35, 1.0)


func _separation(speed: float) -> Vector2:
	var push := Vector2.ZERO
	var personal := maxf(_half.x, 6.0) + 2.0
	for other: Fish in tank.fish_nodes():
		if other == self:
			continue
		var away := exact_pos - other.exact_pos
		var d := away.length()
		if d > 0.01 and d < personal:
			push += away / d * (personal - d) / personal
	return push * speed


func _alignment(speed: float) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for other: Fish in tank.fish_nodes():
		if other != self and other.data.species == data.species and exact_pos.distance_to(other.exact_pos) < 24.0:
			sum += other.velocity
			n += 1
	return (sum / n - velocity) * 0.3 if n > 0 else Vector2.ZERO
