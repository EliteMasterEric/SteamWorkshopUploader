extends PopupMenu

enum Item {
	QUIT,
}

const SHORTCUT_QUIT = preload("res://Resources/Shortcuts/quit.tres")

func _ready() -> void:
	self.set_item_shortcut(Item.QUIT, SHORTCUT_QUIT)

func _on_index_pressed(index: int) -> void:
	match index:
		Item.QUIT:
			# Quit the application.
			get_tree().quit()
