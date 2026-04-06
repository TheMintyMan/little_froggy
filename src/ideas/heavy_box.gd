extends Pushable

var is_floating = false

@export var target_button : Node3D

func _ready() -> void:
	target_button.pressed.connect(start_floating)
	target_button.released.connect(stop_floating)

func start_floating():
	is_floating = true

func stop_floating():
	is_floating = false

func handle_push(collider:Node3D, dir:Vector2) -> bool:
	if is_floating:
		return super(collider, dir)
	return false
