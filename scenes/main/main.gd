extends Node3D
class_name Main

@export var levels : Array[PackedScene] = []
@export var level_index = 0
var current_level : Node
# The scene current_level was made from, so a restart can make a fresh copy of it
var _current_scene : PackedScene

func _ready() -> void:
	goto_level(level_index)
	
func next_level():
	goto_level((level_index + 1) % levels.size())
	
func previous_level():
	goto_level(((level_index - 1) + levels.size()) % levels.size())
	
func goto_level(index):
	prints('to_level', level_index)
	assert(index >= 0 or index < levels.size())
	_load_level(levels[index])
	level_index = index

func goto_world(new_level :PackedScene):
	prints('to_level')
	_load_level(new_level)

## Starts the current level again from the beginning.
func reload_level():
	_load_level(_current_scene)

func _load_level(scene: PackedScene):
	if current_level != null:
		current_level.queue_free()
	_current_scene = scene
	current_level = scene.instantiate()
	add_child(current_level)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if (Input.is_action_just_pressed("previous_level")):
		previous_level()
	elif (Input.is_action_just_pressed("next_level")):
		next_level()
