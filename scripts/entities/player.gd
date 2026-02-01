extends RigidBody2D


const SPEED: float = 2000.0
const JUMP_VELOCITY: float = -200.0
const MAX_CHARGE_TIME: float = 1.0
const MAX_JUMP_MULTIPLIER: float = 1.5
const ROLL_SPEED: float = 0.05

var jump_charge := 0.0
var is_charging := false
var is_on_floor := false
var was_on_floor := false
var landing_momentum_timer := 0.0

@onready var sprite: Sprite2D = $PlayerSprite2D
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
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
		apply_central_force(Vector2(direction * current_speed, 0.0))
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
	apply_central_impulse(Vector2(0.0, JUMP_VELOCITY * multiplier * 2.0))
	is_charging = false
	jump_charge = 0.0
