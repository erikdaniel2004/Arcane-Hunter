extends CanvasLayer

#region Variables
@onready var menu_settings = preload("res://menus/menu_settings/scene/menu_settings.tscn").instantiate()
@onready var resources = $resources
#endregion

#region Ready
func _ready():
	aplicar_volumen_desde_config()
#endregion

#region Generic Functions
#region Settings
func aplicar_volumen_desde_config():
	var path = "user://JSON/config.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var config = JSON.parse_string(file.get_as_text())
		if config is Dictionary:
			var musica = config.get("musica", 0.5)
			var sonidos = config.get("sonidos", 0.5)

			var music_bus_index = AudioServer.get_bus_index("Music")
			if music_bus_index != -1:
				AudioServer.set_bus_volume_db(music_bus_index, linear_to_db(musica))
			var sfx_bus_index = AudioServer.get_bus_index("SFX")
			if sfx_bus_index != -1:
				AudioServer.set_bus_volume_db(sfx_bus_index, linear_to_db(sonidos))

func linear_to_db(value: float) -> float:
	return -80 if value == 0 else 20 * log(value) / log(10)

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

#region Stats
func _on_btn_stats_pressed():
	var menu_stats = preload("res://menus/menu_stats/scene/menu_stats.tscn").instantiate()
	add_child(menu_stats)
	await get_tree().process_frame
	menu_stats.cargar_estadisticas()
	hide()
#endregion

#region Credits
func _on_btn_credits_pressed() -> void:
	var menu_credits = preload("res://menus/menu_credits/scene/menu_credits.tscn").instantiate()
	add_child(menu_credits)
	await get_tree().process_frame
	hide()
#endregion

#region Help
func _on_btn_help_pressed() -> void:
	var ruta_absoluta: String

	if Engine.is_editor_hint():
		ruta_absoluta = ProjectSettings.globalize_path("res://docs/manual_usuario.pdf")
	else:
		var base = OS.get_executable_path().get_base_dir()
		ruta_absoluta = base.path_join("docs").path_join("manual_usuario.pdf")

	print("Intentando abrir:", ruta_absoluta)

	if FileAccess.file_exists(ruta_absoluta):
		OS.shell_open(ruta_absoluta)
	else:
		print("No se encontró el manual en la carpeta docs junto al .exe")
#endregion

#region Upgrades
func _on_btn_upgrades_pressed() -> void:
	var menu_upgrades = preload("res://menus/menu_upgrades/scene/menu_upgrades.tscn").instantiate()
	add_child(menu_upgrades)
	await get_tree().process_frame
	hide()
#endregion

#region Exit
func _on_btn_end_pressed():
	get_tree().quit()
#endregion
#endregion
#endregion
