class_name GhostFormSwitcher
extends Node
## Shows one mesh while the ghost wanders and another while it charges,
## animating between them. Pure visuals: it only listens to the behavior.
##
## Scene layout:
##   Ghost
##   ├─ WanderChargeBehavior
##   ├─ GhostFormSwitcher        (this script)
##   ├─ WanderForm  (Node3D / MeshInstance3D, any scale)
##   └─ ChargeForm  (Node3D / MeshInstance3D, any scale)

@export var behavior: ChargeBehavior
@export var wander_form: Node3D
@export var charge_form: Node3D

## Total time of the swap (shrink out, then pop in).
@export var transition_time: float = 0.5
## Fraction of transition_time spent shrinking the old form.
@export_range(0.1, 0.9) var out_fraction: float = 0.35

var _current: Node3D
var _rest_scale: Dictionary = {} # Node3D -> Vector3
var _tween: Tween


func _ready() -> void:
	assert(behavior != null and wander_form != null and charge_form != null,
			"GhostFormSwitcher needs a behavior and both forms assigned.")

	for form: Node3D in [wander_form, charge_form]:
		_rest_scale[form] = form.scale

	# Start fully in the wander form, with the charge form hidden.
	_hide_form(charge_form)
	_current = wander_form
	wander_form.visible = true

	behavior.state_changed.connect(_on_state_changed)


func _on_state_changed(new_state: ChargeBehavior.State) -> void:
	# Recover keeps the charge form: the ghost just hit someone and is gloating.
	var target := wander_form if new_state == ChargeBehavior.State.WANDER else charge_form
	if target != _current:
		_switch_to(target)


func _switch_to(next: Node3D) -> void:
	var prev := _current
	_current = next

	if _tween:
		_tween.kill()

	# If we interrupted a transition, make sure nothing else is left half-visible.
	for form: Node3D in _rest_scale.keys():
		if form != prev and form != next:
			_hide_form(form)

	var out_time := transition_time * out_fraction
	var in_time := transition_time - out_time

	_tween = create_tween()

	# Shrink out. TRANS_BACK + EASE_IN gives a little anticipation wind-up first.
	_tween.tween_property(prev, "scale", Vector3.ZERO, out_time) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	_tween.tween_callback(prev.hide)

	# Pop in with a jelly-like overshoot.
	_tween.tween_callback(func() -> void:
		next.scale = Vector3.ZERO
		next.show())
	_tween.tween_property(next, "scale", _rest_scale[next], in_time) \
		.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _hide_form(form: Node3D) -> void:
	form.scale = Vector3.ZERO
	form.visible = false
