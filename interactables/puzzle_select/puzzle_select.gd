extends StaticBody3D
class_name PuzzleSelect

signal puzzle_started
signal puzzle_completed

## How many flies the frog has to eat inside this puzzle to complete it.
@export var flies_to_complete: int = 3

var flies_eaten: int = 0
var is_active: bool = false
var is_completed: bool = false

# The golden fly the frog pulls on to start the puzzle. Hidden while the puzzle is running.
@onready var golden_fly: Node3D = $fly

# Off-tree copies of the flies as they were placed, so a reset can bring back the ones that were eaten
var _starting_flies: Array[Food] = []
# Visibility and collision each hidden node had before the puzzle hid it, so they can be put back
var _hidden_state: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		_watch_child(child)
		if child is Food:
			_starting_flies.append((child as Food).duplicate() as Food)
	child_entered_tree.connect(_watch_child)

## Called by the frog's tongue. Hides the rest of the level and starts counting flies.
func start_puzzle() -> void:
	if is_active or is_completed:
		return
	is_active = true
	flies_eaten = 0
	golden_fly.visible = false
	var player := GameManager.get_player()
	if player != null:
		player.reset_food_count()
	_reset_flies()
	var level := GameManager.get_level()
	if level != null:
		_hide_rest_of_level(level)
	puzzle_started.emit()

func _watch_child(child: Node) -> void:
	if child is Food:
		(child as Food).eaten.connect(_on_fly_eaten)

func _on_fly_eaten() -> void:
	if not is_active:
		return
	flies_eaten += 1
	print("puzzle flies eaten: ", flies_eaten, " / ", flies_to_complete)
	if flies_eaten >= flies_to_complete:
		_complete_puzzle()

func _complete_puzzle() -> void:
	is_active = false
	is_completed = true
	_show_level()
	puzzle_completed.emit()

## Puts the world back and resets the progress of this puzzle.
func _reset_puzzle() -> void:
	is_active = false
	flies_eaten = 0
	golden_fly.visible = true
	_reset_flies()
	_show_level()

func _unhandled_input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("ui_escape"):
		_reset_puzzle()
		get_viewport().set_input_as_handled()

## Removes whatever flies are left and puts back the ones as they were placed.
func _reset_flies() -> void:
	for child in get_children():
		if child is Food:
			child.queue_free()
	for fly in _starting_flies:
		add_child(fly.duplicate())

## Hides every node in the level except this puzzle (and its children), the frog,
## and anything in the "Persistent" node (lights and anything else the level needs).
func _hide_rest_of_level(node: Node) -> void:
	var player := GameManager.get_player()
	for child in node.get_children():
		if child == self or child == player or _is_persistent(child):
			continue
		if child.is_ancestor_of(self) or _has_persistent_descendant(child):
			_hide_rest_of_level(child)
		else:
			_hide_tree(child)

func _is_persistent(node: Node) -> bool:
	return node.name == "Persistent" or node.is_in_group("Persistent")

func _has_persistent_descendant(node: Node) -> bool:
	for descendant in node.find_children("*", "", true, false):
		if _is_persistent(descendant):
			return true
	return false

## Hides a node and everything under it, and turns off its collision so the hidden
## ground and objects can't be walked on, pulled or eaten.
func _hide_tree(root: Node) -> void:
	var nodes: Array = [root]
	nodes.append_array(root.find_children("*", "", true, false))
	for node in nodes:
		if _hidden_state.has(node):
			continue
		var saved := {}
		if node is Node3D:
			saved["visible"] = node.visible
			node.visible = false
		if node is CollisionObject3D:
			saved["layer"] = node.collision_layer
			saved["mask"] = node.collision_mask
			node.collision_layer = 0
			node.collision_mask = 0
		if not saved.is_empty():
			_hidden_state[node] = saved

func _show_level() -> void:
	for node in _hidden_state:
		if not is_instance_valid(node):
			continue
		var saved: Dictionary = _hidden_state[node]
		if saved.has("visible"):
			node.visible = saved["visible"]
		if saved.has("layer"):
			node.collision_layer = saved["layer"]
			node.collision_mask = saved["mask"]
	_hidden_state.clear()
