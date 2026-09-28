class_name Player
extends RigidBody3D

@export var player_id: int = 1
@export var device_id: int = 0

var input: Vector2 = Vector2.ZERO

@export var acceleration: float = 30.0
@export var deceleration: float = 40.0
@export var max_velocity: float = 10.0

@export var invert_controls: bool = false
var inversion_factor: float

@export var rotation_speed: float = 5.0

var right_pressed := false
var left_pressed := false
var up_pressed := false
var down_pressed := false

@onready var model: Node3D = $Rig_Medium
@onready var animations: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	inversion_factor = -1.0 if invert_controls else 1.0

func _input(event: InputEvent) -> void:
	if event.device != device_id:
		return
	
	if event.is_action_pressed("Right"):
		right_pressed = true
	elif event.is_action_released("Right"):
		right_pressed = false
	
	if event.is_action_pressed("Left"):
		left_pressed = true
	elif event.is_action_released("Left"):
		left_pressed = false
	
	if event.is_action_pressed("Down"):
		down_pressed = true
	elif event.is_action_released("Down"):
		down_pressed = false
	
	if event.is_action_pressed("Up"):
		up_pressed = true
	elif event.is_action_released("Up"):
		up_pressed = false
	
	input.x = float(right_pressed) - float(left_pressed)
	input.y = float(down_pressed) - float(up_pressed)
	input = input.normalized()

func _process(delta: float) -> void:
	var has_input: bool = input.length_squared() > 0.0
	
	if has_input:
		animations.play("Player/Running_B", 0.5)
	else:
		animations.play("Player/Idle_B", 0.5)

func _physics_process(delta: float) -> void:
	var has_input: bool = input.length_squared() > 0.0
	var frame_acceleration: float = acceleration if has_input else deceleration
	var target_velocity := Vector3(
		input.y * -inversion_factor,
		0.0,
		input.x * inversion_factor
	) * max_velocity
	
	linear_velocity = linear_velocity.move_toward(
		target_velocity,
		frame_acceleration * delta
	)
	
	if has_input:
		var target_rotation := atan2(
			input.y * -inversion_factor,
			input.x * inversion_factor
		)
		
		var rotation_difference := angle_difference(
			rotation.y,
			target_rotation
		)
		
		angular_velocity.y = rotation_difference * rotation_speed
	else:
		angular_velocity.y = 0.0
