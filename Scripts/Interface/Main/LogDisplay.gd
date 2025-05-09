extends TextEdit

func _ready() -> void:
	Logger.log_any.connect(on_log_any)

	on_log_any("")

func on_log_any(_last_msg:String) -> void:
	var messages:Array[String] = Logger.get_messages()
	var messages_formatted = "\n".join(messages)
	
	self.text = messages_formatted

	# Scroll to bottom of the text window whenever new messages are added
	self.set_deferred("scroll_vertical", self.get_v_scroll_bar().max_value)
