extends Node

var peer: ENetMultiplayerPeer
var player_nickname: String = ""
var player_nicknames = {}  # Dictionary pour stocker les pseudos des joueurs

# Signal pour notifier qu'un pseudo est déjà pris
signal nickname_rejected()
signal nickname_accepted()

func create_server(port := 12345, max_clients := 10):
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_clients)

	if result != OK:
		print("❌ Impossible de créer le serveur (code erreur : %s)" % result)
		return false

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Ajouter le pseudo du serveur
	player_nicknames[1] = player_nickname
	
	print("✅ Serveur ENet créé sur le port %s" % port)
	return true

func join_server(ip := "127.0.0.1", port := 12345):
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error != OK:
		print("❌ Impossible de se connecter au serveur (code erreur : %s)" % error)
		return false
	multiplayer.multiplayer_peer = peer
	print("→ Connexion au serveur %s:%d" % [ip, port])
	return true

@rpc("any_peer")
func register_player(nickname: String):
	var sender_id = multiplayer.get_remote_sender_id()
	
	# Vérifier si le pseudo est déjà utilisé
	if nickname in player_nicknames.values():
		reject_nickname.rpc_id(sender_id)
		return
	
	# Enregistrer le nouveau pseudo
	player_nicknames[sender_id] = nickname
	accept_nickname.rpc_id(sender_id)
	
	# Informer les autres clients du nouveau joueur
	sync_nicknames.rpc()

@rpc
func reject_nickname():
	nickname_rejected.emit()

@rpc
func accept_nickname():
	nickname_accepted.emit()

@rpc
func sync_nicknames():
	# Synchroniser la liste des pseudos avec tous les clients
	for id in player_nicknames.keys():
		if id != multiplayer.get_unique_id():
			player_nicknames[id] = player_nicknames[id]

func _on_peer_connected(id: int):
	if multiplayer.is_server():
		# Attendre que le client envoie son pseudo
		print("Nouveau client connecté! ID:", id)
	else:
		# Si nous sommes un client, envoyer notre pseudo au serveur
		register_player.rpc_id(1, player_nickname)

func _on_peer_disconnected(id: int):
	if id in player_nicknames:
		player_nicknames.erase(id)
		sync_nicknames.rpc()
	print("Joueur déconnecté! ID:", id)
