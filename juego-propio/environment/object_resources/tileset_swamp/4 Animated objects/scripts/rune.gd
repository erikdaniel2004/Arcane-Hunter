extends RigidBody2D

#region Variables
@export var valor_runa: int = 1  # Valor de la runa (puede usarse para diferentes tipos)

@onready var sprite = $ani_runa
@onready var area = $area_runa
@onready var audio_runa = $audio_runa
#endregion

#region Ready
func _ready():
	sprite.play("idle")
	area.body_entered.connect(_on_body_entered)
#endregion

#region Generic Functions
#region Nodes Connections
func _on_body_entered(body):
	if body.is_in_group("player_knight"):
		body.obtener_runa(valor_runa)
		
		# Desvincular el audio de la moneda antes de eliminarla
		remove_child(audio_runa)  
		get_tree().current_scene.add_child(audio_runa)  
		
		audio_runa.play()
		queue_free()
#endregion
#endregion
