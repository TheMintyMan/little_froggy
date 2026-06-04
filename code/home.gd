extends Node3D

class_name Home

var player: StaticBody3D
var level_root: Level

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_root = get_tree().current_scene.get_child(1)
	assert(level_root is Level)
	level_root.register_home(self)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
