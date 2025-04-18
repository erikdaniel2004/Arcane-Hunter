extends Node2D

@onready var sprite = $ani_flag

func _ready():
	sprite.play("move")
