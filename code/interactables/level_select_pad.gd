extends Node3D
class_name LevelSelectPad

var screen_pos: Vector2
var camera: Camera3D

var level_root: Level
var player: Player 
var is_player_on_top: bool = false
var is_popup_show: bool = false
var is_hit: bool = false

@export var level: PackedScene
@export var level_select_ui: PackedScene
var ui_instance: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_root = get_tree().current_scene.get_child(1)
	player = level_root.get_player()
	%level_popup_pos.hide()
	#%level_popup.visible = false
	%level_popup.hide()
		
	set_process(false)
	
	if level_root and level_root.has_method("get_camera"):
		camera = level_root.get_camera()

func hit(object: Node3D):
	if object is Player:
		popup_ui_show()
		is_hit = true

func un_hit(object: Node3D):
	if object is Player:
		popup_ui_hide()
		is_hit = false
		
func get_level_select() -> PackedScene:
	if level != null:
		return level
	push_error(self.name, " does not have a level selected")
	print("not working")
	return

func popup_ui_show():
	#await get_tree().process_frame
	set_process(true)
	is_popup_show = true
	%level_popup.show()
	%level_popup.visible = true
	
func popup_ui_hide():
	set_process(false)
	%level_popup.visible = false

func level_select_ui_show():
	popup_ui_hide()
	if ui_instance == null:
		print("showing")
		ui_instance = level_select_ui.instantiate()
		ui_instance.instantiator = self
		level_root.add_ui(ui_instance)
		player.movement_disable()
	#if %level_select_ui.has_node("VBoxContainer"):
		#%level_select_ui.get_node("VBoxContainer").grab_focus()
	
func level_select_ui_hide():
	popup_ui_show()
	if ui_instance != null:
		ui_instance.queue_free()
		ui_instance = null
		player.movement_enable()
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_popup_show:
		var global_3d_pos = %level_popup_pos.global_position
		screen_pos = camera.unproject_position(global_3d_pos)
		%level_popup.global_position = screen_pos
		
func _input(event: InputEvent) -> void:
	if is_hit == true:
		if is_popup_show:
			if Input.is_action_just_pressed("ui_confirm"):
				level_select_ui_show()
			if Input.is_action_just_pressed("ui_escape"):
				level_select_ui_hide()
