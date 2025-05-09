extends Panel

@export var show_back_button:bool = false

func _ready():
	%ButtonBack.visible = show_back_button
