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
        else:
                # Inform the server that this client is ready to receive
                # information about the already connected players.
                rpc_id(1, "client_ready")



func _on_peer_connected(id: int):
        print("→ Nouveau joueur connecté : %d" % id)
        # Waiting for the client to notify that its world is ready


var players = {}

@rpc("any_peer", "call_local")
func spawn_player(id: int):
	var player = player_scene.instantiate()
	player.name = "Player_%s" % id
	player.set_multiplayer_authority(id)
	player.position = Vector2(100 + id * 40, 100)
        add_child(player)
        players[id] = player

@rpc("authority")
func client_ready():
        if not multiplayer.is_server():
                return

        var id = multiplayer.get_remote_sender_id()

        for peer_id in players.keys():
                if peer_id != id:
                        rpc_id(id, "spawn_player", peer_id)
