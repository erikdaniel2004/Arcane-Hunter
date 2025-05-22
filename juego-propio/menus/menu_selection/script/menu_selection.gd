extends CanvasLayer

#region Generic Functions
#region Nodes Connections
#region Start Level 1
func _on_btn_start_pressed():
	get_tree().change_scene_to_file("res://environment/scenes/environment.tscn")
#endregion

#region Start Level 2
func _on_btn_start_2_pressed() -> void:
	get_tree().change_scene_to_file("res://environment/scenes/environment2.tscn")
#endregion

#region Exit
func _on_btn_salir_pressed():
	get_tree().change_scene_to_file("res://menus/menu/scene/menu.tscn")
#endregion
#endregion
#endregion
