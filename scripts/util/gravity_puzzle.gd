class_name  GravityPuzzle
extends Area2D


@export var switch: Switch
@export var orbital_force: float = 200.0
@export var centering_force: float = 50.0

@onready var gravity_shader: ColorRect = %GravityShader

var default_grav_mode: SpaceOverride
var initial_body_states: Dictionary = {}

func _ready() -> void:
	default_grav_mode = self.gravity_space_override
	switch.toggled.connect(_on_switch_toggled)
	GlobalData.reset.connect(reset_puzzle)

	# Store initial positions and velocities of bodies in the area
	await get_tree().process_frame
	_store_initial_states()
	_on_switch_toggled(switch.is_on)

func _store_initial_states() -> void:
	for body in get_overlapping_bodies():
		if body is RigidBody2D and body is not Egg:
			initial_body_states[body] = {
				"position": body.global_position,
				"rotation": body.global_rotation,
				"linear_velocity": body.linear_velocity,
				"angular_velocity": body.angular_velocity
			}

func _physics_process(delta: float) -> void:
	if gravity_shader.visible:
		var center = global_position
		for body in get_overlapping_bodies():
			if body is RigidBody2D and body is not Egg:
				var to_center = center - body.global_position
				var distance = to_center.length()

				if distance > 0:
					# Tangential force for orbital motion (perpendicular to radius)
					var tangent = Vector2(-to_center.y, to_center.x).normalized()
					body.apply_central_force(tangent * orbital_force)

					# Gentle centering force to keep objects from flying away
					var center_force = to_center.normalized() * centering_force
					body.apply_central_force(center_force)

func reset_puzzle() -> void:
	for body in initial_body_states.keys():
		if is_instance_valid(body):
			var state = initial_body_states[body]
			body.global_position = state["position"]
			body.global_rotation = state["rotation"]
			body.linear_velocity = state["linear_velocity"]
			body.angular_velocity = state["angular_velocity"]

func _on_switch_toggled(is_on: bool) -> void:
	if is_on:
		self.gravity_space_override = Area2D.SPACE_OVERRIDE_DISABLED
		gravity_shader.visible = false
	else:
		self.gravity_space_override = default_grav_mode
		gravity_shader.visible = true
