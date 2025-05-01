extends Node2D

#region Variables
@onready var sprite = $ani_chest
@onready var area = $area_chest

@export var moneda_escena: PackedScene  # Escena de la moneda
@export var runa_escena: PackedScene  # Escena de la runa
@export var min_monedas: int = 0  # Número mínimo de monedas
@export var max_monedas: int = 6  # Número máximo de monedas

var abierto = false  # Evita que se abra más de una vez
#endregion

#region Ready
func _ready():
	if moneda_escena == null:
		moneda_escena = load("res://environment/object_resources/tileset_swamp/4 Animated objects/scenes/coin.tscn")
	if runa_escena == null:
		runa_escena = load("res://environment/object_resources/tileset_swamp/4 Animated objects/scenes/rune.tscn")
	sprite.play("close")
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
#endregion

#region Generic Functions
#region Drops
func soltar_monedas():
	var cantidad = randi_range(min_monedas, max_monedas)
	
	for i in range(cantidad):
		var moneda = moneda_escena.instantiate() as RigidBody2D
		get_tree().current_scene.add_child(moneda)
		moneda.global_position = global_position + Vector2(randf_range(-10, 10), -10)
		moneda.apply_impulse(Vector2(randf_range(-100, 100), -150))

func soltar_runa():
	var chance = randi_range(1, 100)  # Generar un número aleatorio entre 1 y 100
	if chance == 1:  # Si el número aleatorio es 1, se genera la runa
		var runa = runa_escena.instantiate() as RigidBody2D
		get_tree().current_scene.add_child(runa)
		runa.global_position = global_position + Vector2(randf_range(-10, 10), -10)
		runa.apply_impulse(Vector2(randf_range(-100, 100), -150))
#endregion

#region Nodes Connections
func _on_body_entered(body):
	if body.is_in_group("player_knight") and not abierto:
		sprite.play("open")
		soltar_monedas()
		soltar_runa()
		abierto = true  # Evitar que se abra varias veces

func _on_body_exited(body):
	if body.is_in_group("player_knight") and abierto:
		sprite.play("close")
#endregion
#endregion
