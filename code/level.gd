extends Node
class_name Level
signal win_condition_met (wincon: bool)

var food_on_grid: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#main = get_tree().current_scene
	GameManager.set_level(self)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func on_food_eaten() -> void:
	food_on_grid -= 1
	
func add_ui(ui_instance: Control):
	%CanvasLayer.add_child(ui_instance)	
