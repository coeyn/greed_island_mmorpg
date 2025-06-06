extends Node2D

@export var player_scene: PackedScene
var players = {}

func _enter_tree():
	print("→ World ajouté au SceneTree")

func _ready():
	# Attendre que le réseau soit prêt
	await get_tree().process_frame
	while multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		await get_tree().process_frame

	var my_id = multiplayer.get_unique_id()
	print("→ Mon ID réseau :", my_id)

	# Configuration selon le type de pair
	if multiplayer.is_server():
		print("Je suis le serveur")
		# Le serveur crée son propre joueur
		spawn_players.rpc(my_id)
	else:
		print("Je suis un client")
		# Le client demande au serveur de le spawner
		request_spawn.rpc_id(1)



func _on_peer_connected(id: int):
	print("→ Nouveau joueur connecté : %d" % id)
	# Le serveur n'a pas besoin de faire quoi que ce soit ici
	# Les clients demanderont eux-mêmes la liste des joueurs

func _on_peer_disconnected(id: int):
	print("→ Joueur déconnecté : %d" % id)
	if players.has(id):
		players[id].queue_free()
		players.erase(id)

func create_player(id: int):
	if players.has(id):
		return
		
	var player = player_scene.instantiate()
	player.name = str(id)
	if player.has_node("NameLabel"):
		player.get_node("NameLabel").text = "Joueur " + str(id)
	player.position = Vector2(100 + id * 40, 100)
	add_child(player)
	
	# Set authority before adding to players dictionary
	player.set_multiplayer_authority(id)
	
	# Make sure authority is set correctly
	if player.get_multiplayer_authority() == multiplayer.get_unique_id():
		print("Je suis l'autorité pour le joueur ", id)
	else:
		print("Je ne suis pas l'autorité pour le joueur ", id)
		
	players[id] = player
	
	# Si nous sommes le serveur, informer tous les autres clients
	if multiplayer.is_server():
		for peer_id in multiplayer.get_peers():
			spawn_players.rpc_id(peer_id, id)

# Appelé par les clients pour demander leur spawn
@rpc("any_peer")
func request_spawn():
	if not multiplayer.is_server():
		return
	
	var id = multiplayer.get_remote_sender_id()
	spawn_players.rpc(id)

# Crée un joueur pour l'ID spécifié
@rpc("any_peer", "call_local")
func spawn_players(id: int):
	# Vérifier si le joueur existe déjà
	if players.has(id):
		return

	print("Création du joueur ", id)
	var player = player_scene.instantiate()
	player.name = str(id)
	
	# Définir l'autorité avant d'ajouter l'enfant
	player.set_multiplayer_authority(id)
	
	# Position aléatoire pour éviter le chevauchement
	var x = 100 + (randi() % 400)
	var y = 100 + (randi() % 400)
	player.position = Vector2(x, y)
	
	add_child(player)
	players[id] = player

	print("Autorité du joueur ", id, " : ", player.get_multiplayer_authority())
	
	# Si nous sommes le serveur, propager aux autres clients
	if multiplayer.is_server():
		# Propager à tous les clients sauf celui qui vient d'être créé
		for peer_id in multiplayer.get_peers():
			if peer_id != id:
				spawn_players.rpc_id(peer_id, id)
				
	# Si nous sommes un client qui vient de se connecter, demander les autres joueurs
	elif not multiplayer.is_server() and id == multiplayer.get_unique_id():
		request_existing_players.rpc_id(1)
	if multiplayer.is_server() and multiplayer.get_remote_sender_id() != id:
		for peer_id in multiplayer.get_peers():
			if peer_id != id:
				spawn_players.rpc_id(peer_id, id)

# Appelé par un client pour demander la liste des joueurs existants
@rpc("any_peer")
func request_existing_players():
	if not multiplayer.is_server():
		return
		
	var sender_id = multiplayer.get_remote_sender_id()
	for player_id in players:
		if player_id != sender_id:
			spawn_players.rpc_id(sender_id, player_id)
