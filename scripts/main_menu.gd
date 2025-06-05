# scripts/main_menu.gd
extends Control

@onready var ip_input := $VBoxContainer/LineEdit

func _ready():
	$VBoxContainer/ButtonCreate.pressed.connect(_on_host)
	$VBoxContainer/ButtonJoin.pressed.connect(_on_join)

func _on_host():
	if Network.create_server():
		get_tree().change_scene_to_file("res://scenes/world.tscn")
	else:
		print("Erreur lors de la création du serveur")


func _on_join():
	var ip = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
		Network.join_server(ip)
		get_tree().change_scene_to_file("res://scenes/world.tscn")
