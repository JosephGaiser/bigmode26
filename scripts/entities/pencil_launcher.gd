class_name PencilLauncher
extends Node2D


@export var projectile: PackedScene
@export var fire_rate: float = 5.0
@export var strength: float = 1000.0
@export var projectiles_node: Node2D

@onready var fire_timer: Timer = %FireTimer

func _ready() -> void:
	fire_timer.wait_time = fire_rate
	fire_timer.autostart = true
	fire_timer.start()
	fire_timer.timeout.connect(_on_timer_timeout)
	launch()

func launch() -> void:
	if not projectile:
		return

	var proj: PencilProjectile = projectile.instantiate() as PencilProjectile

	proj.global_position = global_position
	proj.rotation = global_rotation
	projectiles_node.add_child(proj)

	var impulse_direction: Vector2 = Vector2.RIGHT.rotated(global_rotation)
	proj.apply_impulse(impulse_direction * strength)

func _on_timer_timeout() -> void:
	launch()
