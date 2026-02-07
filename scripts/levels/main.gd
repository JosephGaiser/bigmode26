class_name Main
extends Node2D


@export var world: PackedScene 

@onready var level_container: Node2D = %LevelContainer
@onready var palette: CanvasLayer = $Palette
@onready var dither: CanvasLayer = $Dither
@onready var menu: MainMenu = %Menu
@onready var game_over: GameOver = %GameOver

var world_instance: Node2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	game_over.visible = false
	GlobalData.game_over.connect(_on_game_over)
	menu.start_pressed.connect(_on_start_button_pushed)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_shaders"):
		palette.visible = !palette.visible
		dither.visible = !dither.visible

func _on_start_button_pushed() -> void:
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(menu, "modulate:a", 0.0, 0.8)
	tween.finished.connect(_load_world)

func _load_world() -> void:
	if is_instance_valid(menu):
		menu.queue_free()
	world_instance = world.instantiate()
	level_container.add_child(world_instance)
	world_instance.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(world_instance, "modulate:a", 1.0, 0.8)
	
func _unload_world() -> void:
	if world_instance:
		world_instance.queue_free()
		
func _on_game_over() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_unload_world()
	game_over.modulate.a = 0.0
	game_over.visible = true
	var tween: Tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(game_over, "modulate:a", 1.0, 0.8)
