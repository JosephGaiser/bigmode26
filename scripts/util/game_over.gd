class_name GameOver
extends Control

@onready var title_label: Label = %TitleLabel
@onready var time_value_label: Label = %TimeValueLabel

func _ready() -> void:
	GlobalData.game_over.connect(_on_game_over)
	_start_title_float()

func _start_title_float() -> void:
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(title_label, "position:y", title_label.position.y - 15, 2.0)
	tween.tween_property(title_label, "position:y", title_label.position.y + 15, 2.0)

func _on_game_over() -> void:
	time_value_label.text = GlobalData.format_time(GlobalData.best_time)
