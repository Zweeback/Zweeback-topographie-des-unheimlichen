extends CharacterBody3D

@export var move_speed := 6.0
@export var mouse_sensitivity := 0.0025

var camera_pivot: Node3D
var camera: Camera3D
var pitch := deg_to_rad(-10.0)

func _ready() -> void:
	_build_body()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build_body() -> void:
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	add_child(collision)

	var mesh_instance := MeshInstance3D.new()
	var capsule_mesh := CapsuleMesh.new()
	capsule_mesh.radius = 0.45
	capsule_mesh.height = 1.8
	mesh_instance.mesh = capsule_mesh
	mesh_instance.position.y = 0.9
	add_child(mesh_instance)

	camera_pivot = Node3D.new()
	camera_pivot.position = Vector3(0.0, 1.35, 0.0)
	camera_pivot.rotation.x = pitch
	add_child(camera_pivot)

	var arm := SpringArm3D.new()
	arm.spring_length = 4.5
	arm.margin = 0.15
	camera_pivot.add_child(arm)

	camera = Camera3D.new()
	camera.current = true
	arm.add_child(camera)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	var input_vec := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_A):
		input_vec.x -= 1.0
	if Input.is_physical_key_pressed(KEY_D):
		input_vec.x += 1.0
	if Input.is_physical_key_pressed(KEY_W):
		input_vec.y -= 1.0
	if Input.is_physical_key_pressed(KEY_S):
		input_vec.y += 1.0
	input_vec = input_vec.normalized()

	var direction := (transform.basis * Vector3(input_vec.x, 0.0, input_vec.y)).normalized()
	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 5.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 5.0 * delta)

	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		pitch = clampf(pitch - event.relative.y * mouse_sensitivity, deg_to_rad(-55.0), deg_to_rad(35.0))
		camera_pivot.rotation.x = pitch
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
