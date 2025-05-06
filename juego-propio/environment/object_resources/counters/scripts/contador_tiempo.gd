extends Control

#region Variables
@onready var lbl_tiempo = $lbl_tiempo

var tiempo := 0.0
var contando := true
#endregion

#region Process
func _process(delta):
	if contando:
		tiempo += delta
		lbl_tiempo.text = "Tiempo: %.2fs" % tiempo + "s"
#endregion

#region Generic Functions
#region Begin
func iniciar():
	tiempo = 0.0
	contando = true
	lbl_tiempo.text = "Tiempo: 0.00s"
#endregion

#region Restart
func reiniciar():
	tiempo = 0
	lbl_tiempo.text = "Tiempo: 0s"
#endregion

#region Pause
func pausar():
	contando = false
#endregion

#region Reanude
func reanudar():
	contando = true
#endregion

#region Time
func obtener_tiempo() -> int:
	return int(tiempo)
#endregion
#endregion
