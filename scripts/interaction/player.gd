class_name Player
extends RigidBody3D

signal score_changed(player_id: GameManager.PlayerId, addition: int)

enum StaminaState { USE, COMPLETE_REGEN }

@export var player_id: GameManager.PlayerId = GameManager.PlayerId.PLAYER_1
@onready var device_id: int = ControllerRegistry.get_controller_id(player_id)

@export var max_stamina = 100
@export var stamina_regeneration = 33
@export var stamina_depletion = 10
@export var capture_duration: float = 0.35

var input: Vector2 = Vector2.ZERO
var do_suck: bool = false

var stamina_state: StaminaState = StaminaState.USE
@onready var stamina: float = max_stamina

@export var acceleration: float = 30.0
@export var deceleration: float = 40.0
@export var max_velocity: float = 10.0

@export var invert_controls: bool = false
@onready var inversion_factor: float = -1.0 if invert_controls else 1.0

@export var rotation_speed: float = 5.0

var right_pressed: bool = false
var left_pressed: bool = false
var up_pressed: bool = false
var down_pressed: bool = false

var red_pressed: bool = false
var blue_pressed: bool = false
var green_pressed: bool = false
var yellow_pressed: bool = false

var disabled: bool = true
var stun_time_left: float = 0.0
var is_stunned: bool:
	get: return stun_time_left > 0.0
var fresh_stun: bool = false

@onready var model: Node3D = $Rig_Medium
@onready var animations: AnimationPlayer = $AnimationPlayer
@onready var suction_point: Node3D = $"Rig_Medium/Area3D/Suction Point"
@onready var suction: Area3D = $Rig_Medium/Area3D

func _ready() -> void:
	suction.body_entered.connect(_on_suction_body_entered)
	match player_id:
		GameManager.PlayerId.PLAYER_1:
			remove_child($Ranger)
		
		GameManager.PlayerId.PLAYER_2:
			remove_child($Mage)

func _get_button(event: InputEvent, action: StringName, current_value: bool) -> bool:
	if event.is_action_pressed(action):
		return true
	
	if event.is_action_released(action):
		return false
	
	return current_value

func _input(event: InputEvent) -> void:
	if event.device != device_id:
		return
	
	red_pressed = _get_button(event, "Red", red_pressed)
	blue_pressed = _get_button(event, "Blue", blue_pressed)
	green_pressed = _get_button(event, "Green", green_pressed)
	yellow_pressed = _get_button(event, "Yellow", yellow_pressed)
	
	do_suck = red_pressed or blue_pressed or green_pressed or yellow_pressed
	
	right_pressed = _get_button(event, "Right", right_pressed)
	left_pressed = _get_button(event, "Left", left_pressed)
	down_pressed = _get_button(event, "Down", down_pressed)
	up_pressed = _get_button(event, "Up", up_pressed)
	
	input.x = float(right_pressed) - float(left_pressed)
	input.y = float(down_pressed) - float(up_pressed)
	input = input.normalized()

func _process(delta: float) -> void:
	if disabled:
		return
	
	stun_time_left = maxf(0.0, stun_time_left - delta)
	var can_suck: bool = do_suck and not is_stunned
	if can_suck and stamina_state == StaminaState.USE:
		stamina -= stamina_depletion * delta
		suction.process_mode = Node.PROCESS_MODE_INHERIT
		suction.visible = true
	else:
		stamina += stamina_regeneration * delta
		suction.process_mode = Node.PROCESS_MODE_DISABLED
		suction.visible = false
	
	if stamina <= 0.0:
		stamina_state = StaminaState.COMPLETE_REGEN
		stamina = 0.0
	elif stamina >= max_stamina:
		stamina_state = StaminaState.USE
		stamina = max_stamina
	
	var has_input: bool = input.length_squared() > 0.0
	
	if is_stunned and fresh_stun:
		fresh_stun = false
		animations.play("Player/Death_A", 0.2)
	elif has_input:
		animations.play("Player/Running_B", 0.5)
	elif not is_stunned:
		animations.play("Player/Idle_B", 0.5)

func _physics_process(delta: float) -> void:
	if disabled or is_stunned:
		return
	
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


func _on_game_play_started() -> void:
	disabled = false

func _on_game_play_ended() -> void:
	animations.play("Player/Idle_B", 0.5)
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	suction.process_mode = Node.PROCESS_MODE_DISABLED
	suction.visible = false
	disabled = true

func _on_suction_body_entered(body: Node3D) -> void:
	if disabled or not body is Ghost:
		return
	_capture_ghost(body)

func stun(duration: float) -> void:
	fresh_stun = true
	stun_time_left = maxf(duration, stun_time_left)

func _capture_ghost(ghost: Ghost) -> void:
	if ghost.is_captured:
		return
	
	ghost.begin_capture.call_deferred()
	
	score_changed.emit(player_id, ghost.point_value)
	
	var start_position := ghost.global_position
	
	# The tween belongs to the player, so it keeps running even though the ghost is disabled.
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ghost, "scale", Vector3.ONE * 0.01, capture_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# tween_method re-reads the target each frame, so the ghost follows the moving nozzle.
	tween.tween_method(func(t: float) -> void:
		if is_instance_valid(ghost):
			ghost.global_position = start_position.lerp(suction_point.global_position, t),
		0.0, 1.0, capture_duration) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ghost.queue_free)
