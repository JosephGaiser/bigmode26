extends Node2D

@onready var goal_area_2d: Area2D = %GoalArea2D
@onready var goal_audio_stream_player_2d: AudioStreamPlayer2D = %GoalAudioStreamPlayer2D
@onready var confetti_cpu_particles_2d: CPUParticles2D = %ConfettiCPUParticles2D
@onready var finished_label: Label = %FinishedLabel
@onready var eggbertina: RigidBody2D = %Eggbertina


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	finished_label.visible = false
	goal_area_2d.body_entered.connect(_on_goal_entered)


func _on_goal_entered(body: Node2D) -> void:
	if body is Egg and !GlobalData.goal_reached:
		if confetti_cpu_particles_2d:
			confetti_cpu_particles_2d.restart()
			confetti_cpu_particles_2d.emitting = true
		finished_label.visible = true
		confetti_cpu_particles_2d.emitting = true
		GlobalData.goal_reached = true
		GlobalData.stop_timer()
		goal_audio_stream_player_2d.play()
		Dialogic.VAR.set_variable("finish_time", GlobalData.format_time(GlobalData.best_time))
		_play_dialouge(body)
		
func _play_dialouge(egg: Egg) -> void:
	var layout: Node = Dialogic.start("egg_goal")
	layout.register_character("egg", egg)
	layout.register_character("Eggbertina", eggbertina)
	get_viewport().set_input_as_handled()
