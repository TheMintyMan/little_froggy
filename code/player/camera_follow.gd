extends Camera3D

@export var follow_object : Node3D
@export var location_offset : Vector3
## 0..1. How much of last frame's velocity is kept. Higher = heavier, laggier follow.
@export_range(0.0, 1.0) var momentum : float = 0.85
## Pull strength toward the target position.
@export var speed : float = 12.0

# Ground-plane velocity (UE VelX -> x, UE VelY -> z since Godot's ground plane is X/Z).
var _vel_x : float = 0.0
var _vel_z : float = 0.0
## Squared speed of the camera this frame (UE ActualSpeedMoving), handy for effects.
var actual_speed_moving : float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if follow_object:
		global_position = _target_position()
	else:
		push_warning("Camera follow_object is not assigned!")

## Where the camera wants to sit. The camera keeps its own Y (height).
func _target_position() -> Vector3:
	var pos = follow_object.global_position + location_offset
	pos.y = global_position.y
	return pos

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not follow_object:
		return

	var object_pos = global_position
	var target_pos = _target_position()

	var settled = is_equal_approx(target_pos.x, object_pos.x) and is_equal_approx(target_pos.z, object_pos.z) \
			and is_zero_approx(_vel_x) and is_zero_approx(_vel_z)
	if settled:
		_vel_x = 0.0
		_vel_z = 0.0
		return

	# Momentum blend: keep some of last frame's velocity, add a pull toward the target.
	_vel_x = momentum * _vel_x + (1.0 - momentum) * (target_pos.x - object_pos.x) * speed * delta
	_vel_z = momentum * _vel_z + (1.0 - momentum) * (target_pos.z - object_pos.z) * speed * delta

	global_position = Vector3(object_pos.x + _vel_x, object_pos.y, object_pos.z + _vel_z)

	actual_speed_moving = _vel_x * _vel_x + _vel_z * _vel_z
