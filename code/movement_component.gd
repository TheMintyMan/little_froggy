extends Node
class_name MovementComponent

@export var _movement_curve: Curve
@export var _movement_jump_basic_curve: Curve
@export var _movement_speed: float = 1.0
@export var _movement_duration: float = 0.2
@export var anim_tree: AnimationTree
@onready var _parent: Node3D = get_parent()

var _moving: bool = false

var _time_elapsed_move: float = 0.0

var _start_pos: Vector3
var _target_rot: float
var _target_pos: Vector3

var _jump_height: float = 0.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func is_moving() -> bool:
	if _moving == true:
		return true
	else:
		return false

func set_move(pos: Vector3):
	_start_pos = _parent.global_position
	_target_pos = pos
	_moving = true

func _move(delta: float):
	_time_elapsed_move += delta
	var t = _time_elapsed_move / _movement_duration
	var current_curve_step = _movement_curve.sample(t)
	var new_pos = lerp(_start_pos, _target_pos, current_curve_step)
	
	var jump_sample = _movement_jump_basic_curve.sample(t)
	new_pos.y = jump_sample * _jump_height
	
	# print(t, " ", time_elapsed)
	#_parent.global_position = lerp(_parent.global_position, _target_pos, _movement_curve.sample(t))
	_parent.global_position = new_pos
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
