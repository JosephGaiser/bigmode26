class_name EntityKillBox
extends Node2D

@onready var kill_box_area_2d: Area2D = $KillBoxArea2D


func _ready() -> void:
	kill_box_area_2d.body_entered.connect(_on_kill_box_entered)
	
func _on_kill_box_entered(body: Node2D) -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(body, "modulate:a", 0.0, 0.8)
	tween.finished.connect(func() -> void:
		if body != null and body.is_inside_tree():
			body.queue_free()
	)
	
