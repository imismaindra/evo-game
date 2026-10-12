extends CharacterBody2D

const SPEED = 220.0

func _physics_process(_delta):
	# Mengambil input arah 2D dari tombol panah/WASD
	var input_vector = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_vector * SPEED
	move_and_slide()
