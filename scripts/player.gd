extends CharacterBody2D

const SPEED := 200

@onready var anim = $AnimatedSprite2D

func _ready():
	if not is_multiplayer_authority():
		set_process(false)
		set_physics_process(false)

func _physics_process(delta):
	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	elif Input.is_action_pressed("ui_down"):
		direction.y += 1
	elif Input.is_action_pressed("ui_left"):
		direction.x -= 1
	elif Input.is_action_pressed("ui_right"):
		direction.x += 1

	velocity = direction * SPEED
	move_and_slide()

	if direction != Vector2.ZERO:
		if direction.y > 0:
			anim.play("walk_down")
		elif direction.y < 0:
			anim.play("walk_up")
		elif direction.x > 0:
			anim.play("walk_right")
		elif direction.x < 0:
			anim.play("walk_left")
	else:
		anim.stop()
