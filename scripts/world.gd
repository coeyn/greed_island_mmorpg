extends Node2D

@export var player_scene : PackedScene

func _ready():
	if multiplayer.is_server():
		_spawn_player(multiplayer.get_unique_id())
		multiplayer.peer_connected.connect(_spawn_player)

	elif multiplayer.is_client():
		_spawn_player(multiplayer.get_unique_id())

func _spawn_player(id: int):
	var player = player_scene.instantiate()
	add_child(player)
	player.set_multiplayer_authority(id)
	player.position = Vector2(100 + id * 50, 100)
