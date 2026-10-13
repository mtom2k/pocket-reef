extends Node
## Background bubbler loop plus occasional single bubble pops. Follows TankState volume/mute.

const LOOP := preload("res://assets/audio/bubbler_loop.wav")
const POPS := [
	preload("res://assets/audio/pop_1.wav"),
	preload("res://assets/audio/pop_2.wav"),
	preload("res://assets/audio/pop_3.wav"),
	preload("res://assets/audio/pop_4.wav"),
]

var _loop_player: AudioStreamPlayer
var _pop_player: AudioStreamPlayer


func _ready() -> void:
	var loop: AudioStreamWAV = LOOP.duplicate()
	loop.loop_mode = AudioStreamWAV.LOOP_FORWARD
	loop.loop_begin = 0
	loop.loop_end = int(loop.get_length() * loop.mix_rate)

	_loop_player = AudioStreamPlayer.new()
	_loop_player.stream = loop
	add_child(_loop_player)

	_pop_player = AudioStreamPlayer.new()
	_pop_player.max_polyphony = 3
	add_child(_pop_player)

	TankState.settings_changed.connect(_apply)
	_apply()


func _apply() -> void:
	var s := TankState.settings
	var audible: bool = not s.muted and s.volume > 0.0
	_loop_player.volume_db = linear_to_db(maxf(0.0001, s.volume))
	_pop_player.volume_db = _loop_player.volume_db - 8.0
	if audible and not _loop_player.playing:
		_loop_player.play()
	elif not audible:
		_loop_player.stop()


## A big bubble reached the surface.
func pop() -> void:
	if TankState.settings.muted or not _loop_player.playing:
		return
	_pop_player.stream = POPS.pick_random()
	_pop_player.pitch_scale = randf_range(0.85, 1.2)
	_pop_player.play()
