extends Control

func _ready() -> void:
	$Button.pressed.connect(_start_game)

func _start_game() -> void:
	get_tree().change_scene_to_file("res://WEB-RUNNER.tscn")
