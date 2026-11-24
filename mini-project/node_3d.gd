
extends Node3D

@export var ball: Node3D
@export var other_character: Node3D
@export var ai: CharacterBody3D

@export var smooth_speed: float = 5.0
@export var target_height: float = 1.0

@onready var camera: Camera3D = $Camera3D


func _ready():
	camera.position = Vector3.ZERO
	camera.rotation = Vector3.ZERO


func _process(delta: float):

	if not is_instance_valid(ai):
		return

	var target: Node3D = null

	if ai.state == 0:
		target = ball
	else:
		target = other_character

	if not is_instance_valid(target):
		return

	var target_position = target.global_position + Vector3.UP * target_height

	# Convert target position into pivot parent's local space
	var local_target = get_parent().to_local(target_position)

	# Direction from pivot to target
	var local_direction = local_target - position

	if local_direction.length_squared() < 0.001:
		return

	# Calculate desired local rotation
	var desired_basis = Basis.looking_at(
		local_direction.normalized(),
		Vector3.UP
	)

	var weight = 1.0 - exp(-smooth_speed * delta)

	# Smoothly rotate pivot
	quaternion = quaternion.slerp(
		desired_basis.get_rotation_quaternion(),
		weight
	).normalized()
