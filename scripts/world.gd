extends Node2D

@export var player_scene: PackedScene
var players = {}
var pending_nicknames = {}

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
		create_player(my_id)
	else:
		print("Je suis un client")
		# Le client demande au serveur de le spawner
		request_spawn.rpc_id(1)

func create_player(id: int) -> Node:
	if players.has(id):
		print("Le joueur ", id, " existe déjà")
		return players[id]
	
	print("Création du joueur ", id)
	var player = player_scene.instantiate()
	player.name = str(id)
	# Position aléatoire pour éviter le chevauchement
	var x = 100 + (randi() % 400)
	var y = 100 + (randi() % 400)
	player.position = Vector2(x, y)
	
	# Set authority before adding to players dictionary
	player.set_multiplayer_authority(id)
	add_child(player)
	players[id] = player

	# Correction : appliquer le pseudo si déjà connu
	if Network.player_nicknames.has(id):
		update_player_nickname(id, Network.player_nicknames[id])
	# Correction : appliquer le pseudo en attente si présent
	elif pending_nicknames.has(id):
		update_player_nickname(id, pending_nicknames[id])
		pending_nicknames.erase(id)

	return player

func update_player_nickname(player_id: int, nickname: String):
	print("Mise à jour du pseudo pour ", player_id, ": ", nickname)
	var player = players.get(player_id)
	if player and player.has_method("set_nickname"):
		player.set_nickname(nickname)
	else:
		# Stocker le pseudo en attente si le joueur n'existe pas encore
		pending_nicknames[player_id] = nickname

# Appelé par les clients pour demander leur spawn
@rpc("any_peer")
func request_spawn():
	if not multiplayer.is_server():
		return
	
	var id = multiplayer.get_remote_sender_id()
	print("Demande de spawn reçue du client ", id)
	
	# Envoyer tous les joueurs existants au nouveau client
	for existing_id in players.keys():
		sync_player.rpc_id(id, existing_id, players[existing_id].position)
	
	# Créer le nouveau joueur localement sur le serveur
	var player = create_player(id)
	# Propager à tous les autres clients
	sync_player.rpc(id, player.position)

# Synchronise un joueur pour tous les clients
@rpc("any_peer", "call_local")
func sync_player(id: int, pos: Vector2):
	print("Synchronisation du joueur ", id)
	var player = create_player(id)
	player.position = pos
	
	# Demander la synchronisation des pseudos si c'est notre joueur
	if id == multiplayer.get_unique_id():
		Network.request_nickname_sync.rpc_id(1)
