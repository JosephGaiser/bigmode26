class_name PencilLauncher
extends Node2D


@export var projectile: PackedScene
@export var fire_rate: float = 5.0
@export var strength: float = 1000.0
@export var projectiles_node: Node2D

@onready var fire_timer: Timer = %FireTimer
@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var smoke_particles: CPUParticles2D = %SmokeParticles
@onready var audio_stream_player_2d: AudioStreamPlayer2D = $AudioStreamPlayer2D

var base_scale: Vector2

func _ready() -> void:
	GlobalData.reset.connect(_on_reset)
	base_scale = sprite_2d.scale
	fire_timer.wait_time = fire_rate
	fire_timer.autostart = true
	fire_timer.start()
	fire_timer.timeout.connect(_on_timer_timeout)

func _on_reset() -> void:
	for child in projectiles_node.get_children():
		child.queue_free()
	fire_timer.start()

func launch() -> void:
	audio_stream_player_2d.play()
	if not projectile:
		return

	smoke_particles.restart()
	smoke_particles.emitting = true
	
	var proj: PencilProjectile = projectile.instantiate() as PencilProjectile

	proj.global_position = global_position
	proj.rotation = global_rotation
	projectiles_node.add_child(proj)

	var impulse_direction: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	proj.apply_impulse(impulse_direction * strength)

func _on_timer_timeout() -> void:
	var swell_tween = create_tween()
	swell_tween.set_trans(Tween.TRANS_QUAD)
	swell_tween.set_ease(Tween.EASE_IN_OUT)
	swell_tween.tween_property(sprite_2d, "scale", base_scale * 1.5, 0.5)
	swell_tween.tween_property(sprite_2d, "scale", base_scale, 0.1)
	swell_tween.tween_callback(launch)
