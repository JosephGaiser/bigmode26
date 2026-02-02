class_name EggSpawner
extends Node2D

@export var egg_scene: PackedScene
@export var entities: Node2D

var current_egg: Egg

func _ready() -> void:
	spawn_egg()

func _process(delta: float) -> void:
	pass

func spawn_egg() -> void:
	current_egg = egg_scene.instantiate()
	entities.add_child(current_egg)
	current_egg.global_position = global_position
	current_egg.cracked.connect(_on_egg_cracked)
	
func _on_egg_cracked() -> void:
	spawn_egg()
