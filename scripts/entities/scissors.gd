class_name Scissors
extends AnimatableBody2D

enum PathMode {
	PING_PONG,
	LOOP
}

@export_category("Settings")
@export var travel_time: float = 2.0
@export var path_mode: PathMode = PathMode.PING_PONG

@export_category("Node References")
@export var position_curve: Curve
@export var path_follow: PathFollow2D
@export var sprites: Node2D
@export var open_sprite: Sprite2D
@export var closed_sprite: Sprite2D
@export var hazard_collider: CollisionShape2D
@export var snip_audio_stream_player: AudioStreamPlayer2D
@export var snip_sounds: Array[AudioStream]

var sample_point : float = 0.0
var direction : int = 1
var toggle_timer : float = 0.0
var is_open : bool = false

func _ready() -> void:
	_update_state()

func _physics_process(delta: float) -> void:
	if not path_follow or not position_curve:
		return
		
	sample_point += (delta / travel_time) * direction

	if path_mode == PathMode.LOOP:
		# Loop mode: return to start when reaching end
		if sample_point >= 1.0:
			sample_point = 0.0
	else:
		# Ping-pong mode: reverse direction at ends
		if sample_point >= 1.0:
			direction = -1
			sample_point = 1.0
		elif sample_point <= 0.0:
			direction = 1
			sample_point = 0.0
	
	path_follow.progress_ratio = position_curve.sample(sample_point)
	
	if sprites:
		var move_vec = (path_follow.global_position - global_position).rotated(-global_rotation)
		if abs(move_vec.x) > 0.1:
			sprites.scale.x = -sign(move_vec.x)
		else:
			var current_progress = path_follow.progress
			path_follow.progress += 2.0 * direction 
			var look_ahead_pos = path_follow.global_position
			path_follow.progress = current_progress # Restore original position
			
			var tangent_vec = (look_ahead_pos - global_position).rotated(-global_rotation)
			if abs(tangent_vec.x) > 0.1:
				sprites.scale.x = -sign(tangent_vec.x)
	
	global_position = path_follow.global_position
	
	# Open/close toggle logic
	toggle_timer += delta
	if toggle_timer >= 0.5: # Toggle every 0.5 seconds
		if snip_audio_stream_player and snip_sounds.size() > 0:
			snip_audio_stream_player.stream = snip_sounds[randi() % snip_sounds.size()]
			snip_audio_stream_player.play()
		toggle_timer = 0.0
		is_open = !is_open
		_update_state()

func _update_state() -> void:
	if open_sprite:
		open_sprite.visible = is_open
	if closed_sprite:
		closed_sprite.visible = !is_open
	if hazard_collider:
		# Hazard is active when scissors are NOT open (i.e. closed)
		hazard_collider.set_deferred("disabled", is_open)
