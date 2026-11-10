extends Node

var player: Player = null
var camera: Camera3D = null
var level: Level = null
var frog_home: Node3D = null
var food_count: int = 0
var active_puzzle: PuzzleSelect = null
# Puzzles finished this session. Lives here so that it survives a level being reloaded.
var completed_puzzles: Dictionary = {}

func clear_all() -> void:
	player = null
	camera = null
	level = null
	frog_home = null
	active_puzzle = null
	food_count = 0
	print("cleared all variable values in GameManager")

func set_level(in_level: Level):
	level = in_level
	print("level has been set")
	
func get_level() -> Level:
	return level

func get_main() -> Main:
	var main: Main = get_tree().get_nodes_in_group("main").pop_back()
	if main == null:
		print("oh no! no level manager")
	return main

func next_level() -> void:
	var main: Main = get_main()
	if main == null:
		return
	main.next_level()
	
func set_player(in_player: Player):
	if in_player is Player:
		player = in_player
		set_camera()
	print("player has been set")
	return
	
func get_player() -> Player:
	if is_instance_valid(player):
		return player
	else:
		return null

func clear_player():
	player = null
	print("cleared player")

func set_camera():
	camera = player.find_child("camera", true, false)
	print("camera has been set")

func get_camera() -> Camera3D:
	return camera
	
func set_home(home_node:Node) -> void:
	if (home_node is Home):
		frog_home = home_node
		print("froggy home has been set")
	return
	
func get_home() -> Home:
	return frog_home
	
func add_food() -> void:
	food_count += 1
	print("food has been added. Total: ", food_count)
	
func sub_food() -> void:
	food_count -= 1
	print("food has been subtracted. Total: ", food_count)
	
func clear_food() -> void:
	food_count = 0

func set_active_puzzle(puzzle: PuzzleSelect) -> void:
	active_puzzle = puzzle

func get_active_puzzle() -> PuzzleSelect:
	if is_instance_valid(active_puzzle):
		return active_puzzle
	return null

func mark_puzzle_completed(puzzle_id: String) -> void:
	completed_puzzles[puzzle_id] = true

func is_puzzle_completed(puzzle_id: String) -> bool:
	return completed_puzzles.has(puzzle_id)
