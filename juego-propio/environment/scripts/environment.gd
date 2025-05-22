extends Node2D

#region Variables
@onready var pause_menu_scene := preload("res://menus/menu_options/scene/menu_options.tscn")
@onready var player = get_node("player_knight")
@onready var camera = player.get_node("cam_player")
@onready var menu_levels_scene = preload("res://menus/menu_levels/scene/menu_levels.tscn")
@onready var jefe = $enemies/player_boss_swamp
@onready var pared = $effects/BreakableWall
signal jugador_muerto(data: Dictionary, completado: bool)
var pause_menu_instance: Node = null
var menu_levels_instance: Node = null
#endregion

#region Ready
func _ready():
	await get_tree().process_frame
	player.muerte_por_caida_desactivada = false
	player.establecer_limites_camara(2, 0, 2383, 1843)
	player.conectar_enemigo(jefe)
	if jefe.has_signal("enemigo_muerto"):
		jefe.connect("enemigo_muerto", Callable(self, "_on_jefe_muerto"), CONNECT_DEFERRED)
	add_to_group("nivel")
	aplicar_configuracion_visual()
	mover_a_user_si_no_existe()
	pared.visible = true
	
	# Menú de pausa
	pause_menu_instance = pause_menu_scene.instantiate()
	add_child(pause_menu_instance)
	pause_menu_instance.hide()

	# Menú de estadísticas
	menu_levels_instance = menu_levels_scene.instantiate()
	add_child(menu_levels_instance)
	menu_levels_instance.hide()

	# Conexión a enemigos ya en la escena
	await get_tree().process_frame
	for enemy in get_tree().get_nodes_in_group("enemigos"):
		player.conectar_enemigo(enemy)
	
	# Conectar señal de muerte del jugador
	player.connect("jugador_muerto", Callable(self, "_on_jugador_muerto"))
#endregion

#region Input
func _input(event):
	if event.is_action_pressed("pausa"):
		if get_tree().paused:
			get_tree().paused = false
			pause_menu_instance.hide()
		else:
			get_tree().paused = true
			pause_menu_instance.show()
#endregion

#region Generic Functions

#region Nodes Connection
func _on_jugador_muerto(data: Dictionary, completado: bool):
	get_tree().paused = true
	menu_levels_instance.mostrar_estadisticas(data, completado, get_scene_file_path())
	guardar_estadisticas(data, completado)
	menu_levels_instance.show()

func _on_jefe_muerto(es_jefe):
	print("Se ha ejecutado _on_jefe_muerto")
	player.registrar_muerte_de_jefe()
	
	var data = {
		"tiempo": player.contador3.obtener_tiempo(),
		"monedas": player.monedas,
		"runas": player.runas,
		"enemigos": player.enemigos_muertos,
		"jefes": player.jefes_muertos
	}
	emit_signal("jugador_muerto", data, true)
#endregion

#region Save Stats
func guardar_estadisticas(data: Dictionary, completado: bool):
	var path = "user://JSON/stats.json"
	var estadisticas_totales = {
		"monedas": 0,
		"runas": 0,
		"tiempo": 0.0,
		"enemigos": 0,
		"jefes": 0,
		"muertes": 0
	}

	if FileAccess.file_exists(path):
		var archivo_lectura = FileAccess.open(path, FileAccess.READ)
		var existentes = JSON.parse_string(archivo_lectura.get_as_text())
		if existentes is Dictionary:
			estadisticas_totales = existentes

	# Suma totales
	estadisticas_totales.monedas += data.monedas
	estadisticas_totales.runas += data.runas
	estadisticas_totales.tiempo += data.tiempo
	estadisticas_totales.enemigos += data.enemigos
	estadisticas_totales.jefes += data.jefes
	if not completado:
		estadisticas_totales.muertes += 1

	var archivo_escritura = FileAccess.open(path, FileAccess.WRITE)
	archivo_escritura.store_string(JSON.stringify(estadisticas_totales))
#endregion

#region Settings JSON
func mover_a_user_si_no_existe():
	var origen_directorio := "res://JSON"
	var destino_directorio := "user://JSON"

	# Asegurar que exista el directorio destino
	if not DirAccess.dir_exists_absolute(destino_directorio):
		var dir_user = DirAccess.open("user://")
		dir_user.make_dir("JSON")

	var dir_origen = DirAccess.open(origen_directorio)
	if dir_origen:
		dir_origen.list_dir_begin()
		var archivo := dir_origen.get_next()
		while archivo != "":
			if not dir_origen.current_is_dir() and archivo.ends_with(".json"):
				var ruta_origen = origen_directorio + "/" + archivo
				var ruta_destino = destino_directorio + "/" + archivo

				if not FileAccess.file_exists(ruta_destino):
					var archivo_origen = FileAccess.open(ruta_origen, FileAccess.READ)
					var contenido = archivo_origen.get_as_text()
					var archivo_destino = FileAccess.open(ruta_destino, FileAccess.WRITE)
					archivo_destino.store_string(contenido)
			archivo = dir_origen.get_next()
		dir_origen.list_dir_end()

func aplicar_configuracion_visual():
	var path = "user://JSON/config.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var resultado = JSON.parse_string(file.get_as_text())
		if resultado is Dictionary:
			var config: Dictionary = resultado
			var activar_efectos : bool = config.get("efectos_visuales", true)

			for nodo in get_tree().get_nodes_in_group("efectos_visuales"):
				if nodo is Node:
					nodo.visible = activar_efectos
				if nodo.has_method("emitting"):
					nodo.emitting = activar_efectos
				if "efectos_visuales_activos" in nodo:
					nodo.efectos_visuales_activos = activar_efectos
#endregion
#endregion
