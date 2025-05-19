extends RichTextLabel

func _on_meta_clicked(meta: Variant) -> void:
	# Assume [url=] contains a link, and open it.
	OS.shell_open(str(meta))
