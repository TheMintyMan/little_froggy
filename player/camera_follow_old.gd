extends Camera3D

@export var follow_object : Node3D
@export var follow_speed : float = 5.0
@export var location_offset : Vector3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.
	if follow_object:
		global_position = follow_object.global_position + location_offset
	else:
		push_warning("Camera follow_object is not assigned!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not follow_object:
		return
	
	var target_pos = follow_object.global_position + location_offset
	target_pos.y = self.global_position.y
	global_position = global_position.lerp(target_pos, follow_speed * delta)
