extends Node2D


@export var entities_scenes: Array[PackedScene] = []
@export var spawn_rate: float = 1.0
@export var entities_node: Node2D

@onready var timer: Timer = $Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#add a slight randomness to the start time to avoid all entities spawning at the same time
	timer.wait_time = spawn_rate + randf()
	timer.start()
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	spawn()

func spawn() -> void:
	var entity: Node2D = entities_scenes[randi() % entities_scenes.size()].instantiate()
	entity.global_position = global_position
	if entities_node:
		entities_node.add_child(entity)
		
	#apply some subtle randomness to the rotation
	entity.rotation += randf() * 360
	#apply a small impulse to the body to make it bounce a bit
	if entity is RigidBody2D:
		var impulse := Vector2(randf_range(-100.0, 100.0), randf_range(-200.0, -50.0))
		entity.apply_central_impulse(impulse)
		entity.apply_torque_impulse(randf_range(-100.0, 100.0))
