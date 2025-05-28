extends Node2D

#region Variables
# Variables concretas
@onready var pause_menu_scene := preload("res://menus/menu_options/scene/menu_options.tscn")
@onready var player = get_node("players/player_knight")
@onready var camera = player.get_node("cam_player")
@onready var menu_levels_scene = preload("res://menus/menu_levels/scene/menu_levels.tscn")
@onready var jefe = $enemies/player_boss_swamp
@onready var pared = $effects/BreakableWall
@onready var player1 := $players/player_knight
@onready var player2 = $players/player_cat
@onready var salida_nivel = $effects/end_level # Final del nivel
@export var limite_separacion := 300

# Señales
signal jugador_muerto(data: Dictionary, completado: bool)

# Variables genéricas
var pause_menu_instance: Node = null
var menu_levels_instance: Node = null
var modo_multijugador := Global.modo_multijugador
var salud_original_enemigos = {}
var jefes_vivos := 0
#endregion

#region Ready
func _ready():
	await get_tree().process_frame
	player.muerte_por_caida_desactivada = false
	player2.muerte_por_caida_desactivada = false
	player.establecer_limites_camara(2, 0, 2383, 1843)
	add_to_group("nivel")
	aplicar_configuracion_visual()
	mover_a_user_si_no_existe()
	pared.visible = true
	
	# Contar jefes vivos al cargar
	jefes_vivos = 0
	for jefe_individual in get_tree().get_nodes_in_group("jefes"):
		jefes_vivos += 1
		if jefe_individual.has_signal("enemigo_muerto") and not jefe_individual.is_connected("enemigo_muerto", Callable(self, "_on_jefe_muerto")):
			print("Jefe conectado correctamente")
			jefe_individual.connect("enemigo_muerto", Callable(self, "_on_jefe_muerto"), CONNECT_DEFERRED)

	salida_nivel.set_deferred("monitoring", false)  # Bloquear la salida al inicio
	
	if modo_multijugador:
		set_jugador2_activo(true)
		duplicar_salud_enemigos()
	else:
		set_jugador2_activo(false)
		restaurar_salud_enemigos()
	
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

#region Physics Process
func _physics_process(delta):
	if not modo_multijugador:
		return

	bloquear_jugadores_por_limites_de_camara()
	bloquear_jugadores_por_separacion()
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
#region Distance Players
func bloquear_jugadores_por_limites_de_camara():
	var cam_pos = camera.global_position
	var cam_size = camera.get_viewport_rect().size
	var limite_izquierdo = cam_pos.x - cam_size.x / 2
	var limite_derecho = cam_pos.x + cam_size.x / 2

	# Limitar player1 (knight)
	if player1.global_position.x < limite_izquierdo:
		player1.velocity.x = max(player1.velocity.x, 0)
	elif player1.global_position.x > limite_derecho:
		player1.velocity.x = min(player1.velocity.x, 0)

	# Limitar player2 (cat), solo si sigue existiendo
	if is_instance_valid(player2):
		if player2.global_position.x < limite_izquierdo:
			player2.velocity.x = max(player2.velocity.x, 0)
		elif player2.global_position.x > limite_derecho:
			player2.velocity.x = min(player2.velocity.x, 0)

func bloquear_jugadores_por_separacion():
	if not is_instance_valid(player2):
		return
	
	var distancia = player1.global_position.x - player2.global_position.x

	if abs(distancia) > limite_separacion:
		if distancia > 0:
			# player1 está delante → player2 muy atrás
			player1.velocity.x = min(player1.velocity.x, 0) # bloquea avance
			player2.velocity.x = max(player2.velocity.x, 0) # bloquea retroceso
		else:
			# player2 está delante → player1 muy atrás
			player2.velocity.x = min(player2.velocity.x, 0) # bloquea avance
			player1.velocity.x = max(player1.velocity.x, 0) # bloquea retroceso
#endregion

#region Player 2
func set_jugador2_activo(activo: bool):
	player2.visible = activo
	player2.set_physics_process(activo)
	player2.set_process(activo)
	player2.set_process_input(activo)
	player2.set_process_unhandled_input(activo)

	if activo:
		player2.jugador_principal = player1

	# Activar o desactivar colisiones
	for shape in player2.get_children():
		if shape is CollisionShape2D:
			shape.disabled = not activo
		elif shape.has_method("get_children"):
			for child in shape.get_children():
				if child is CollisionShape2D:
					child.disabled = not activo

#endregion

#region Health Enemies
func duplicar_salud_enemigos():
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if "max_health" in enemigo and enemigo.has_node("bar_health/TextureProgressBar"):
			var barra = enemigo.get_node("bar_health/TextureProgressBar")
			var salud = enemigo.max_health

			# Guardar salud original solo si aún no se ha hecho
			if not salud_original_enemigos.has(enemigo):
				salud_original_enemigos[enemigo] = salud

			enemigo.max_health = salud * 2
			enemigo.current_health = enemigo.max_health
			barra.max_value = enemigo.max_health
			barra.value = enemigo.current_health

func restaurar_salud_enemigos():
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		if salud_original_enemigos.has(enemigo):
			var salud = salud_original_enemigos[enemigo]
			if enemigo.has_node("bar_health/TextureProgressBar"):
				var barra = enemigo.get_node("bar_health/TextureProgressBar")
				enemigo.max_health = salud
				enemigo.current_health = salud
				barra.max_value = salud
				barra.value = salud
#endregion

#region Nodes Connection
func _on_jugador_muerto(data: Dictionary, completado: bool):
	get_tree().paused = true
	menu_levels_instance.mostrar_estadisticas(data, completado, get_scene_file_path())
	guardar_estadisticas(data, completado)
	menu_levels_instance.show()

func _on_jefe_muerto(es_jefe):
	print("Se ha ejecutado _on_jefe_muerto")
	player.registrar_muerte_de_jefe()
	
	jefes_vivos -= 1
	if jefes_vivos <= 0:
		# Todos los jefes han muerto, se activa la salida
		if salida_nivel:
			print("Todos los jefes muertos. Activando salida.")
			salida_nivel.set_deferred("monitoring", true)

	# Emitir al final, para evitar pausar antes de activar salida
	var data = {
		"tiempo": player.contador3.obtener_tiempo(),
		"monedas": player.monedas,
		"runas": player.runas,
		"enemigos": player.enemigos_muertos,
		"jefes": player.jefes_muertos
	}
	emit_signal("jugador_muerto", data, true)
#endregion
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
