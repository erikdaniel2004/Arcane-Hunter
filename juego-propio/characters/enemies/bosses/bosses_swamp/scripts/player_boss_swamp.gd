extends CharacterBody2D

#region Variables
# Referencias a nodos
@onready var ani_boss = $ani_boss # Animaciones del jefe
@onready var col_boss = $col_boss # Colisiones del jefe
@onready var area_ataque = $boss_area # Area de ataque del jefe
@onready var audio_boss = $audio_boss # Reproductor de sonido del jefe
@onready var gravity: int = ProjectSettings.get("physics/2d/default_gravity")
@onready var detector_right = $detector_right # Detector de suelo a la derecha
@onready var detector_left = $detector_left # Detector de suelo a la izquierda
@onready var bar_health = $bar_health/TextureProgressBar # Barra de salud
@onready var timer_bar = $timer_bar # Tiempo que tarda en desaparecer la barra de salud
@onready var timer_dead = $timer_dead # Tiempo que tarda en morir
@onready var timer_attack = $timer_attack # Tiempo que tarda en realizar otro ataque
@onready var timer_invulnerable = Timer.new() # Tiempo en el que el jefe se hace invulnerable
@onready var particles_blood = $particles_blood # Particulas de sangre

# Export variables
@export var speed := 100
@export var charge_speed := 300
@export var max_health := 500
@export var x_activar := 450
@export var y_activar := 1743

# Estados
var current_health := max_health
var is_attacking = false
var esta_herido = false
var is_dead = false
var puede_atacar = true
var is_burlando = false
var ha_comenzado = false
var jugador_detectado: Node = null
var ultima_pos_jugador = Vector2.ZERO
var sentido := 1

var golpes_recibidos_seguidos = 0
var es_invulnerable = false

# Señal para determinar la muerte del enemigo
signal enemigo_muerto(es_jefe: bool)
#endregion

#region Ready
func _ready():
	ani_boss.play("idle")
	bar_health.visible = false
	add_to_group("enemigos")
	area_ataque.body_entered.connect(_on_boss_area_body_entered)
	add_child(timer_invulnerable)
	timer_invulnerable.wait_time = 2.0
	timer_invulnerable.one_shot = true
	timer_invulnerable.timeout.connect(_reset_invulnerabilidad)

	await get_tree().process_frame
	var jugadores = get_tree().get_nodes_in_group("players")
	if jugadores.size() > 0:
		jugador_detectado = jugadores[0]
		if jugador_detectado.has_method("_on_enemigo_muerto"):
			connect("enemigo_muerto", Callable(jugador_detectado, "_on_enemigo_muerto"), CONNECT_DEFERRED)

	var environment = get_tree().get_first_node_in_group("nivel")
	if environment and environment.has_method("_on_jefe_muerto"):
		connect("enemigo_muerto", Callable(environment, "_on_jefe_muerto"), CONNECT_DEFERRED)

#endregion

#region Physics Process
func _physics_process(delta):
	if is_dead:
		return

	velocity.y += gravity * delta

	if not ha_comenzado and jugador_detectado:
		if jugador_detectado.global_position.x >= x_activar and jugador_detectado.global_position.y >= y_activar:
			iniciar_combate()
		else:
			ani_boss.play("idle")
		return

	if is_attacking or esta_herido or is_burlando:
		move_and_slide()
		return

	if jugador_detectado:
		var direccion = (jugador_detectado.global_position - global_position).normalized()
		velocity.x = direccion.x * speed
		ani_boss.flip_h = jugador_detectado.global_position.x > global_position.x
		
		# Solo correr si no está contra una pared
		if not is_on_wall():
			if !ani_boss.is_playing() or ani_boss.animation != "run":
				ani_boss.play("run")
		else:
			if !ani_boss.is_playing() or ani_boss.animation != "idle":
				ani_boss.play("idle")
	else:
		velocity.x = 0
		ani_boss.play("idle")

	move_and_slide()
#endregion

#region Generic Functions

#region Attack
func iniciar_combate():
	ha_comenzado = true
	is_burlando = true
	ani_boss.play("sneer")
	await get_tree().create_timer(3).timeout
	is_burlando = false
	puede_atacar = true

