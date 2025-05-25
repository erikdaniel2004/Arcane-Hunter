extends CharacterBody2D

#region Variables
@export var gravity_scale = 2
@export var speed = 200
@export var acceleration = 200
@export var friction = 900
@export var jump_force = -550
@export var air_acceleration = 1500
@export var air_friction = 700
@export var max_health := 100
@export var damage := 25
@export var death_y_threshold: float = 1500
@export var jugador_principal: Node = null

@onready var ani_player = $ani_player
@onready var time = $time
@onready var timer_invincible = $timer_invincible
@onready var timer_bar = $timer_bar
@onready var audio_player = $audio_player
@onready var attack_area = $attack_area
@onready var area_empuje = $area_empuje
@onready var bar_health = $bar_health/TextureProgressBar
@onready var particles_blood = $particles_blood

# Variable de vida
var current_health := max_health

# Variable que vuelve invulnerable durante X segundos al jugador
var is_invulnerable := false

# Variable para determinar si el jugador ha sido herido
var esta_herido = false

# Variable para determinar la dirección de el último atacante
var last_attacker: Node = null

# Variable para determinar la cámara principal
var camara_jugador: Camera2D = null

# Variables para almacenar de forma temporal los coleccionables
var monedas_recogidas := 0
var runas_recogidas := 0

var input_axis = Input.get_axis("mover_izquierda_p2", "mover_derecha_p2")

#endregion

#region Ready
func _ready():
	add_to_group("players")
	bar_health.visible = false
	camara_jugador = get_tree().get_root().get_node("environment/players/player_knight/cam_player")
#endregion

#region Physics Process
func _physics_process(delta):
	# Impedir que el gato salga de los límites de la cámara
	if camara_jugador:
		var cam_pos = camara_jugador.global_position
		var cam_size = camara_jugador.get_viewport_rect().size
		var limite_izquierdo = cam_pos.x - cam_size.x / 2
		var limite_derecho = cam_pos.x + cam_size.x / 2
		
		if global_position.x < limite_izquierdo:
			velocity.x = max(velocity.x, 0)
		elif global_position.x > limite_derecho:
			velocity.x = min(velocity.x, 0)

	# Si está herido, ignora input pero sigue física
	if esta_herido:
		input_axis = 0

	if global_position.y > death_y_threshold:
		desactivar()

	input_axis = Input.get_axis("mover_izquierda_p2", "mover_derecha_p2")
	apply_gravity(delta)
	handle_acceleration(input_axis, delta)
	apply_friction(input_axis, delta)
	handle_jump()
	handle_air_acceleration(input_axis, delta)
	update_animation(input_axis)
	move_and_slide()
	update_attack_area_direction()

	if Input.is_action_just_pressed("atacar_p2"):
		atacar()

	if Input.is_action_just_pressed("maullar_p2"):
		audio_player.play()

	detectar_cajas_cercanas()
#endregion

#region Physics Functions
func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_scale

func handle_acceleration(input_axis, delta):
	if is_on_floor() and input_axis != 0:
		velocity.x = move_toward(velocity.x, speed * input_axis, acceleration * delta)

func apply_friction(input_axis, delta):
	if input_axis == 0 and is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func handle_jump():
	if is_on_floor() and Input.is_action_just_pressed("saltar_p2"):
		velocity.y = jump_force

func handle_air_acceleration(input_axis, delta):
	if not is_on_floor(): 
		if input_axis != 0:
			velocity.x = move_toward(velocity.x, speed * input_axis, air_acceleration * delta)
#endregion

#region Animation
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

#region Collectibles
func sumar_monedas(valor):
	monedas_recogidas += valor
	enviar_monedas_a_principal()

func obtener_runa(valor):
	runas_recogidas += valor
	enviar_runas_a_principal()
	
func enviar_monedas_a_principal():
	if jugador_principal and jugador_principal.has_method("sumar_monedas"):
		jugador_principal.sumar_monedas(monedas_recogidas)
		monedas_recogidas = 0

func enviar_runas_a_principal():
	if jugador_principal and jugador_principal.has_method("obtener_runa"):
		jugador_principal.obtener_runa(runas_recogidas)
		runas_recogidas = 0
#endregion

#region Damage/Death
func recibir_dano(cantidad):
	if is_invulnerable or current_health <= 0:
		return

	current_health -= cantidad
	current_health = clamp(current_health, 0, max_health)
	bar_health.value = current_health
	bar_health.visible = true
	timer_bar.start()

	# Activar partículas de sangre
	particles_blood.restart()
	particles_blood.emitting = true
	if last_attacker and last_attacker.global_position.x < global_position.x:
		particles_blood.rotation_degrees = 180
	else:
		particles_blood.rotation_degrees = 0

	# Si muere directamente, no reproducir animación hurt
	if current_health <= 0:
		desactivar()
		return

	# Reproducir animación de daño sin congelar la física
	esta_herido = true
	ani_player.play("hurt")
	await ani_player.animation_finished
	esta_herido = false

	hacer_invulnerable_temporalmente()

func desactivar():
	set_physics_process(false)
	visible = false
	collision_layer = 0
	collision_mask = 0
	await get_tree().create_timer(0.5).timeout
	queue_free()

func hacer_invulnerable_temporalmente():
	is_invulnerable = true
	timer_invincible.start()

func _on_timer_invincible_timeout():
	is_invulnerable = false

func _on_timer_bar_timeout():
	bar_health.visible = false
#endregion

#region Attack
func atacar():
	ani_player.play("attack")
	var area = attack_area.get_overlapping_bodies()
	for cuerpo in area:
		if cuerpo.has_method("recibir_dano") and cuerpo.is_in_group("enemigos") or cuerpo.is_in_group("destructibles"):
			cuerpo.recibir_dano(damage)
#endregion

#region Health Bar
# Función que recupera parte de la salud de jugador
func recuperar_vida(cantidad):
	current_health += cantidad
	current_health = clamp(current_health, 0, max_health)
	bar_health.value = current_health
	bar_health.visible = true
	timer_bar.start()
#endregion

#region Player Found
func get_jugador_principal() -> Node:
	var jugador = get_tree().get_root().get_node_or_null("environment/players/player_knight")
	if jugador == null:
		push_error("No se encontró el jugador principal")
	return jugador
#endregion

#region Interactions
func detectar_cajas_cercanas():
	for bodie in area_empuje.get_overlapping_bodies():
		if bodie is RigidBody2D and (bodie.name.begins_with("Box") or bodie.name.begins_with("Barrel")):
			var dir = (bodie.global_position - global_position).normalized()
			bodie.apply_central_impulse(dir * 200)

func update_attack_area_direction():
	var offset = 20
	if ani_player.flip_h:
		attack_area.position.x = -offset
	else:
		attack_area.position.x = offset
#endregion
