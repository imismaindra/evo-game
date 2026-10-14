## enemy.gd — Hunter-X / Goblin (v2.0)
## ═══════════════════════════════════════════════════════════════════
## EVOLUSI v1.0 → v2.0:
##   v1.0: Navigasi linier Euclidean murni — tersangkut di dinding.
##   v2.0: A* pathfinding via NavigationAgent2D + FSM (CHASE / SEARCH).
##
## GOTCHA GODOT 4 — NavigationAgent2D timing:
##   • is_navigation_finished() mengembalikan TRUE saat path KOSONG
##     (belum dihitung), bukan hanya saat benar-benar tiba di target.
##     → Jangan pakai is_navigation_finished() sebagai guard gerak di CHASE.
##   • NavigationServer2D memproses path query secara asinkron di AKHIR
##     physics frame. Target baru → path siap di frame BERIKUTNYA.
##   • Solusi: flag _nav_ready + await 2 physics_frame agar region dan
##     map sudah tersinkronisasi sebelum query pertama dikirim.
## ═══════════════════════════════════════════════════════════════════
extends CharacterBody2D

# ── Konstanta ─────────────────────────────────────────────────────────
const SPEED           := 130.0   ## px/detik
const DETECTION_RANGE := 350.0   ## px — radius aktivasi CHASE
const ARRIVAL_DIST    := 24.0    ## px — jarak "sudah sampai" ke player
const SEARCH_DURATION := 3.0     ## detik SEARCH sebelum idle

# ── FSM ───────────────────────────────────────────────────────────────
enum State { CHASE, SEARCH }
var _state: State = State.CHASE

# ── Internal ──────────────────────────────────────────────────────────
var _nav_ready      := false   # true setelah navigation map siap
var _search_timer   := 0.0
var _last_known_pos := Vector2.ZERO

# ── Node refs ─────────────────────────────────────────────────────────
@export var player_node: CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var anim:      AnimatedSprite2D  = $AnimatedSprite2D
@onready var path_line: Line2D            = $PathLine


# ════════════════════════════════════════════════════════════════════
func _ready() -> void:
	$HitArea.body_entered.connect(_on_hit_area_body_entered)

	# Fallback: cari player via group jika belum di-assign via export
	if not player_node:
		await get_tree().process_frame
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player_node = players[0] as CharacterBody2D

	# ── Sinkronisasi NavigationServer2D ──────────────────────────────
	# Frame 1: StaticBody2D terdaftar di physics server.
	# Frame 2: main.gd._ready() menjalankan bake_navigation_polygon(false).
	# Frame 3: NavigationServer2D memproses hasil bake → map siap di-query.
	await get_tree().physics_frame
	await get_tree().physics_frame
	await get_tree().physics_frame

	nav_agent.path_desired_distance   = 16.0
	nav_agent.target_desired_distance = 20.0
	nav_agent.avoidance_enabled       = false

	_nav_ready = true
	anim.play("idle")


# ════════════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	if not player_node or not _nav_ready:
		anim.play("idle")
		_update_path_line()
		return

	match _state:
		State.CHASE:  _state_chase(delta)
		State.SEARCH: _state_search(delta)

	_update_path_line()
	


# ── State: CHASE ──────────────────────────────────────────────────────
func _state_chase(_delta: float) -> void:
	var dist_to_player := global_position.distance_to(player_node.global_position)

	# Transisi ke SEARCH jika player keluar detection range
	if dist_to_player > DETECTION_RANGE:
		_last_known_pos = player_node.global_position
		_search_timer   = SEARCH_DURATION
		_state          = State.SEARCH
		return

	# Perbarui target A* setiap frame (NavigationServer proses di akhir frame)
	nav_agent.target_position = player_node.global_position

	# Guard: sudah sangat dekat → berhenti (jangan pakai is_navigation_finished()
	# karena juga true saat path belum dihitung!)
	if dist_to_player <= ARRIVAL_DIST:
		velocity = Vector2.ZERO
		move_and_slide()
		anim.play("idle")
		return

	_move_along_path()


# ── State: SEARCH ─────────────────────────────────────────────────────
func _state_search(delta: float) -> void:
	var dist_to_player := global_position.distance_to(player_node.global_position)

	# Kembali CHASE jika player terdeteksi lagi
	if dist_to_player <= DETECTION_RANGE:
		_state = State.CHASE
		return

	_search_timer -= delta

	if _search_timer > 0.0:
		nav_agent.target_position = _last_known_pos
		# Di SEARCH boleh pakai is_navigation_finished() — path ke titik statis
		# sudah pasti terhitung setelah nav_ready = true
		if not nav_agent.is_navigation_finished():
			_move_along_path()
		else:
			velocity = Vector2.ZERO
			move_and_slide()
			anim.play("idle")
	else:
		# Habis waktu search → idle di tempat
		velocity = Vector2.ZERO
		move_and_slide()
		anim.play("idle")


# ── Helper: gerak mengikuti waypoint NavMesh ───────────────────────────
func _move_along_path() -> void:
	var next_pos  := nav_agent.get_next_path_position()
	var direction := (next_pos - global_position).normalized()

	# Guard: direction mendekati nol berarti path belum siap (frame pertama)
	# → tunggu frame berikutnya, jangan apply velocity kosong
	if direction.length_squared() < 0.01:
		anim.play("idle")
		return

	velocity = direction * SPEED
	move_and_slide()

	# ── Animasi & arah hadap ──────────────────────────────────────────
	if velocity.length() > 5.0:
		anim.play("walk")
		anim.flip_h = velocity.x < 0
	else:
		anim.play("idle")



# ── Visualisasi Pathfinding UI ───────────────────────────────────────
func _update_path_line() -> void:
	if not path_line:
		return
	if not _nav_ready or not player_node or not is_physics_processing():
		path_line.visible = false
		return

	var current_path := nav_agent.get_current_navigation_path()
	if current_path.size() > 1:
		# Sambungkan titik awal langsung dari posisi goblin saat ini
		current_path[0] = global_position
		path_line.points = current_path
		path_line.visible = true
	else:
		path_line.visible = false

func clear_path_line() -> void:
	if path_line:
		path_line.visible = false
		path_line.clear_points()


# ════════════════════════════════════════════════════════════════════
func _on_hit_area_body_entered(body: Node2D) -> void:
	if body == player_node:
		player_node.take_damage()
