extends StaticBody3D
class_name Pushable

@export var outline_mesh : MeshInstance3D

var action_manager = ActionManager.new({
	"move": [move, undo_move]
})

func outline_on():
	if outline_mesh:
		outline_mesh.visible = true

func outline_off():
	if outline_mesh:
		outline_mesh.visible = false

func move(dir:Vector2):
	var new_grid_pos: Vector2 = Global.get_grid_pos(self) + dir
	var new_world_pos: Vector3 = Vector3(new_grid_pos.x, self.position.y, new_grid_pos.y)
	Global.move_to_grid_pos(self, new_world_pos)

func undo_move(dir:Vector2):
	var new_grid_pos: Vector2 = Global.get_grid_pos(self) - dir
	var new_grid_node = Global.grid_check(new_grid_pos)
	var new_world_pos: Vector3 = Vector3(new_grid_pos.x, self.position.y, new_grid_pos.y)
	Global.move_to_grid_pos(self, new_world_pos)

func handle_wall(_collider:Node3D, _dir:Vector2) -> bool:
	return false

func handle_push(collider:Node3D, dir:Vector2) -> bool:
	if collider == null:
		action_manager.do_action("move", [dir])
		return true
	
	if collider.push(dir):
		action_manager.do_action("move", [dir])
		return true
	else:
		return false

func push(dir:Vector2) -> bool:
	var new_pos =  Global.get_grid_pos(self) + dir
	var collider = Global.grid_check(new_pos);
	if collider == null or collider.is_in_group("pushable"):
		return handle_push(collider, dir)

	if collider.is_in_group("wall"):
		return handle_wall(collider, dir)

	# The level's ground is a "floor" collider on every tile, so plain floor is open ground
	if collider.is_in_group("floor"):
		return handle_push(null, dir)

	# Anything else occupying the target tile blocks the push/pull
	return false
