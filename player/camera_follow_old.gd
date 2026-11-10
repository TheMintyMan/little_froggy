extends Camera3D

@export var follow_object : Node3D
@export var follow_speed : float = 5.0
@export var location_offset : Vector3
@export var shift_when_facing_down : bool = true

## Added to location_offset.z while the frog is facing down.
@export var down_offset : float = 3.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if follow_object:
		global_position = follow_object.global_position + location_offset
	else:
		push_warning("Camera follow_object is not assigned!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not follow_object:
		return

	var offset = location_offset
	if shift_when_facing_down and _is_facing_down():
		offset.z += down_offset

	var target_pos = follow_object.global_position + offset
	target_pos.y = self.global_position.y
	global_position = global_position.lerp(target_pos, follow_speed * delta)

func _is_facing_down() -> bool:
	var player = get_parent()
	return player != null and "facing_dir" in player and player.facing_dir == Vector2(0, -1)
