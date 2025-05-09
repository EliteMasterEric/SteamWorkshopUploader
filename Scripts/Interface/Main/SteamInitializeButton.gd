extends Button

func _ready() -> void:
	Steamworks.call_on_init(on_steamworks_init)

func _on_pressed() -> void:
	Steamworks.start_steam()

func on_steamworks_init() -> void:
	print("Initialized Steamworks, disabling button...")
	if Steamworks.is_initialized:
		self.disabled = true
