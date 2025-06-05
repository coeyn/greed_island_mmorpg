extends Control

@onready var ip_input = $VBoxContainer/LineEditIP

func _ready():
	$VBoxContainer/ButtonHost.pressed.connect(_on_host_pressed)
	$VBoxContainer/ButtonJoin.pressed.connect(_on_join_pressed)

func _on_host_pressed():
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	Network.create_server()

func _on_join_pressed():
	get_tree().change_scene_to_file("res://scenes/world.tscn")
	var ip = ip_input.text.strip_edges()
	Network.join_server(ip)
