extends Node

signal reset
signal game_over

var goal_reached: bool = false
var timer_running: bool = false
var current_time: float = 0.0
var best_time: float = INF

func _process(delta: float) -> void:
	if timer_running:
		current_time += delta

func start_timer() -> void:
	timer_running = true
	current_time = 0.0

func stop_timer() -> void:
	if timer_running:
		timer_running = false
		if current_time < best_time:
			best_time = current_time

func reset_timer() -> void:
	reset.emit()
	timer_running = false
	current_time = 0.0

func format_time(time: float) -> String:
	var minutes := int(time) / 60
	var seconds := int(time) % 60
	return "%02d:%02d" % [minutes, seconds]

func game_over_dialogue_ended() -> void:
	game_over.emit()
