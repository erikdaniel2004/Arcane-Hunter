extends CharacterBody2D

@onready var ani_gorgon = $ani_gorgon
@onready var gravity: int = ProjectSettings.get("physics/2d/default_gravity")
@onready var detector_right = $detector_right
@onready var detector_left = $detector_left
@onready var time = $time
@export var speed = 100

# Variable para indicar si la gorgona está atacando
var is_attacking = false

# Variable para indicar el sentido del movimiento (1 = derecha, -1 = izquierda)
var sentido = 1

func _ready() -> void:
	ani_gorgon.play("run")  # Iniciar con la animación de correr

func _on_gorgon_area_body_entered(body: Node2D) -> void:
	if body.is_in_group("player_knight") and not is_attacking:
		is_attacking = true  # Bloquea el movimiento
		velocity.x = 0  # Detiene el movimiento
		ani_gorgon.play("attack")
		body.morir()  # Ejecuta la función de muerte del jugador
		await ani_gorgon.animation_finished  # Espera a que termine la animación de ataque
		is_attacking = false  # Permite el movimiento nuevamente
		ani_gorgon.play("run")  # Regresa a la animación de correr

func _physics_process(delta: float) -> void:
	if not is_attacking:  # Solo se mueve si no está atacando
		velocity.y += gravity * delta  # Aplicar gravedad

		# Si choca con una pared, cambia de dirección
		if is_on_wall():
			sentido = -sentido

		# Verifica el suelo con los detectores
		if sentido == 1 and detector_right.is_colliding():
			velocity.x = speed
			ani_gorgon.flip_h = false
		elif sentido == -1 and detector_left.is_colliding():
			velocity.x = -speed
			ani_gorgon.flip_h = true
		else:
			sentido = -sentido  # Cambia de dirección si no hay suelo

		ani_gorgon.play("run")  # Asegura que la animación de correr siga mientras camina

	else:
		velocity.x = 0  # No moverse mientras ataca

	move_and_slide()  # Aplicar movimiento
