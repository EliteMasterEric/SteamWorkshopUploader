extends Button

var upload_target_path:String = ""

var dialog:FileDialog

signal target_path_changed(path:String)

func _on_pressed() -> void:
	dialog = FileDialog.new()
	
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	
	dialog.use_native_dialog = UserPreferences.fetch().native_dialogs
	
	if UserPreferences.fetch().last_browse_dir != "":
		dialog.current_dir = UserPreferences.fetch().last_browse_dir
	
	dialog.dir_selected.connect(on_dir_selected)
	
	add_child(dialog)
	dialog.popup_centered_ratio(0.8)

func on_dir_selected(path:String) -> void:
	Logger.info("Got target folder: " + path)
	upload_target_path = path
	target_path_changed.emit(upload_target_path)
	UserPreferences.fetch().last_browse_dir = path

func _exit_tree() -> void:
	if dialog != null:
		dialog.queue_free()
