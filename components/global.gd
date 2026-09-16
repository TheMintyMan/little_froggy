extends Node3D
signal do_undo

const TILESIZE = 1
var time_index: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func get_grid_pos(n:Node3D) -> Vector2:
	assert(n.global_position.x == floor(n.global_position.x))
	assert(n.global_position.z == floor(n.global_position.z))

	return Vector2(
		n.global_position.x/TILESIZE,
		n.global_position.z/TILESIZE
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
	emit_signal("do_undo")
	time_index -= 1
	
func convert_rot_dir(rot: float) -> Vector2:
	var dir: Vector2 = Vector2(cos(rot), sin(rot))
	var dir_int: Vector2i = Vector2i(round(dir.x*-1), round(dir.y))
	return dir_int
