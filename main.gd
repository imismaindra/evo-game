## main.gd — Game Controller
## Orkestrasi sinyal, state game (playing/game_over/win), dan restart.
extends Node2D

const TOTAL_KEYS := 5

var keys_collected: int = 0
var game_active: bool = true

@onready var hud: CanvasLayer       = $HUD
@onready var player                  = $Player
@onready var portal                  = $Portal
@onready var enemy                   = $Enemy

func _ready() -> void:
	# Hubungkan sinyal player
	player.hit_by_enemy.connect(_on_game_over)
	# Hubungkan sinyal portal
	portal.player_entered.connect(_on_win)
	# Hubungkan sinyal tiap koin (dilakukan via group agar otomatis)
	_connect_coins()
	hud.update_keys(0)
	hud.update_portal_status(false)

func _connect_coins() -> void:
	for coin in get_tree().get_nodes_in_group("coin"):
		coin.collected.connect(_on_coin_collected)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_restart") and not game_active:
		get_tree().reload_current_scene()

# ── Signal Handlers ────────────────────────────────────────────────

func _on_coin_collected() -> void:
	if not game_active:
		return
	keys_collected += 1
	hud.update_keys(keys_collected)
	if keys_collected >= TOTAL_KEYS:
		portal.unlock()
		hud.update_portal_status(true)

func _on_game_over() -> void:
	if not game_active:
		return
	game_active = false
	# Hentikan pergerakan player dan enemy
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	hud.show_game_over()

func _on_win() -> void:
	if not game_active:
		return
	game_active = false
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	hud.show_win()
