extends StaticBody3D

signal awawa

@export var height: int = 1



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	

func get_height() -> int:
	return height

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
