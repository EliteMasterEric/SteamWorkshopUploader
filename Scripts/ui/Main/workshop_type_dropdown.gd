extends OptionButton

func _ready():
	Steamworks.call_on_init(on_steamworks_init)

func on_steamworks_init():
	self.disabled = false

func _on_item_selected(index: int):
	var type_id = get_item_id(index)
	var type_name = get_item_text(index)
	Logger.info("Steam Workshop Item type selected: " + type_name + " (" + str(type_id) + ")")
