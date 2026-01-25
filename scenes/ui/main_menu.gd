extends Node2D

func _ready() -> void:
	%MainButtons.grab_focus()
	%FULLSCREEN.button_pressed = true if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN else false
	%mainvolslider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))
	%musicvolslider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("MUSIC")))
	%sfxvolslider.value = db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))
	
func _on_play_pressed() -> void:
	var main = get_tree().get_nodes_in_group("main").pop_back()
	if main == null:
		print("oh no! no level manager")
		return
	main.next_level()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_settings_pressed() -> void:
	%MainButtons.visible = false
	%SettingsMenu.visible = true
	%SettingsMenu.grab_focus()

func _on_credits_pressed() -> void:
	%MainButtons.visible = false
	%CreditsMenu.visible = true
	$%CreditsMenu.grab_focus()

func _on_back_pressed() -> void:
	%MainButtons.visible = true
	%MainButtons.grab_focus()
	
	if(%SettingsMenu.visible):
		%SettingsMenu.visible = false
		%SettingsMenu.release_focus()
		
	if(%CreditsMenu.visible):
		%CreditsMenu.visible = false
		%SettingsMenu.release_focus()

func _on_fullscreen_toggled(toggled_on: bool) -> void:
	if (toggled_on):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_mainvolslider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("Master"), value)

func _on_musicvolslider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("MUSIC"), value)

func _on_sfxvolslider_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_linear(AudioServer.get_bus_index("SFX"), value)
