extends RigidBody2D

@onready var interactable: Node = $Interactable

@export var slip_chance: float = 0.05

func _ready() -> void:
	if interactable:
		interactable.grip_multiplier = 0.4
		interactable.grabbed.connect(_on_grabbed)
		interactable.grab_rejected.connect(_on_grab_rejected)

func _on_grabbed(_hand: Hand) -> void:
	print("[DEBUG_LOG] Soap grabbed! It's slippery.")

func _on_grab_rejected(_hand: Hand) -> void:
	print("[DEBUG_LOG] Soap grab rejected!")

func _physics_process(delta: float) -> void:
	# Custom behavior: occasionally slip out of hand even if distance is fine
	if interactable and interactable.is_inside_tree() and get_parent() is Hand:
		if randf() < slip_chance * delta:
			get_parent().release()
			print("[DEBUG_LOG] Soap slipped!")
