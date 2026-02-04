class_name Hand
extends CharacterBody2D

@export_category("Node References")
## Sprite used when the hand is open (idle)
@export var open_hand_sprite_2d: Sprite2D
## Sprite used when the hand is closed (grabbing/holding)
@export var closed_hand_sprite_2d: Sprite2D
## Area used to detect grabbable objects
@export var grab_area_2d: Area2D
@export var grab_center_marker_2d: Marker2D

@export_category("FX Node References")
@onready var blood_particles: CPUParticles2D = $FX/BloodParticles

@export_category("SFX Node References")
## Audio player for the grab sound effect
@export var grab_audio_stream_player_2d: AudioStreamPlayer2D
## Audio player for the drop sound effect
@export var drop_audio_stream_player_2d: AudioStreamPlayer2D
@onready var injured_audio_player: AudioStreamPlayer2D = $SFX/InjuredAudioPlayer

@export_category("Hand Settings")
## Maximum distance the hand can be from the held object before it's released
@export var max_hold_distance: float = 300.0
## Friction multiplier for objects in the "slippery" group
@export var slippery_grip_multiplier: float = 0.35
## Base speed at which the held object follows the hand
@export var follow_speed: float = 18.0
## Minimum follow speed to prevent items from lagging too far behind
@export var min_follow_speed: float = 6.0
## Sensitivity multiplier for mouse delta movement
@export var mouse_sensitivity: float = 1.2
## Maximum speed the hand can move per frame
@export var max_speed: float = 3000.0
## Damping factor to smooth hand movement (0-1, higher = more damping)
@export var movement_damping: float = 0.85
## Rotation speed when articulating a held body (alt action)
@export var articulation_rotation_speed: float = 0.01

@export_category("Grab Feedback")
## how long the hand stays "closed" after a failed grab
@export var grab_reject_hold_time: float = 0.18
## duration of the shake effect on grab rejection
@export var grab_reject_shake_time: float = 0.18
## intensity of the shake effect in pixels
@export var grab_reject_shake_pixels: float = 3.5
## cooldown period before another grab can be attempted after a rejection
@export var grab_reject_cooldown: float = 0.12

enum State { IDLE, GRABBING, HOLDING, REJECTING }
var current_state: State = State.IDLE

var held_body: RigidBody2D = null
var held_interactable: Node = null
var hold_offset: Vector2 = Vector2.ZERO
var held_body_was_frozen: bool = false
var held_body_freeze_mode: RigidBody2D.FreezeMode = RigidBody2D.FREEZE_MODE_STATIC
var held_body_had_collision_exception: bool = false

var _reject_cooldown_until_ms: int = 0
var _closed_hand_base_pos: Vector2 = Vector2.ZERO
var _original_spawn_pos: Vector2 = Vector2.ZERO
var _mouse_delta: Vector2 = Vector2.ZERO
var _held_body_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_closed_hand_base_pos = closed_hand_sprite_2d.position
	_original_spawn_pos = global_position
	_set_state(State.IDLE)

func _set_state(new_state: State) -> void:
	print("[DEBUG_LOG] Hand: Changing state from ", current_state, " to ", new_state)
	# Exit logic for current state
	match current_state:
		State.HOLDING:
			print("[DEBUG_LOG] Hand: Exiting HOLDING state, restoring held body: ", held_body)
			_restore_held_body()
			if held_interactable and held_interactable.has_method(&"on_release"):
				held_interactable.on_release(self)
			held_body = null
			held_interactable = null
		State.REJECTING:
			closed_hand_sprite_2d.position = _closed_hand_base_pos
	
	current_state = new_state
	
	# Entry logic for new state
	match current_state:
		State.IDLE:
			_update_hand_sprite(false)
		State.GRABBING, State.HOLDING, State.REJECTING:
			_update_hand_sprite(true)
	
	if current_state == State.IDLE:
		if drop_audio_stream_player_2d and not drop_audio_stream_player_2d.is_playing():
			drop_audio_stream_player_2d.play()

