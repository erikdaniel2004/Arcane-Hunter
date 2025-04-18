extends Control

@onready var ani_runa = $hbox_runa/ani_runa
@onready var lbl_runa = $hbox_runa/lbl_runa

func _ready():
	ani_runa.play("idle")
func actualizar(monedas:int):
	lbl_runa.text = str(monedas)
