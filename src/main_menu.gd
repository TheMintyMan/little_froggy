extends Node2D


func _on_start_pressed() -> void:
	var main = get_tree().get_nodes_in_group("main").pop_back()
	if main == null:
		print("oh no! no level manager")
		return
	main.next_level()
