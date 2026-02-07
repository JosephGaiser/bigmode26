class_name MainMenu
extends Control

signal start_pressed

@onready var title_label: Label = %TitleLabel

func _ready() -> void:
	_start_title_float()

func _start_title_float() -> void:
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_label, "position:y", title_label.position.y - 15, 2.0)
	tween.tween_property(title_label, "position:y", title_label.position.y + 15, 2.0)


func _on_start_button_pressed() -> void:
	start_pressed.emit()
