## player.gd — Core-01 / Soldier (v1.0)
## Gerakan 8-arah, animasi berjalan/idle, flip horizontal, emit sinyal saat terkena musuh.
extends CharacterBody2D

signal hit_by_enemy

const SPEED = 200.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * SPEED
	move_and_slide()

	# Kontrol animasi & arah hadap
	if input_vector != Vector2.ZERO:
		anim.play("walk")
		if input_vector.x < 0:
			anim.flip_h = true
		elif input_vector.x > 0:
			anim.flip_h = false
	else:
		anim.play("idle")

## Dipanggil oleh Enemy saat body_entered
func take_damage() -> void:
	emit_signal("hit_by_enemy")
