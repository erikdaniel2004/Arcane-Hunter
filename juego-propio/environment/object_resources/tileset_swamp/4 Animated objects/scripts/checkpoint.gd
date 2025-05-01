extends Node2D

#region Variables
@onready var sprite = $ani_flag
#endregion

#region Ready
func _ready():
	sprite.play("move")
#endregion
