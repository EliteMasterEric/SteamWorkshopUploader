extends Node

@export var print_logs:bool = true

signal log_any(message:String)
signal log_info(message:String)
signal log_error(message:String)
signal log_warning(message:String)

var messages:Array[String] = []

func info(message:String):
	if print_logs:
		print(message)
	messages.append("[INFO] " + message)
	log_any.emit(message)
	log_info.emit(message)

func error(message:String):
	if print_logs:
		push_error(message)
	messages.append("[ERROR] " + message)
	log_any.emit(message)
	log_error.emit(message)

func warning(message:String):
	if print_logs:
		push_warning(message)
	messages.append("[WARNING] " + message)
	log_any.emit(message)
	log_warning.emit(message)

func clear():
	messages.clear()

func get_messages() -> Array[String]:
	return messages
