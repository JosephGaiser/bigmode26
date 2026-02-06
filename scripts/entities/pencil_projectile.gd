class_name PencilProjectile
extends RigidBody2D

@onready var pencil_sprite_2d: Sprite2D = %PencilSprite2D
@onready var hit_audio_stream_player_2d: AudioStreamPlayer2D = %HitAudioStreamPlayer2D
@onready var trail_particles: CPUParticles2D = %TrailParticles
@onready var hazard_area_2d: Area2D = %HazardArea2D
@onready var hazard_collision_shape_2d: CollisionShape2D = %HazardCollisionShape2D

@export var lifetime: float = 10.0  # Destroy after 10 seconds if still exists

var time_alive: float = 0.0

func _ready() -> void:
	hazard_area_2d.connect("body_entered", _on_body_entered)


func _process(delta: float) -> void:
	time_alive += delta

	# Destroy if lifetime exceeded
	if time_alive >= lifetime:
		destroy()

func destroy() -> void:
	queue_free()

func stick() -> void:
	hit_audio_stream_player_2d.play()
	call_deferred("_do_stick")

func _do_stick() -> void:
	trail_particles.emitting = false
	self.freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	self.freeze = true
	linear_velocity = Vector2.ZERO
	angular_velocity = 0.0
	gravity_scale = 0.0
	self.set_collision_mask_value(1, false)
	self.set_collision_mask_value(3, false)
	self.set_collision_mask_value(4, false)
	hazard_area_2d.monitoring = false
	hazard_area_2d.set_collision_layer_value(5, false)
	hazard_area_2d.set_collision_mask_value(2, false)
	hazard_area_2d.set_collision_mask_value(3, false)
	hazard_area_2d.set_collision_mask_value(4, false)

func _on_body_entered(body: Node) -> void:
	if body is StaticBody2D:
		stick()
	if body is Egg:
		body._trigger_crack_effects()
