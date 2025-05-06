extends CanvasLayer

#region Variables
@onready var menu_settings = preload("res://menus/menu_settings/scene/menu_settings.tscn").instantiate()
@onready var resources = $resources
#endregion

#region Ready
func _ready():
	# Escala el contenido si estamos en pantalla completa
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		ajustar_escala_a_pantalla()
#endregion

#region Generic Functions

#region Fullscreen
func ajustar_escala_a_pantalla():
	var viewport_size = get_viewport().get_visible_rect().size
	var diseño_base = Vector2(384, 216) * 3
	var factor_escala = viewport_size / diseño_base
	var escala_final = min(factor_escala.x, factor_escala.y)

	# Escala solo el nodo de contenido visual
	if has_node("resources"):
		var contenido = resources
		contenido.scale = Vector2(escala_final, escala_final)

		if contenido is Control:
			await get_tree().process_frame
			var size = contenido.get_combined_minimum_size()
			contenido.position = (viewport_size - size * escala_final) / 2
#endregion

#region Nodes Connections
#region Start
func _on_btn_start_pressed():
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")
#endregion

#region Settings
func _on_btn_settings_pressed():	
	menu_settings.menu_padre = self
	add_child(menu_settings)
	menu_settings.show()
	self.hide()
#endregion

#region Exit
func _on_btn_end_pressed():
	get_tree().quit()
#endregion
#endregion
#endregion
