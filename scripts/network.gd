extends Node

var peer: ENetMultiplayerPeer
var player_nickname: String = ""
var player_nicknames = {}  # Dictionary pour stocker les pseudos des joueurs

func create_server(port := 12345, max_clients := 10):
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_clients)

	if result != OK:
		print("❌ Impossible de créer le serveur (code erreur : %s)" % result)
		return false

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	
	# Utiliser l'ID dynamique du serveur (host) pour le pseudo
	var my_id = multiplayer.get_unique_id()
	player_nicknames[my_id] = player_nickname
	
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
	print("[DEBUG] register_player appelé sur serveur. sender_id:", sender_id, "nickname:", nickname)
	
	# Vérifier si le pseudo est déjà utilisé
	if nickname in player_nicknames.values():
		print("Pseudo déjà utilisé:", nickname)
		return
	
	# Enregistrer le nouveau pseudo
	player_nicknames[sender_id] = nickname
	print("Nouveau pseudo enregistré:", nickname, "pour ID:", sender_id)
	print("[DEBUG] Etat actuel player_nicknames:", player_nicknames)
	
	# Si nous sommes le serveur, synchroniser la liste complète des pseudos avec tous les clients
	if multiplayer.is_server():
		for peer_id in multiplayer.get_peers():
			for id in player_nicknames.keys():
				sync_nickname.rpc_id(peer_id, id, player_nicknames[id])
		# Synchroniser aussi pour le serveur local
		for id in player_nicknames.keys():
			sync_nickname.rpc(id, player_nicknames[id])

@rpc
func sync_nickname(player_id: int, nickname: String):
	player_nicknames[player_id] = nickname
	
	# Log de debug pour vérifier la scène courante
	if get_tree().current_scene:
		print("[DEBUG] Scène courante:", get_tree().current_scene.name)
	else:
		print("[DEBUG] Aucune scène courante!")

	# Mettre à jour le pseudo dans la scène actuelle
	if get_tree().current_scene and get_tree().current_scene.has_method("update_player_nickname"):
		get_tree().current_scene.update_player_nickname(player_id, nickname)

@rpc("any_peer")
func request_nickname_sync():
	if not multiplayer.is_server():
		return
		
	var sender_id = multiplayer.get_remote_sender_id()
	print("Demande de synchronisation des pseudos reçue de:", sender_id)
	
	# Envoyer tous les pseudos connus au client
	for id in player_nicknames.keys():
		sync_nickname.rpc_id(sender_id, id, player_nicknames[id])

func _on_peer_connected(id: int):
	if multiplayer.is_server():
		print("Nouveau client connecté! ID:", id)
		print("[DEBUG] Serveur attend un register_player du client:", id)
		# Synchroniser tous les pseudos avec tous les clients
		for peer_id in multiplayer.get_peers():
			for pid in player_nicknames.keys():
				sync_nickname.rpc_id(peer_id, pid, player_nicknames[pid])
		for pid in player_nicknames.keys():
			sync_nickname.rpc(pid, player_nicknames[pid])
	else:
		await get_tree().process_frame
		print("[DEBUG] Client envoie register_player.rpc_id(1, ...)")
		register_player.rpc_id(1, player_nickname)

func _on_peer_disconnected(id: int):
	if id in player_nicknames:
		player_nicknames.erase(id)
		
		# Si nous sommes le serveur, informer tous les clients de la déconnexion
		if multiplayer.is_server():
			for peer_id in multiplayer.get_peers():
				sync_nickname.rpc_id(peer_id, id, "")
	print("Joueur déconnecté! ID:", id)
