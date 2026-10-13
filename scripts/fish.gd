class_name Fish
extends Node2D
## One fish. Steering-based movement: wander within the species' depth band, school (if the
## species does), avoid crowding, and chase food when hungry. Renders snapped to whole pixels.
##
## Habits (SpeciesDB): "swim" roams open water; "bottom" dashes and rests along the gravel and
## occasionally darts up for air; "crawl" walks on the gravel and never leaves it.
##
## Performance: decisions (targets, neighbours, finding food) run THINK_INTERVAL apart, staggered
## across fish; movement, chasing a flake and eating it still happen every frame.

const SWIM_SHADER := preload("res://shaders/swim.gdshader")
const PAD := Vector2i(0, 2)
const FOOD_SIGHT := 110.0
const EAT_RANGE := 3.0
const HUNGER_FOOD_VALUE := 0.25
const THINK_INTERVAL := 0.1

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
var _think_in := randf() * THINK_INTERVAL
var _desired := Vector2.ZERO
var _food: Node2D = null


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

	_think_in -= delta
	if _think_in <= 0.0:
		_desired = _steer(THINK_INTERVAL - _think_in)
		_think_in += THINK_INTERVAL
	if _food != null:
		if not is_instance_valid(_food) or _food.is_queued_for_deletion():
			_food = null
			_think_in = 0.0  # someone else ate it: decide again next frame
		elif not _try_eat():
			_desired = _chase(_speed())
	velocity = velocity.lerp(_desired, clampf(delta * 1.6, 0.0, 1.0))
	exact_pos += velocity * delta
	exact_pos = tank.clamp_to_water(exact_pos, _half)
	if spec.habit == "crawl":
		exact_pos.y = tank.floor_y() - _half.y + 1.0
		# Picking at the gravel: a 1px bob while resting.
		position = exact_pos.round() + Vector2(0, 1 if _rest > 0.0 and int(_phase * 2.0) % 2 == 0 else 0)
	else:
		position = exact_pos.round()

	# Face the flake being chased; otherwise turn only on a clear direction change,
	# so fish don't flicker when hovering.
	if _food != null and absf(_food.position.x - exact_pos.x) > 2.0:
		_facing_left = _food.position.x < exact_pos.x
	elif velocity.x < -1.5:
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

	_food = _pick_food() if data.hunger > 0.12 else null
	if _food != null:
		return _chase(speed)

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


## Nearest flake, but stick with the current one unless another is clearly closer
## (otherwise a fish between two flakes keeps changing its mind and never gets either).
func _pick_food() -> Node2D:
	var nearest: Node2D = tank.nearest_food(mouth(), FOOD_SIGHT, spec.habit == "crawl")
	if _food != null and is_instance_valid(_food) and not _food.is_queued_for_deletion() and nearest != null:
		if mouth().distance_to(nearest.position) > 0.7 * mouth().distance_to(_food.position):
			return _food
	return nearest


## Swim so the head (not the middle of the body) arrives at the flake.
func _chase(speed: float) -> Vector2:
	if spec.habit == "crawl":
		return Vector2(signf(_food.position.x - mouth().x) * speed * 1.5, 0.0)
	var head := Vector2(-_half.x if _facing_left else _half.x, 0.0) * 0.7
	var to_food := _food.position - (exact_pos + head)
	return to_food.normalized() * speed * 1.7 * clampf(to_food.length() / 6.0, 0.35, 1.0)


## Eats the flake being chased if it's within reach. Returns true if it did.
func _try_eat() -> bool:
	var reach := _food.position - mouth()
	var close: bool
	if spec.habit == "crawl":
		close = absf(reach.x) <= _half.x and absf(reach.y) <= 6.0
	else:
		# At the mouth, or anywhere over the front half of the head.
		var head := Rect2(exact_pos - _half * 0.8, _half * 1.6)
		if _facing_left:
			head.size.x *= 0.5
		else:
			head.position.x += head.size.x * 0.5
			head.size.x *= 0.5
		close = reach.length() <= EAT_RANGE or head.has_point(_food.position)
	if not close:
		return false
	tank.eat(_food)
	_food = null
	data.hunger = maxf(0.0, data.hunger - HUNGER_FOOD_VALUE)
	_excited = 0.6
	_rest = 0.8
	_desired = Vector2.ZERO
	_think_in = 0.0
	return true


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
	var personal_sq := personal * personal
	for other in tank.fish_nodes():
		if other == self:
			continue
		var away: Vector2 = exact_pos - other.exact_pos
		var d_sq := away.length_squared()
		if d_sq > 0.0001 and d_sq < personal_sq:
			var d := sqrt(d_sq)
			push += away / d * (personal - d) / personal
	return push * speed


func _alignment(speed: float) -> Vector2:
	var sum := Vector2.ZERO
	var n := 0
	for other in tank.fish_nodes():
		if other != self and other.data.species == data.species and exact_pos.distance_squared_to(other.exact_pos) < 576.0:
			sum += other.velocity
			n += 1
	return (sum / n - velocity) * 0.3 if n > 0 else Vector2.ZERO
