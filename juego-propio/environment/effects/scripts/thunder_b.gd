extends Node2D

@onready var thunder_sprite = $thunder
@onready var flash_rect = $CanvasLayer/flash_rect
@onready var timer_trueno = $timer_thunder
@onready var audio_thunder = $audio_thunder
@onready var tween = create_tween()

func _ready():
	timer_trueno.timeout.connect(_on_timer_trueno_timeout)
	timer_trueno.wait_time = randf_range(1.0, 10.0)
	timer_trueno.start()
	randomize()  # Para que randf_range dé valores distintos en cada ejecución

	flash_rect.hide()
	flash_rect.color = Color(1, 1, 1, 0)

	# Evita mostrar el rayo desde el inicio
	thunder_sprite.stop()
	thunder_sprite.frame = 0
	thunder_sprite.hide()


	# Evita mostrar el rayo desde el inicio
	thunder_sprite.stop()
	thunder_sprite.frame = 0
	thunder_sprite.hide()

func _on_timer_trueno_timeout():
	await get_tree().create_timer(0.1).timeout
	reproducir_trueno()

	# Reinicia el temporizador con un nuevo tiempo aleatorio entre 1 y 10 segundos
	timer_trueno.wait_time = randf_range(1.0, 10.0)
	timer_trueno.start()


func reproducir_trueno():
	thunder_sprite.show()
	thunder_sprite.play("thunder")

	# Destello blanco inicial
	flash_rect.show()
	flash_rect.color = Color(1, 1, 1, 0.8)

	tween.kill()
	tween = create_tween()
	tween.tween_property(flash_rect, "color", Color(0.6, 0.8, 1.0, 0.4), 0.3)
	tween.tween_property(flash_rect, "color", Color(0.6, 0.8, 1.0, 0.0), 0.5)
	tween.tween_callback(Callable(flash_rect, "hide"))

	await get_tree().create_timer(0.3).timeout
	audio_thunder.play()

	await thunder_sprite.animation_finished
	thunder_sprite.hide()
	thunder_sprite.stop()
	thunder_sprite.frame = 0  # Reinicia a frame inicial

	await get_tree().create_timer(4.0).timeout
