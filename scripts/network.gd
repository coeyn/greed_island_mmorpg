extends Node

var peer: ENetMultiplayerPeer

func create_server(port := 12345, max_clients := 10):
	var peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, max_clients)

	if result != OK:
		print("❌ Impossible de créer le serveur (code erreur : %s)" % result)
		return false

	multiplayer.multiplayer_peer = peer
	print("✅ Serveur ENet créé sur le port %s" % port)
	return true

func join_server(ip := "127.0.0.1", port := 12345):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer  # ✅ CORRECT
	print("→ Connexion au serveur %s:%d" % [ip, port])
