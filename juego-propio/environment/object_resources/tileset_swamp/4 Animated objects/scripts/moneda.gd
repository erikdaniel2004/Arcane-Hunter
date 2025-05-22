extends RigidBody2D

#region Variables
@export var valor_moneda: int = 1

@onready var sprite = $ani_moneda
@onready var area = $area_moneda
@onready var audio_moneda = $audio_moneda  # Nodo de audio dentro de la moneda
@onready var col_area = $area_moneda/col_area
#endregion

#region Ready
func _ready():
	col_area.disabled = true
	await get_tree().create_timer(0.3).timeout
	col_area.disabled = false
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
	sprite.play("idle")
	area.body_entered.connect(_on_body_entered)
	
	# Tween para simular levitación
	var tween = create_tween()
	tween.set_loops()  # Bucle infinito
	tween.tween_property(self, "position:y", position.y - 5, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "position:y", position.y, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
#endregion

#region Generic Functions
#region Nodes Connections
func _on_body_entered(body):
	if body.is_in_group("player_knight"):
		body.sumar_monedas(valor_moneda)
		
		# Desvincular el audio de la moneda antes de eliminarla
		remove_child(audio_moneda)  
		get_tree().current_scene.add_child(audio_moneda)  
		
		audio_moneda.play()
		queue_free()
#endregion
#endregion