func iniciar_ataque():
	if jugador_detectado == null or is_attacking or esta_herido or is_dead:
		return

	var distancia = global_position.distance_to(jugador_detectado.global_position)
	if distancia < 100:
		realizar_ataque("attack1")
	elif distancia < 200:
		realizar_ataque("attack2")
	elif distancia < 300:
		realizar_ataque("attack3")
	else:
		realizar_ataque("attack4")

func realizar_ataque(tipo: String):
	is_attacking = true
	puede_atacar = false
	velocity.x = 0
	ani_boss.flip_h = jugador_detectado.global_position.x > global_position.x
	ani_boss.play(tipo)
	ultima_pos_jugador = jugador_detectado.global_position

	if tipo in ["attack1", "attack2", "attack3"]:
		if jugador_detectado and jugador_detectado.has_method("recibir_dano"):
			jugador_detectado.last_attacker = self
			jugador_detectado.recibir_dano(25)

	match tipo:
		"attack1", "attack2", "attack3":
			await ani_boss.animation_finished
			iniciar_burla()
		"attack4":
			await ataque_carga()

	timer_attack.start()
	is_attacking = false

func ataque_carga():
	ani_boss.play("attack4")
	await get_tree().create_timer(1.0).timeout
	var direccion = (jugador_detectado.global_position - global_position).normalized()
	while true:
		var collision = move_and_collide(direccion * charge_speed * get_process_delta_time())
		if collision:
			var collider = collision.get_collider()
			if collider.is_in_group("players") and collider.has_method("recibir_dano"):
				jugador_detectado.last_attacker = self
				collider.recibir_dano(50)
			velocity = Vector2.ZERO
			iniciar_burla()
			return
		await get_tree().process_frame
	velocity = Vector2.ZERO
	await ani_boss.animation_finished
	iniciar_burla()
#endregion

#region Sneer
func iniciar_burla():
	is_burlando = true
	ani_boss.play("sneer")
	var tiempo = 3.0
	while tiempo > 0 and is_burlando:
		await get_tree().create_timer(0.1).timeout
		tiempo -= 0.1
	is_burlando = false
#endregion

#region Damage/Death
func recibir_dano(cantidad):
	if is_dead or es_invulnerable:
		return

	golpes_recibidos_seguidos += 1
	timer_invulnerable.start()

	if golpes_recibidos_seguidos >= 3:
		es_invulnerable = true
		golpes_recibidos_seguidos = 0
		return

	# Resta vida y actualiza la barra
	current_health -= cantidad
	
	# Activa partículas de sangre
	particles_blood.restart()
	particles_blood.emitting = true

	# Si quieres que se orienten hacia el jugador
	if jugador_detectado and jugador_detectado.global_position.x < global_position.x:
		particles_blood.rotation_degrees = 180
	else:
		particles_blood.rotation_degrees = 0
		
	bar_health.visible = true
	bar_health.value = current_health
	timer_bar.start()

	if is_burlando:
		is_burlando = false
		await get_tree().create_timer(0.5).timeout

	var vidas_a_recuperar = int((max_health - current_health) / 100) * 50
	var jugadores = get_tree().get_nodes_in_group("players")
	if jugadores.size() > 0:
		var player = jugadores[0]
		if player.has_method("recuperar_vida"):
			player.recuperar_vida(vidas_a_recuperar)

	if current_health <= 0:
		morir()
		return

	ani_boss.play("hurt")

func _reset_invulnerabilidad():
	es_invulnerable = false
	golpes_recibidos_seguidos = 0

func morir():
	is_dead = true
	audio_boss.play()
	ani_boss.play("death")
	col_boss.set_deferred("disabled", true)
	set_physics_process(false)
	emit_signal("enemigo_muerto", true)
	
	await ani_boss.animation_finished
	timer_dead.start()
	await timer_dead.timeout
	
	# Buscar la pared por nombre o grupo
	var pared = get_tree().get_nodes_in_group("breakable_wall")
	if pared.size() > 0:
		pared[0].romper_pared()
	queue_free()
#endregion

#region Nodes Connections
func _on_boss_area_body_entered(body):
	if body.is_in_group("players") and puede_atacar and not is_attacking and not esta_herido and not is_dead:
		jugador_detectado = body
		var ataque_random = randi_range(1, 4)
		realizar_ataque("attack" + str(ataque_random))

func _on_timer_bar_timeout():
	bar_health.visible = false

func _on_timer_attack_timeout():
	puede_atacar = true
#endregion
#endregion
