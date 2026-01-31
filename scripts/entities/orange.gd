class_name Orange
extends RigidBody2D


@export var OrangeSliceScene: PackedScene
@export var slice_audio_stream: AudioStream

@onready var slice_particles: CPUParticles2D = $SliceParticles
@onready var slice_audio_player: AudioStreamPlayer2D = $SliceAudioPlayer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func slice() -> void:
	# Disable collisions immediately to prevent physics issues
	collision_layer = 0
	collision_mask = 0
	freeze = true
	
	if slice_audio_player and slice_audio_stream:
		slice_audio_player.stream = slice_audio_stream
		slice_audio_player.play()
	
	if slice_particles:
		slice_particles.emitting = true
	
	if not OrangeSliceScene:
		# Wait for audio/particles if needed, but for now just queue_free
		# If we want to wait for particles/sound, we should hide the sprite
		$Sprite2D.visible = false
		await get_tree().create_timer(1.0).timeout
		queue_free()
		return
	
	for i in range(2):
		var slice_instance: OrangeSlice = OrangeSliceScene.instantiate()
		get_parent().add_child(slice_instance)
		slice_instance.global_position = global_position + Vector2(randf_range(-10, 10), randf_range(-10, 10))
		if slice_instance is RigidBody2D:
			slice_instance.apply_central_impulse(Vector2(randf_range(-500, 500), randf_range(-500, 500)))
	
	$Sprite2D.visible = false
	# Keep the orange alive for a bit so particles and sound can finish
	await get_tree().create_timer(1.0).timeout
	queue_free()
