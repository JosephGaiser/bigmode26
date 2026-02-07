class_name GameOver
extends Control

@onready var title_label: Label = %TitleLabel
@onready var time_value_label: Label = %TimeValueLabel
@onready var time_panel_container: PanelContainer = %TimePanelContainer

func _ready() -> void:
	GlobalData.game_over.connect(_on_game_over)
	_float(title_label)
	_float(time_panel_container)

func _float(node: Node) -> void:
	var tween: Tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var random_offset: float = randf_range(0.0, 0.3)
	tween.tween_interval(random_offset)
	
	var float_distance: float = randf_range(4.0, 10.0)
	var duration: float = randf_range(1.5, 2.5)
	var start_y: float = node.position.y
	tween.tween_property(node, "position:y", start_y - float_distance, duration)
	tween.tween_property(node, "position:y", start_y + float_distance, duration)

func _on_game_over() -> void:
	time_value_label.text = GlobalData.format_time(GlobalData.best_time)
