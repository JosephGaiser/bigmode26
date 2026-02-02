class_name World
extends Node2D

# CAMERAS
@onready var player_phantom_camera_2d: PhantomCamera2D = %PlayerPhantomCamera2D

@onready var up_section_pcam: PhantomCamera2D = %UpSectionPhantomCamera2D
@onready var big_room_pcam: PhantomCamera2D = %BigRoomPhantomCamera2D

# CAMERA TRIGGER AREAS
@onready var up_section_area_2d: Area2D = %UpSectionArea2D
@onready var big_room_area_2d: Area2D = %BigRoomArea2D

@onready var hand: Hand = %Hand

func _ready() -> void:
	up_section_area_2d.body_entered.connect(_on_body_entered.bind(up_section_pcam))
	up_section_area_2d.body_exited.connect(_on_body_exited.bind(up_section_pcam))
	
	big_room_area_2d.body_entered.connect(_on_body_entered.bind(big_room_pcam))
	big_room_area_2d.body_exited.connect(_on_body_exited.bind(big_room_pcam))

func _on_body_entered(body: Node2D, pcam: PhantomCamera2D) -> void:
	if body is Hand:
		pcam.set_follow_target(hand)
		pcam.set_priority(20)


func _on_body_exited(body: Node2D, pcam: PhantomCamera2D) -> void:
	if body is Hand:
		pcam.set_priority(0)
		pcam.set_follow_target(null)
