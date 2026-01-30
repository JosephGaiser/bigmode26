class_name Hand
extends CharacterBody2D


@export_category("Node References")
@export var open_hand_sprite_2d: Sprite2D
@export var closed_hand_sprite_2d: Sprite2D
@export var grab_area_2d: Area2D
@export var grab_audio_stream_player_2d: AudioStreamPlayer2D
@export var drop_audio_stream_player_2d: AudioStreamPlayer2D
@export var phantom_camera: PhantomCamera2D
@export var camera: Camera2D

@export_category("Hand Settings")
@export var max_hold_distance: float = 300.0
@export var slippery_grip_multiplier: float = 0.35
@export var follow_speed: float = 18.0
@export var min_follow_speed: float = 6.0
@export var speed: float = 2200.0

@export_category("Grab Feedback")
@export var grab_reject_hold_time: float = 0.18 # how long the hand stays "closed" after a failed grab
@export var grab_reject_shake_time: float = 0.18
@export var grab_reject_shake_pixels: float = 3.5
@export var grab_reject_cooldown: float = 0.12

var is_grabbing: bool = false
var held_body: RigidBody2D = null
var held_interactable: Node = null
var hold_offset: Vector2 = Vector2.ZERO
var held_body_was_frozen: bool = false
var held_body_freeze_mode: RigidBody2D.FreezeMode = RigidBody2D.FREEZE_MODE_STATIC
var held_body_had_collision_exception: bool = false

var _rejecting_grab: bool = false
var _reject_cooldown_until_ms: int = 0
var _closed_hand_base_pos: Vector2 = Vector2.ZERO


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_closed_hand_base_pos = closed_hand_sprite_2d.position

func _physics_process(delta: float) -> void:
	if _rejecting_grab:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var target: Vector2 = get_global_mouse_position()
	if phantom_camera:
		var view_size := get_viewport_rect().size * phantom_camera.zoom
		var view_rect := Rect2(camera.get_screen_center_position() - view_size * 0.5, view_size)
		target = target.clamp(view_rect.position, view_rect.position + view_rect.size)
	var target_direction: Vector2 = (target - global_position)
	velocity = target_direction.normalized() * min(speed, target_direction.length() / delta)
	_apply_hold_force(delta)
	move_and_slide()


func _input(event: InputEvent) -> void:
	if event.is_action_released("hand_grab"):
		release()
	if event.is_action_pressed("hand_grab"):
		grab()

func release() -> void:
	if _rejecting_grab:
		return
	is_grabbing = false
	_restore_held_body()
	if held_interactable and held_interactable.has_method("on_release"):
		held_interactable.on_release(self)
	held_body = null
	held_interactable = null
	_update_hand_sprite()

func grab() -> void:
	if _rejecting_grab:
		return
	if Time.get_ticks_msec() < _reject_cooldown_until_ms:
		return

	if !grab_audio_stream_player_2d.is_playing():
		grab_audio_stream_player_2d.play()

	# We optimistically close the hand for responsiveness,
	# but we won't "attach" unless the target accepts the grab.
	is_grabbing = true
	_update_hand_sprite()

	var candidate := _find_grabbable_body()
	if not candidate:
		is_grabbing = true # keep "closed" while button is held
		return

	var interactable := _get_interactable(candidate)

	# Ask the object if this grab is allowed BEFORE freezing/attaching it.
	if interactable and interactable.has_method("can_grab") and not interactable.can_grab(self):
		if interactable.has_method("on_grab_rejected"):
			interactable.on_grab_rejected(self)
		await _play_grab_rejected_feedback()
		return

	# Compatibility for objects without Interactable component but with can_grab method
	if not interactable and candidate.has_method("can_grab") and not candidate.can_grab(self):
		if candidate.has_method("on_grab_rejected"):
			candidate.on_grab_rejected(self)
		await _play_grab_rejected_feedback()
		return

	# Success: commit the grab.
	held_body = candidate
	held_interactable = interactable
	hold_offset = held_body.global_position - global_position
	held_body_was_frozen = held_body.freeze
	held_body_freeze_mode = held_body.freeze_mode
	held_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	held_body.freeze = true
	held_body_had_collision_exception = held_body.get_collision_exceptions().has(self)
	if not held_body_had_collision_exception:
		held_body.add_collision_exception_with(self)
		add_collision_exception_with(held_body)
	
	if held_interactable and held_interactable.has_method("on_grab"):
		held_interactable.on_grab(self)
	elif held_body.has_method("grab"): # fallback for old pattern
		held_body.grab(self)

func _play_grab_rejected_feedback() -> void:
	_rejecting_grab = true
	_reject_cooldown_until_ms = Time.get_ticks_msec() + int(grab_reject_cooldown * 1000.0)

	# Keep the hand visibly "closed" for a moment (delayed release).
	is_grabbing = true
	_update_hand_sprite()

	var end_time_ms := Time.get_ticks_msec() + int(grab_reject_shake_time * 1000.0)
	while Time.get_ticks_msec() < end_time_ms:
		var offset := Vector2(
			randf_range(-grab_reject_shake_pixels, grab_reject_shake_pixels),
			randf_range(-grab_reject_shake_pixels, grab_reject_shake_pixels)
		)
		closed_hand_sprite_2d.position = _closed_hand_base_pos + offset
		await get_tree().process_frame

	closed_hand_sprite_2d.position = _closed_hand_base_pos

	await get_tree().create_timer(grab_reject_hold_time).timeout

	is_grabbing = false
	held_body = null
	_update_hand_sprite()
	_rejecting_grab = false

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
	if held_interactable and "grip_multiplier" in held_interactable:
		return held_interactable.grip_multiplier
	if body.has_meta("grip_multiplier"):
		return float(body.get_meta("grip_multiplier"))
	if body.is_in_group("slippery"):
		return slippery_grip_multiplier
	return 1.0

func _get_interactable(body: Node) -> Node:
	for child in body.get_children():
		if child.has_signal("grabbed"):
			return child
	return null

func _apply_hold_force(delta: float) -> void:
	if not is_grabbing:
		return
	if not is_instance_valid(held_body):
		_restore_held_body()
		held_body = null
		held_interactable = null
		return
	
	if held_interactable and held_interactable.has_method("on_hold_process"):
		held_interactable.on_hold_process(self, delta)
	
	var target_position := global_position + hold_offset
	var to_target := target_position - held_body.global_position
	var grip_multiplier := _get_grip_multiplier(held_body)
	if to_target.length() > max_hold_distance * grip_multiplier:
		drop_audio_stream_player_2d.play()
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
	if not held_body_had_collision_exception:
		held_body.remove_collision_exception_with(self)
		remove_collision_exception_with(held_body)
