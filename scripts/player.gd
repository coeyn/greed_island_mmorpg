extends CharacterBody2D

const SPEED := 200.0

@onready var sprite = $AnimatedSprite2D
@onready var name_label = $NameLabel  # Référence au Label pour le pseudo

func _enter_tree():
	# Vérifier l'autorité dès l'entrée dans l'arbre
	if is_multiplayer_authority():
		print("Je suis l'autorité pour ", name, " (ID: ", get_multiplayer_authority(), ")")
	else:
		print("Je ne suis PAS l'autorité pour ", name, " (ID: ", get_multiplayer_authority(), ")")

func _ready():
	# Désactiver le traitement physique sur les instances non-autorités
	set_physics_process(is_multiplayer_authority())
	
	# Définir le nom du joueur si nous sommes l'autorité
	if is_multiplayer_authority():
		# Utiliser le pseudo du Network singleton
		if Network.player_nickname != "":
			name_label.text = Network.player_nickname
			sync_nickname.rpc(Network.player_nickname)
		else:
			# Fallback au nom du nœud si pas de pseudo (ne devrait pas arriver)
			name_label.text = str(name)
			sync_nickname.rpc(str(name))

@rpc("unreliable")
func sync_state(pos: Vector2, anim: String):
	# Seules les instances non-autorités reçoivent les mises à jour
	if not is_multiplayer_authority():
		position = pos
		sprite.play(anim)

@rpc("any_peer")
func sync_nickname(nickname: String):
	# Mettre à jour le pseudo affiché
	if name_label:
		name_label.text = nickname

func _physics_process(_delta):
	if not is_multiplayer_authority():
		return

	var direction = Vector2.ZERO
	var anim = "idle"

	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
		anim = "walk_up"
	elif Input.is_action_pressed("ui_down"):
		direction.y += 1
		anim = "walk_down"
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1
		anim = "walk_left"
	elif Input.is_action_pressed("ui_right"):
		direction.x += 1
		anim = "walk_right"

	velocity = direction.normalized() * SPEED
	move_and_slide()

	sprite.play(anim)
	sync_state.rpc(position, anim)
