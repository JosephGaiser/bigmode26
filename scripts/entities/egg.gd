class_name Egg
extends Node2D

signal cracked

@export var shell_1: PackedScene
@export var shell_2: PackedScene

@onready var body: RigidBody2D = $RigidBody2D
@onready var sprite: Sprite2D = $RigidBody2D/EggSprite2D
@onready var crack_particles: CPUParticles2D = $CrackParticles

const CRACK_VELOCITY_THRESHOLD: float = 800.0
var last_velocity := Vector2.ZERO

func _ready() -> void:
	body.contact_monitor = true
	body.max_contacts_reported = 4

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(body):
		return
	
	# Check for hard impact (cracking)
	if body.get_contact_count() > 0:
		# If the difference between last velocity and current velocity is huge, we hit something hard
		var velocity_change := (body.linear_velocity - last_velocity).length()
		if velocity_change > CRACK_VELOCITY_THRESHOLD:
			_trigger_crack_effects()
			return
	
	last_velocity = body.linear_velocity

func _on_hold_process(_hand: Node2D, _delta: float) -> void:
	# and prevent velocity buildup
	body.linear_velocity = Vector2.ZERO
	body.angular_velocity = 0.0

func _trigger_crack_effects() -> void:
	cracked.emit()
	var impact_pos := body.global_position
	body.queue_free()
	
	crack_particles.global_position = impact_pos
	crack_particles.restart()
	crack_particles.emitting = true
	
	# Spawn egg shells
	for shell_scene in [shell_1, shell_2]:
		if not shell_scene:
			continue
		var shell: RigidBody2D = shell_scene.instantiate()
		get_parent().add_child(shell)
		shell.global_position = impact_pos
		var impulse := Vector2()
		impulse.x = randf_range(-100.0, 100.0)
		impulse.y = randf_range(-200.0, -50.0)
		shell.apply_central_impulse(impulse)
		shell.angular_velocity = randf_range(-5.0, 5.0)
	queue_free()
