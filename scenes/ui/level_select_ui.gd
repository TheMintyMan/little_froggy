extends Control

var instantiator: LevelSelectPad = null


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


func _on_btn_leaderboard_pressed() -> void:
	print("testing button press")


func _on_btn_exit_pressed() -> void:
	instantiator.level_select_ui_hide()


func _on_btn_enter_pressed() -> void:
	var main: Main = GameManager.get_main()
	if main == null:
		return
	main.goto_world(instantiator.get_level_select())
