extends CanvasLayer

#region Variables
@onready var lbl_level = $resources/labels/lbl_level
@onready var lbl_score = $resources/labels/lbl_score
@onready var lbl_time = $resources/labels/lbl_time
@onready var lbl_coins = $resources/labels/lbl_coins
@onready var lbl_runes = $resources/labels/lbl_runes
@onready var lbl_enemies = $resources/labels/lbl_enemies
@onready var btn_restart = $resources/buttons/btn_restart
@onready var btn_back = $resources/buttons/btn_back
@onready var star_empty = [$resources/images/Star, $resources/images/Star2, $resources/images/Star3]
@onready var star_full = [$resources/images/Star4, $resources/images/Star5, $resources/images/Star6]

var nombre_nivel_actual := ""  # Se establece desde el nivel al mostrar el menú
var nivel_completado := false  # Se guarda el estado del nivel actual
#endregion

#region Generic Functions
#region Stats
func mostrar_estadisticas(data: Dictionary, completado: bool, nivel_actual: String):
	nombre_nivel_actual = nivel_actual
	nivel_completado = completado

	lbl_level.text = "¡Nivel completado!" if completado else "¡Has muerto!"
	lbl_time.text = "Tiempo: %.2fs" % data.tiempo
	lbl_coins.text = "Monedas: %d" % data.monedas
	lbl_runes.text = "Runas: %d" % data.runas
	lbl_enemies.text = "Enemigos totales: %d" % data.enemigos

	var puntaje = (data.monedas * 600) + (data.runas * 2500) + (data.enemigos * 5800) + (data.jefes * 26100)
	puntaje -= int(data.tiempo) * 100
	if puntaje < 0:
		puntaje = 0
	lbl_score.text = "Puntaje: %d" % puntaje
	
	# Mostrar estrellas según el puntaje
	mostrar_estrellas(puntaje)
	self.show()

func mostrar_estrellas(puntaje: int):
	var maximo = 100000
	var umbral_1 = maximo * 0.3
	var umbral_2 = maximo * 0.6
	var umbral_3 = maximo * 0.8

	# Ocultar todas las estrellas llenas
	for estrella in star_full:
		estrella.visible = false

	# Mostrar según umbral
	if puntaje >= umbral_1:
		star_full[0].visible = true
	if puntaje >= umbral_2:
		star_full[1].visible = true
	if puntaje >= umbral_3:
		star_full[2].visible = true
#endregion

#region Nodes Connection
#region Restart
func _on_btn_restart_pressed():
	get_tree().paused = false
	if nombre_nivel_actual != "":
		get_tree().change_scene_to_file(nombre_nivel_actual)
#endregion

#region Back
func _on_btn_back_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")
#endregion
#endregion
#endregion
