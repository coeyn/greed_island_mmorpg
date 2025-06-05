extends Node2D

@export var player_scene: PackedScene

func _enter_tree():
	print("→ World ajouté au SceneTree")

func _ready():
	await get_tree().process_frame

	# 💡 Attendre que le peer réseau soit bien en place
	while multiplayer.multiplayer_peer == null or multiplayer.multiplayer_peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		await get_tree().process_frame

	var my_id = multiplayer.get_unique_id()
	print("→ Mon ID réseau :", my_id)

	spawn_player.rpc(my_id)

	if multiplayer.is_server():
		multiplayer.peer_connected.connect(_on_peer_connected)



func _on_peer_connected(id: int):
	print("→ Nouveau joueur connecté : %d" % id)

	# 1. D'abord on demande à tout le monde de spawn ce joueur
	spawn_player.rpc(id)

	# 2. Puis on attend 1 frame pour s'assurer qu'il soit bien instancié
	await get_tree().process_frame

	# 3. Ensuite on envoie au nouveau venu tous les autres joueurs
	for peer_id in multiplayer.get_peers():
		if peer_id != id:
			rpc_id(id, "spawn_player", peer_id)


var players = {}

@rpc("any_peer", "call_local")
func spawn_player(id: int):
	var player = player_scene.instantiate()
	player.name = "Player_%s" % id
	player.set_multiplayer_authority(id)
	player.position = Vector2(100 + id * 40, 100)
	add_child(player)
	players[id] = player
