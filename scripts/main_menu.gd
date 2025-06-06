extends Control

@onready var ip_input := $VBoxContainer/LineEdit
@onready var nickname_input := $VBoxContainer/NicknameEdit
@onready var create_button := $VBoxContainer/ButtonCreate
@onready var join_button := $VBoxContainer/ButtonJoin

var nickname_valid := false

func _ready():
	create_button.pressed.connect(_on_host)
	join_button.pressed.connect(_on_join)
	nickname_input.text_changed.connect(_on_nickname_changed)
	
	# Désactiver les boutons par défaut
	create_button.disabled = true
	join_button.disabled = true

func _on_nickname_changed(new_text: String):
	# Vérifier si le pseudo est valide (non vide et au moins 3 caractères)
	nickname_valid = new_text.strip_edges().length() >= 3
	create_button.disabled = !nickname_valid
	join_button.disabled = !nickname_valid

func _on_host():
	if !nickname_valid:
		_show_error("Veuillez entrer un pseudo valide (minimum 3 caractères)")
		return
		
	# Stocker le pseudo dans le singleton Network pour l'utiliser plus tard
	Network.player_nickname = nickname_input.text.strip_edges()
	
	if Network.create_server():
		get_tree().change_scene_to_file("res://scenes/world.tscn")
	else:
		_show_error("Erreur lors de la création du serveur")

func _on_join():
	if !nickname_valid:
		_show_error("Veuillez entrer un pseudo valide (minimum 3 caractères)")
		return
		
	var ip = ip_input.text.strip_edges()
	if ip == "":
		ip = "127.0.0.1"
	
	# Stocker le pseudo dans le singleton Network
	Network.player_nickname = nickname_input.text.strip_edges()
	
	# Tenter de rejoindre le serveur
	if Network.join_server(ip):
		get_tree().change_scene_to_file("res://scenes/world.tscn")
	else:
		_show_error("Impossible de se connecter au serveur")

func _show_error(message: String):
	var dialog = AcceptDialog.new()
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
