class_name Spinner
extends Node2D

@export var entity_scene : PackedScene
@export var rotation_speed : float = 2.0

var entity : Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	entity = entity_scene.instantiate()
	add_child(entity)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	entity.rotation += rotation_speed
