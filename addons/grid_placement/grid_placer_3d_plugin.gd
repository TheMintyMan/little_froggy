@tool
@icon("icon.svg")
#class_name MintyGridTool
extends EditorPlugin

var active_helper: Node3D = null
var is_dragging: bool = false

## Called when the node enters the scene tree for the first time.
#func _ready() -> void:
	#pass # Replace with function body.
#
#
## Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
	#
	#if Engine.is_editor_hint():
		#pass
	#else:
		#pass

var auto_tile_directions: Array[Vector3] = [
	Vector3i(0,0,1), # UP
	Vector3i(-1,0,0), # RIGHT
	Vector3i(0,0,-1), # DOWN
	Vector3i(1,0,0), # LEFT
	#Vector3i(-1,0,1), # RIGHT UP 
	#Vector3i(-1,0,-1), # RIGHT DOWN
	#Vector3i(1,0,1), # LEFT UP
	#Vector3i(1,0,-1), # LEFT DOWN
]


enum tile_types {
	EMPTY = 0,
	GROUND = 1,
}

# The master tile position info
var tile_pos_info_dict: Dictionary[Vector3, tile_types] = {
}

# The corner meshes that surrounds each master tile position
var tile_corner_pos_dict: Dictionary[Vector3, Array] = {
}

# Array of 
var tile_corners: Array[Vector3]

func set_tile_pos():
	# add or edit tile_pos_info_dict position and set the value to empty or ground
	pass

func set_corner_pos():
	# add or edit tile_corner_pos_dict key and the 4 values
	pass

func get_auto_tile_assets() -> Dictionary:
	return {
		"solid": active_helper.get("solid_mesh"),
		"edge": active_helper.get("edge_mesh"),
		"concave_corner": active_helper.get("cocave_corner_mesh"),
		"convex_corner": active_helper.get("convex_corner_mesh"),
		"connecting_corner": active_helper.get("connecting_corner_mesh"),
	}
	
func get_this_tile(in_pos:Vector3) -> Dictionary:
	var auto_tile_assets: Dictionary[String, PackedScene]
	auto_tile_assets = get_auto_tile_assets()
	var final_asset: String = ""
	
	var checked_directions: Array[Vector3] = []
	
	for direction in auto_tile_directions:
		var check_pos: Vector3 = in_pos + direction
		if is_grid_occupied(check_pos):
			checked_directions.append(check_pos)
			pass
		pass
	
	if checked_directions.is_empty():
		# There's nothing around it
		pass
	
	return auto_tile_assets.get(final_asset)
	
func is_grid_occupied(in_pos: Vector3) -> bool:
	return false

func _enter_tree():
	# Initialization of the plugin goes here.
	print("Grid Placer Tool: Enabled. Click in the 3D viewport to place objects")

func _exit_tree():
	print("Grid Placer Tool: Disabled.")

# Called by the editor when the user selects a handled object
func _edit(object: Object) -> void:
	active_helper = object as Node3D

# Called when the user deselects the handled object
func _make_visible(visible: bool) -> void:
	if not visible:
		active_helper = null
		is_dragging = false
	
func _handles(object: Object) -> bool:
	return object is Node3D and object.get_script() != null and object.get_script().get_path().ends_with("grid_placer_helper.gd")

func _forward_3d_gui_input(camera: Camera3D, event: InputEvent) -> int:
	if !active_helper or !active_helper.get("tool_enabled"):
		is_dragging = false
		return EditorPlugin.AFTER_GUI_INPUT_PASS
	
	var loaded_scene: PackedScene = active_helper.get("object_to_spawn")
	var grid_size = active_helper.get("grid_size")
	var target_y : float = active_helper.get("target_y")
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			
			process_placement(camera, event.position, grid_size, target_y, loaded_scene)
			return EditorPlugin.AFTER_GUI_INPUT_STOP
		else:
			is_dragging = false
			return EditorPlugin.AFTER_GUI_INPUT_STOP
			
	if event is InputEventMouseMotion and is_dragging:
		print("dragging")
		process_placement(camera, event.position, grid_size, target_y, loaded_scene)
		return EditorPlugin.AFTER_GUI_INPUT_STOP
			
	return EditorPlugin.AFTER_GUI_INPUT_PASS


func process_placement(camera: Camera3D, screen_pos: Vector2, grid_size: float, target_y: float, loaded_scene: PackedScene) -> void:
	
	var intersection_pos = _raycast_from_mouse(camera, screen_pos, target_y)
	var snapped_pos: Vector3 = _get_grid_snapped_pos(intersection_pos, grid_size)
	if is_position_occupied(snapped_pos):
		print("overlapping")
		return
				
	print("intersection: ", intersection_pos, "snapped: ", snapped_pos)
	spawn_object(loaded_scene, snapped_pos)


func _raycast_from_mouse(camera: Camera3D, screen_pos: Vector2, target_y: float) -> Vector3:
	var ray_origin: Vector3 = camera.project_ray_origin(screen_pos)
	var ray_dir: Vector3 = camera.project_ray_normal(screen_pos)

	var ray_distance: float = (target_y -ray_origin.y) / ray_dir.y
	var intersection_point
	
	if ray_distance > 0.0:
		intersection_point = ray_origin + (ray_dir * ray_distance)	
		
	return intersection_point

func _get_grid_snapped_pos(world_pos : Vector3, grid_size: float) -> Vector3:	
	
	var snapped_x = snapped(world_pos.x, grid_size)
	var snapped_z = snapped(world_pos.z, grid_size)
	#Vector3(snapped_x + (cell_size / 2), world_pos.y, snapped_z + (cell_size / 2))
	return Vector3(snapped_x, world_pos.y, snapped_z)
	
func spawn_object(packed_scene: PackedScene, target_world_pos: Vector3) -> void:
	var scene_root: Node = get_editor_interface().get_edited_scene_root()
	var new_node: Node3D = packed_scene.instantiate() as Node3D
	if !new_node:
		print("Grid Placer Tool: Object not set")
		return

	var parent_node: Node = active_helper
	if !parent_node:
		print("Grid Placer Tool: Parent Not Set")
		return
	
	var base_name: String = packed_scene.get_state().get_node_name(0)
	if base_name.is_empty():
		base_name = "SpawnedObject"
		
	var counter: int = 1
	# Using "%03d" % counter formats the integer with zero-padding (e.g., 001, 002...)
	var final_name: String = base_name + "_" + ("%03d" % counter)
	
	# Loop until we find a unique, unused name among parent's children
	while parent_node.has_node(final_name):
		counter += 1
		final_name = base_name + "_" + ("%03d" % counter)
		
	new_node.name = final_name
	
	parent_node.add_child(new_node)
	new_node.owner = scene_root
	new_node.global_position = target_world_pos
	
	if !new_node:
		return

func is_position_occupied(target_world_pos: Vector3) ->bool:
	if !active_helper:
		return false
	var parent_node: Node = active_helper
	
	for child in parent_node.get_children():
		if child is Node3D:
			if child.global_position.distance_to(target_world_pos) < 0.2:
				return true
	
	return false
