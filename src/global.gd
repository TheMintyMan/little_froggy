extends Node3D
signal do_undo

signal win_condition_met

const TILESIZE = 1
var time_index: int = 0
var player: Node3D = null
var total_food: int = 0
var food_collected: int = 0
var home: Node3D = null

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

func register_player(player_node:Node):
	player = player_node
	print("player registered using global")
	
func unregister_player( player_node:Node):
	player = null
	print("unregistered player")
	
func register_food(value: int) -> void:
	total_food += value
	
func on_food_eaten(value: int) -> void:
	food_collected += value
	_check_win_condition()
	
func register_home(home_node:Node) -> void:
	home = home_node

func _check_win_condition() -> void:
	if food_collected >= total_food && home == null:
		win_condition_met.emit()
		print("win check: won")
	elif food_collected >= total_food && player.global_position == home.global_position:
		win_condition_met.emit()
		print("win check: won")
	else:
		print("win check: not yet won")
		return

func get_player() -> Node:
	if is_instance_valid(player):
		return player
	else:
		return null

func grid_check(pos:Vector2) -> Node3D:
	$RayCast3D.global_position = Vector3(pos.x*TILESIZE, $RayCast3D.global_position.y, pos.y*TILESIZE)
	$RayCast3D.force_raycast_update()
	return $RayCast3D.get_collider()
	
func move_to_grid_pos(n:Node3D, pos:Vector2):
	if (n.get('current_height') != null):
		n.global_position = Vector3(pos.x, n.current_height/2, pos.y)
	else:
		n.global_position = Vector3(pos.x, n.global_position.y, pos.y)
	
func undo():
	emit_signal("do_undo")
	time_index -= 1
