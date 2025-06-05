extends Node

var peer: ENetMultiplayerPeer

func create_server(port := 12345, max_clients := 10):
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_clients)

	if result != OK:
		print("❌ Impossible de créer le serveur (code erreur : %s)" % result)
		return false

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
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

func _on_peer_connected(id: int):
	print("Pair connecté! ID:", id)

func _on_peer_disconnected(id: int):
	print("Pair déconnecté! ID:", id)
