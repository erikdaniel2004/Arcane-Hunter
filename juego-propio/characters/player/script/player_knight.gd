extends CharacterBody2D

#region Variables
# Propiedades del jugador sobre el terreno
@export var gravity_scale = 2
@export var speed = 200
@export var acceleration = 200
@export var friction = 900
@export var jump_force = -550
@export var air_acceleration = 1500
@export var air_friction = 700
@export var max_health := 100

# Coordenadas en las que se detiene la muerte por caida
@export var death_limit_stop_x := 1800
@export var death_limit_stop_y := 1500

# Altura límite para morir
@export var death_y_threshold: float = 1500

# Variables sobre los atributos del jugador
@onready var ani_player = $ani_player
@onready var time = $time
@onready var timer_invincible = $timer_invincible
@onready var timer_bar = $timer_bar
@onready var audio_player = $audio_player
@onready var attack_area = $attack_area
@onready var bar_health = $bar_health/TextureProgressBar
@onready var particles_blood = $particles_blood # Partículas de sangre

# Referencia al contador de monedas
@onready var contador: Control = $CanvasLayer/contador_moneda

# Referencia al contador de runas
@onready var contador2: Control = $CanvasLayer2/contador_runa

# Variable que guarda el último atacante del jugador
var last_attacker: Node = null

# Variable para desactivar la muerte por caida tras pasar un punto de control
var muerte_por_caida_desactivada := false

# Contadores
var monedas = 0
var runas = 0

# Variable que determina si la gorgona ha sido herida
var esta_herido = false

# Variable con la que contabilizar la vida de la gorgona
var current_health := max_health

# Variable con la que hacer invulnerable al jugador cuando reciba un ataque
var is_invulnerable := false
#endregion

#region Ready
# Función que establece unos parámetros al cargar el jugador
func _ready():
	add_to_group("player_knight")
	contador.actualizar(0)
	contador2.actualizar(0)
	bar_health.visible = false
#endregion

#region Physics Process
# Función que procesa la física del jugador sobre sus atributos y terreno
func _physics_process(delta: float) -> void:
	if not muerte_por_caida_desactivada and global_position.x >= death_limit_stop_x and global_position.y >= death_limit_stop_y:
		muerte_por_caida_desactivada = true

	if esta_herido:
		move_and_slide()
		return

	var input_axis = Input.get_axis("mover_izquierda", "mover_derecha")

	# Si cae por debajo del límite y no ha pasado el punto donde se desactiva la caída
	if not muerte_por_caida_desactivada and global_position.y > death_y_threshold:
		morir()

	apply_gravity(delta)
	handle_acceleration(input_axis, delta)
	apply_friction(input_axis, delta)
	handle_jump()
	handle_air_acceleration(input_axis, delta)
	update_animation(input_axis)
	move_and_slide()
	if Input.is_action_just_pressed("atacar"):
		atacar()
	update_attack_area_direction()
#endregion

#region Physics Functions
# Función con la que se aplican las propiedades de la gravedad
func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_scale

# Función que aplica una aceleración al jugador
func handle_acceleration(input_axis, delta):
	if not is_on_floor():
		return
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta)

# Función que aplica fricción
func apply_friction(input_axis, delta):
	if input_axis == 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)

# Función que permite la ejecución de saltos por el jugador
func handle_jump():
	if is_on_floor():
		if Input.is_action_just_pressed("saltar"):
			velocity.y = jump_force

# Función que aplica una aceleración en el aire determinada
func handle_air_acceleration(input_axis, delta):
	if is_on_floor():
		return
	if input_axis != 0:
		velocity.x = move_toward(velocity.x, speed * input_axis, air_acceleration * delta)

# Función que actualiza la animación concreta del jugador en función de la tecla pulsada
func update_animation(input_axis):
	if ani_player.is_playing() and ani_player.animation == "attack":
		return
	if input_axis != 0:
		ani_player.speed_scale = velocity.length() / 100
		ani_player.flip_h = (input_axis < 0)
		ani_player.play("run")
	elif not is_on_floor():
		ani_player.play("jump")
	else:
		ani_player.speed_scale = 1
		ani_player.play("idle")
#endregion

#region Generic Functions
#region Collectibles
# Función para sumar monedas
func sumar_monedas(valor):
	monedas += valor
	contador.actualizar(monedas)
	
# Función para sumar runas
func obtener_runa(valor):
	runas += valor
	contador2.actualizar(runas)
#endregion

#region Damage/Death
# Función para la muerte del jugador
func morir():
	audio_player.play() 
	ani_player.play("dead")
	set_physics_process(false)
	time.start()
	await time.timeout
	get_tree().reload_current_scene()
	
# Función que aplica una reducción de salud al personaje
func recibir_dano(cantidad):
	if is_invulnerable:
		return

	# Resta vida
	current_health -= cantidad

	# Activa partículas de sangre
	particles_blood.restart()
	particles_blood.emitting = true

	# Orienta la sangre según la dirección del atacante (enemigo)
	if last_attacker and last_attacker.global_position.x < global_position.x:
		particles_blood.rotation_degrees = 180
	else:
		particles_blood.rotation_degrees = 0
	current_health = clamp(current_health, 0, max_health)
	bar_health.value = current_health
	bar_health.visible = true
	timer_bar.start()

	esta_herido = true
	set_physics_process(false)
	ani_player.play("hurt")
	await ani_player.animation_finished
	esta_herido = false
	set_physics_process(true)

	if current_health <= 0:
		morir()
	else:
		hacer_invulnerable_temporalmente()

# Función que hace invencible al jugador cuando recibe daño por un corto periodo de tiempo
func hacer_invulnerable_temporalmente():
	is_invulnerable = true
	timer_invincible.start()
#endregion

#region Attack
# Función que contiene la lógica al hacer click para atacar
func atacar():
	ani_player.play("attack")
	var area = attack_area.get_overlapping_bodies()

	for cuerpo in area:
		if cuerpo.is_in_group("enemigos"):
			if cuerpo.has_method("recibir_dano"):
				cuerpo.recibir_dano(25)
#endregion

#region Health Bar
# Función que recupera parte de la salud de jugador
func recuperar_vida(cantidad):
	current_health += cantidad
	current_health = clamp(current_health, 0, max_health)
	bar_health.value = current_health
#endregion

#region Direction
# Función con la que se gestiona la dirección de los ataques
func update_attack_area_direction():
	var offset = 20
	if ani_player.flip_h:
		attack_area.position.x = -offset
	else:
		attack_area.position.x = offset
#endregion

#region Nodes Connections
# Función que hace invisible la barra de salud del jugador tras un periodo corto de tiempo 
func _on_timer_bar_timeout():
	bar_health.visible = false
	
# Función que devuelve la vulnerabilidad al jugador cuando el tiempo ha pasado
func _on_timer_invincible_timeout():
	is_invulnerable = false
#endregion
#endregion
