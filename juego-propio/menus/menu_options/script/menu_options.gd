extends CanvasLayer

#region Variables
@onready var btn_resume = $resources/btn_resume
@onready var btn_restart = $resources/btn_restart
@onready var btn_levels = $resources/btn_levels
@onready var btn_settings = $resources/btn_settings
@onready var btn_quit = $resources/btn_quit
@onready var btn_quit2 = $resources/btn_quit2
@onready var color_rect = $color_rect
#endregion

#region Ready
func _ready():
	hide()
#endregion

#region Options
func _unpause_and_close():
	get_tree().paused = false
	color_rect.visible = false
	hide()

func _on_btn_continue_pressed():
	_unpause_and_close()

func _on_btn_restart_pressed():
	get_tree().paused = false
	var current_scene = get_tree().current_scene.scene_file_path
	_unpause_and_close()
	get_tree().change_scene_to_file(current_scene)

func _on_btn_levels_pressed():
	get_tree().paused = false
	_unpause_and_close()
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")

func _on_btn_settings_pressed():
	var ajustes = preload("res://menus/menu_settings/scene/menu_settings.tscn").instantiate()
	ajustes.menu_padre = self
	for nodo in get_tree().get_nodes_in_group("nivel"):
		if nodo.has_method("aplicar_configuracion_visual"):
			ajustes.entorno_nivel = nodo
			break
	add_child(ajustes)
	ajustes.show()
	self.hide()

func _on_btn_quit_pressed():
	get_tree().paused = false
	_unpause_and_close()
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")

func _on_btn_quit2_pressed():
	get_tree().paused = false
	_unpause_and_close()
#endregion
