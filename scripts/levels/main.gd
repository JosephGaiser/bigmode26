class_name Main
extends Node2D

@onready var level: Node2D = $Level

@export_category("Levels")
@export var Level1: PackedScene 
@export var Level2: PackedScene
@onready var palette: CanvasLayer = $Palette
@onready var dither: CanvasLayer = $Dither

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_shaders"):
		palette.visible = !palette.visible
		dither.visible = !dither.visible

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
