class_name Pause
extends Control

@export var hand: Hand
@onready var sens_h_slider: HSlider = %SensHSlider

var is_paused := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		is_paused = !is_paused
		visible = is_paused
		get_tree().paused = is_paused
		if !is_paused:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Allow UI elements to process input while paused
	_set_process_mode_recursive(self, Node.PROCESS_MODE_ALWAYS)
	if hand and sens_h_slider:
		sens_h_slider.value = hand.mouse_sensitivity
		sens_h_slider.value_changed.connect(_on_sens_slider_changed)


func _set_process_mode_recursive(node: Node, mode: Node.ProcessMode) -> void:
	node.process_mode = mode
	for child in node.get_children():
		_set_process_mode_recursive(child, mode)


func _on_sens_slider_changed(value: float) -> void:
	if hand:
		hand.mouse_sensitivity = value
