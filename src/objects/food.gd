extends StaticBody3D

class_name Food

@export var value: int = 1
var _is_eaten = false
var level_root: Level
var player: Player 

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	level_root = get_tree().current_scene.get_child(1)
	level_root.register_food()
	player = level_root.get_player()

func eat() -> void:
	if _is_eaten:
		return
	level_root.on_food_eaten()
	_is_eaten = true
	queue_free()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
