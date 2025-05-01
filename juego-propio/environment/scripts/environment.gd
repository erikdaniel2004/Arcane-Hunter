extends Node2D

@onready var pause_menu_scene := preload("res://menus/menu_options/scene/menu_options.tscn")
var pause_menu_instance: Node = null

func _ready():
	# Instanciar el menú y añadirlo como hijo oculto
	pause_menu_instance = pause_menu_scene.instantiate()
	add_child(pause_menu_instance)
	pause_menu_instance.hide()

func _input(event):
	if event.is_action_pressed("pausa"):
		if get_tree().paused:
			get_tree().paused = false
			pause_menu_instance.hide()
		else:
			get_tree().paused = true
			pause_menu_instance.show()
