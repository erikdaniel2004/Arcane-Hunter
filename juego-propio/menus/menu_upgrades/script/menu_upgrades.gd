extends CanvasLayer

#region Variables
const PATH_MEJORAS := "user://JSON/upgrades.json"
const PATH_STATS := "user://JSON/stats.json"

# Coste progresivo hasta 10 niveles
const MAX_NIVEL = 10
const COSTES := [5, 10, 15, 30, 60, 120, 240, 480, 600, 850, 1000]

# Diccionario con los niveles de mejora actuales
var mejoras = {
	"vida": 0,
	"daño": 0,
	"velocidad": 0
}

# Referencias visuales
@onready var pb_vida = $resources/progress_bars/progressbar_health
@onready var pb_danio = $resources/progress_bars/progressbar_damage
@onready var pb_velocidad = $resources/progress_bars/progressbar_velocity

@onready var btn_salud = $resources/buttons/btn_plus_health
@onready var btn_danio = $resources/buttons/btn_plus_damage
@onready var btn_velocidad = $resources/buttons/btn_plus_velocity
#endregion

#region Ready
func _ready():
	cargar_mejoras()
	actualizar_barras()
#endregion

#region Generic Functions
#region Upgrades
# Confirmación antes de comprar
func confirmar_mejora(attr: String):
	var nivel = mejoras[attr]
	if nivel >= MAX_NIVEL:
		mostrar_mensaje("¡Ya has alcanzado el nivel máximo en " + attr + "!")
		return

	var coste = COSTES[nivel]
	var stats = cargar_json(PATH_STATS)
	var runas = stats.get("runas", 0)

	if runas < coste:
		mostrar_mensaje("No tienes suficientes runas. Necesitas %d." % coste)
		return

	var dialogo = ConfirmationDialog.new()
	dialogo.dialog_text = "¿Gastar %d runas para mejorar %s?" % [coste, attr.capitalize()]
	dialogo.get_ok_button().text = "Aceptar"
	dialogo.get_cancel_button().text = "Cancelar"
	add_child(dialogo)

	dialogo.confirmed.connect(func():
		aplicar_mejora(attr, coste)
		remove_child(dialogo)
		dialogo.queue_free()
	)

	dialogo.canceled.connect(func():
		remove_child(dialogo)
		dialogo.queue_free()
	)

	dialogo.popup_centered()

# Aplica la mejora, resta runas y guarda
func aplicar_mejora(attr: String, coste: int):
	mejoras[attr] += 1
	guardar_json(PATH_MEJORAS, mejoras)
	actualizar_barras()

	var stats = cargar_json(PATH_STATS)
	stats["runas"] = max(0, stats["runas"] - coste)
	guardar_json(PATH_STATS, stats)

# Cargar archivo de mejoras
func cargar_mejoras():
	if FileAccess.file_exists(PATH_MEJORAS):
		var datos = cargar_json(PATH_MEJORAS)
		for clave in mejoras.keys():
			mejoras[clave] = datos.get(clave, 0)
	else:
		guardar_json(PATH_MEJORAS, mejoras)
#endregion

#region Progress Bar
# Actualizar la UI visual de las barras
func actualizar_barras():
	pb_vida.value = mejoras["vida"]
	pb_danio.value = mejoras["daño"]
	pb_velocidad.value = mejoras["velocidad"]
#endregion

#region Messages
# Mostrar popup simple
func mostrar_mensaje(texto: String):
	var popup = AcceptDialog.new()
	popup.dialog_text = texto
	add_child(popup)
	popup.popup_centered()
#endregion

#region JSON
# Utilidades de JSON
func cargar_json(ruta: String) -> Dictionary:
	if not FileAccess.file_exists(ruta):
		return {}
	var file = FileAccess.open(ruta, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	return data if typeof(data) == TYPE_DICTIONARY else {}

func guardar_json(ruta: String, data: Dictionary):
	var file = FileAccess.open(ruta, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
#endregion

#region Nodes Connection
#region Back
func _on_btn_back_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://menus/menu/scene/menu.tscn")
#endregion

#region Restart
func _on_btn_restart_pressed() -> void:
	var runas_a_devolver = 0
	for atributo in mejoras.keys():
		for i in range(mejoras[atributo]):
			runas_a_devolver += COSTES[i]

	var dialogo = ConfirmationDialog.new()
	dialogo.dialog_text = "¿Reiniciar todas las mejoras?\nRecibirás %d runas a cambio." % runas_a_devolver
	dialogo.get_ok_button().text = "Aceptar"
	dialogo.get_cancel_button().text = "Cancelar"
	add_child(dialogo)

	dialogo.confirmed.connect(func():
		# Devolver runas al archivo stats.json
		var stats = cargar_json(PATH_STATS)
		stats["runas"] += runas_a_devolver
		guardar_json(PATH_STATS, stats)

		# Resetear mejoras y actualizar
		mejoras = {"vida": 0, "daño": 0, "velocidad": 0}
		guardar_json(PATH_MEJORAS, mejoras)
		actualizar_barras()
		remove_child(dialogo)
		dialogo.queue_free()
	)

	dialogo.canceled.connect(func():
		remove_child(dialogo)
		dialogo.queue_free()
	)

	dialogo.popup_centered()
#endregion

#region Buttons Plus
func _on_btn_plus_health_pressed():
	confirmar_mejora("vida")

func _on_btn_plus_damage_pressed():
	confirmar_mejora("daño")

func _on_btn_plus_velocity_pressed():
	confirmar_mejora("velocidad")
	#endregion
#endregion
#endregion
