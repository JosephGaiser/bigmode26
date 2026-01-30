class_name Knife
extends RigidBody2D

@onready var sharp_area_2d: Area2D = $SharpArea2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	

func grab(hand: Hand) -> void:
	if sharp_area_2d.get_overlapping_areas().has(hand.grab_area_2d):
		print("OUCH!")
		hand.release()
