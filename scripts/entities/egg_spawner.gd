class_name EggSpawner
extends Node2D

signal egg_spawned

@export var egg_scene: PackedScene
@export var entities: Node2D

var current_egg: Egg

func _ready() -> void:
	spawn_egg()
	GlobalData.reset.connect(_on_reset)

func spawn_egg() -> void:
	current_egg = egg_scene.instantiate()
	current_egg.global_position = global_position
	current_egg.cracked.connect(_on_egg_cracked)
	entities.add_child(current_egg)
	egg_spawned.emit(current_egg)
	
func _on_egg_cracked() -> void:
	pass

func _on_reset() -> void:
	if !current_egg.is_cracked:
		current_egg._trigger_crack_effects()
	spawn_egg()
