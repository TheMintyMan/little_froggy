extends Node3D
class_name LevelSelectPad

@export var level: PackedScene

var screen_pos: Vector2
var camera: Camera3D

var level_root: Level
var player: Player 
var is_player_on_top: bool = false
var is_popup_show: bool = false

@export var ui: PackedScene
var ui_node: Node

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	level_root = get_tree().current_scene.get_child(1)
	player = level_root.get_player()
	
	#%level_popup.visible = false
	%level_popup.hide()
	%level_select_ui.visible = false
	
	set_process(false)
	
	if level_root and level_root.has_method("get_camera"):
		camera = level_root.get_camera()

func hit(object: Node3D):
	if object is Player:
		print("Yes, I have been hit by ", object.name)
		popup_ui_show()
		
func un_hit(object: Node3D):
	if object is Player:
		print ("I am un hitting from ", object.name)
		popup_ui_hide()

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
	%level_select_ui.show()
	%level_select_ui.visible = true
	
	
func level_select_ui_hide():
	%level_select_ui.visible = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if is_popup_show:
		var global_3d_pos = %level_popup_pos.global_position
		screen_pos = camera.unproject_position(global_3d_pos)
		%level_popup.global_position = screen_pos
		
func _input(event: InputEvent) -> void:
	if is_popup_show:
		if Input.is_action_just_pressed("ui_confirm"):
			print("pressed gui input")
			level_select_ui_show()

		if Input.is_action_just_pressed("ui_escape"):
			level_select_ui_hide()

func _on_area_entered(body: Node3D) -> void:
	
	print("testing testing: ", body.name)
	if body is Player:
		print("something has entered")


func _on_area_exited(body: Node3D) -> void:
	pass # Replace with function body.
