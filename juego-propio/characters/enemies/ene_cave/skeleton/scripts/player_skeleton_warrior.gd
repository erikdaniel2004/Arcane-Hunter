extends CharacterBody2D

#region Variables
# Referencias a nodos de la escena
@onready var ani_skeleton = $ani_skeleton  # Animaciones del esqueleto
@onready var col_skeleton = $col_skeleton
@onready var audio_skeleton = $audio_skeleton  # Reproductor de sonido para el slime
@onready var gravity: int = ProjectSettings.get("physics/2d/default_gravity")  # Gravedad general del proyecto
@onready var detector_right = $detector_right  # Detector de suelo a la derecha
@onready var detector_left = $detector_left  # Detector de suelo a la izquierda
@onready var bar_health = $bar_health/TextureProgressBar  # Barra de vida
@onready var timer_bar = $timer_bar  # Temporizador para ocultar la barra de vida
@onready var timer_dead = $timer_dead  # Temporizador tras la muerte
@onready var timer_attack = $timer_attack  # Temporizador de ataque para limitar el ataque continuo
@onready var area_ataque = $skeleton_area  # Área de detección del esqueleto
@onready var particles_blood = $particles_blood # Partículas de sangre

# Variables exportables
@export var speed = 100  # Velocidad de movimiento
@export var max_health := 50  # Vida máxima

# Variables internas
var current_health := max_health  # Vida actual
var sentido = 1  # Dirección de movimiento (1 = derecha, -1 = izquierda)
var is_attacking = false  # Indica si está atacando
var esta_herido = false  # Indica si está recibiendo daño
var is_dead = false  # Indica si está muerto
var esperando_revivir = false # Indica si el enemigo está esperando X segundos antes de revivir
var rematado := false # Indica si el enemigo está rematado
var puede_atacar = true  # Controla si puede atacar nuevamente
var jugador_detectado: Node = null  # Referencia al jugador detectado
var puede_moverse := true # Controla si el enemigo se puede mover o no
var puede_ser_rematado := false  # Solo se activa tras animación "dead"

# Señal para determinar la muerte del enemigo
signal enemigo_muerto(es_jefe: bool)
#endregion

#region Ready
func _ready() -> void:
	# Al iniciar, se reproduce la animación de caminar y se oculta la barra de vida
	ani_skeleton.play("run")
	bar_health.visible = false
	
	# Se conectan las señales del área de ataque para detectar entrada y salida del jugador
	area_ataque.body_entered.connect(_on_skeleton_area_body_entered)
	area_ataque.body_exited.connect(_on_skeleton_area_body_exited)
#endregion

#region Physics Process
# Función principal que se ejecuta cada frame de física
func _physics_process(delta: float) -> void:
	# Si está muerta, no hace nada
	if is_dead:
		return

	if not puede_moverse:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Si está recibiendo daño, solo se desliza sin más acciones
	if esta_herido:
		move_and_slide()
		return

	# Movimiento normal cuando no está atacando
	if not is_attacking:
		velocity.y += gravity * delta  # Aplica gravedad

		# Si choca contra una pared, cambia de sentido
		if is_on_wall():
			sentido = -sentido

		# Verifica los detectores de suelo y decide si moverse
		if sentido == 1 and detector_right.is_colliding():
			velocity.x = speed
			ani_skeleton.flip_h = false
		elif sentido == -1 and detector_left.is_colliding():
			velocity.x = -speed
			ani_skeleton.flip_h = true
		else:
			sentido = -sentido  # Cambia de dirección si no hay suelo

		ani_skeleton.play("run")  # Reproduce la animación de correr

	else:
		velocity.x = 0  # Si está atacando, no se mueve

	move_and_slide()  # Mueve al personaje
#endregion

#region Generic Functions
#region Attack
# Lógica del ataque
func iniciar_ataque():
	# Se evita atacar si está en medio de otra acción importante
	if jugador_detectado == null or is_attacking or esta_herido or is_dead:
		return

	is_attacking = true
	puede_atacar = false  # Se desactiva el permiso de atacar hasta que el jugador se salga
	velocity.x = 0
	
	if jugador_detectado.global_position.x < global_position.x:
		ani_skeleton.flip_h = true
	else:
		ani_skeleton.flip_h = false
		
	ani_skeleton.play("attack")

	# Si el jugador tiene el método recibir_dano, se le inflige daño
	if jugador_detectado.has_method("recibir_dano"):
		jugador_detectado.last_attacker = self
		jugador_detectado.recibir_dano(25)

	timer_attack.start()  # Comienza el tiempo de recuperación del ataque
#endregion

#region Damage/Death/Revive
# Función para recibir daño
func recibir_dano(cantidad):
	if esta_herido or (is_dead and rematado):
		return

	if esperando_revivir and not rematado and puede_ser_rematado:
		rematado = true
		timer_dead.stop()
		emit_signal("enemigo_muerto", false)
		queue_free()
		return

	if is_dead:
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
		
	bar_health.value = current_health
	bar_health.visible = true
	timer_bar.start()

	# Si la vida llega a 0, muere
	if current_health <= 0:
		is_dead = true
		morir()
		return

	# Si aún no muere, reproduce la animación de daño
	esta_herido = true
	set_physics_process(false)
	ani_skeleton.play("hurt")
	await ani_skeleton.animation_finished
	esta_herido = false
	set_physics_process(true)

# Lógica de muerte del esqueleto
func morir():
	is_dead = true
	esperando_revivir = true
	puede_ser_rematado = false
	audio_skeleton.play()
	ani_skeleton.play("dead")
	area_ataque.set_monitoring(false)
	col_skeleton.set_deferred("disabled", false)
	puede_moverse = false

	await ani_skeleton.animation_finished
	puede_ser_rematado = true

	timer_dead.start()  # Espera 2 segundos
	await timer_dead.timeout
	
	if not rematado:
		revivir()
	else:
		queue_free()

# Lógica de recuperación de vida del esqueleto si no se remata
func revivir():
	is_dead = false
	esperando_revivir = false
	rematado = false
	current_health = max_health

	# Desactivar el movimiento mientras se reproduce la animación
	puede_moverse = false
	col_skeleton.set_deferred("disabled", false)
	area_ataque.set_monitoring(false)

	ani_skeleton.play("return")
	await ani_skeleton.animation_finished

	# Puede volver a moverse y atacar
	puede_moverse = true
	area_ataque.set_monitoring(true)
	ani_skeleton.play("run")

#endregion

#region Nodes Connections
# Función que se ejecuta cuando un cuerpo entra en el área de ataque
func _on_skeleton_area_body_entered(body):
	# Si el cuerpo es un jugador y puede atacar, inicia el ataque
	if body.is_in_group("players") and not is_attacking and puede_atacar:
		jugador_detectado = body
		iniciar_ataque()

# Función que se ejecuta cuando un cuerpo sale del área de ataque
func _on_skeleton_area_body_exited(body):
	# Solo si el jugador que salió es el que estaba detectado, se vuelve a permitir el ataque
	if body == jugador_detectado:
		puede_atacar = true
		jugador_detectado = null
		
# Oculta la barra de vida tras un tiempo
func _on_timer_bar_timeout():
	bar_health.visible = false

# Finaliza el estado de ataque tras el temporizador
func _on_timer_attack_timeout():
	is_attacking = false
#endregion
#endregion
