class_name Door
extends Node2D

@export var switch: Switch
@onready var polygon_2d: Polygon2D = %Polygon2D
@onready var door_collision_shape_2d: CollisionShape2D = %DoorCollisionShape2D

func _ready() -> void:
	switch.toggled.connect(_on_switch_toggled)
	_on_switch_toggled(switch.is_on)

func _on_switch_toggled(is_on: bool) -> void:
	door_collision_shape_2d.set_deferred("disabled", is_on)
	polygon_2d.visible = !is_on
