extends CharacterBody2D

const SPEED := 200.0

@onready var sprite = $AnimatedSprite2D

@rpc("call_remote")
func sync_state(pos: Vector2, anim: String):
	position = pos
	sprite.play(anim)

func _ready():
	await get_tree().process_frame
	if is_multiplayer_authority():
		print("→ Je contrôle ce joueur (%s)" % name)
	else:
		print("→ Joueur distant : %s" % name)



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
