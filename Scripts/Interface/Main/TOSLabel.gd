extends RichTextLabel

func _on_meta_clicked(_meta: Variant) -> void:
	Steamworks.open_tos_url()
