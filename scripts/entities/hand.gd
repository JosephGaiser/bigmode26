class_name Hand
extends CharacterBody2D

@export_category("Node References")
@export var open_hand_sprite_2d: Sprite2D
@export var closed_hand_sprite_2d: Sprite2D
@export var grab_area_2d: Area2D

@export_category("FX Node References")
@onready var blood_particles: CPUParticles2D = $FX/BloodParticles

@export_category("SFX Node References")
@export var grab_audio_stream_player_2d: AudioStreamPlayer2D
@export var drop_audio_stream_player_2d: AudioStreamPlayer2D
@onready var injured_audio_player: AudioStreamPlayer2D = $SFX/InjuredAudioPlayer

@export_category("Hand Settings")
@export var max_hold_distance: float = 300.0
@export var slippery_grip_multiplier: float = 0.35
@export var follow_speed: float = 18.0
@export var min_follow_speed: float = 6.0
@export var speed: float = 2200.0
@export var articulation_rotation_speed: float = 0.01

@export_category("Grab Feedback")
## how long the hand stays "closed" after a failed grab
@export var grab_reject_hold_time: float = 0.18
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
var _mouse_delta: Vector2 = Vector2.ZERO
var _held_body_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	_closed_hand_base_pos = closed_hand_sprite_2d.position

func _process(delta: float) -> void:
	if _rejecting_grab:
		return

func _physics_process(delta: float) -> void:
	if _rejecting_grab:
		velocity = Vector2.ZERO
		move_and_slide()
		# We still want to reset _mouse_delta even during rejection
		_mouse_delta = Vector2.ZERO
		return

	if is_grabbing:
		if held_body:
			if !is_instance_valid(held_body):
				print("[DEBUG_LOG] Hand _physics_process: held_body is INVALID while holding. Releasing.")
				release()
			else:
				if Input.is_action_pressed("hand_alt"):
					# Articulate the held object
					var rotation_amount: float = _mouse_delta.x * articulation_rotation_speed
					
					var pivot: Marker2D = held_body.get_node_or_null(^"PivotMarker2D")
					if pivot:
						var pivot_global_pos := pivot.global_position
						held_body.global_position = pivot_global_pos + (held_body.global_position - pivot_global_pos).rotated(rotation_amount)
						held_body.rotation += rotation_amount
						# Update hold_offset so the object stays in its new relative position to the hand
						hold_offset = held_body.global_position - global_position
					else:
						held_body.rotation += rotation_amount
					
					# We still want to apply hold force to keep it in place relative to hand
					# But we don't move the hand itself
					velocity = Vector2.ZERO
				else:
					_update_velocity_towards_mouse(delta)
		else:
			# Not holding anything but hand is closed (e.g. grabbing air or during rejection)
			_update_velocity_towards_mouse(delta)
	else:
		_update_velocity_towards_mouse(delta)
	
	_mouse_delta = Vector2.ZERO # reset for next frame
	_apply_hold_force(delta)
	_apply_collision_impulses()
	move_and_slide()
	
	# If mouse is released, ensure we release even if we didn't get the InputEvent
	if not Input.is_action_pressed("hand_grab") and is_grabbing:
		release()

func _update_velocity_towards_mouse(delta: float) -> void:
	var target: Vector2 = get_global_mouse_position()
	var target_direction: Vector2 = (target - global_position)
	velocity = target_direction.normalized() * min(speed, target_direction.length() / delta)


func _apply_collision_impulses() -> void:
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var body := collision.get_collider()
		
		if body is RigidBody2D and body != held_body:
			var impulse_direction := -collision.get_normal()
			var push_force := velocity.dot(impulse_direction)
			
			if push_force > 0:
				var impulse : Vector2 = impulse_direction * push_force * body.mass * 0.05
				body.apply_central_impulse(impulse)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_mouse_delta = event.relative
	
	if event.is_action_released("hand_grab"):
		release()
	elif event.is_action_pressed("hand_grab"):
		grab()

func release() -> void:
	# Always ensure these are reset
	_rejecting_grab = false
	is_grabbing = false
	
	if drop_audio_stream_player_2d and not drop_audio_stream_player_2d.is_playing():
		drop_audio_stream_player_2d.play()
	
	_restore_held_body()
	
	if held_interactable and held_interactable.has_method("on_release"):
		held_interactable.on_release(self)
		
	held_body = null
	held_interactable = null
	_update_hand_sprite()
	closed_hand_sprite_2d.position = _closed_hand_base_pos

func grab() -> void:
	if _rejecting_grab:
		return
	if Time.get_ticks_msec() < _reject_cooldown_until_ms:
		return
	if !grab_audio_stream_player_2d.is_playing():
		grab_audio_stream_player_2d.play()
	
	# If we're already holding something, release it first (though release() is usually called by input)
	if held_body:
		release()

	# Optimistically show the closed hand
	is_grabbing = true
	_update_hand_sprite()

	var candidate := _find_grabbable_body()
	if not candidate:
		# Just keeping the hand closed is fine, no need to return early if we want to allow "grabbing air"
		return

	var interactable := _get_interactable(candidate)

	# Validation checks
	var cannot_grab = false
	if interactable and interactable.has_method(&"can_grab") and not interactable.can_grab(self):
		cannot_grab = true
	elif not interactable and candidate.has_method(&"can_grab") and not candidate.call(&"can_grab", self):
		cannot_grab = true

	if cannot_grab:
		if interactable and interactable.has_method(&"on_grab_rejected"):
			interactable.on_grab_rejected(self)
		elif not interactable and candidate.has_method(&"on_grab_rejected"):
			candidate.call(&"on_grab_rejected", self)
		
		_play_grab_rejected_feedback()
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
	
	if held_interactable and held_interactable.has_method(&"on_grab"):
		held_interactable.on_grab(self)
	elif held_body.has_method(&"grab"): # fallback for old pattern
		held_body.call(&"grab", self)

