extends Node

@export var steam_apps: Array[SteamApp] = []

var app_id:int = -1;

var is_initialized:bool = false;

var tos_url = "https://steamcommunity.com/sharedfiles/workshoplegalagreement"

var ugc_items:Dictionary[int, Dictionary] = {}

var current_steam_app:SteamApp:
	get():
		if app_id == -1:
			return null
		for app in steam_apps:
			if app.app_id == app_id:
				return app
		return null
		
var current_ugc_item:Dictionary = {}

signal steamworks_init
signal steamworks_ugc_items_retrieved

signal current_stats_received()
signal item_created(item_id: int)
signal item_updated(item_id: int)
signal item_deleted(result:int, file_id: int)
signal item_downloaded(result:int, file_id: int, app_id:int)
signal item_installed(app_id:int, file_id: int)
signal ugc_query_completed(handle: int, result:int, results_returned:int, total_matching:int, cached:bool)

#
# Initialization Methods
#

func _ready():
	if Engine.has_singleton("Steam"):
		connect_signals()
		Logger.info("Successfully initialized Steamworks callbacks.")

func start_steam():
	if Engine.has_singleton("Steam"):
		initialize()
	else:
		Logger.error("GodotSteam is not initialized!")

func connect_signals():
	# Steam.connect("stea", on_steamworks_error, CONNECT_PERSIST)
	Steam.current_stats_received.connect(on_current_stats_received)
	
	Steam.item_created.connect(on_item_created)
	Steam.item_updated.connect(on_item_updated)
	Steam.item_deleted.connect(on_item_deleted)
	Steam.item_downloaded.connect(on_item_downloaded)
	Steam.item_installed.connect(on_item_installed)
	Steam.overlay_toggled.connect(on_overlay_toggled)
	Steam.ugc_query_completed.connect(on_ugc_query_completed)
	Steam.dlc_installed.connect(on_dlc_installed)
	Steam.user_subscribed_items_list_changed.connect(on_user_subscribed_items_list_changed)

func initialize():
	if is_initialized:
		print("Not initializing, already initialized.")
		return
	
	if app_id == -1:
		Logger.error("Can't init Steamworks, app ID not selected!")
		return
	
	var result:Dictionary = Steam.steamInitEx(app_id, false)
	var success = result["status"] == Steam.STEAM_API_INIT_RESULT_OK
	if success:
		Logger.info("Successfully initialized Steamworks!")
		is_initialized = true
		
		steamworks_init.emit()
	else:
		Logger.error("Steam failed to initialize. Status: " + result["status"] + ", Info: " + result["verbal"])

func _process(_delta: float) -> void:
	# Run callbacks to handle Steam events every frame
	Steam.run_callbacks()
	
#
# Query Methods
#

func get_app_id() -> int:
	return Steam.current_app_id

func get_user_display_name() -> String:
	return Steam.getPersonaName()

func get_user_steam_id() -> int:
	return Steam.getSteamID()

func get_ugc_items() -> Dictionary[int, Dictionary]:
	return ugc_items

#
# Action Methods
#

func call_on_init(callback: Callable):
	if is_initialized:
		callback.call()
	else:
		steamworks_init.connect(callback)

func open_url(url:String):
	if is_initialized:
		Steam.activateGameOverlayToWebPage(url, Steam.OverlayToWebPageMode.OVERLAY_TO_WEB_PAGE_MODE_DEFAULT)
	else:
		OS.shell_open(url)

func open_tos_url() -> void:
	open_url(tos_url)

func create_workshop_item(type:Steam.WorkshopFileType):
	Steam.createItem(Steam.current_app_id, type)

var _ugc_update_handle:int = -1

func update_workshop_item(file_id:int, new_params:Dictionary, change_notes:String):
	_ugc_update_handle = Steam.startItemUpdate(Steam.current_app_id, file_id)

	# TODO: Allow for setting the title and description in other languages
	Steam.setItemUpdateLanguage(_ugc_update_handle, "english")

	Steam.setItemTitle(_ugc_update_handle, new_params["title"])
	Steam.setItemTags(_ugc_update_handle, new_params["tags"].split(','))
	Steam.setItemVisibility(_ugc_update_handle, new_params["visibility"])

	if new_params["preview_path"] != "":
		print("Updating item preview file: " + new_params["preview_path"])
		Steam.setItemPreview(_ugc_update_handle, new_params["preview_path"])

	# Result will be received by on_item_updated
	Steam.submitItemUpdate(_ugc_update_handle, change_notes)

