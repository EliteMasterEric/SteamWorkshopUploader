extends Button

func _on_button_pressed() -> void:
	Logger.info("Creating Steam Workshop item...")
	var type:Steam.WorkshopFileType = %DropdownWorkshopType.get_selected_id()
	Steamworks.create_workshop_item(type)
