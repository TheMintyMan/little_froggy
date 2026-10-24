extends Node
class_name Level

## If true, stepping onto a tile with no ground makes the frog fall and the level resets.
## Turn off for levels without floor colliders (like the level selector), where empty tiles are walkable.
@export var can_fall_off: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#main = get_tree().current_scene
	GameManager.set_level(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
	
func add_ui(ui_instance: Control):
	%CanvasLayer.add_child(ui_instance)
