class_name TempFolder

static func create_temp_folder() -> String:
	var global_tmp = OS.get_temp_dir()
	var timestamp = Time.get_unix_time_from_system()
	var folder_name = "steamworkshop_temp_%d" % [timestamp]
	var temp_path = global_tmp.path_join(folder_name)
	
	# Create the directory
	var dir = DirAccess.open(global_tmp)
	if dir.make_dir(folder_name) != OK:
		Logger.error("Failed to create temporary directory: " + temp_path)
		return ""
		
	return temp_path

## Copy each of the provided absolute file paths to the corresponding relative paths, relative to target_path.
static func copy_files_to_folder(target_path:String, absolute_paths:Array[String], relative_paths:Array[String]) -> bool:
	if absolute_paths.size() != relative_paths.size():
		Logger.error("Mismatched array sizes in copy_files_to_folder")
		return false
		
	var dir = DirAccess.open(target_path)
	if not dir:
		Logger.error("Could not open target directory: " + target_path)
		return false
		
	for i in range(absolute_paths.size()):
		var abs_path = absolute_paths[i]
		var rel_path = relative_paths[i]
		var final_path = (target_path + "/" + rel_path).simplify_path()
		
		# Create any needed subdirectories
		var rel_dir = rel_path.get_base_dir()
		if rel_dir != "":
			if dir.make_dir_recursive(rel_dir) != OK:
				Logger.error("Failed to create subdirectory: " + rel_dir)
				return false
				
		# Copy the file
		var err = DirAccess.copy_absolute(abs_path, final_path)
		if err != OK:
			Logger.error("Failed to copy file %s to %s: %d" % [abs_path, rel_path, err])
			return false
			
	return true
