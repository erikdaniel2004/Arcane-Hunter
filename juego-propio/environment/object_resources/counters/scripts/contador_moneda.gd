extends Control

#region Variables
@onready var ani_moneda = $hbox_moneda/ani_moneda
@onready var lbl_moneda = $hbox_moneda/lbl_moneda
#endregion

#region Ready
func _ready():
	ani_moneda.play("idle")
#endregion
	
#region Generic Functions
#region Update
func actualizar(monedas:int):
	lbl_moneda.text = str(monedas)
#endregion
#endregion
