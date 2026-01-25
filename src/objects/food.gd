extends StaticBody3D

class_name Food

signal eaten(value: int)
@export var value: int = 1
var _is_eaten = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Global.register_food(value)

func eat() -> void:
	if _is_eaten:
		return
	Global.on_food_eaten(value)
	_is_eaten = true
	eaten.emit(value)
	queue_free()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
