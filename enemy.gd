## enemy.gd — Hunter-X / Orc (v1.0)
## ═══════════════════════════════════════════════════════════════════
## KELEMAHAN NAVIGASI v1.0 (INTENTIONAL / DOCUMENTED):
##   Menggunakan kalkulasi vektor linier Euclidean murni.
##   Formula: velocity = (player.global_position - global_position).normalized() * SPEED
##
##   Konsekuensi: Enemy tidak bisa bermanuver mengelilingi obstacle.
##   Saat player berdiri di balik sudut dalam dinding "L", enemy akan
##   bergerak lurus ke arah player dan menempel/tersangkut di dinding
##   (deadlock navigasi). Ini adalah kelemahan yang sengaja dipertahankan
##   untuk demonstrasi evolusi perangkat lunak ke v2.0.
## ═══════════════════════════════════════════════════════════════════
extends CharacterBody2D

const SPEED = 130.0

@export var player_node: CharacterBody2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	# Hubungkan HitArea untuk deteksi sentuhan dengan player
	$HitArea.body_entered.connect(_on_hit_area_body_entered)
	# Fallback: jika player_node tidak ter-assign via export NodePath,
	# cari manual via group "player" setelah satu frame
	if not player_node:
		await get_tree().process_frame
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0] as CharacterBody2D

func _physics_process(_delta: float) -> void:
	if not player_node:
		anim.play("idle")
		return

	# [v1.0 FLAW] Navigasi linier — tidak ada pathfinding, raycast, atau steering
	var direction := (player_node.global_position - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()

	# Kontrol animasi & arah hadap
	if velocity.length() > 5.0:
		anim.play("walk")
		if velocity.x < 0:
			anim.flip_h = true
		elif velocity.x > 0:
			anim.flip_h = false
	else:
		anim.play("idle")

func _on_hit_area_body_entered(body: Node2D) -> void:
	if body == player_node:
		player_node.take_damage()
