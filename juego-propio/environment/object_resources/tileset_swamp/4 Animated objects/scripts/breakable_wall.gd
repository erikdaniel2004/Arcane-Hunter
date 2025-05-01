extends StaticBody2D

#region Variables
@onready var sprite = $image
@onready var colision = $col_wall
@onready var particulas = $particles
#endregion

#region Ready
func _ready():
	add_to_group("breakable_wall")
#endregion

#region Generic Functions
#region Break Wall
func romper_pared():
	# Desactiva la colisión y oculta el sprite
	colision.disabled = true
	sprite.visible = false

	# Activa las partículas
	particulas.emitting = true

	# Espera 2 segundos y elimina la pared
	await get_tree().create_timer(2.0).timeout
	queue_free()
#endregion
#endregion
