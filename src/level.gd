extends Node
class_name Level
signal win_condition_met

var food_ingame: int = 0
var home: Node3D = null
var player: Player = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

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
	food_ingame += 1
	
func on_food_eaten() -> void:
	food_ingame -= 1
	check_win_condition()
	
func register_home(home_node:Node) -> void:
	home = home_node

func check_win_condition() -> void:
	if (!(food_ingame == 0 && home == null)):
		print("win check: not yet won")
	
	if(!home):
		return
	
	if food_ingame == 0 && player.global_position == home.global_position:
		win_condition_met.emit()
		print("win check: won")
	else:
		win_condition_met.emit()
		print("win check: won")
