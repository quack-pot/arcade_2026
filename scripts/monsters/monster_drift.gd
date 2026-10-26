extends Node3D

@export var float_speed: float = 3.0
@export var lifetime: float = 12.0

var timer: float = 0.0

func _ready() -> void:
	var children = get_children()
	if not children.is_empty():
		var random_child = children.pick_random() as Node3D
		random_child.process_mode = Node.PROCESS_MODE_INHERIT
		random_child.visible = true

func _process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
		return
	
	position += transform.basis.z * (float_speed * delta)
