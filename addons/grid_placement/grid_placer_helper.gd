@tool
extends Node3D
class_name GridPlacerHelper

@export_group("Tool Status")
@export var tool_enabled: bool = true

@export_tool_button("Clear All Children", "Remove")
var clear_children_button: Callable = _clear_all_children

@export_group("Grid Properties")

@export var grid_size: float = 1.0

@export var target_y: float = 0.0

@export_group("Spawning Options")
@export var object_to_spawn: PackedScene
@export var cocave_corner_mesh: Array[PackedScene]
@export var convex_corner_mesh: Array[PackedScene]
@export var connecting_corner_mesh: Array[PackedScene]
@export var solid_mesh: Array[PackedScene]
@export var edge_mesh: Array[PackedScene]

func _clear_all_children() -> void:
	print("Grid Placer: Clearing")
	for child in get_children():
		child.queue_free()
	notify_property_list_changed()
