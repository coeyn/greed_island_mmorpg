extends Node

var peer : ENetMultiplayerPeer

func create_server(port := 12345):
	peer = ENetMultiplayerPeer.new()
	peer.create_server(port, 8)
	multiplayer.multiplayer_peer = peer
	print("Serveur lancé.")

func join_server(ip := "127.0.0.1", port := 12345):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, port)
	multiplayer.multiplayer_peer = peer
	print("Connexion à %s:%d" % [ip, port])
