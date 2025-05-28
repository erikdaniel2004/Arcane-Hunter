extends CanvasLayer

#region Generic Functions
#region Nodes Connection
#region Options
func _on_btn_quit_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/menu/scene/menu.tscn")
#endregion
#endregion
#endregion
