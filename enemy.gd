extends CharacterBody2D

# Evolusi v2.0:
# 1. Menggunakan NavigationAgent2D (A* Pathfinding polygon)
# 2. State Machine sederhana untuk menangani status pengejaran

enum State { CHASE, SEARCH }
var current_state = State.CHASE

@export var player_node: Node2D
const SPEED = 130.0

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

func _ready():
	# Menunggu frame pertama selesai agar sinkron dengan NavigationServer
	await get_tree().physics_frame

func _physics_process(_delta):
	if not player_node:
		return

	match current_state:
		State.CHASE:
			# Update target lokasi ke posisi pemain secara berkala
			nav_agent.target_position = player_node.global_position
			
			if not nav_agent.is_target_reached():
				var next_path_pos = nav_agent.get_next_path_position()
				var direction = (next_path_pos - global_position).normalized()
				velocity = direction * SPEED
				move_and_slide()
			else:
				velocity = Vector2.ZERO
				current_state = State.SEARCH
				
		State.SEARCH:
			# Berhenti sejenak jika target tercapai atau mencari ulang
			velocity = Vector2.ZERO
			if global_position.distance_to(player_node.global_position) > 40.0:
				current_state = State.CHASE
