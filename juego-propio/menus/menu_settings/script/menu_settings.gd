extends CanvasLayer

#region Variables
# Rutas de las texturas de las barras
const BAR_FILL = preload("res://interface/2 Bars/Loading_bar1.png")
const BAR_EMPTY = preload("res://interface/2 Bars/Loading_bar2.png")

@onready var music_slider = $resources/sliders/slider_music
@onready var sounds_slider = $resources/sliders/slider_sounds
@onready var music_bar = $resources/progress_bars/progressbar_music
@onready var sounds_bar = $resources/progress_bars/progressbar_sounds
@onready var tick_effects = $resources/images/icon_tick
@onready var btn_close = $resources/buttons/btn_close
@onready var btn_apply = $resources/buttons/btn_apply
var menu_padre: Node = null
var entorno_nivel: Node = null
#endregion

#region Ready
func _ready():
	var path = "user://JSON/config.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var config = JSON.parse_string(file.get_as_text())
		if config:
			music_slider.value = config.get("musica", 0.5)
			sounds_slider.value = config.get("sonidos", 0.5)
			tick_effects.visible = config.get("efectos_visuales", true)

	# Sliders invisibles pero activos
	music_slider.modulate.a = 0
	sounds_slider.modulate.a = 0

	_set_bar_style(music_bar)
	_set_bar_style(sounds_bar)

	music_bar.value = music_slider.value
	sounds_bar.value = sounds_slider.value
	_update_audio_volumes()

	music_slider.connect("value_changed", Callable(self, "_on_slider_music_value_changed"))
	sounds_slider.connect("value_changed", Callable(self, "_on_slider_sounds_value_changed"))
	hide()
#endregion

#region Options
func _on_slider_music_value_changed(value):
	music_bar.value = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(value))

func _on_slider_sounds_value_changed(value):
	sounds_bar.value = value
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(value))

func _on_btn_close_pressed():
	self.hide()
	if menu_padre:
		menu_padre.show()

func _on_btn_apply_pressed():
	var path = "user://JSON/config.json"
	var config_actual := {
		"musica": music_slider.value,
		"sonidos": sounds_slider.value,
		"efectos_visuales": tick_effects.visible
	}

	# Leer configuración previa para comparar
	var efectos_visuales_anterior : bool = tick_effects.visible
	if FileAccess.file_exists(path):
		var file_lectura = FileAccess.open(path, FileAccess.READ)
		var config_previa = JSON.parse_string(file_lectura.get_as_text())
		if config_previa is Dictionary and config_previa.has("efectos_visuales"):
			efectos_visuales_anterior = config_previa["efectos_visuales"]

	# Guardar configuración nueva
	var file_escritura = FileAccess.open(path, FileAccess.WRITE)
	file_escritura.store_string(JSON.stringify(config_actual))

	# Si ha cambiado efectos_visuales, reiniciar el nivel
	if efectos_visuales_anterior != config_actual["efectos_visuales"]:
		var current_scene = get_tree().current_scene.scene_file_path
		get_tree().paused = false
		get_tree().change_scene_to_file(current_scene)
	else:
		# No reiniciar, solo cerrar el menú
		self.hide()
		if menu_padre:
			menu_padre.show()

	self.hide()
	if menu_padre:
		menu_padre.show()

func _on_btn_fullscreen_pressed():
	tick_effects.visible = !tick_effects.visible

func linear_to_db(value: float) -> float:
	return -80 if value == 0 else 20 * log(value) / log(10)

func _set_bar_style(bar: TextureProgressBar):
	bar.texture_progress = BAR_FILL
	bar.texture_under = BAR_EMPTY

func _update_audio_volumes():
	_on_slider_music_value_changed(music_slider.value)
	_on_slider_sounds_value_changed(sounds_slider.value)
#endregion
