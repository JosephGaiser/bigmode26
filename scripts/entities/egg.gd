class_name Egg
extends RigidBody2D

signal cracked

@export var shell_1: PackedScene
@export var shell_2: PackedScene

@export_category("Bounce Settings")
## Curve that determines crack chance based on bounce count (X: bounce number, Y: crack probability 0-1)
@export var bounce_crack_chance_curve: Curve
## Minimum velocity change required to count as a bounce attempt
@export var bounce_velocity_threshold: float = 500.0

@onready var sprite: Sprite2D = $EggSprite2D
@onready var crack_particles: CPUParticles2D = %CrackParticles
@onready var impact_audio_stream_player_2d: AudioStreamPlayer2D = %ImpactAudioStreamPlayer2D
@onready var crack_audio_stream_player_2d: AudioStreamPlayer2D = %CrackAudioStreamPlayer2D
@onready var floor_ray_cast_2d: RayCast2D = %FloorRayCast2D

const IMPACT_VELOCITY_THRESHOLD: float = 300.0
const CRACK_VELOCITY_THRESHOLD: float = 950.0
var last_velocity := Vector2.ZERO
var is_cracked := false
var is_held := false
var bounce_count: int = 0

func _ready() -> void:
	_play_dialouge("egg_intro", true)
	contact_monitor = true
	max_contacts_reported = 4
	
func _play_dialouge(timeline: String, interupt: bool = false) -> void:
	if !interupt and Dialogic.current_timeline != null:
		return
		
	var layout: Node = Dialogic.start(timeline)
	layout.register_character("egg", sprite)
	get_viewport().set_input_as_handled()


func _physics_process(_delta: float) -> void:
	if is_cracked:
		return

	if is_held:
		is_held = false  # Reset flag, will be set again by hand if still held
		return

	# Check for hard impact (cracking or bouncing)
	if get_contact_count() > 0:
		# If the difference between last velocity and current velocity is huge, we hit something hard
		var velocity_change := (linear_velocity - last_velocity).length()
		if velocity_change > 200.0:
			impact_audio_stream_player_2d.play()
		if velocity_change > CRACK_VELOCITY_THRESHOLD:
			# Check if egg should bounce instead of crack
			if _should_bounce():
				_trigger_bounce()
			else:
				_trigger_crack_effects()
			return
	last_velocity = linear_velocity

func _on_hold_process(_hand: Node2D, _delta: float) -> void:
	is_held = true
	# and prevent velocity buildup
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0

func _should_bounce() -> bool:
	# If no curve is set or velocity too low, don't bounce
	if not bounce_crack_chance_curve:
		return false

	var velocity_change := (linear_velocity - last_velocity).length()
	if velocity_change < bounce_velocity_threshold:
		return false

	# Sample the curve at current bounce count
	var crack_chance := bounce_crack_chance_curve.sample(float(bounce_count))
	var random_roll := randf()

	# If random roll is greater than crack chance, we bounce!
	return random_roll > crack_chance

func _trigger_bounce() -> void:
	bounce_count += 1
	_play_dialouge("egg_bounce", true)
	print("[DEBUG_LOG] Egg: Bounced! Count: ", bounce_count)

func _trigger_crack_effects() -> void:
	Dialogic.VAR.egg_deaths += 1
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

	print("[DEBUG_LOG] Egg: Cracked after ", bounce_count, " bounces")
