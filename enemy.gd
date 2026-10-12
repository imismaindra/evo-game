extends CharacterBody2D

# Variabel untuk menampung referensi pemain dari Main scene
@export var player_node: Node2D
const SPEED = 130.0

func _physics_process(_delta):
	if player_node:
		# Logika v1.0 (Kelemahan): Garis lurus linier tanpa spatial awareness / pathfinding
		var direction = (player_node.global_position - global_position).normalized()
		velocity = direction * SPEED
		move_and_slide()
