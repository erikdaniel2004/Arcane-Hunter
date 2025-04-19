extends CharacterBody2D

@onready var ani_boss = $ani_boss
@onready var col_boss = $col_boss
@onready var audio_boss = $audio_boss
@onready var gravity: int = ProjectSettings.get("physics/2d/default_gravity")
@onready var detector_right = $detector_right
@onready var detector_left = $detector_left
@onready var area_ataque = $boss_area
@onready var bar_health = $bar_health/TextureProgressBar
@onready var timer_bar = $timer_bar
@onready var timer_dead = $timer_dead
@onready var timer_attack = $timer_attack

@export var max_health := 1000
@export var speed := 80
@export var charge_speed := 300
@export var x_activar := 925  # Coordenada X en la que empieza
@export var y_activar := 1775  # Coordenada Y en la que empieza

var current_health := max_health
var is_dead = false
var is_attacking = false
var is_burlando = false
var puede_atacar = true
var jugador_detectado: Node2D = null
var ultima_pos_jugador = Vector2.ZERO
var ha_comenzado = false  # Para evitar que el jefe empiece antes de tiempo


func _ready():
	add_to_group("enemigos")
	var jugadores = get_tree().get_nodes_in_group("player_knight")
	if jugadores.size() > 0:
		jugador_detectado = jugadores[0]


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not ha_comenzado:
		ani_boss.play("idle")

		if jugador_detectado != null and jugador_detectado.global_position.x >= x_activar and jugador_detectado.global_position.y >= y_activar:
			iniciar_combate()
		
		# Mover al menos para que el boss no esté congelado del todo
		velocity = Vector2.ZERO
		move_and_slide()
		return
		
	if is_attacking or is_burlando:
		move_and_slide()
		return

	if jugador_detectado:
		var distancia = global_position.distance_to(jugador_detectado.global_position)
		var direccion = (jugador_detectado.global_position - global_position).normalized()

		ani_boss.flip_h = jugador_detectado.global_position.x < global_position.x

		if puede_atacar:
			if distancia < 100:
				realizar_ataque("attack1")
			elif distancia < 200:
				realizar_ataque("attack2")
			elif distancia < 300:
				realizar_ataque("attack3")
			else:
				realizar_ataque("attack4")
		else:
			velocity = direccion * speed
	else:
		velocity = Vector2.ZERO

	move_and_slide()

func iniciar_combate():
	ha_comenzado = true
	is_burlando = true
	ani_boss.play("sneer")
	await get_tree().create_timer(3).timeout
	is_burlando = false
	puede_atacar = true

func realizar_ataque(tipo: String) -> void:
	is_attacking = true
	puede_atacar = false
	velocity = Vector2.ZERO
	ani_boss.play(tipo)

	# Guardamos la posición del jugador para el ataque de carga
	ultima_pos_jugador = jugador_detectado.global_position

	match tipo:
		"attack1", "attack2", "attack3":
			await ani_boss.animation_finished
			iniciar_burla()
		"attack4":
			# Cargar en línea recta
			await ataque_carga()

	timer_attack.start()  # Para reactivar ataques tras enfriamiento
	is_attacking = false

func ataque_carga() -> void:
	var direccion = (ultima_pos_jugador - global_position).normalized()
	var tiempo_carga = 0.5  # Duración en segundos de la carga

	var tiempo_transcurrido = 0.0
	while tiempo_transcurrido < tiempo_carga:
		velocity = direccion * charge_speed
		move_and_slide()
		await get_tree().create_timer(0.05).timeout
		tiempo_transcurrido += 0.05

	velocity = Vector2.ZERO
	await ani_boss.animation_finished
	iniciar_burla()

func iniciar_burla() -> void:
	is_burlando = true
	ani_boss.play("sneer")

	await get_tree().create_timer(3).timeout
	if is_burlando:  # No fue interrumpida
		is_burlando = false

func recibir_dano(cantidad: int) -> void:
	if is_dead:
		return

	current_health -= cantidad
	bar_health.visible = true
	bar_health.value = current_health
	timer_bar.start()

	# Cancelar burla si estaba burlándose
	if is_burlando:
		is_burlando = false
		await get_tree().create_timer(2).timeout  # Espera de 2s tras ser interrumpido

	# CURACIÓN AL JUGADOR POR CADA 100 DE DAÑO
	var vidas_a_recuperar = int((max_health - current_health) / 100) * 50
	var jugadores = get_tree().get_nodes_in_group("player_knight")
	if jugadores.size() > 0:
		var player = jugadores[0]
		if player.has_method("recuperar_vida"):
			player.recuperar_vida(vidas_a_recuperar)

	if current_health <= 0:
		morir()

func morir():
	is_dead = true
	ani_boss.play("death")
	col_boss.set_deferred("disabled", true)
	area_ataque.set_monitoring(false)
	await ani_boss.animation_finished
	timer_dead.start()
	await timer_dead.timeout
	queue_free()

func _on_timer_attack_timeout():
	puede_atacar = true
