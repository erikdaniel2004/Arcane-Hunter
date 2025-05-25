extends CanvasLayer

@onready var btn_multijugador = $resources/boxs/vbox_multi/btn_multijugador
var modo_multijugador: bool = false

func _ready():
	actualizar_icono()

func actualizar_icono():
	if modo_multijugador:
		btn_multijugador.icon = preload("res://.godot/imported/Icon_98.png-64bfc14399c21f2b107c48ae47426035.ctex")
	else:
		btn_multijugador.icon = preload("res://.godot/imported/Icon_33.png-344a8cf7bd7047290ca97fa3372a969a.ctex")
		
#region Generic Functions
#region Nodes Connections
#region Start Level 1
func _on_btn_start_pressed():
	Global.modo_multijugador = modo_multijugador
	get_tree().change_scene_to_file("res://environment/scenes/environment.tscn")
#endregion

#region Start Level 2
func _on_btn_start_2_pressed():
	Global.modo_multijugador = modo_multijugador
	get_tree().change_scene_to_file("res://environment/scenes/environment2.tscn")
#endregion

#region Muliplayer
func _on_btn_multijugador_pressed():
	modo_multijugador = !modo_multijugador
	actualizar_icono()
#endregion

#region Exit
func _on_btn_salir_pressed():
	get_tree().change_scene_to_file("res://menus/menu/scene/menu.tscn")
#endregion
#endregion
#endregion
