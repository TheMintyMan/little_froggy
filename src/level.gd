extends Node
class_name Level
signal win_condition_met (wincon: bool)

var food_on_grid: int = 0
var frog_home: Node3D = null
var player: Player
var main: Main

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	main = get_tree().current_scene
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func register_player(player_node:Node):
	player = player_node
	print("player registered using global")
	
func unregister_player():
	player = null
	print("unregistered player")

func get_player() -> Player:
	if is_instance_valid(player):
		return player
	else:
		return null
		
func register_food() -> void:
	food_on_grid += 1
	
func on_food_eaten() -> void:
	food_on_grid -= 1
	check_win_condition()
	
func register_home(home_node:Node) -> void:
	if (home_node is Home):
		frog_home = home_node
		print("home registered")
	return
	
func get_home() -> Home:
	return frog_home

func check_win_condition() -> void:
	print("food on grid", food_on_grid)
	if (food_on_grid != 0):
		win_condition_met.emit(false)
		print("win check: not yet won")
		return
	
	if food_on_grid == 0 && player.global_position == frog_home.global_position:
		win_condition_met.emit(true)
		print("win check: won 1")
		main.next_level()
	elif food_on_grid == 0 && frog_home == null:
		win_condition_met.emit(false)
		print("win check: won 2")
