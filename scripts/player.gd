extends CharacterBody2D

const SPEED := 200.0

@onready var sprite = $AnimatedSprite2D
@onready var name_label = $NameLabel  # Référence au Label

func _enter_tree():
	# Vérifier l'autorité dès l'entrée dans l'arbre
	if is_multiplayer_authority():
		print("Je suis l'autorité pour ", name, " (ID: ", get_multiplayer_authority(), ")")
	else:
		print("Je ne suis PAS l'autorité pour ", name, " (ID: ", get_multiplayer_authority(), ")")

func _ready():
	# Désactiver le traitement physique sur les instances non-autorités
	set_physics_process(is_multiplayer_authority())

	# Configurer le label du nom
	if !name_label:  # Si le label n'existe pas encore
		name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.position = Vector2(-50, -30)  # Positionner au-dessus du sprite
		name_label.custom_minimum_size = Vector2(100, 20)  # Largeur minimale pour le texte
		add_child(name_label)

	# Définir le texte du label (vous pouvez le personnaliser)
	name_label.text = str(name)  # Utilise le nom du nœud par défaut

@rpc("unreliable")
func sync_state(pos: Vector2, anim: String, player_name: String = ""):
	if not is_multiplayer_authority():
		position = pos
		sprite.play(anim)
		if player_name != "":
			name_label.text = player_name

func _physics_process(delta):
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
