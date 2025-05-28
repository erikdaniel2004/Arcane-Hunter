extends RigidBody2D

#region Variables
@export var health := 50
@export var break_force_threshold := 400.0
@export var escene_coin: PackedScene
@export var escene_rune: PackedScene
@export var escene_food: PackedScene

@onready var particles: CPUParticles2D = $particles
#endregion

#region Ready
func _ready():
	sleeping = false
	if escene_coin == null:
		escene_coin = load("res://environment/object_resources/tileset_cave/Objects_Animated/scenes/coin.tscn")
	if escene_rune == null:
		escene_rune = load("res://environment/object_resources/tileset_cave/Objects_Animated/scenes/rune.tscn")
	if escene_food == null:
		escene_food = load("res://environment/object_resources/tileset_cave/Objects/Food/scenes/food1.tscn")
#endregion

#region Generic Functions

#region Damage/Break
func recibir_dano(value: int):
	health -= value
	shake()
	if health <= 0:
		_break()

func _break():
	if particles:
		particles.emitting = true

	# Intentar generar drop aleatorio
	random_drop()

	# Espera un instante para que las partículas se vean
	await get_tree().create_timer(0.5).timeout
	queue_free()
#endregion

#region Shake
func shake():
	var force := Vector2(randf_range(-300, 300), randf_range(-200, 200))
	apply_central_impulse(force)
#endregion

#region Drops
func random_drop():
	var result = randi_range(1, 10)
	var drop
	if result == 1:
		drop = escene_coin.instantiate()
	elif result == 2:
		drop = escene_rune.instantiate()
	elif result == 3:
		drop = escene_food.instantiate()
	else:
		return

	if drop:
		get_tree().current_scene.add_child(drop)
		drop.global_position = global_position + Vector2(randf_range(-10, 10), -10)
		if drop is RigidBody2D:
			drop.freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
#endregion
#endregion
