extends CharacterBody2D

const SPEED := 200.0

@onready var sprite = $AnimatedSprite2D

func _enter_tree():
	# Vérifier l'autorité dès l'entrée dans l'arbre
	if is_multiplayer_authority():
		print("Je suis l'autorité pour ", name, " (ID: ", get_multiplayer_authority(), ")")
	else:
		print("Je ne suis PAS l'autorité pour ", name, " (ID: ", get_multiplayer_authority(), ")")

func _ready():
	# Désactiver le traitement physique sur les instances non-autorités
	set_physics_process(is_multiplayer_authority())

@rpc("unreliable")
func sync_state(pos: Vector2, anim: String):
	# Seules les instances non-autorités reçoivent les mises à jour
	if not is_multiplayer_authority():
		position = pos
		sprite.play(anim)

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
