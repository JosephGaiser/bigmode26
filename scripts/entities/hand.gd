extends Node2D


@export var open_hand_sprite_2d: Sprite2D
@export var closed_hand_sprite_2d: Sprite2D
@export var grab_area_2d: Area2D
@export var max_hold_distance: float = 300.0
@export var slippery_grip_multiplier: float = 0.35
@export var follow_speed: float = 18.0
@export var min_follow_speed: float = 6.0

var is_grabbing: bool = false
var held_body: RigidBody2D = null
var hold_offset: Vector2 = Vector2.ZERO
var held_body_was_frozen: bool = false
var held_body_freeze_mode: int = RigidBody2D.FREEZE_MODE_STATIC

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _physics_process(delta: float) -> void:
	position = get_global_mouse_position()
	_apply_hold_force(delta)
	
	
func _input(event: InputEvent) -> void:
	if event.is_action_released("hand_grab"):
		release()
	if event.is_action_pressed("hand_grab"):
		grab()

func release() -> void:
	is_grabbing = false
	_restore_held_body()
	held_body = null
	_update_hand_sprite()

func grab() -> void:
	is_grabbing = true
	held_body = _find_grabbable_body()
	if held_body:
		hold_offset = held_body.global_position - global_position
		held_body_was_frozen = held_body.freeze
		held_body_freeze_mode = held_body.freeze_mode
		held_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
		held_body.freeze = true
	_update_hand_sprite()
	
func _update_hand_sprite() -> void:
	if is_grabbing:
		open_hand_sprite_2d.visible = false
		closed_hand_sprite_2d.visible = true
	else:
		open_hand_sprite_2d.visible = true
		closed_hand_sprite_2d.visible = false

func _find_grabbable_body() -> RigidBody2D:
	if not grab_area_2d:
		return null
	var closest_body: RigidBody2D = null
	var closest_distance := INF
	for body in grab_area_2d.get_overlapping_bodies():
		if body is RigidBody2D:
			var distance := global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_body = body
	return closest_body

func _get_grip_multiplier(body: RigidBody2D) -> float:
	if body.has_meta("grip_multiplier"):
		return float(body.get_meta("grip_multiplier"))
	if body.is_in_group("slippery"):
		return slippery_grip_multiplier
	return 1.0

func _apply_hold_force(delta: float) -> void:
	if not is_grabbing:
		return
	if not is_instance_valid(held_body):
		_restore_held_body()
		held_body = null
		return
	var target_position := global_position + hold_offset
	var to_target := target_position - held_body.global_position
	var grip_multiplier := _get_grip_multiplier(held_body)
	if to_target.length() > max_hold_distance * grip_multiplier:
		release()
		return
	var mass : float = max(held_body.mass, 0.01)
	var tuned_follow_speed : float = max(follow_speed / mass, min_follow_speed)
	held_body.global_position = held_body.global_position.lerp(target_position, clamp(tuned_follow_speed * delta, 0.0, 1.0))

func _restore_held_body() -> void:
	if not is_instance_valid(held_body):
		return
	held_body.freeze = held_body_was_frozen
	held_body.freeze_mode = held_body_freeze_mode
