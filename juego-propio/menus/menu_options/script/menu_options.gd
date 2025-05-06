extends CanvasLayer

#region Variables
@onready var btn_resume = $resources/btn_resume
@onready var btn_restart = $resources/btn_restart
@onready var btn_levels = $resources/btn_levels
@onready var btn_settings = $resources/btn_settings
@onready var btn_quit = $resources/btn_quit
@onready var btn_quit2 = $resources/btn_quit2
@onready var color_rect = $color_rect
#endregion

#region Ready
func _ready():
	hide()
#endregion

#region Physics Process
func _physics_process(delta):
	if Input.is_action_just_pressed("pausa"):
		color_rect.visible = true
		if visible:
			_unpause_and_close()
		else:
			await get_tree().process_frame
			show()
			get_tree().paused = true
#endregion

#region Options
func _unpause_and_close():
	get_tree().paused = false
	color_rect.visible = false
	hide()

func _on_btn_continue_pressed():
	_unpause_and_close()

func _on_btn_restart_pressed():
	var current_scene = get_tree().current_scene.scene_file_path
	_unpause_and_close()
	get_tree().change_scene_to_file(current_scene)

func _on_btn_levels_pressed():
	_unpause_and_close()
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")

func _on_btn_settings_pressed():
	var ajustes = preload("res://menus/menu_settings/scene/menu_settings.tscn").instantiate()
	ajustes.menu_padre = self
	add_child(ajustes)
	ajustes.show()
	self.hide()

func _on_btn_quit_pressed():
	_unpause_and_close()
	get_tree().change_scene_to_file("res://menus/menu_selection/scene/menu_selection.tscn")

func _on_btn_quit2_pressed():
	_unpause_and_close()
#endregion
