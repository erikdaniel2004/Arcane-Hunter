extends CanvasLayer

#region Variables
# Rutas de las texturas de las barras
const BAR_FILL = preload("res://interface/2 Bars/Loading_bar1.png")
const BAR_EMPTY = preload("res://interface/2 Bars/Loading_bar2.png")

@onready var music_slider = $resources/sliders/slider_music
@onready var sounds_slider = $resources/sliders/slider_sounds
@onready var music_bar = $resources/progress_bars/progressbar_music
@onready var sounds_bar = $resources/progress_bars/progressbar_sounds
@onready var tick_fullscreen = $resources/images/icon_tick
@onready var btn_close = $resources/buttons/btn_close
@onready var btn_apply = $resources/buttons/btn_apply
var menu_padre: Node = null
#endregion

#region Ready
func _ready():
	# Inicialmente está oculto para que este menú no aparezca por pantalla
	hide()
	
	# Sliders invisibles pero activos
	music_slider.modulate.a = 0
	sounds_slider.modulate.a = 0

	# Texturas personalizadas
	_set_bar_style(music_bar)
	_set_bar_style(sounds_bar)
	
	music_slider.connect("value_changed", Callable(self, "_on_slider_music_value_changed"))
	sounds_slider.connect("value_changed", Callable(self, "_on_slider_sounds_value_changed"))

	# Volumen inicial (temporal)
	var default_volume := 0.5
	music_slider.value = default_volume
	sounds_slider.value = default_volume
	music_bar.value = default_volume
	sounds_bar.value = default_volume
	_update_audio_volumes()

	# Ocultar tick si no está en pantalla completa
	tick_fullscreen.visible = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
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
	self.hide()
	if menu_padre:
		menu_padre.show()


func _on_btn_fullscreen_pressed():
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	if is_fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		tick_fullscreen.visible = false
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		tick_fullscreen.visible = true

func linear_to_db(value: float) -> float:
	return -80 if value == 0 else 20 * log(value) / log(10)

func _set_bar_style(bar: TextureProgressBar):
	bar.texture_progress = BAR_FILL
	bar.texture_under = BAR_EMPTY

func _update_audio_volumes():
	_on_slider_music_value_changed(music_slider.value)
	_on_slider_sounds_value_changed(sounds_slider.value)
#endregion
