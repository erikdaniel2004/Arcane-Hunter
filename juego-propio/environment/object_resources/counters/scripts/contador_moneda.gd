extends Control

@onready var ani_moneda = $hbox_moneda/ani_moneda
@onready var lbl_moneda = $hbox_moneda/lbl_moneda

func _ready():
	ani_moneda.play("idle")
func actualizar(monedas:int):
	lbl_moneda.text = str(monedas)
