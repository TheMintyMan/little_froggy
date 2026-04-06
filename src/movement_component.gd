extends Node
class_name MovementComponent

@export var _movement_curve: Curve
@export var _movement_speed: float = 1.0
@export var _movement_duration: float = 0.1
@export var anim_tree: AnimationTree
@onready var _parent: Node3D = get_parent()

var _moving: bool = false

var _time_elapsed_move: float = 0.0

var _target_rot: float
var _target_pos: Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func is_moving() -> bool:
	if _moving == true:
		return true
	else:
		return false

func set_move(pos: Vector3):
	_target_pos = pos
	_moving = true

func _move(delta: float):
	_time_elapsed_move += delta
	var t = _time_elapsed_move / _movement_duration
	# print(t, " ", time_elapsed)
	_parent.global_position = lerp(_parent.global_position, _target_pos, _movement_curve.sample(t))
	if (t >= 1.0):
		_time_elapsed_move = 0.0
		_moving = false

func set_move_turn(rot: float):
	_target_rot = rot
	_moving = true

func _move_turn():
	pass

func set_move_leap(pos: Vector3):
	_target_pos = pos
	_moving = true


func _move_leap(delta: float):
	_move(delta)
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if _moving:
		_move(delta)
	pass
