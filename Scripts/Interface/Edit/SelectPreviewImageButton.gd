extends Button

const FILTERS = [
	"*.png,*.jpg,*.jpeg;Image Files;image/png,image/jpeg",
	"*.gif;Animated Image Files;image/gif"
]

var preview_image_path:String = ""

var dialog:FileDialog

func _on_pressed() -> void:
	dialog = FileDialog.new()
	
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.filters = FILTERS
	
	dialog.use_native_dialog = UserPrefHandler.user_preferences.native_dialogs
	
	if UserPrefHandler.user_preferences.last_browse_dir != "":
		dialog.current_dir = UserPrefHandler.user_preferences.last_browse_dir
	
	dialog.file_selected.connect(on_file_selected)
	
	add_child(dialog)
	dialog.popup_centered_ratio(0.8)

func on_file_selected(path:String) -> void:
	Logger.info("Got preview file: " + path)
	preview_image_path = path
	WebImage.load_from_path(preview_image_path, %SpritePreviewImage)
	
	var byte_size = WebImage.get_byte_size_from_path(preview_image_path)
	Logger.info("Preview image size is " + str(byte_size) + " bytes")

	UserPrefHandler.user_preferences.last_browse_dir = dialog.current_dir

	if byte_size > 1024 * 1024:
		Logger.warning("Preview image is larger than 1MB! This may cause issues with uploading.")
	
func _exit_tree() -> void:
	dialog.queue_free()
