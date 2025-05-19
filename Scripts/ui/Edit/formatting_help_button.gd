extends Button

func _on_pressed() -> void:
	Steamworks.open_url(Steamworks.formatting_url)
