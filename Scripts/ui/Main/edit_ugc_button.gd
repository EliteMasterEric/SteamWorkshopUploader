extends Button

func _on_pressed() -> void:
	var selected_id = %DropdownWorkshopItem.get_selected_item_id()
	Logger.info("Editing UGC Item: " + str(selected_id))
	
	Steamworks.current_ugc_item = Steamworks.ugc_items[selected_id]
	get_tree().change_scene_to_file("res://scenes/ui/EditItem.tscn")
