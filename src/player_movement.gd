extends Node
class_name PlayerMovement

@export var movement_curve: Curve
@export var movement_speed: float = 1.0
var moving: bool = false
@export var movement_duration: float = 0.5
var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	time += delta
	if moving:
		pass
	pass
	
func move_default(player: Player, target_pos: Vector3) -> Vector3:
	var t = time / movement_duration
	var new_pos = player.global_position
	new_pos = lerp(player.global_position, target_pos, movement_curve.sample(0.5))
	
	return new_pos

func move_leap(player: Player, target_pos: Vector3) -> Vector3:
	return Vector3.ZERO
