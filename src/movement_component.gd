extends Node
class_name MovementComponent

@export var _movement_curve: Curve
@export var _movement_speed: float = 1.0
@export var _movement_duration: float = 0.1
var _parent: Node3D

var _moving_default: bool = false
var _moving_turn: bool = false
var _moving_leap: bool = false

var _time_elapsed_move: float = 0.0
var _time_elapsed_turn: float = 0.0
var _time_elapsed_up: float = 0.0

var _target_pos: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_parent = get_parent()
	pass

func is_moving() -> bool:
	if _moving_default || _moving_leap || _moving_turn == true:
		return true
	else:
		return false

func set_move_default(pos: Vector3):
	_target_pos = pos
	_moving_default = true

func _move_default(delta: float):
	_time_elapsed_move += delta
	var t = _time_elapsed_move / _movement_duration
	# print(t, " ", time_elapsed)
	var new_pos = _parent.global_position
	_parent.global_position = lerp(_parent.global_position, _target_pos, _movement_curve.sample(t))
	if (t >= 1.0):
		_time_elapsed_move = 0.0
		_moving_default = false
	
func _move_turn():
	pass

func _move_leap(player: Player, target_pos: Vector3) -> Vector3:
	return Vector3.ZERO
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _moving_default:
		_move_default(delta)
	pass
