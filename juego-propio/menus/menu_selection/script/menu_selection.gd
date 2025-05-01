extends Control

#region Generic Functions
#region Nodes Connections
#region Start
func _on_btn_start_pressed():
	get_tree().change_scene_to_file("res://environment/scenes/environment.tscn")
#endregion

#region Exit
func _on_btn_salir_pressed():
	get_tree().change_scene_to_file("res://menus/menu/scene/menu.tscn")
#endregion
#endregion
#endregion
