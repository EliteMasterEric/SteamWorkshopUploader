extends CheckBox

func _on_target_path_changed(path: String) -> void:
	self.disabled = (path == "")
	if self.disabled:
		self.button_pressed = false
	else:
		self.button_pressed = UserPreferences.fetch().upload_hide_excluded

func _on_toggled(toggled_on: bool) -> void:
	UserPreferences.fetch().upload_hide_excluded = toggled_on
