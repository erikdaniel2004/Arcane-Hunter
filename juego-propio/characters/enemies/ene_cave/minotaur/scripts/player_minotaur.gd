extends CharacterBody2D

#region Variables
# Referencias a nodos de la escena
@onready var ani_minotaur = $ani_minotaur  # Animaciones de la gorgona
@onready var col_minotaur = $col_minotaur
@onready var audio_minotaur = $audio_minotaur  # Reproductor de sonido para la gorgona
@onready var gravity: int = ProjectSettings.get("physics/2d/default_gravity")  # Gravedad general del proyecto
@onready var detector_right = $detector_right  # Detector de suelo a la derecha
@onready var detector_left = $detector_left  # Detector de suelo a la izquierda
@onready var bar_health = $bar_health/TextureProgressBar  # Barra de vida
@onready var timer_bar = $timer_bar  # Temporizador para ocultar la barra de vida
@onready var timer_dead = $timer_dead  # Temporizador tras la muerte
@onready var timer_attack = $timer_attack  # Temporizador de ataque para limitar el ataque continuo
@onready var area_ataque = $minotaur_area  # Área de detección del jugador
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
var puede_atacar = true  # Controla si puede atacar nuevamente
var jugador_detectado: Node = null  # Referencia al jugador detectado

# Señal para determinar la muerte del enemigo
signal enemigo_muerto(es_jefe: bool)
#endregion

#region Ready
func _ready() -> void:
	# Al iniciar, se reproduce la animación de caminar y se oculta la barra de vida
	ani_minotaur.play("run")
	bar_health.visible = false
	
	# Se conectan las señales del área de ataque para detectar entrada y salida del jugador
	if not area_ataque.is_connected("body_entered", Callable(self, "_on_minotaur_area_body_entered")):
		area_ataque.body_entered.connect(_on_minotaur_area_body_entered)
		
	if not area_ataque.is_connected("body_exited", Callable(self, "_on_minotaur_area_body_exited")):
		area_ataque.body_exited.connect(_on_minotaur_area_body_exited)
#endregion

#region Physics Process
# Función principal que se ejecuta cada frame de física
func _physics_process(delta: float) -> void:
	# Si está muerta, no hace nada
	if is_dead:
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
			ani_minotaur.flip_h = false
		elif sentido == -1 and detector_left.is_colliding():
			velocity.x = -speed
			ani_minotaur.flip_h = true
		else:
			sentido = -sentido  # Cambia de dirección si no hay suelo

		ani_minotaur.play("run")  # Reproduce la animación de correr

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
		ani_minotaur.flip_h = true
	else:
		ani_minotaur.flip_h = false
		
	ani_minotaur.play("attack")

	# Si el jugador tiene el método recibir_dano, se le inflige daño
	if jugador_detectado.has_method("recibir_dano"):
		jugador_detectado.last_attacker = self
		jugador_detectado.recibir_dano(25)

	timer_attack.start()  # Comienza el tiempo de recuperación del ataque
#endregion

#region Damage/Death
# Función para recibir daño
func recibir_dano(cantidad):
	# Si está herida o muerta, no puede recibir más daño
	if esta_herido or is_dead:
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
	ani_minotaur.play("hurt")
	await ani_minotaur.animation_finished
	esta_herido = false
	set_physics_process(true)

# Lógica de muerte de la gorgona
func morir():
	is_dead = true
	audio_minotaur.play()  # Sonido de muerte
	ani_minotaur.play("dead")  # Animación de muerte
	area_ataque.set_monitoring(false)  # Desactiva el área de ataque
	col_minotaur.set_deferred("disabled", true)  # Desactiva el collider
	set_physics_process(false)  # Detiene el procesamiento
	emit_signal("enemigo_muerto", false)
	await ani_minotaur.animation_finished  # Espera a que termine la animación
	timer_dead.start()
	await timer_dead.timeout
	queue_free()  # Elimina la gorgona de la escena
#endregion

#region Nodes Connections
# Función que se ejecuta cuando un cuerpo entra en el área de ataque
func _on_minotaur_area_body_entered(body):
	# Si el cuerpo es un jugador y puede atacar, inicia el ataque
	if body.is_in_group("players") and not is_attacking and puede_atacar:
		jugador_detectado = body
		iniciar_ataque()

# Función que se ejecuta cuando un cuerpo sale del área de ataque
func _on_minotaur_area_body_exited(body):
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
