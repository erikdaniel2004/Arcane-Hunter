extends CanvasLayer

#region Variables
@onready var lbl_coins = $resources/labels/lbl_coins
@onready var lbl_runes = $resources/labels/lbl_runes
@onready var lbl_timer = $resources/labels/lbl_timer
@onready var lbl_enemies = $resources/labels/lbl_enemies
@onready var lbl_bosses = $resources/labels/lbl_bosses
@onready var lbl_deaths = $resources/labels/lbl_deaths
#endregion

#region Generic Functions
#region Stats
func cargar_estadisticas():
	var path = "user://JSON/stats.json"
	if FileAccess.file_exists(path):
		var archivo = FileAccess.open(path, FileAccess.READ)
		var resultado = JSON.parse_string(archivo.get_as_text())
		if resultado is Dictionary:
			var datos = resultado
			if datos:
				lbl_coins.text = "Monedas: %d" % datos.monedas
				lbl_runes.text = "Runas totales: %d" % datos.runas
				lbl_timer.text = "Tiempo: %.2fs" % datos.tiempo
				lbl_enemies.text = "Enemigos derrotados: %d" % datos.enemigos
				lbl_bosses.text = "Jefes derrotados: %d" % datos.jefes
				lbl_deaths.text = "Muertes: %d" % datos.muertes
#endregion

#region Nodes Conecction
#region Back
func _on_btn_back_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/menu/scene/menu.tscn")
#endregion
#endregion
#endregion
