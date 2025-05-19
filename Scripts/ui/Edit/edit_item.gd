extends Control

func _ready() -> void:
	reset_fields()
	
func reset_fields():
	var file_id:int = Steamworks.current_ugc_item["file_id"]
	var title:String = Steamworks.current_ugc_item["title"]
	var description:String = Steamworks.current_ugc_item["description"]

	var visibility:int = Steamworks.current_ugc_item["visibility"]

	var score:float = Steamworks.current_ugc_item["score"]
	var votes_up:int = Steamworks.current_ugc_item["votes_up"]
	var votes_down:int = Steamworks.current_ugc_item["votes_down"]
	
	var preview_url:String = Steamworks.current_ugc_item["preview_url"]

	var time_created:int = Steamworks.current_ugc_item["time_created"]
	var time_updated:int = Steamworks.current_ugc_item["time_updated"]

	var time_created_str:String = Time.get_datetime_string_from_unix_time(time_created)
	var time_updated_str:String = Time.get_datetime_string_from_unix_time(time_updated)

	var _tags_truncated:bool = Steamworks.current_ugc_item["tags_truncated"]
	var tags:String = Steamworks.current_ugc_item["tags"]
	var _tag_list = tags.split(",")

	var _result:int = Steamworks.current_ugc_item["result"]
	var _file_type:Steam.WorkshopFileType = Steamworks.current_ugc_item["file_type"]
	var _creator_app_id:int = Steamworks.current_ugc_item["creator_app_id"]
	var _consumer_app_id:int = Steamworks.current_ugc_item["consumer_app_id"]
	var _steam_id_owner:int = Steamworks.current_ugc_item["steam_id_owner"]
	var _time_added_to_user_list:int = Steamworks.current_ugc_item["time_added_to_user_list"]
	var _banned:bool = Steamworks.current_ugc_item["banned"]
	var _accepted_for_use:bool = Steamworks.current_ugc_item["accepted_for_use"]
	var _handle_file:int = Steamworks.current_ugc_item["handle_file"]
	var _handle_preview_file:int = Steamworks.current_ugc_item["handle_preview_file"]
	var _file_name:String = Steamworks.current_ugc_item["file_name"]
	var _file_size:int = Steamworks.current_ugc_item["file_size"]
	var _preview_file_size:int = Steamworks.current_ugc_item["preview_file_size"]
	var _url:String = Steamworks.current_ugc_item["url"]
	var _num_children:int = Steamworks.current_ugc_item["num_children"]
	var _total_files_size:int = Steamworks.current_ugc_item["total_files_size"]
	
	%LabelFileIDValue.text = str(file_id)
	var score_value = str(score) + " (+" + str(votes_up) + "/-" + str(votes_down) + ")"
	%LabelScoreValue.text = score_value
	%LabelFileCreatedValue.text = time_created_str
	%LabelFileUpdatedValue.text = time_updated_str

	%LineEditTitle.text = title
	%OptionButtonVisibility.selected = %OptionButtonVisibility.get_item_index(visibility)
	
	%TextEditDescription.text = description
	%RichTextDescription.text = description
	
	load_preview_from_url(preview_url)

func load_preview_from_url(url:String) -> void:
	if url == "":
		return
	WebImage.load_image_from_url(url, %SpritePreviewImage)

func _on_button_revert_pressed() -> void:
	Logger.info("Reverting UGC changes...")
	reset_fields()

func get_visiblity() -> Steam.RemoteStoragePublishedFileVisibility:
	return %OptionButtonVisibility.get_item_id(%OptionButtonVisibility.selected)

func _on_button_submit_pressed() -> void:
	Logger.info("Submitting UGC changes...")
	
	var file_id:int = Steamworks.current_ugc_item["file_id"]
	var new_ugc_data = Steamworks.current_ugc_item.duplicate()
	
	new_ugc_data["title"] = %LineEditTitle.text
	
	if %CheckBoxDescriptionShouldUpdate.button_pressed:
		Logger.info("Including description in upload...")
		new_ugc_data["description"] = %RichTextDescription.text
	else:
		new_ugc_data["description"] = ""

	new_ugc_data["visibility"] = get_visiblity()
	new_ugc_data["tags"] = ",".join(%HBoxTagList.current_tags)
	
	if %ButtonSelectPreviewImage.preview_image_path != "":
		new_ugc_data["preview_path"] = %ButtonSelectPreviewImage.preview_image_path
	else:
		new_ugc_data["preview_path"] = ""
	
	var change_notes:String = %LineEditChangeNotes.text
	
	if change_notes == "":
		Logger.error("Can't upload, must include change notes!")
		return

	var upload_dir:String = ""
	var base_dir:String = %ButtonBrowseFiles.upload_target_path
	
	if base_dir == "":
		Logger.info("No file upload specified, ignoring...")
	elif %CheckBoxExcludeFiles.button_pressed:
		# Exclusion enabled!
		Logger.info("File upload specified: " + base_dir)
		#specified with exclusion, copying to , ignoring...")
		var temp_dir = TempFolder.create_temp_folder()
		
		var export_data:Dictionary[String, PackedStringArray] = %ItemListFiles.export_data()
		
		if export_data.size() == 0:
			Logger.error("Couldn't build file list for upload!")
			Logger.error("CANCELLING upload!")
			return
		
		var relative_paths = export_data["relative_paths"]
		var absolute_paths = export_data["absolute_paths"]
		var count = relative_paths.size()
		
		Logger.info("Copying " + str(count) + " files to: " + temp_dir)
		
		var success = TempFolder.copy_files_to_folder(temp_dir, absolute_paths, relative_paths)
		if not success:
			Logger.error("Failed to copy files to temp folder!")
			Logger.error("CANCELLING upload!")
			return
		
		upload_dir = temp_dir
	else:
		# Exclusion disabled!
		Logger.info("File upload specified: " + base_dir)
		Logger.info("Exclusion disabled, copying folder as-is...")
		upload_dir = base_dir

	new_ugc_data["upload_path"] = upload_dir

	Steamworks.update_workshop_item(file_id, new_ugc_data, change_notes)
	
	# Back to main menu
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")
