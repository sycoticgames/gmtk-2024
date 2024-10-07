extends CharacterBody3D

@onready var anchor = $Anchor
@onready var camera = $Anchor/Camera
@onready var mesh = $Mesh

@onready var girl = $"Mesh/character-female-b2"
@onready var boy = $"Mesh/character-male-d2"
@onready var animation_tree = $Mesh/AnimationTree
@onready var animation_state = $Mesh/AnimationTree.get("parameters/playback")

@onready var block_check = $Anchor/Camera/BlockCheck

@onready var crosshair = $Anchor/Camera/BlockCheck/Crosshair

#ORBIT
const ORBIT_SPEED := 0.5
var _orbit_speed := Vector2()
#MOVEMENT
const SPEED = 5.0
const CLIMB_SPEED = 2.5
const JUMP_VELOCITY = 4.5
var direction: Vector3
#ZOOM
const SCROLL_SPEED := 25.0
const ZOOM_MIN := 1.0
const ZOOM_MAX := 15.0
var _scroll_speed := 0.0

func _ready():
	anchor.basis = basis
	boy.visible = false
	girl.visible = true
	pass

func _process(delta):
	if direction != Vector3.ZERO:
		mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(direction.x, direction.z), SPEED * delta)
	
	var block = block_check.get_collider()
	if is_instance_valid(block):
		crosshair.set_surface_override_material(0, preload("res://assets/materials/crosshair_hover.tres"))
	else:
		crosshair.set_surface_override_material(0, preload("res://assets/materials/crosshair.tres"))

func _physics_process(delta):
	if Global.current_gamemode != Global.GameMode.SCALE:
		if not is_on_floor():
			velocity += get_gravity() * delta
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		move_and_slide()
		return
	
	var input_dir = Input.get_vector("move_left", "move_right", "move_backward", "move_forward")
	if not is_on_floor():
		velocity += get_gravity() * 2 * delta
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY * 1.5
		animation_tree.set("parameters/conditions/is_jumping", true)
		animation_tree.set("parameters/conditions/is_grounded", false)
	if is_on_floor():
		animation_tree.set("parameters/conditions/is_jumping", false)
		animation_tree.set("parameters/conditions/is_grounded", true)

	direction = (transform.basis * Vector3(-input_dir.x, 0, input_dir.y)).normalized()
	direction = direction.rotated(Vector3.UP, anchor.rotation.y).normalized()
	
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
	animation_tree.set("parameters/IdleWalkRun/blend_position", velocity.length()/SPEED)
	if Global.current_gamemode == Global.GameMode.SCALE:
		move_and_slide()
	
	if global_position.y <= -5.0:
		global_position = Vector3(0,1.25,0)
	
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		anchor.rotate_y(-_orbit_speed.x * delta)
		camera.rotate_x(_orbit_speed.y * delta)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-45), deg_to_rad(60))
		_orbit_speed = Vector2()
	
	var new_camera_zoom = camera.position.move_toward(anchor.position, -_scroll_speed * delta)
	new_camera_zoom.y += _scroll_speed * delta * 0.5
	if new_camera_zoom.distance_to(anchor.position) < ZOOM_MAX && new_camera_zoom.distance_to(anchor.position) > ZOOM_MIN:
		camera.position = new_camera_zoom
	_scroll_speed = 0.0

func _input(event):
	if Global.current_gamemode != Global.GameMode.SCALE:
		return
	if event is InputEventMouseMotion:
		_orbit_speed = event.relative * ORBIT_SPEED
		
	var scroll_input = Input.get_axis("zoom_in_camera", "zoom_out_camera")
	if scroll_input != 0:
		_scroll_speed = scroll_input * SCROLL_SPEED
		
	if event.is_action_pressed("select"):
		_check_for_block()
	if event.is_action_released("select"):
		animation_tree.set("parameters/conditions/dropped_block", true)
		animation_tree.set("parameters/conditions/is_holding_block", false)

func _check_for_block():
	var block = block_check.get_collider()
	if is_instance_valid(block):
		animation_tree.set("parameters/conditions/dropped_block", false)
		animation_tree.set("parameters/conditions/is_holding_block", true)
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
