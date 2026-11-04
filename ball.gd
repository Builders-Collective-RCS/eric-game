
extends CharacterBody3D

@export var area_center: Vector3 = Vector3(-16, 0, 0)
@export var area_size: Vector3 = Vector3(15, 1, 15)
@export var reset_height: float = -5.0
@export var respawn_distance_from_receiver: float = 3.0
@export var minimum_flight_time: float = 1.0
# Ball movement settings
@export var starting_height: float = 1.0
@export var max_flight_time: float = 8.0

var is_thrown: bool = false
var is_held: bool = false
var current_holder: Node3D = null
var current_target: Node3D = null

var flight_timer: float = 0.0


func _ready():
	velocity = Vector3.ZERO
	is_thrown = false
	is_held = false

	# Prevent the ball from falling before it is thrown.
	set_physics_process(true)


func _physics_process(delta: float):

	if is_thrown:

		flight_timer += delta

		# Straight-line movement without gravity.
		move_and_slide()
		
		if flight_timer >= minimum_flight_time:

		# Check whether the ball has reached its target.
			if is_instance_valid(current_target):

				if global_position.distance_to(current_target.global_position) < 1.0:
					print("BALL REACHED TARGET!")
					respawn_ball()
					return

		# Reset if the ball falls off the map.
		if global_position.y < reset_height:
			print("BALL FELL OFF MAP!")
			respawn_ball()
			return

		# Reset if the ball takes too long to reach its target.
		if flight_timer >= max_flight_time:
			print("BALL FLIGHT TIME EXPIRED!")
			respawn_ball()



func throw_ball(power: float):

	if not is_instance_valid(current_target):
		print("ERROR: NO VALID TARGET!")
		return

	is_held = false
	is_thrown = true

	flight_timer = 0.0

	# Calculate direction toward actual target
	var target_position = current_target.global_position + Vector3.UP
	var direction = target_position - global_position

	if direction.length_squared() < 0.001:
		return

	direction = direction.normalized()

	velocity = direction * power

	show()

	print("BALL THROWN!")
	print("BALL POSITION: ", global_position)
	print("TARGET POSITION: ", target_position)
	print("VELOCITY: ", velocity)


	print("BALL THROWN!")
	print("TARGET POSITION: ", current_target.global_position)
	print("BALL POSITION: ", global_position)
	print("VELOCITY: ", velocity)


func respawn_ball():

	is_thrown = false
	is_held = false
	current_holder = null

	velocity = Vector3.ZERO
	flight_timer = 0.0

	# Remember the receiver before clearing the target.
	var receiver = current_target
	current_target = null

	# Find a safe random position.
	for i in range(100):

		var spawn_position = Vector3(
			randf_range(
				area_center.x - area_size.x / 2.0,
				area_center.x + area_size.x / 2.0
			),
			area_center.y + starting_height,
			randf_range(
				area_center.z - area_size.z / 2.0,
				area_center.z + area_size.z / 2.0
			)
		)

		if is_instance_valid(receiver):

			var distance = Vector2(
				spawn_position.x - receiver.global_position.x,
				spawn_position.z - receiver.global_position.z
			).length()

			if distance < respawn_distance_from_receiver:
				continue

		global_position = spawn_position
		show()

		print("BALL RESPAWNED AT: ", spawn_position)
		return

	# Fallback position.
	global_position = area_center + Vector3.UP * starting_height


func _on_area_3d_body_entered(body: Node3D):

	if not is_thrown:
		return

	if not is_instance_valid(current_target):
		return

	if body != current_target:
		return

	print("BALL HIT THE RECEIVER!")

	respawn_ball()
