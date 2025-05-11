extends OptionButton

# We have to store item IDs separate,
# because setting the OptionButton index to a high number breaks.
var id_mapping:Array[int] = []

func _ready():
	Steamworks.steamworks_ugc_items_retrieved.connect(on_ugc_items_retrieved)
	
func on_ugc_items_retrieved():
	var items = Steamworks.get_ugc_items()
	
	if items.size() > 0:
		self.clear()
		for item_id in items:
			var item = items.get(item_id)
			process_item(item)
		self.disabled = false
	else:
		self.clear()
		self.add_item("Empty", 0)
		self.disabled = true
	
	var item_id = get_selected_item_id()
	%ButtonEditUGC.disabled = item_id == -1

func process_item(item:Dictionary):
	var _result:int = item["result"]
	var file_id:int = item["file_id"]
	var _file_type:Steam.WorkshopFileType = item["file_type"]
	var _creator_app_id:int = item["creator_app_id"]
	var _consumer_app_id:int = item["consumer_app_id"]
	var title:String = item["title"]
	var _description:String = item["description"]
	var _steam_id_owner:int = item["steam_id_owner"]
	var _time_created:int = item["time_created"]
	var _time_updated:int = item["time_updated"]
	var _time_added_to_user_list:int = item["time_added_to_user_list"]
	var _visibility:int = item["visibility"]
	var _banned:bool = item["banned"]
	var _accepted_for_use:bool = item["accepted_for_use"]
	var _tags_truncated:bool = item["tags_truncated"]
	var tags:String = item["tags"]
	var _tag_list = tags.split(",")
	var _handle_file:int = item["handle_file"]
	var _handle_preview_file:int = item["handle_preview_file"]
	var _file_name:String = item["file_name"]
	var _file_size:int = item["file_size"]
	var _preview_file_size:int = item["preview_file_size"]
	var _url:String = item["url"]
	var _votes_up:int = item["votes_up"]
	var _votes_down:int = item["votes_down"]
	var _score:float = item["score"]
	var _num_children:int = item["num_children"]
	var _total_files_size:int = item["total_files_size"]
	
	var item_label = title + " (" + str(file_id) + ")"
	
	id_mapping.append(file_id)
	self.add_item(item_label)

func _on_item_selected(index: int) -> void:
	var item_name = get_item_text(index)
	Logger.info("Steam Workshop Item selected: " + item_name)
	
	var item_id = get_selected_item_id()
	%ButtonEditUGC.disabled = item_id == -1

func get_selected_item_id() -> int:
	return id_mapping[selected]
