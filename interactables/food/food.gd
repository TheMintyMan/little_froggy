extends StaticBody3D

class_name Food

signal eaten
signal uneaten

@export var value: int = 1
var _is_eaten = false
#var level_root: Level
var player: Player

# Eaten food stays in the scene, hidden, so that undo can bring it back
var _collision_layer_before_eaten: int = 0

var action_manager = ActionManager.new({
	"eat": [_do_eat, _undo_eat],
})

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#level_root = get_tree().current_scene.get_child(1)
	#level_root.register_food()
	GameManager.add_food()
	#player = level_root.get_player()

## Eats this food as part of the current undo step. Returns false if it was already eaten.
func eat() -> bool:
	if _is_eaten:
		return false
	action_manager.do_action("eat", [])
	return true

func _do_eat() -> void:
	set_eaten(true)
	eaten.emit()

func _undo_eat() -> void:
	set_eaten(false)
	uneaten.emit()
	var frog := GameManager.get_player()
	if frog != null:
		frog.on_food_eaten(-get_food_value())

## Eats or restores this food directly, without it being a step in the undo history.
func set_eaten(is_eaten: bool) -> void:
	if is_eaten == _is_eaten:
		return
	_is_eaten = is_eaten
	visible = not is_eaten
	if is_eaten:
		#level_root.on_food_eaten()
		GameManager.sub_food()
		_collision_layer_before_eaten = collision_layer
		collision_layer = 0
	else:
		GameManager.add_food()
		collision_layer = _collision_layer_before_eaten

func get_food_value() -> int:
	return value

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
