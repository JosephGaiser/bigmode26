class_name Pause
extends Control

@export var hand: Hand
@onready var sens_h_slider: HSlider = %SensHSlider

var is_paused := false

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("game_pause"):
		# On web, first escape releases mouse capture without triggering our pause
		# So we check if mouse is captured before toggling
		if OS.has_feature("web") and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			# Mouse is captured, so this escape should release and pause
			is_paused = true
			visible = true
			get_tree().paused = true
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		elif OS.has_feature("web") and Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			# Mouse already released, toggle pause state
			is_paused = !is_paused
			visible = is_paused
			get_tree().paused = is_paused
			if !is_paused:
				call_deferred("_recapture_mouse")
		else:
			# Not web, normal behavior
			is_paused = !is_paused
			visible = is_paused
			get_tree().paused = is_paused
			if !is_paused:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Fallback: recapture on any click when game is active
	elif event is InputEventMouseButton and event.pressed and !is_paused and visible == false:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _recapture_mouse() -> void:
	await get_tree().create_timer(0.1, true, false, true).timeout
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


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