func _physics_process(delta: float) -> void:
	match current_state:
		State.IDLE, State.GRABBING:
			_update_velocity_towards_mouse(delta)
		State.HOLDING:
			if !is_instance_valid(held_body):
				print("[DEBUG_LOG] Hand: held_body is INVALID. Releasing.")
				_set_state(State.IDLE)
			else:
				if Input.is_action_pressed("hand_alt"):
					_articulate_held_body()
				else:
					_update_velocity_towards_mouse(delta)
				_apply_hold_force(delta)
		State.REJECTING:
			velocity = Vector2.ZERO

	_mouse_delta = Vector2.ZERO
	_apply_collision_impulses()
	move_and_slide()
	
	# Fail-safe release
	if not Input.is_action_pressed("hand_grab") and current_state != State.IDLE and current_state != State.REJECTING:
		_set_state(State.IDLE)

func _articulate_held_body() -> void:
	var rotation_amount: float = _mouse_delta.x * articulation_rotation_speed
	var pivot: Marker2D = held_body.get_node_or_null(^"PivotMarker2D")
	if pivot:
		var pivot_global_pos := pivot.global_position
		held_body.global_position = pivot_global_pos + (held_body.global_position - pivot_global_pos).rotated(rotation_amount)
		held_body.rotation += rotation_amount
		hold_offset = held_body.global_position - global_position
	else:
		held_body.rotation += rotation_amount
	velocity = Vector2.ZERO

func _update_velocity_towards_mouse(delta: float) -> void:
	# Apply mouse delta as velocity, scaled by sensitivity
	var delta_velocity := _mouse_delta * mouse_sensitivity
	velocity += delta_velocity

	# Clamp to max speed
	if velocity.length() > max_speed:
		velocity = velocity.normalized() * max_speed

	# Apply damping for smooth deceleration
	velocity *= movement_damping


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
	
	if event.is_action_pressed("player_reset"):
		reset_to_spawn()
	
	if event.is_action_released("hand_grab"):
		if current_state != State.REJECTING:
			_set_state(State.IDLE)
	elif event.is_action_pressed("hand_grab"):
		_try_grab()

func _try_grab() -> void:
	if current_state == State.REJECTING or Time.get_ticks_msec() < _reject_cooldown_until_ms:
		return
	
	if !grab_audio_stream_player_2d.is_playing():
		grab_audio_stream_player_2d.play()
	
	var candidate := _find_grabbable_body()
	if not candidate:
		_set_state(State.GRABBING)
		return

	var interactable := _get_interactable(candidate)
	if _is_grab_rejected(candidate, interactable):
		_start_rejection(candidate, interactable)
		return

	# Success
	held_body = candidate
	held_interactable = interactable
	hold_offset = held_body.global_position - global_position
	_prepare_held_body()
	_set_state(State.HOLDING)
	
	if held_interactable and held_interactable.has_method(&"on_grab"):
		held_interactable.on_grab(self)
	elif held_body.has_method(&"grab"):
		held_body.call(&"grab", self)

func _is_grab_rejected(body: RigidBody2D, interactable: Node) -> bool:
	if interactable and interactable.has_method(&"can_grab"):
		return not interactable.can_grab(self)
	if body.has_method(&"can_grab"):
		return not body.call(&"can_grab", self)
	return false

func _start_rejection(body: RigidBody2D = null, interactable: Node = null) -> void:
	print("[DEBUG_LOG] Hand: _start_rejection called. current_state: ", current_state)
	if interactable and interactable.has_method(&"on_grab_rejected"):
		interactable.on_grab_rejected(self)
	elif body and body.has_method(&"on_grab_rejected"):
		body.call(&"on_grab_rejected", self)
	
	_set_state(State.REJECTING)
	_reject_cooldown_until_ms = Time.get_ticks_msec() + int((grab_reject_shake_time + grab_reject_hold_time + grab_reject_cooldown) * 1000.0)
	
	# Shake feedback
	var end_time_ms := Time.get_ticks_msec() + int(grab_reject_shake_time * 1000.0)
	while Time.get_ticks_msec() < end_time_ms:
		if current_state != State.REJECTING: break
		closed_hand_sprite_2d.position = _closed_hand_base_pos + Vector2(randf_range(-grab_reject_shake_pixels, grab_reject_shake_pixels), randf_range(-grab_reject_shake_pixels, grab_reject_shake_pixels))
		await get_tree().process_frame
	
	if current_state == State.REJECTING:
		closed_hand_sprite_2d.position = _closed_hand_base_pos
		await get_tree().create_timer(grab_reject_hold_time).timeout
		if current_state == State.REJECTING:
			_set_state(State.IDLE)

