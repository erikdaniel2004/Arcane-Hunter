extends Area2D

#region Variables
@export var siguiente_nivel: String = "res://menus/menu_selection/scene/menu_selection.tscn"
#endregion

#region Ready
func _ready():
	body_entered.connect(_on_body_entered)
#endregion

#region Generic Functions
#region Nodes Connections
func _on_body_entered(body):
	if body.is_in_group("player_knight"):
		get_tree().change_scene_to_file(siguiente_nivel)
#endregion
#endregion
