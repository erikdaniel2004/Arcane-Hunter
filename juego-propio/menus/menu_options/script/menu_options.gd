extends CanvasLayer

#region Nodes
@onready var menu_panel = $menu_options
@onready var btn_resume = $menu_options/Control2/btn_resume
@onready var btn_restart = $menu_options/Control2/btn_restart
@onready var btn_levels = $menu_options/Control2/btn_levels
@onready var btn_settings = $menu_options/Control2/btn_settings
@onready var btn_quit = $menu_options/Control2/btn_quit
@onready var btn_quit2 = $menu_options/Control2/btn_quit2
#endregion

#region Ready
func _ready():
	menu_panel.hide()
#endregion

func _input(event):
	if event.is_action_pressed("pausa"):
		if menu_panel.visible:
			menu_panel.hide()
			get_tree().paused = false
		else:
			await get_tree().process_frame  # Espera a que se actualice el tamaño del panel
			var viewport_size = get_viewport().size
			menu_panel.rect_position = (viewport_size - menu_panel.rect_size) / 2
			menu_panel.show()
			get_tree().paused = true

func _unpause_and_close():
	get_tree().paused = false
	menu_panel.hide()

#region Actions
func _on_btn_continue_pressed():
	_unpause_and_close()

func _on_btn_restart_pressed():
	var current_scene = get_tree().current_scene.scene_file_path
	_unpause_and_close()
	get_tree().change_scene_to_file(current_scene)

func _on_btn_levels_pressed():
	_unpause_and_close()
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")

func _on_btn_settings_pressed():
	_unpause_and_close()
	get_tree().change_scene_to_file("res://menus/menu_settings/scene/menu_settings.tscn")

func _on_btn_quit_pressed():
	_unpause_and_close()
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")
	
func _on_btn_quit2_pressed():
	_unpause_and_close()
#endregion
