extends Node2D

@onready var goal_area_2d: Area2D = %GoalArea2D
@onready var goal_audio_stream_player_2d: AudioStreamPlayer2D = %GoalAudioStreamPlayer2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	goal_area_2d.body_entered.connect(_on_goal_entered)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_goal_entered(body: Node2D) -> void:
	if body is Egg and !GlobalData.goal_reached:
		GlobalData.goal_reached = true
		GlobalData.stop_timer()
		goal_audio_stream_player_2d.play()
		Dialogic.VAR.set_variable("finish_time", GlobalData.format_time(GlobalData.best_time))
		body._play_dialouge("egg_goal")
