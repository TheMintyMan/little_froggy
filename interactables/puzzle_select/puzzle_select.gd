extends StaticBody3D
class_name PuzzleSelect

signal puzzle_started
signal puzzle_completed

const PUZZLE_COMPLETE_POPUP = preload("res://interactables/puzzle_select/puzzle_complete_popup.tscn")

## How many flies the frog has to eat inside this puzzle to complete it.
@export var flies_to_complete: int = 3

var flies_eaten: int = 0
var is_active: bool = false
var is_completed: bool = false

# The golden fly the frog pulls on to start the puzzle. Hidden while the puzzle is running.
@onready var golden_fly: Node3D = $fly
@onready var trigger_shape: CollisionShape3D = $CollisionShape3D

# Visibility and collision each hidden node had before the puzzle hid it, so they can be put back
var _hidden_state: Dictionary = {}
# Food and crates inside this puzzle, hidden until the golden fly is pulled
var _contents_state: Dictionary = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for child in get_children():
		_watch_child(child)
	child_entered_tree.connect(_watch_child)
	if GameManager.is_puzzle_completed(_get_puzzle_id()):
		_show_as_completed()
	else:
		_hide_contents()

## Identifies this puzzle across reloads: which level it's in, and where in that level.
func _get_puzzle_id() -> String:
	if owner == null:
		return scene_file_path
	return owner.scene_file_path + "::" + str(owner.get_path_to(self))

## Puts a puzzle that was finished before this level was (re)loaded back in its finished state.
func _show_as_completed() -> void:
	is_completed = true
	_set_golden_fly_shown(false)
	for child in get_children():
		if child is Food:
			(child as Food).set_eaten(true)

## The golden fly and its collision go together. A hidden fly must not block the frog's tile.
func _set_golden_fly_shown(shown: bool) -> void:
	golden_fly.visible = shown
	trigger_shape.disabled = not shown

## Called by the frog's tongue. Hides the rest of the level and starts counting flies.
func start_puzzle() -> void:
	if is_active or is_completed:
		return
	is_active = true
	flies_eaten = 0
	_set_golden_fly_shown(false)
	GameManager.set_active_puzzle(self)
	# Undo stays inside the puzzle, the moves that led up to it are hidden with the rest of the level
	Global.set_undo_checkpoint()
	var player := GameManager.get_player()
	if player != null:
		player.reset_food_count()
	_reset_flies()
	_show_contents()
	var level := GameManager.get_level()
	if level != null:
		_hide_rest_of_level(level)
	puzzle_started.emit()

func _watch_child(child: Node) -> void:
	if child is Food:
		(child as Food).eaten.connect(_on_fly_eaten)
		(child as Food).uneaten.connect(_on_fly_uneaten)

func _on_fly_eaten() -> void:
	if not is_active:
		return
	flies_eaten += 1
	print("puzzle flies eaten: ", flies_eaten, " / ", flies_to_complete)
	if flies_eaten >= flies_to_complete:
		_complete_puzzle()
		print("Puzzle completed")

func _on_fly_uneaten() -> void:
	if is_active:
		flies_eaten -= 1

func _complete_puzzle() -> void:
	is_active = false
	is_completed = true
	GameManager.set_active_puzzle(null)
	GameManager.mark_puzzle_completed(_get_puzzle_id())

	Global.set_undo_checkpoint()
	_show_level()
	_show_complete_popup()
	puzzle_completed.emit()
	
	# Temporary code
	GameManager.next_level()

## Fades a "Puzzle Complete" message in and out over the level.
func _show_complete_popup() -> void:
	var level := GameManager.get_level()
	if level != null:
		level.add_child(PUZZLE_COMPLETE_POPUP.instantiate())

## Puts the frog, flies and crates back to how they were when this puzzle started.
func restart() -> void:
	Global.undo_all()

## Leaves the puzzle: puts the world back and resets the progress of this puzzle.
func _reset_puzzle() -> void:
	restart()
	is_active = false
	flies_eaten = 0
	_set_golden_fly_shown(true)
	GameManager.set_active_puzzle(null)
	_reset_flies()
	_hide_contents()
	_show_level()

func _unhandled_input(event: InputEvent) -> void:
	if is_active and event.is_action_pressed("ui_escape"):
		var player := GameManager.get_player()
		# The frog is drowning or falling, and restarts the puzzle itself when that's over
		if player != null and player.is_movement_disabled:
			return
		_reset_puzzle()
		get_viewport().set_input_as_handled()

## Brings back any flies that were eaten, including before the puzzle was started.
func _reset_flies() -> void:
	for child in get_children():
		if child is Food:
			(child as Food).set_eaten(false)

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
			_hide_tree(child, _hidden_state)

func _is_persistent(node: Node) -> bool:
	return node.name == "Persistent" or node.is_in_group("Persistent")

func _has_persistent_descendant(node: Node) -> bool:
	for descendant in node.find_children("*", "", true, false):
		if _is_persistent(descendant):
			return true
	return false

## Hides a node and everything under it, and turns off its collision so the hidden
## ground and objects can't be walked on, pulled or eaten.
func _hide_tree(root: Node, state: Dictionary) -> void:
	var nodes: Array = [root]
	nodes.append_array(root.find_children("*", "", true, false))
	for node in nodes:
		if state.has(node):
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
			state[node] = saved

## Food and crates inside the puzzle stay hidden until the golden fly is pulled.
func _hide_contents() -> void:
	for child in get_children():
		if child is Food or child is Pushable:
			_hide_tree(child, _contents_state)

func _show_contents() -> void:
	_restore_state(_contents_state)

func _show_level() -> void:
	_restore_state(_hidden_state)

## Puts back whatever _hide_tree hid in this state, then forgets it.
func _restore_state(state: Dictionary) -> void:
	for node in state:
		if not is_instance_valid(node):
			continue
		var saved: Dictionary = state[node]
		if saved.has("visible"):
			node.visible = saved["visible"]
		if saved.has("layer"):
			node.collision_layer = saved["layer"]
			node.collision_mask = saved["mask"]
	state.clear()
