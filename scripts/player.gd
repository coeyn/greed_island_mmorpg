extends CharacterBody2D

const SPEED := 200.0

func _physics_process(delta):
	var direction = Vector2.ZERO

	# Priorité verticale > horizontale
	if Input.is_action_pressed("ui_up"):
		direction.y = -1
	elif Input.is_action_pressed("ui_down"):
		direction.y = 1
	elif Input.is_action_pressed("ui_left"):
		direction.x = -1
	elif Input.is_action_pressed("ui_right"):
		direction.x = 1

	velocity = direction * SPEED
	move_and_slide()

	# Animation
	var anim = ""
	if direction.y > 0:
		anim = "walk_down"
	elif direction.y < 0:
		anim = "walk_up"
	elif direction.x > 0:
		anim = "walk_right"
	elif direction.x < 0:
		anim = "walk_left"

	if anim != "":
		$AnimatedSprite2D.play(anim)
	else:
		$AnimatedSprite2D.stop()
