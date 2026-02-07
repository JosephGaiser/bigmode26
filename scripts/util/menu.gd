class_name MainMenu
extends Control

signal start_pressed

@onready var title_label: Label = %TitleLabel
@onready var title_label_2: Label = %TitleLabel2
@onready var egg_shell_1: Sprite2D = $EggShell1
@onready var egg_shell_2: Sprite2D = $EggShell2

func _ready() -> void:
	_float(title_label)
	_float(title_label_2)
	_float(egg_shell_1)
	_float(egg_shell_2)

func _float(node: Node) -> void:
	var tween: Tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	var random_offset: float = randf_range(0.0, 0.3)
	tween.tween_interval(random_offset)
	
	var float_distance: float = randf_range(10.0, 20.0)
	var duration: float = randf_range(1.5, 2.5)
	var start_y: float = node.position.y
	tween.tween_property(node, "position:y", start_y - float_distance, duration)
	tween.tween_property(node, "position:y", start_y + float_distance, duration)

func _on_start_button_pressed() -> void:
	start_pressed.emit()
