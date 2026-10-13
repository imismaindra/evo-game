## coin.gd — Encryption Key Fragment
## Area2D yang mendeteksi Player, emit sinyal, lalu hapus diri.
extends Area2D

signal collected

# Efek visual saat koin diambil: kedip cepat sebelum hilang
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		emit_signal("collected")
		_play_collect_effect()

func _play_collect_effect() -> void:
	# Nonaktifkan collision supaya tidak trigger dua kali
	$CollisionShape2D.set_deferred("disabled", true)
	# Animasi: scale up + fade out
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property($Visual, "scale", Vector2(2.0, 2.0), 0.15)
	tween.tween_property($Visual, "modulate:a", 0.0, 0.15)
	tween.chain().tween_callback(queue_free)
