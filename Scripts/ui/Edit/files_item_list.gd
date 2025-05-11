extends Tree

@export var icon_include:Texture2D = null
@export var icon_exclude:Texture2D = null

const STEAMIGNORE_PATH: String = ".steamignore"

# Current contents of .steamignore, relative to the chosen directory.
var steamignore: GitIgnore

# True if a file or directory should be included, false if not.
var include_list: Dictionary[String, bool] = {}
# Lists all files and subdirectories of a given directory.
var dir_children: Dictionary[String, PackedStringArray] = {}

# Associates a TreeItem node ID with a path.
var paths_by_tree_item: Dictionary[int, Dictionary] = {}

## Initialize the file item list.
func _ready() -> void:
	# Basic layout
	self.set_column_title(0, "File")
	self.set_column_expand(0, true)
	self.set_column_expand_ratio(0, 10)
	
	self.set_column_title(1, "Type")
	self.set_column_expand(1, true)
	self.set_column_expand_ratio(1, 2)
	
	self.set_column_title(2, "Include?")
	self.set_column_expand(2, true)
	self.set_column_expand_ratio(2, 1)
	
	self.button_clicked.connect(on_button_pressed)
	UserPreferences.fetch().change_include_hidden_files.connect(on_change_should_include_hidden_files)
	
	render_blank_list()

func get_target_path() -> String:
	var result = %ButtonBrowseFiles.upload_target_path
	if result == null:
		result = ""
	return result

## If true, allow excluding files from the upload.
func is_exclude_enabled() -> bool:
	return %CheckBoxExcludeFiles.button_pressed

## If true, exclude files specified in .steamignore by default.
func is_steamignore_enabled() -> bool:
	return is_exclude_enabled() and %CheckBoxUseSteamIgnore.button_pressed

## If true, hide files and directories from the list once they are excluded.
func should_hide_excluded() -> bool:
	return is_exclude_enabled() and %CheckBoxHideExcluded.button_pressed

## If true, include files and folders hidden by the OS in the directory listing.
func should_include_hidden_files() -> bool:
	return UserPreferences.fetch().include_hidden_files

## Called when is_exclude_enabled changes.
func on_change_is_exclude_enabled(_new_value:bool) -> void:
	Logger.info("File exclusion toggled.")
	
	if include_list.size() == 0:
		Logger.info("  ...but file list isn't rendered yet.")
		return
	
	# Recursively enable inclusion on the root path, then update button statuses.
	set_include_state(get_target_path(), true)
	# We have to re-add the excluded items,
	# but exclusion itself doesn't need to change.
	render_include_list(get_target_path())

## Called when is_steamignore_enabled changes.
func on_change_is_steamignore_enabled(_new_value:bool) -> void:
	Logger.info("steamignore toggled.")
	
	if include_list.size() == 0:
		Logger.info("  ...but file list isn't rendered yet.")
		return
	
	# We basically have to re-compute the inclusion list.
	self.call_deferred("reset_include_list")

## Called when should_hide_excluded changes.
func on_change_should_hide_excluded(_new_value:bool) -> void:
	Logger.info("Hide exclusion toggled.")
	
	if include_list.size() == 0:
		Logger.info("  ...but file list isn't rendered yet.")
		return
	
	# We have to re-add the excluded items,
	# but exclusion itself doesn't need to change.
	render_include_list(get_target_path())

## Called when should_include_hidden_files changes.
func on_change_should_include_hidden_files(_new_value:bool) -> void:
	Logger.info("Include hidden toggled.")
	
	if include_list.size() == 0:
		Logger.info("  ...but file list isn't rendered yet.")
		return
	
	# We basically have to re-compute the inclusion list.
	self.call_deferred("reset_include_list")

## Called when target path changes.
func on_target_path_changed(_path:String) -> void:
	Logger.info("Target path changed.")
	self.call_deferred("reset_include_list")

## Called when any include/exclude button is pressed.
func on_button_pressed(item: TreeItem, _column: int, _button_id: int, _mouse_button_index:int):
	var data = paths_by_tree_item[item.get_instance_id()]
	var relative_path = data["relative_path"]
	var include = not include_list[relative_path]
	Logger.info("Pressed button for path: " + data["relative_path"] + " = " + str(include))

	# set_include_state assigns values of include_list but recursively.
	set_include_state(relative_path, include)
	refresh_node_buttons(item)

## Render a blank list of files.
func render_blank_list() -> void:
	# Display unselectable text in the blank layout.
	self.clear()
	var root = self.create_item()
	self.hide_root = false
	root.set_selectable(0, false)
	root.set_selectable(1, false)
	root.set_selectable(2, false)
	root.set_text(0, "Click 'Browse' to select a folder to upload.")

## Empties the include list, and repopulates the list of files.
func reset_include_list() -> void:
	Logger.info("Hard-resetting file include list...")
	var root_path = get_target_path()

	# Remove all entries.
	include_list.clear()
	dir_children.clear()

	build_steamignore(root_path)
	populate_include_list(root_path)
	render_include_list(root_path)

## Build an object representing the .steamignore contents for a given path, recursively.
func build_steamignore(root_path:String) -> void:
	if is_steamignore_enabled():
		steamignore = GitIgnore.load_from_directory(root_path, STEAMIGNORE_PATH)
	else:
		steamignore = GitIgnore.new("")
	
	steamignore.append_gitignore_for_subdirectory("", ".steamignore")
	
	print("Built steamignore:")
	print(steamignore)

