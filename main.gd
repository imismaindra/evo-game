## main.gd — Game Controller
## Orkestrasi sinyal, state game (playing/game_over/win), dan restart.
extends Node2D

const TOTAL_KEYS := 5

var keys_collected: int = 0
var game_active: bool = true

@onready var hud:        CanvasLayer         = $HUD
@onready var player                          = $Player
@onready var portal                          = $Portal
@onready var enemy                           = $Enemy
@onready var nav_region: NavigationRegion2D  = $NavigationRegion2D

func _ready() -> void:
	# ── Bangun NavigationPolygon secara manual via GDScript ───────────
	# Pendekatan ini 100% deterministik: tidak bergantung pada bake editor
	# maupun runtime bake engine — polygon langsung di-compute dari
	# koordinat dinding yang diketahui persis dari main.tscn.
	#
	# Koordinat dinding (position = center, size = full):
	#   BorderTop    : (400,  10), 800×20  → bounds (0,0)-(800,20)
	#   BorderBottom : (400, 590), 800×20  → bounds (0,580)-(800,600)
	#   BorderLeft   : ( 10, 300),  20×600 → bounds (0,0)-(20,600)
	#   BorderRight  : (790, 300),  20×600 → bounds (780,0)-(800,600)
	#   LWall1_H     : (210, 180), 200×20  → bounds (110,170)-(310,190)
	#   LWall1_V     : (110, 280),  20×200 → bounds (100,180)-(120,380)
	#   LWall2_H     : (580, 320), 200×20  → bounds (480,310)-(680,330)
	#   LWall2_V     : (680, 220),  20×200 → bounds (670,120)-(690,320)
	#   MidDivider   : (430, 300), 120×20  → bounds (370,290)-(490,310)
	#   SmallWall_LB : (300, 460),  20×120 → bounds (290,400)-(310,520)
	#
	# Agent radius 14px di-padding ke setiap sisi obstacle.
	# Outer boundary sedikit di dalam border wall (20px dari tepi layar).
	# ─────────────────────────────────────────────────────────────────
	_build_nav_polygon()

	# Hubungkan sinyal player
	player.hit_by_enemy.connect(_on_game_over)
	# Hubungkan sinyal portal
	portal.player_entered.connect(_on_win)
	# Hubungkan sinyal tiap koin (dilakukan via group agar otomatis)
	_connect_coins()
	hud.update_keys(0)
	hud.update_portal_status(false)


func _build_nav_polygon() -> void:
	# ── Godot 4.2+ API ───────────────────────────────────────────────
	# make_polygons_from_outlines() deprecated → gunakan:
	#   NavigationMeshSourceGeometryData2D  untuk definisi area & obstacle
	#   NavigationServer2D.bake_from_source_geometry_data()  tanpa callback
	#   = sinkron di main thread, selesai sebelum baris berikutnya.
	# ─────────────────────────────────────────────────────────────────
	var poly        := NavigationPolygon.new()
	poly.agent_radius = 14.0

	var source_data := NavigationMeshSourceGeometryData2D.new()

	# ── Area walkable (traversable outline) ──────────────────────────
	# Di dalam border wall 20px → (20,20) ke (780,580)
	source_data.add_traversable_outline(PackedVector2Array([
		Vector2( 20,  20), Vector2(780,  20),
		Vector2(780, 580), Vector2( 20, 580),
	]))

	# ── Obstacle walls + 14px agent-radius padding (obstruction) ─────
	# LWall1_H : center(210,180) size 200×20 → bounds (110,170)-(310,190)
	source_data.add_obstruction_outline(PackedVector2Array([
		Vector2( 96, 156), Vector2(324, 156),
		Vector2(324, 204), Vector2( 96, 204),
	]))
	# LWall1_V : center(110,280) size 20×200 → bounds (100,180)-(120,380)
	source_data.add_obstruction_outline(PackedVector2Array([
		Vector2( 86, 166), Vector2(134, 166),
		Vector2(134, 394), Vector2( 86, 394),
	]))
	# LWall2_H : center(580,320) size 200×20 → bounds (480,310)-(680,330)
	source_data.add_obstruction_outline(PackedVector2Array([
		Vector2(466, 296), Vector2(694, 296),
		Vector2(694, 344), Vector2(466, 344),
	]))
	# LWall2_V : center(680,220) size 20×200 → bounds (670,120)-(690,320)
	source_data.add_obstruction_outline(PackedVector2Array([
		Vector2(656, 106), Vector2(704, 106),
		Vector2(704, 334), Vector2(656, 334),
	]))
	# MidDivider : center(430,300) size 120×20 → bounds (370,290)-(490,310)
	source_data.add_obstruction_outline(PackedVector2Array([
		Vector2(356, 276), Vector2(504, 276),
		Vector2(504, 324), Vector2(356, 324),
	]))
	# SmallWall_LB : center(300,460) size 20×120 → bounds (290,400)-(310,520)
	source_data.add_obstruction_outline(PackedVector2Array([
		Vector2(276, 386), Vector2(324, 386),
		Vector2(324, 534), Vector2(276, 534),
	]))

	# Bake SINKRON (tanpa Callable callback = main thread, blocking)
	NavigationServer2D.bake_from_source_geometry_data(poly, source_data)

	# Terapkan ke NavigationRegion2D
	nav_region.navigation_polygon = poly



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
	if enemy.has_method("clear_path_line"):
		enemy.clear_path_line()
	hud.show_game_over()

func _on_win() -> void:
	if not game_active:
		return
	game_active = false
	player.set_physics_process(false)
	enemy.set_physics_process(false)
	if enemy.has_method("clear_path_line"):
		enemy.clear_path_line()
	hud.show_win()