func _prepare_held_body() -> void:
	held_body.global_position = grab_center_marker_2d.global_position # TODO FIX
	held_body_was_frozen = held_body.freeze
	held_body_freeze_mode = held_body.freeze_mode
	print("[DEBUG_LOG] Hand: Preparing body. Original freeze: ", held_body_was_frozen, " freeze_mode: ", held_body_freeze_mode)
	held_body.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	held_body.freeze = true
	held_body_had_collision_exception = held_body.get_collision_exceptions().has(self)
	if not held_body_had_collision_exception:
		held_body.add_collision_exception_with(self)
		add_collision_exception_with(held_body)

func _update_hand_sprite(closed: bool) -> void:
	open_hand_sprite_2d.visible = !closed
	closed_hand_sprite_2d.visible = closed

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
	if not is_instance_valid(held_body):
		return
	
	if held_interactable and held_interactable.has_method(&"on_hold_process"):
		held_interactable.on_hold_process(self, delta)
	
	if not is_instance_valid(held_body) or current_state != State.HOLDING:
		return
	
	var target_position := global_position + hold_offset
	var to_target := target_position - held_body.global_position
	var grip_multiplier := _get_grip_multiplier(held_body)
	
	if to_target.length() > max_hold_distance * grip_multiplier:
		_set_state(State.IDLE)
		return
		
	var mass : float = max(held_body.mass, 0.01)
	var tuned_follow_speed : float = max(follow_speed / mass, min_follow_speed)
	
	var new_pos: Vector2 = held_body.global_position.lerp(target_position, clamp(tuned_follow_speed * delta, 0.0, 1.0))
	_held_body_velocity = (new_pos - held_body.global_position) / delta
	held_body.global_position = new_pos

func _restore_held_body() -> void:
	print("[DEBUG_LOG] Hand: Restoring body: ", held_body)
	if not is_instance_valid(held_body):
		print("[DEBUG_LOG] Hand: held_body is NOT valid in _restore_held_body")
		return
	
	print("[DEBUG_LOG] Hand: Setting freeze to ", held_body_was_frozen)
	# Use set_deferred if we are in a physics callback
	held_body.set_deferred(&"freeze", held_body_was_frozen)
	held_body.freeze_mode = held_body_freeze_mode
	print("[DEBUG_LOG] Hand: Body freeze is now: ", held_body.freeze, " (deferred set to ", held_body_was_frozen, ")")
	
	if not held_body_was_frozen:
		held_body.set_deferred(&"linear_velocity", _held_body_velocity)
		# Wake up the body if it's sleeping
		if held_body.has_method(&"set_sleeping"):
			held_body.set_deferred(&"sleeping", false)
	
	if not held_body_had_collision_exception:
		held_body.remove_collision_exception_with(self)
		remove_collision_exception_with(held_body)


func reset_to_spawn() -> void:
	print("[DEBUG_LOG] Hand: Resetting to spawn: ", _original_spawn_pos)
	_set_state(State.IDLE)
	global_position = _original_spawn_pos
	velocity = Vector2.ZERO


func _on_vulnerable_area_2d_area_entered(_area: Area2D) -> void:
	print("[DEBUG_LOG] Hand: Vulnerable area entered. Held body: ", held_body)
	if current_state == State.HOLDING:
		print("[DEBUG_LOG] Hand: Was holding, transitioning to REJECTING")
		# Zero out momentum so the egg falls gently and can be caught
		_held_body_velocity = Vector2.ZERO
	_start_rejection()

	if blood_particles:
		blood_particles.restart()
		blood_particles.emitting = true

	if injured_audio_player:
		injured_audio_player.play()

	if drop_audio_stream_player_2d and not drop_audio_stream_player_2d.is_playing():
		drop_audio_stream_player_2d.play()
