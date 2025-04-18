extends Control

func _on_btn_start_pressed():
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")


func _on_btn_end_pressed():
	get_tree().quit()
