extends CharacterBody2D

const SPEED := 200.0

@onready var sprite = $AnimatedSprite2D
@onready var name_label = $NameLabel

@export var nickname: String = ""

# S'assurer que les RPCs sont configurés avant d'être utilisés
func _enter_tree():
	# Vérifier l'autorité dès l'entrée dans l'arbre
	if is_multiplayer_authority():
		print("Je suis l'autorité pour ", name, " (ID: ", get_multiplayer_authority(), ")")
	else:
		print("Je ne suis PAS l'autorité pour ", name, " (ID: ", get_multiplayer_authority(), ")")

func _ready():
	# Désactiver le traitement physique sur les instances non-autorités
	set_physics_process(is_multiplayer_authority())
	
	# Attendre une frame pour s'assurer que le nœud est bien dans l'arbre
	await get_tree().process_frame
	
	# Définir le nom du joueur si nous sommes l'autorité
	if is_multiplayer_authority():
		update_nickname(Network.player_nickname)

	if name_label:
		name_label.text = nickname

@rpc("any_peer", "call_local")
func sync_state(pos: Vector2, anim: String):
	# Seules les instances non-autorités reçoivent les mises à jour
	if not is_multiplayer_authority():
		position = pos
		sprite.play(anim)

func update_nickname(new_nickname: String):
	if name_label and new_nickname != "":
		name_label.text = new_nickname
		# Propager le changement seulement si nous sommes l'autorité
		if is_multiplayer_authority():
			# Attendre une frame pour s'assurer que le nœud est bien dans l'arbre partout
			await get_tree().process_frame
			sync_nickname.rpc(new_nickname)

@rpc("any_peer", "call_local")
func sync_nickname(new_nickname: String):
	if name_label:
		name_label.text = new_nickname
	# Met à jour la propriété synchronisée
	nickname = new_nickname

func set_nickname(new_nickname: String):
	nickname = new_nickname
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
