class_name Player
extends RigidBody2D

const SPEED: float = 2000.0
const JUMP_VELOCITY: float = -200.0
const MAX_CHARGE_TIME: float = 1.0
const MAX_JUMP_MULTIPLIER: float = 1.5
const ROLL_SPEED: float = 0.05
const CRACK_VELOCITY_THRESHOLD: float = 800.0
const RESPAWN_DELAY: float = 0.5

var jump_charge := 0.0
var is_charging := false
var is_on_floor := false
var was_on_floor := false
var landing_momentum_timer := 0.0
var last_velocity := Vector2.ZERO
var pending_respawn := false
var respawn_timer := 0.0

@export var shell_1: PackedScene
@export var shell_2: PackedScene

@onready var sprite: Sprite2D = $PlayerSprite2D
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var crack_particles: CPUParticles2D = $CrackParticles

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if respawn_timer > 0:
		state.linear_velocity = Vector2.ZERO
		state.angular_velocity = 0.0
		return

	if pending_respawn:
		var spawn_marker = get_tree().get_first_node_in_group(&"spawn_marker")
		if not spawn_marker:
			spawn_marker = get_parent().find_child("PlayerSpawnMarker", true, false)
		
		if spawn_marker:
			state.linear_velocity = Vector2.ZERO
			state.angular_velocity = 0.0
			# Reset rotations and position using transform
			state.transform = Transform2D.IDENTITY.translated(spawn_marker.global_position)
			
			# Reset local variables
			rotation = 0.0
			last_velocity = Vector2.ZERO
			sprite.rotation = 0.0
			collision_shape.rotation = 0.0
			
			# Restore collision layer/mask after respawning
			set_deferred(&"collision_layer", 8) # Layer 4: Player
			set_deferred(&"collision_mask", 7) # Layers 1, 2, 3
			
			sprite.show() # Show sprite again after respawn
		
		pending_respawn = false
		return

	# Check for hard impact (cracking)
	if not freeze and respawn_timer <= 0 and state.get_contact_count() > 0:
		# If the difference between last velocity and current velocity is huge, we hit something hard
		var velocity_change := (state.linear_velocity - last_velocity).length()
		if velocity_change > CRACK_VELOCITY_THRESHOLD:
			_trigger_crack_effects()
	
	last_velocity = state.linear_velocity
			
	# Check if on floor by looking at contacts
	was_on_floor = is_on_floor
	is_on_floor = false
	if state.get_contact_count() > 0:
		for i in range(state.get_contact_count()):
			var normal: Vector2 = state.get_contact_local_normal(i)
			if normal.y < -0.5: # Upward normal
				is_on_floor = true
				break

func _physics_process(delta: float) -> void:
	if respawn_timer > 0 or pending_respawn:
		if respawn_timer > 0:
			respawn_timer -= delta
			if respawn_timer <= 0:
				pending_respawn = true
		return

	# Keep track of landing
	if is_on_floor and not was_on_floor:
		landing_momentum_timer = 0.5 # 0.5 seconds of reduced friction after landing
	
	if landing_momentum_timer > 0:
		landing_momentum_timer -= delta

	# Handle jump charge.
	if Input.is_action_just_pressed("player_jump") and is_on_floor and not freeze:
		is_charging = true
		jump_charge = 0.0
	
	if is_charging:
		if freeze:
			is_charging = false
			jump_charge = 0.0
		elif Input.is_action_pressed("player_jump"):
			jump_charge = min(jump_charge + delta, MAX_CHARGE_TIME)
		else:
			# Jump on release
			perform_jump()

	# Get the input direction and handle the movement/deceleration.
	var direction := Input.get_axis(&"player_left", &"player_right")
	
	# Limited mobility for the egg
	var current_speed: float = SPEED * 0.5
	
	if direction and not freeze:
		var force: Vector2
		force.x = direction * current_speed
		force.y = 0.0
		apply_central_force(force)
	elif is_on_floor and not freeze:
		# Add some artificial friction when no input to stop sliding forever
		# But less when we just landed to preserve some momentum
		var friction: float = 10.0 if landing_momentum_timer <= 0 else 2.0
		linear_velocity.x = move_toward(linear_velocity.x, 0.0, friction)
	
	# Limit horizontal velocity to avoid infinite acceleration
	var max_v: float = 400.0
	
	if not freeze and abs(linear_velocity.x) > max_v:
		linear_velocity.x = move_toward(linear_velocity.x, sign(linear_velocity.x) * max_v, 10.0)
	
	# Handle rolling visual and physics shape
	var rotation_step: float = linear_velocity.x * ROLL_SPEED * delta
	if freeze:
		rotation_step = 0.0
	elif not is_on_floor:
		rotation_step *= 0.5
	
	sprite.rotation += rotation_step
	collision_shape.rotation += rotation_step


func _on_hold_process(_hand: Hand, _delta: float) -> void:
	# Keep the player sprite rotation from going crazy when held
	# and prevent velocity buildup
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0


func perform_jump() -> void:
	if not is_charging:
		return
		
	var multiplier: float = 1.0 + (jump_charge / MAX_CHARGE_TIME) * (MAX_JUMP_MULTIPLIER - 1.0)
	# Physics-based jump needs much more force to overcome gravity and mass
	var impulse: Vector2
	impulse.x = 0.0
	impulse.y = JUMP_VELOCITY * multiplier * 2.0
	apply_central_impulse(impulse)
	is_charging = false
	jump_charge = 0.0


func respawn() -> void:
	_trigger_crack_effects()


func _trigger_crack_effects() -> void:
	# Hide the player sprite and disable collision
	sprite.hide()
	
	# Start respawn timer
	respawn_timer = RESPAWN_DELAY
	
	# Play particle effects
	crack_particles.restart()
	crack_particles.emitting = true
	
	# Spawn egg shells
	var spawned_shells: Array[RigidBody2D] = []
	for shell_scene in [shell_1, shell_2]:
		if shell_scene:
			var shell: RigidBody2D = shell_scene.instantiate()
			spawned_shells.append(shell)
			
			# Put shells on Entities node so they are behind the hand
			var entities_node = get_tree().get_first_node_in_group(&"entities")
			if not entities_node:
				entities_node = get_parent().find_child("Entities", true, false)
			
			if entities_node:
				entities_node.add_child(shell)
			else:
				get_parent().add_child(shell)
				
			shell.global_position = global_position
			
			# Add collision exception so they don't explode the player or each other immediately
			add_collision_exception_with(shell)
			for other_shell in spawned_shells:
				if other_shell != shell:
					shell.add_collision_exception_with(other_shell)

			# Add some random velocity to the shells
			var impulse := Vector2()
			impulse.x = randf_range(-100.0, 100.0)
			impulse.y = randf_range(-200.0, -50.0)
			shell.apply_central_impulse(impulse)
			shell.angular_velocity = randf_range(-5.0, 5.0)
