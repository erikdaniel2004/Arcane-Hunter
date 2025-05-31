extends CanvasLayer

#region Variables
@onready var lbl_coins = $resources/labels/lbl_coins
@onready var lbl_runes = $resources/labels/lbl_runes
@onready var lbl_timer = $resources/labels/lbl_timer
@onready var lbl_enemies = $resources/labels/lbl_enemies
@onready var lbl_bosses = $resources/labels/lbl_bosses
@onready var lbl_deaths = $resources/labels/lbl_deaths
@onready var confirm_restart_dialog = $confirm_restart_dialog
#endregion

#region Generic Functions
#region Stats
func cargar_estadisticas():
	var path = "user://JSON/stats.json"
	if FileAccess.file_exists(path):
		var archivo = FileAccess.open(path, FileAccess.READ)
		var contenido = archivo.get_as_text()
		var resultado = JSON.parse_string(contenido)

		if resultado is Dictionary:
			var datos = resultado
			lbl_coins.text = "Monedas: %d" % datos.monedas
			lbl_runes.text = "Runas totales: %d" % datos.runas
			lbl_timer.text = "Tiempo: %.2fs" % datos.tiempo
			lbl_enemies.text = "Enemigos derrotados: %d" % datos.enemigos
			lbl_bosses.text = "Jefes derrotados: %d" % datos.jefes
			lbl_deaths.text = "Muertes: %d" % datos.muertes
		else:
			print("Error al parsear el JSON de estadísticas. Contenido:", contenido)

#endregion

#region Nodes Conecction
#region Back
func _on_btn_back_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/menu/scene/menu.tscn")
#endregion

#region Restart
func _on_btn_restart_pressed() -> void:
	confirm_restart_dialog.popup_centered()
#endregion

#region Confirm
func _on_confirm_restart_dialog_confirmed() -> void:
	var path = "user://JSON/stats.json"

	# Crear estructura vacía
	var datos_reiniciados = {
		"monedas": 0,
		"runas": 0,
		"tiempo": 0.0,
		"enemigos": 0,
		"jefes": 0,
		"muertes": 0
	}

	# Guardar los datos reiniciados (con cierre seguro del archivo)
	var archivo := FileAccess.open(path, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos_reiniciados))
		archivo = null  # fuerza cierre

	# Recargar estadísticas
	cargar_estadisticas()
#endregion
#endregion
#endregion
