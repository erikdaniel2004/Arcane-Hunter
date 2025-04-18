extends RigidBody2D

@export var valor_moneda: int = 1

@onready var sprite = $ani_moneda
@onready var area = $area_moneda
@onready var audio_moneda = $audio_moneda  # Nodo de audio dentro de la moneda

func _ready():
	sprite.play("idle")
	area.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.is_in_group("player_knight"):
		body.sumar_monedas(valor_moneda)
		
		# Desvincular el audio de la moneda antes de eliminarla
		remove_child(audio_moneda)  
		get_tree().current_scene.add_child(audio_moneda)  
		
		audio_moneda.play()
		queue_free()
