@tool
extends Node

# This script will create terrain from all its children static bodies with polygon2D children

func _ready() -> void:
	if not Engine.is_editor_hint():
		for child in get_children():
			if child is StaticBody2D:
				_create_terrain(child)


func _create_terrain(static_body2d: StaticBody2D) -> void:
	static_body2d.collision_layer = 2 # world collision mask
	var coll := CollisionPolygon2D.new()
	coll.polygon = static_body2d.get_node("Polygon2D").polygon
	static_body2d.add_child(coll)
