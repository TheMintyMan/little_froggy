extends StaticBody3D
class_name Pushable

var action_manager = ActionManager.new({
	"move": [move, undo_move]
})

func move(dir:Vector2):
	Global.move_to_grid_pos(self, Global.get_grid_pos(self) + dir)

func undo_move(dir:Vector2):
	Global.move_to_grid_pos(self, Global.get_grid_pos(self) - dir)

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
		if not handle_wall(collider, dir):
			return false

	
	assert(false)
	return false
