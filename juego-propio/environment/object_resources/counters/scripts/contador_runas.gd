extends Control

#region Variables
@onready var ani_runa = $hbox_runa/ani_runa
@onready var lbl_runa = $hbox_runa/lbl_runa
#endregion

#region Ready
func _ready():
	ani_runa.play("idle")
#endregion
	
#region Generic Functions
#region Update
func actualizar(monedas:int):
	lbl_runa.text = str(monedas)
#endregion
#endregion
