extends CheckBox

func _on_toggled(toggled_on: bool) -> void:
	%TextEditDescription.disabled = not toggled_on
	if not toggled_on:
		%TextEditDescription.text = Steamworks.current_ugc_item["description"]
		%RichTextDescription.text = Steamworks.current_ugc_item["description"]
