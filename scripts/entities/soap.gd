extends RigidBody2D

@onready var interactable: Node = $Interactable

@export var slip_chance: float = 0.05

@onready var bubble_particles: CPUParticles2D = $BubbleParticles

func _ready() -> void:
	if interactable:
		interactable.grip_multiplier = 0.4
		interactable.grabbed.connect(_on_grabbed)
		interactable.released.connect(_on_released)
		interactable.grab_rejected.connect(_on_grab_rejected)

func _on_grabbed(_hand: Hand) -> void:
	print("[DEBUG_LOG] Soap grabbed! It's slippery.")
	if bubble_particles:
		bubble_particles.emitting = true

func _on_released(_hand: Hand) -> void:
	if bubble_particles:
		bubble_particles.emitting = false

func _on_grab_rejected(_hand: Hand) -> void:
	print("[DEBUG_LOG] Soap grab rejected!")

func _on_hold_process(hand: Hand, delta: float) -> void:
	# Custom behavior: occasionally slip out of hand
	# Slip chance increases with hand velocity
	var current_slip_chance = slip_chance
	if hand.velocity.length() > 500:
		current_slip_chance *= 2.0
	
	if randf() < current_slip_chance * delta:
		hand.release()
		print("[DEBUG_LOG] Soap slipped!")
