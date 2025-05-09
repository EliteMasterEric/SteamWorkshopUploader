extends CodeEdit

func _on_text_changed() -> void:
	%RichTextDescription.text = self.text
