class_name DialougeTrigger
extends Area2D

@export var timeline: String

func _ready() -> void:
	pass

func _on_body_entered(body: Node2D) -> void:
	if body is Egg:
		body._play_dialouge(timeline)
