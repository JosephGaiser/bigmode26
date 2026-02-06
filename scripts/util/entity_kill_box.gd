class_name EntityKillBox
extends Node2D

@onready var kill_box_area_2d: Area2D = $KillBoxArea2D


func _ready() -> void:
	kill_box_area_2d.body_entered.connect(_on_kill_box_entered)
	
func _on_kill_box_entered(body: Node2D) -> void:
	body.queue_free()
