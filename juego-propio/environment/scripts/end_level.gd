extends Area2D

#region Variables
@export var environment_path: NodePath = "../.."
#endregion

#region Ready
func _ready():
	body_entered.connect(_on_body_entered)
#endregion

#region Generic Functions
#region Nodes Connections
func _on_body_entered(body):
	if body.is_in_group("player_knight"):
		# Obtener el script del jugador
		var player = body
		var environment = get_node(environment_path)
		
		if environment:
			var data = {
				"tiempo": player.contador3.obtener_tiempo(),
				"monedas": player.monedas,
				"runas": player.runas,
				"enemigos": player.enemigos_muertos, 
				"jefes": player.jefes_muertos
			}
			environment._on_jugador_muerto(data, true) # true = nivel completado
#endregion
#endregion
