class_name Egg
extends RigidBody2D

signal cracked

@export var shell_1: PackedScene
@export var shell_2: PackedScene

@onready var sprite: Sprite2D = $EggSprite2D
@onready var crack_particles: CPUParticles2D = $CrackParticles
@onready var impact_audio_stream_player_2d: AudioStreamPlayer2D = $ImpactAudioStreamPlayer2D
@onready var crack_audio_stream_player_2d: AudioStreamPlayer2D = $CrackAudioStreamPlayer2D

const IMPACT_VELOCITY_THRESHOLD: float = 300.0
const CRACK_VELOCITY_THRESHOLD: float = 950.0
var last_velocity := Vector2.ZERO
var is_cracked := false
var is_held := false

func _ready() -> void:
	contact_monitor = true
	max_contacts_reported = 4

func _physics_process(_delta: float) -> void:
	if is_cracked:
		return

	if is_held:
		is_held = false  # Reset flag, will be set again by hand if still held
		return

	# Check for hard impact (cracking)
	if get_contact_count() > 0:
		# If the difference between last velocity and current velocity is huge, we hit something hard
		var velocity_change := (linear_velocity - last_velocity).length()
		if velocity_change > 200.0:
			impact_audio_stream_player_2d.play()
		if velocity_change > CRACK_VELOCITY_THRESHOLD:
			_trigger_crack_effects()
			return
	last_velocity = linear_velocity

func _on_hold_process(_hand: Node2D, _delta: float) -> void:
	is_held = true
	# and prevent velocity buildup
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func _trigger_crack_effects() -> void:
	is_cracked = true
	set_deferred("freeze", true)
	collision_layer = 0
	collision_mask = 0
	sprite.visible = false
	cracked.emit()
	crack_particles.restart()
	crack_particles.emitting = true
	crack_audio_stream_player_2d.play()
	
	# Spawn egg shells
	for shell_scene in [shell_1, shell_2]:
		if not shell_scene:
			continue
		var shell: RigidBody2D = shell_scene.instantiate()
		add_child(shell)
		shell.global_position = global_position
		var impulse := Vector2()
		impulse.x = randf_range(-100.0, 100.0)
		impulse.y = randf_range(-200.0, -50.0)
		shell.apply_central_impulse(impulse)
		shell.angular_velocity = randf_range(-5.0, 5.0)
