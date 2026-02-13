extends Node3D
class_name Main

@export var levels : Array[PackedScene] = []
@export var level_index = 0
var current_level : Node

func _ready() -> void:
	goto_level(level_index)
	
func next_level():
	goto_level((level_index + 1) % levels.size())
	
func previous_level():
	goto_level(((level_index - 1) + levels.size()) % levels.size())
	
func goto_level(index):
	prints('to_level', level_index)
	assert(index >= 0 or index < levels.size())
	if current_level != null:
		current_level.queue_free()
	current_level = levels[index].instantiate()
	add_child(current_level)
	level_index = index
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("previous_level")):
		previous_level()
	elif (Input.is_action_just_pressed("next_level")):
		next_level()
