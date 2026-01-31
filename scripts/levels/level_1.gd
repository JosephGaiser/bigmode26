class_name Level_1
extends Node2D

@onready var orange_slice_area_2d: Area2D = %OrangeSliceArea2D

var orange_slices_in_tray: Array[OrangeSlice] = []
var stationary_timer: float = 0.0
var required_stationary_time: float = .5
var puzzle_solved: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if puzzle_solved:
		return
		
	if orange_slices_in_tray.size() >= 2:
		var all_stationary: bool = true
		for slice in orange_slices_in_tray:
			# If the slice is being held, it's not "stationary" for the purpose of the puzzle
			if slice.freeze: 
				all_stationary = false
				break
			
			if slice.linear_velocity.length() > 10.0:
				all_stationary = false
				break
		
		if all_stationary:
			stationary_timer += delta
			if stationary_timer >= required_stationary_time:
				_solve_puzzle()
		else:
			stationary_timer = 0.0
	else:
		stationary_timer = 0.0

func _solve_puzzle() -> void:
	puzzle_solved = true
	print("Puzzle Level 1 Solved!")
	var sfx = AudioStreamPlayer.new()
	add_child(sfx)
	sfx.stream = load("res://assets/sfx/Bell Click A.wav")
	sfx.bus = &"SFX"
	sfx.play()
	sfx.finished.connect(sfx.queue_free)
	
	# Add some visual feedback
	var label = Label.new()
	label.text = "SOLVED!"
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 128
	label.label_settings.font_color = Color.GREEN
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	canvas_layer.add_child(label)
	
	# Simple animation
	var tween = create_tween()
	label.modulate.a = 0
	label.scale = Vector2.ZERO
	label.pivot_offset = label.size / 2 # This might not work well without waiting a frame
	tween.tween_property(label, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(label, "scale", Vector2.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(canvas_layer.queue_free)

func _on_orange_slice_area_2d_body_entered(body: Node2D) -> void:
	if body is OrangeSlice:
		if not orange_slices_in_tray.has(body):
			orange_slices_in_tray.append(body)

func _on_orange_slice_area_2d_body_exited(body: Node2D) -> void:
	if body is OrangeSlice:
		orange_slices_in_tray.erase(body)
