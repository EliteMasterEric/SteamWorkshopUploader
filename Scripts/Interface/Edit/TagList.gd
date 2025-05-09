extends Control

var current_tags:Array = []

func _ready():
	var tags:String = Steamworks.current_ugc_item["tags"]
	current_tags = Array(tags.split(","))
	
	var tag_list = Steamworks.current_steam_app.tags
	for tag in tag_list:
		add_tag(tag)

func add_tag(tag:String) -> void:
	var tag_item = CheckBox.new()
	tag_item.text = tag
	if current_tags.has(tag):
		tag_item.button_pressed = true
	tag_item.toggled.connect(on_tag_toggled.bind(tag))
	add_child(tag_item)
	
func on_tag_toggled(toggled_on:bool, tag:String) -> void:
	print("Toggled tag: " + tag + "(" + str(toggled_on) + ")")
	if toggled_on:
		current_tags.append(tag)
	else:
		current_tags.erase(tag)
	Logger.info("Tag list is now " + str(current_tags))
