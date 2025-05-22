extends RigidBody2D

#region Variables
@onready var audio_comida = $audio_comida
@onready var col_comida = $col_comida
@onready var img_comida = $img_comida
@onready var area = $area_comida
@onready var col_area = $area_comida/col_area
# Valor de recuperación
@export var vida_a_recuperar := 25
#endregion

#region Ready
func _ready():
	col_area.disabled = true
	await get_tree().create_timer(0.3).timeout
	col_area.disabled = false
	freeze_mode = RigidBody2D.FREEZE_MODE_KINEMATIC
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
	if body.is_in_group("player_knight") and body.has_method("recuperar_vida"):
		body.recuperar_vida(vida_a_recuperar)
		
		# Desvincular el audio de la comida antes de eliminarla
		remove_child(audio_comida)  
		get_tree().current_scene.add_child(audio_comida) 
		
		audio_comida.play()
		col_comida.set_deferred("disabled", true)
		img_comida.visible = false
		await audio_comida.finished
		queue_free()
#endregion
#endregion
