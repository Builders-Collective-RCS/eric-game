
extends Node3D

@export var ball: Node3D
@export var other_character: Node3D
@export var ai: CharacterBody3D

@export var smooth_speed: float = 5.0
@export var target_height: float = 1.0

var current_target: Node3D


func _ready():
	current_target = ball


func _process(delta: float):

	if not is_instance_valid(ai):
		return

	# Select the correct target
	if ai.state == 0:
		current_target = ball
	else:
		current_target = other_character

	if not is_instance_valid(current_target):
		return

	# Find target position
	var target_position = (
		current_target.global_position
		+ Vector3.UP * target_height
	)

	# Calculate direction
	var direction = target_position - global_position

	if direction.length_squared() < 0.001:
		return

	# Calculate desired world rotation
	var desired_basis = Basis.looking_at(
		direction.normalized(),
		Vector3.UP
	)

	# Convert world rotation into pivot-local rotation
	var parent_node = get_parent()

	var desired_local_basis = (
		parent_node.global_transform.basis.inverse()
		* desired_basis
	).orthonormalized()

	# Smooth rotation
	var weight = 1.0 - exp(-smooth_speed * delta)

	quaternion = quaternion.slerp(
		desired_local_basis.get_rotation_quaternion(),
		weight
	).normalized()
