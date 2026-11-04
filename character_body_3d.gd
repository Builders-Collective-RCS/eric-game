
extends CharacterBody3D

@export var throw_target: Node3D
@export var speed: float = 4.0
@export var pickup_distance: float = 1.2
@export var throw_power: float = 15.0
@export var hold_time: float = 1.0
@export var reenable_pickup_distance: float = 3.0

@export var arena_center: Vector3 = Vector3(-16, 0, 0)
@export var arena_half_size: float = 15.0

@onready var camera: Camera3D = get_node_or_null("CameraPivot/Camera3D")

enum AIState { CHASING, HOLDING, THROWING, WAITING }

var state = AIState.CHASING
var ball_to_chase: CharacterBody3D = null
var can_pickup_ball: bool = true


func _ready():
	if camera == null:
		camera = get_node_or_null("Camera3D")

	ball_to_chase = get_tree().get_first_node_in_group("Ball")


func _physics_process(delta: float):

	var margin = 0.5

	var min_x = arena_center.x - arena_half_size + margin
	var max_x = arena_center.x + arena_half_size - margin
	var min_z = arena_center.z - arena_half_size + margin
	var max_z = arena_center.z + arena_half_size - margin

	if state == AIState.CHASING:

		if not is_instance_valid(ball_to_chase):
			ball_to_chase = get_tree().get_first_node_in_group("Ball")

		if is_instance_valid(ball_to_chase):

			var direction = ball_to_chase.global_position - global_position
			direction.y = 0

			var distance = direction.length()

			var ball_inside_arena = (
				ball_to_chase.global_position.x >= min_x
				and ball_to_chase.global_position.x <= max_x
				and ball_to_chase.global_position.z >= min_z
				and ball_to_chase.global_position.z <= max_z
			)

			if not can_pickup_ball:
				if distance > reenable_pickup_distance:
					can_pickup_ball = true

			if not ball_inside_arena:
				velocity.x = 0
				velocity.z = 0

			elif distance <= pickup_distance and can_pickup_ball:
				velocity.x = 0
				velocity.z = 0
				start_pickup(ball_to_chase)

			elif distance > 0.01:
				direction = direction.normalized()
				velocity.x = direction.x * speed
				velocity.z = direction.z * speed

			else:
				velocity.x = 0
				velocity.z = 0

		else:
			velocity.x = 0
			velocity.z = 0

	else:
		velocity.x = 0
		velocity.z = 0

	# WAIT FOR BALL TO RESPAWN
	if state == AIState.WAITING:

		if is_instance_valid(ball_to_chase):

			if not ball_to_chase.is_thrown:
				state = AIState.CHASING
				can_pickup_ball = true
				print("BALL RESPAWNED! AI CHASING AGAIN!")

	# Keep AI inside arena
	if global_position.x <= min_x and velocity.x < 0:
		velocity.x = 0

	if global_position.x >= max_x and velocity.x > 0:
		velocity.x = 0

	if global_position.z <= min_z and velocity.z < 0:
		velocity.z = 0

	if global_position.z >= max_z and velocity.z > 0:
		velocity.z = 0

	if not is_on_floor():
		velocity += get_gravity() * delta

	move_and_slide()


func start_pickup(ball: CharacterBody3D):

	if state != AIState.CHASING or not can_pickup_ball:
		return

	if not is_instance_valid(ball):
		return

	can_pickup_ball = false
	state = AIState.HOLDING

	print("BALL PICKED UP!")

	velocity.x = 0
	velocity.z = 0

	# Stop ball movement
	ball.velocity = Vector3.ZERO
	ball.set_physics_process(false)

	# Attach ball to AI
	ball.reparent(self, true)

	# Hold ball away from camera
	ball.position = Vector3(1.0, 1.0, -0.5)

	await get_tree().create_timer(hold_time).timeout

	if not is_instance_valid(ball):
		state = AIState.CHASING
		ball_to_chase = null
		return

	if not is_instance_valid(throw_target):
		push_error("THROW TARGET IS NOT ASSIGNED!")
		ball.reparent(get_tree().current_scene, true)
		ball.set_physics_process(true)
		state = AIState.CHASING
		ball_to_chase = ball
		can_pickup_ball = true
		return

	state = AIState.THROWING

	# Get receiver's actual world position
	var target_position = throw_target.global_position + Vector3.UP

	# Detach ball
	ball.reparent(get_tree().current_scene, true)

	# Calculate initial direction toward receiver
	var direction = target_position - global_position

	if direction.length_squared() < 0.001:
		direction = -global_transform.basis.z

	direction = direction.normalized()

	# Position ball in front of AI
	ball.global_position = global_position + Vector3.UP * 1.5 + direction * 1.0

	# Assign receiver BEFORE throwing
	ball.current_target = throw_target

	# Enable ball physics
	ball.velocity = Vector3.ZERO
	ball.set_physics_process(true)
	ball.show()

	# Throw using the ball's actual target position
	ball.throw_ball(throw_power)

	print("BALL THROWN!")
	print("TARGET: ", throw_target.global_position)
	print("BALL POSITION: ", ball.global_position)

	# Wait for ball to reach receiver
	ball_to_chase = ball
	state = AIState.WAITING

	print("AI WAITING FOR BALL!")
