extends Node3D
signal do_undo

const TILESIZE = 1
var time_index: int = 0
# Undo can't go back past this step (see set_undo_checkpoint)
var undo_floor: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func get_grid_pos(n:Node3D) -> Vector2:
	# Approximate, because anything under a rotated parent lands a tiny bit off the exact tile
	assert(is_equal_approx(n.global_position.x, round(n.global_position.x)))
	assert(is_equal_approx(n.global_position.z, round(n.global_position.z)))

	return Vector2(
		round(n.global_position.x/TILESIZE),
		round(n.global_position.z/TILESIZE)
	)

func height_check(n: Node3D, pos: Vector2) -> float:
	var new_grid_node = Global.grid_check(pos)
	var height: float
	if new_grid_node == null:
		height = n.position.y
	else:
		height = new_grid_node.postion.y
	return height

func grid_check(pos:Vector2, mask:int = 1) -> Node3D:
	$RayCast3D.global_position = Vector3(pos.x*TILESIZE, $RayCast3D.global_position.y, pos.y*TILESIZE)
	$RayCast3D.collision_mask = mask
	$RayCast3D.force_raycast_update()
	return $RayCast3D.get_collider()
	
func move_to_grid_pos(n:Node3D, pos:Vector3):
	n.global_position = Vector3(pos.x, pos.y, pos.z)
	
func undo():
	if time_index <= undo_floor:
		return
	emit_signal("do_undo")
	time_index -= 1

## Undoes every step back to the last checkpoint.
func undo_all():
	while time_index > undo_floor:
		undo()

## Everything done so far is now locked in: undo stops here.
func set_undo_checkpoint():
	undo_floor = time_index

## Starts a fresh undo history, for when a new level loads.
func reset_undo():
	time_index = 0
	undo_floor = 0

func convert_rot_dir(rot: float) -> Vector2:
	var dir: Vector2 = Vector2(cos(rot), sin(rot))
	var dir_int: Vector2i = Vector2i(round(dir.x*-1), round(dir.y))
	return dir_int
