class_name Switch
extends Node2D

signal toggled (is_on: bool)

@onready var on_sprite_2d: Sprite2D = %OnSprite2D
@onready var off_sprite_2d: Sprite2D = %OffSprite2D
@onready var toggle_audio_stream_player_2d: AudioStreamPlayer2D = %ToggleAudioStreamPlayer2D
@onready var toggle_area_2d: Area2D = %ToggleArea2D
@onready var spark_particles: CPUParticles2D = %SparkParticles

@export var is_on: bool = false

var starting_state: bool = is_on

func _ready() -> void:
	add_to_group("switch")
	starting_state = is_on
	GlobalData.reset.connect(reset)
	toggle_area_2d.body_entered.connect(_on_hand_entered)
	toggle_area_2d.body_exited.connect(_on_hand_exited)
	_update_sprites()

func reset() -> void:
	_set_state(starting_state)

func _process(_delta: float) -> void:
	pass

func toggle() -> void:
	_set_state(!is_on)

func _set_state(state: bool) -> void:
	is_on = state
	toggled.emit(state)
	_update_sprites()
	if toggle_audio_stream_player_2d:
		toggle_audio_stream_player_2d.play()
	if spark_particles:
		spark_particles.restart()
		spark_particles.emitting = true

func _update_sprites() -> void:
	on_sprite_2d.visible = is_on
	off_sprite_2d.visible = !is_on

var _hand_in_range: Hand = null

func _on_hand_entered(body: Node2D) -> void:
	if body is Hand:
		_hand_in_range = body

func _on_hand_exited(body: Node2D) -> void:
	if body is Hand and body == _hand_in_range:
		_hand_in_range = null

func can_toggle(hand: Hand) -> bool:
	return _hand_in_range == hand

func is_hand_in_range() -> bool:
	return _hand_in_range != null