## For a given directory, adds all files and subdirectories to the include list.
## Default value is based on if exclusion is enabled, and contents of .steamignore files.
func populate_include_list(root_path:String, relative_subdir:String = "") -> void:
	# Retrieve a list of all files and directories in the target path, recursively
	var dir = DirAccess.open(root_path)
	dir.include_hidden = should_include_hidden_files()

	var simplified_path = relative_subdir.simplify_path()

	dir_children[simplified_path] = PackedStringArray()

	for subdir in dir.get_directories():
		var full_path = (root_path + "/" + subdir).simplify_path()
		var relative_path = (relative_subdir + subdir).simplify_path()

		include_list[relative_path] = steamignore.is_included(relative_path)
		dir_children[simplified_path].append(relative_path)
	
		populate_include_list(full_path, relative_path + "/")

	for file in dir.get_files():
		# var full_path = (root_path + "/" + file).simplify_path()
		var relative_path = (relative_subdir + file).simplify_path()

		include_list[relative_path] = steamignore.is_included(relative_path)
		dir_children[simplified_path].append(relative_path)

func render_include_list(root_path:String, relative_subdir:String = "", root_node:TreeItem = null) -> void:
	# Retrieve a list of all files and directories in the target path, recursively
	var dir := DirAccess.open(root_path)
	dir.include_hidden = should_include_hidden_files()

	if root_node == null:
		self.clear()
		root_node = self.create_item()
	self.hide_root = true

	for subdir in dir.get_directories():
		var full_path := (root_path + "/" + subdir).simplify_path()
		var relative_path := (relative_subdir + subdir).simplify_path()

		var include := include_list[relative_path]

		if include or (not should_hide_excluded()):
			# Render the subdirectory.
			var dir_node := render_dir(root_node, subdir, full_path, relative_path, include)
			render_include_list(full_path, relative_path + "/", dir_node)
	
	for file in dir.get_files():
		var full_path := (root_path + "/" + file).simplify_path()
		var relative_path := (relative_subdir + file).simplify_path()

		var include := include_list[relative_path]

		if include or (not should_hide_excluded()):
			# Render the file.
			render_file(root_node, file, full_path, relative_path, include)

func render_dir(root_node:TreeItem, dir_name:String, full_path:String, relative_path:String, include:bool) -> TreeItem:
	var node := self.create_item(root_node)
	update_dir(node, dir_name, relative_path, include)
	paths_by_tree_item[node.get_instance_id()] = {
		"name": dir_name,
		"relative_path": relative_path,
		"full_path": full_path,
		"default_include": include,
		"is_directory": true
	}
	return node

func update_dir(node:TreeItem, dir_name:String, relative_path:String, include:bool) -> void:
	node.set_text(0, dir_name)
	node.set_tooltip_text(0, relative_path)
	node.set_text(1, "Directory")
	node.set_selectable(1, false)
	node.add_button(2, icon_include, 0, false, "Click to exclude from upload")
	update_node_button(node, include)

func render_file(root_node:TreeItem, file_name:String, full_path:String, relative_path:String, include:bool) -> TreeItem:
	var node := self.create_item(root_node)
	update_file(node, file_name, relative_path, include)
	paths_by_tree_item[node.get_instance_id()] = {
		"name": file_name,
		"relative_path": relative_path,
		"full_path": full_path,
		"default_include": include,
		"is_directory": false
	}
	return node

func update_file(node:TreeItem, file_name:String, relative_path:String, include:bool) -> void:
	var file_ext = file_name.get_extension()
	var file_type = "File (" + file_ext + ")"

	node.set_text(0, file_name)
	node.set_tooltip_text(0, relative_path)
	node.set_text(1, file_type)
	node.set_selectable(1, false)
	node.add_button(2, icon_include, 0, false, "Click to exclude from upload")
	update_node_button(node, include)

## Update the buttons of a given tree node to the given status.
func update_node_button(node:TreeItem, include:bool) -> void:
	var texture := icon_include if include else icon_exclude
	var tooltip := "Click to exclude from upload" if include else "Click to include in upload"
	node.set_button(2, 0, texture)
	node.set_button_tooltip_text(2, 0, tooltip)
	node.set_button_disabled(2, 0, not is_exclude_enabled())
	
	if should_hide_excluded() and not include:
		# Remove the node from its parent entirely.
		node.get_parent().remove_child(node)

## Update the buttons of a given tree node and ALL children to the current status.
func refresh_node_buttons(root_node:TreeItem = null) -> void:
	if root_node == null:
		root_node = self.get_root()
	
	var id = root_node.get_instance_id()
	if paths_by_tree_item.has(id):
		var data = paths_by_tree_item[id]
		var relative_path = data["relative_path"]
		var include = include_list[relative_path]
		update_node_button(root_node, include)
	
	# Update the button icons for all children of the node, if present.
	for item in root_node.get_children():
		refresh_node_buttons(item)

func set_include_state(relative_path:String, state:bool, recursive:bool = true) -> void:
	if relative_path == null:
		Logger.error("Tried to set include state of invalid path!")
		return
	
	include_list[relative_path] = state
	
	if recursive and dir_children.has(relative_path):
		for child_path in dir_children[relative_path]:
			set_include_state(child_path, state)

func export_data() -> Dictionary[String, PackedStringArray]:
	var result:Dictionary[String, PackedStringArray] = {
		"absolute_paths": [],
		"relative_paths": []
	}
	
	var root_path = get_target_path()
	if root_path == "":
		return result
	
	for key in include_list:
		var relative_path = key
		var include = include_list[relative_path]
		var absolute_path = (root_path + "/" + relative_path).simplify_path()
		var is_directory = DirAccess.dir_exists_absolute(absolute_path)
		if include and not is_directory:
			result["absolute_paths"].append(absolute_path)
			result["relative_paths"].append(relative_path)
	
	if result["absolute_paths"].size() != result["relative_paths"].size():
		Logger.error("Export list not generated correctly!")
		return {}
	
	return result
