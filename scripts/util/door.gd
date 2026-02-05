class_name Door
extends Node2D

@export var switch: Switch
@onready var polygon_2d: Polygon2D = %Polygon2D
@onready var door_collision_shape_2d: CollisionShape2D = %DoorCollisionShape2D

func _ready() -> void:
	switch.toggled.connect(_on_switch_toggled)

func _on_switch_toggled(is_on: bool) -> void:
	door_collision_shape_2d.set_deferred("disabled", !door_collision_shape_2d.disabled)
	polygon_2d.visible = !polygon_2d.visible