func _play_grab_rejected_feedback() -> void:
	if _rejecting_grab:
		return
		
	_rejecting_grab = true
	_reject_cooldown_until_ms = Time.get_ticks_msec() + int((grab_reject_shake_time + grab_reject_hold_time + grab_reject_cooldown) * 1000.0)

	is_grabbing = true
	_update_hand_sprite()

	# Shake effect
	var shake_timer = get_tree().create_timer(grab_reject_shake_time)
	var end_time_ms := Time.get_ticks_msec() + int(grab_reject_shake_time * 1000.0)
	
	while Time.get_ticks_msec() < end_time_ms:
		if not _rejecting_grab:
			break
		var offset := Vector2(
			randf_range(-grab_reject_shake_pixels, grab_reject_shake_pixels),
			randf_range(-grab_reject_shake_pixels, grab_reject_shake_pixels)
		)
		closed_hand_sprite_2d.position = _closed_hand_base_pos + offset
		await get_tree().process_frame

	if not _rejecting_grab:
		return

	closed_hand_sprite_2d.position = _closed_hand_base_pos
	
	# Wait for the hold time
	await get_tree().create_timer(grab_reject_hold_time).timeout
	
	if _rejecting_grab:
		release()

func _update_hand_sprite() -> void:
	if is_grabbing:
		open_hand_sprite_2d.visible = false
		closed_hand_sprite_2d.visible = true
	else:
		open_hand_sprite_2d.visible = true
		closed_hand_sprite_2d.visible = false

func _find_grabbable_body() -> RigidBody2D:
	var closest_body: RigidBody2D = null
	var closest_distance := INF
	for body in grab_area_2d.get_overlapping_bodies():
		if body is RigidBody2D and not body.freeze:
			var distance := global_position.distance_to(body.global_position)
			if distance < closest_distance:
				closest_distance = distance
				closest_body = body
	print("Grabbing on ", closest_body)
	return closest_body

func _get_grip_multiplier(body: RigidBody2D) -> float:
	if held_interactable and &"grip_multiplier" in held_interactable:
		var mult = held_interactable.get(&"grip_multiplier")
		return float(mult)
	if body.has_meta(&"grip_multiplier"):
		var meta_val = body.get_meta(&"grip_multiplier")
		return float(meta_val)
	if body.is_in_group(&"slippery"):
		return slippery_grip_multiplier
	return 1.0

func _get_interactable(body: Node) -> Node:
	for child in body.get_children():
		if child.has_signal(&"grabbed"):
			return child
	return null

func _apply_hold_force(delta: float) -> void:
	if not is_grabbing or not held_body:
		return
		
	if not is_instance_valid(held_body):
		print("[DEBUG_LOG] Hand _apply_hold_force: held_body is INVALID. Releasing.")
		release()
		return
	
	if held_interactable and held_interactable.has_method(&"on_hold_process"):
		held_interactable.on_hold_process(self, delta)
	
	# Check again as on_hold_process might have triggered a release or invalidated it
	if not is_grabbing or not is_instance_valid(held_body):
		return
	
	var target_position := global_position + hold_offset
	var to_target := target_position - held_body.global_position
	var grip_multiplier := _get_grip_multiplier(held_body)
	
	if to_target.length() > max_hold_distance * grip_multiplier:
		release()
		return
		
	var mass : float = max(held_body.mass, 0.01)
	var tuned_follow_speed : float = max(follow_speed / mass, min_follow_speed)
	
	var new_pos: Vector2 = held_body.global_position.lerp(target_position, clamp(tuned_follow_speed * delta, 0.0, 1.0))
	_held_body_velocity = (new_pos - held_body.global_position) / delta
	held_body.global_position = new_pos

func _restore_held_body() -> void:
	if not is_instance_valid(held_body):
		return
	
	held_body.freeze = held_body_was_frozen
	held_body.freeze_mode = held_body_freeze_mode
	
	if not held_body.freeze:
		held_body.linear_velocity = _held_body_velocity
		# Wake up the body if it's sleeping
		if held_body.has_method(&"set_sleeping"):
			held_body.sleeping = false
	
	if not held_body_had_collision_exception:
		held_body.remove_collision_exception_with(self)
		remove_collision_exception_with(held_body)


func _on_vulnerable_area_2d_area_entered(_area: Area2D) -> void:
	# Force a clean state reset
	release()
	
	if drop_audio_stream_player_2d and not drop_audio_stream_player_2d.is_playing():
		drop_audio_stream_player_2d.play()
