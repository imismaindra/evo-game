## portal.gd — Extraction Portal / Treasure Gate
## Area2D yang mendeteksi Player, emit sinyal hanya jika terbuka (semua koin terkumpul).
extends Area2D

signal player_entered

const OPEN_TEXTURE = preload("res://assets/dungeon/portal_open.png")

var is_locked: bool = true

@onready var visual: Sprite2D = $Visual

func unlock() -> void:
	is_locked = false
	visual.texture = OPEN_TEXTURE
	# Visual feedback: pulse scale + glow hijau emas saat terbuka
	var tween := create_tween().set_loops()
	tween.tween_property(visual, "scale", Vector2(2.8, 2.8), 0.4)
	tween.parallel().tween_property(visual, "modulate", Color(1.2, 1.2, 0.8, 1.0), 0.4)
	tween.tween_property(visual, "scale", Vector2(2.4, 2.4), 0.4)
	tween.parallel().tween_property(visual, "modulate", Color(0.9, 0.9, 0.9, 1.0), 0.4)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not is_locked:
		emit_signal("player_entered")
