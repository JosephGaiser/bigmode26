class_name Knife
extends RigidBody2D

@onready var interactable: Node = $Interactable
@onready var sharp_area_2d: Area2D = $SharpArea2D
@onready var reject_audio_player: AudioStreamPlayer2D = $RejectAudioPlayer
@onready var blood_particles: CPUParticles2D = $BloodParticles

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if interactable:
		interactable.grabbed.connect(_on_grabbed)
		interactable.grab_rejected.connect(_on_grab_rejected)

func _can_grab_check(hand: Hand) -> bool:
	# If the hand's grab area overlaps the blade, disallow the grab.
	for area in sharp_area_2d.get_overlapping_areas():
		if area == hand.grab_area_2d:
			return false
	return true

func _on_grabbed(_hand: Hand) -> void:
	# Add any visual/audio feedback for a successful grab here
	pass

func _on_grab_rejected(hand: Hand) -> void:
	if reject_audio_player:
		reject_audio_player.play()
	
	if blood_particles:
		blood_particles.global_position = hand.global_position
		blood_particles.emitting = true
