class_name Fireball
extends Area3D
## Flies in a straight line. Stuns the first player it touches, then disappears.
##
## Scene: Area3D (this script) + CollisionShape3D (small sphere) + mesh/particles.
## Collision mask must include the players' layer (and walls, if you want it to
## stop on them). Leave the ghosts' layer out of the mask.

@export var speed: float = 10.0
@export var lifetime: float = 4.0
@export var stun_duration: float = 1.5

var direction: Vector3 = Vector3.FORWARD

var _age: float = 0.0
var _spent: bool = false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


## Call after the fireball has been added to the scene tree.
func launch(from: Vector3, dir: Vector3) -> void:
	global_position = from
	dir.y = 0.0
	direction = dir.normalized() if dir.length_squared() > 0.0001 else Vector3.FORWARD
	rotation.y = atan2(-direction.x, -direction.z)


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node3D) -> void:
	if _spent or body is Ghost:
		return
	_spent = true
	if body.has_method("stun"):
		body.stun(stun_duration)
	queue_free()
