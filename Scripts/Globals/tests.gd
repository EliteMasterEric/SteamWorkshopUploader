extends Node

@export var tests_enabled:bool = true

func _ready():
	if tests_enabled:
		run_tests()

func run_tests():
	Logger.info("Running all tests...")
	TestGitIgnore.run_all_gitignore_tests()
