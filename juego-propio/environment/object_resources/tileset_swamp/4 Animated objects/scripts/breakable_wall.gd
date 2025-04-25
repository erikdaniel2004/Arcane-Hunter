extends StaticBody2D

@onready var sprite = $image
@onready var colision = $col_wall
@onready var particulas = $particles

func _ready():
	add_to_group("breakable_wall")

func romper_pared():
	# Desactiva la colisión y oculta el sprite
	colision.disabled = true
	sprite.visible = false

	# Activa las partículas
	particulas.emitting = true

	# Espera 2 segundos y elimina la pared
	await get_tree().create_timer(2.0).timeout
	queue_free()