var _ugc_request_handle:int = -1
var _page_number:int = 1

func query_published_items(page:int = 1):
	if not is_initialized:
		Logger.error("Could not query published items, Steam not initialized!")
		return
	
	if _ugc_request_handle != -1:
		Logger.error("Could not query published items, request already in progress!")
		return
	
	var list = Steam.UserUGCList.USER_UGC_LIST_PUBLISHED
	var type = Steam.UGCMatchingUGCType.UGC_MATCHING_UGC_TYPE_ITEMS
	var sort = Steam.UserUGCListSortOrder.USER_UGC_LIST_SORT_ORDER_CREATION_ORDER_DESC
	
	_ugc_request_handle = Steam.createQueryUserUGCRequest(
		get_user_steam_id(),
		list, type, sort,
		get_app_id(), get_app_id(), page)
		
	# Return the full description.
	Steam.setReturnLongDescription(_ugc_request_handle, true)
	
	Steam.sendQueryUGCRequest(_ugc_request_handle)

func fetch_queried_ugc_items(count: int):
	for i in range(count):
		var item = Steam.getQueryUGCResult(_ugc_request_handle, i)
		ugc_items.set(item["file_id"], item)
		
		# Seems to always be 0 for Binding of Isaac.
		# var num_kv_tags = Steam.getQueryUGCNumKeyValueTags(_ugc_request_handle, i)
		# print("Entry has " + str(num_kv_tags) + " key/value tags")
		
		var preview_url = Steam.getQueryUGCPreviewURL(_ugc_request_handle, i)
		item["preview_url"] = preview_url

#
# Signal Callbacks
#

func on_current_stats_received():
	Logger.info("[STEAM] Current stats received")
	emit_signal("current_stats_received")
	
func on_item_created(result:int, file_id: int, accept_tos:bool):
	Logger.info("[STEAM] Item created: " + str(file_id) + " (result: " + str(result) + ")")
	emit_signal("item_created", result, file_id, accept_tos)
	
func on_item_updated(result: int, need_to_accept_tos:bool):
	Logger.info("[STEAM] Item updated: " + str(result) + " (need to accept TOS? " + str(need_to_accept_tos) + ")")
	emit_signal("item_updated", result, need_to_accept_tos)
	
func on_item_deleted(result:int, file_id: int):
	Logger.info("[STEAM] Item deleted: " + str(file_id) + " (result: " + str(result) + ")")
	emit_signal("item_deleted", result, file_id)
	
func on_item_downloaded(result:int, file_id: int, _app_id:int):
	Logger.info("[STEAM] Item downloaded: " + str(file_id) + " (result: " + str(result) + ")")
	emit_signal("item_downloaded", result, file_id, _app_id)
	
func on_item_installed(_app_id:int, file_id: int):
	Logger.info("[STEAM] Item installed: " + str(file_id))
	emit_signal("item_installed", _app_id, file_id)
	
func on_ugc_query_completed(handle: int, result:int, results_returned:int, total_matching:int, cached:bool):
	Logger.info("[STEAM] UGC query completed (result: " + str(result) + "), got " + str(results_returned) + " items")
	emit_signal("ugc_query_completed", handle, result, results_returned, total_matching, cached)
	
	if result == Steam.RESULT_OK:
		fetch_queried_ugc_items(results_returned)
	else:
		Logger.error("Couldn't get published UGC: " + str(result))
	
	_ugc_request_handle = -1
		
	if results_returned == 50:
		_page_number += 1
		query_published_items(_page_number)
	else:
		steamworks_ugc_items_retrieved.emit()
	
func on_dlc_installed(_app_id:int):
	Logger.info("[STEAM] DLC installed: " + str(_app_id))
	emit_signal("dlc_installed", _app_id)
	
func on_user_subscribed_items_list_changed(_app_id:int):
	Logger.info("[STEAM] User subscribed items list changed")
	emit_signal("user_subscribed_items_list_changed", _app_id)

func on_overlay_toggled(active:bool, user_initiated:bool, _app_id:int):
	Logger.info("[STEAM] Overlay toggled: " + str(active) + " (user? " + str(user_initiated) + ")")
	emit_signal("overlay_toggled", active, user_initiated)
