extends Node2D

@onready var pause_menu_scene := preload("res://menus/menu_options/scene/menu_options.tscn")
@onready var player = get_node("player_knight") # o tu ruta real
@onready var menu_levels_scene = preload("res://menus/menu_levels/scene/menu_levels.tscn")

var pause_menu_instance: Node = null
var menu_levels_instance: Node = null

func _ready():
	# Menú de pausa
	pause_menu_instance = pause_menu_scene.instantiate()
	add_child(pause_menu_instance)
	pause_menu_instance.hide()

	# Menú de estadísticas
	menu_levels_instance = menu_levels_scene.instantiate()
	add_child(menu_levels_instance)
	menu_levels_instance.hide()

	# Conexión a enemigos ya en la escena
	for enemy in get_tree().get_nodes_in_group("enemigos"):
		player.conectar_enemigo(enemy)
		
	# Conectar señal de muerte del jugador
	player.connect("jugador_muerto", Callable(self, "_on_jugador_muerto"))

func _input(event):
	if event.is_action_pressed("pausa"):
		if get_tree().paused:
			get_tree().paused = false
			pause_menu_instance.hide()
		else:
			get_tree().paused = true
			pause_menu_instance.show()

func _on_jugador_muerto(data: Dictionary, completado: bool):
	get_tree().paused = true
	menu_levels_instance.mostrar_estadisticas(data, completado, get_scene_file_path())
	menu_levels_instance.show()
