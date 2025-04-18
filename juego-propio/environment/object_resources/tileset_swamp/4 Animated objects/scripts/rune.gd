extends RigidBody2D

@export var valor_runa: int = 1  # Valor de la runa (puede usarse para diferentes tipos)

@onready var sprite = $ani_runa
@onready var area = $area_runa
@onready var audio_runa = $audio_runa

func _ready():
	sprite.play("idle")
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player_knight"):
		body.sumar_monedas(valor_runa)
		
		# Desvincular el audio de la moneda antes de eliminarla
		remove_child(audio_runa)  
		get_tree().current_scene.add_child(audio_runa)  
		
		audio_runa.play()
		queue_free()
