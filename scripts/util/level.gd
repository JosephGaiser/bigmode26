@tool
extends Node

# This script will create terrain from all its children static bodies with polygon2D children

func _ready() -> void:
	if not Engine.is_editor_hint():
		for child in get_children():
			if child is StaticBody2D:
				_create_terrain(child)


func _create_terrain(static_body2d: StaticBody2D) -> void:
	static_body2d.set_collision_layer_value(2, true) # world collision mask
	var coll := CollisionPolygon2D.new()
	coll.polygon = static_body2d.get_node("Polygon2D").polygon
	static_body2d.add_child(coll)
	
	if static_body2d.is_in_group("hazard"):
		# This is a hazard, crate a hazard area 2d as well
		var hazard_area_2d := Area2D.new()
		var hazard_coll := CollisionPolygon2D.new()
		hazard_coll.polygon = static_body2d.get_node("Polygon2D").polygon
		hazard_area_2d.set_collision_layer_value(1, false)
		hazard_area_2d.set_collision_mask_value(1, false)
		hazard_area_2d.set_collision_layer_value(5, true)
		hazard_area_2d.add_child(hazard_coll)
		static_body2d.add_child(hazard_area_2d)
