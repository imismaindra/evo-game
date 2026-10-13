## hud.gd — Heads-Up Display (CanvasLayer)
## Menampilkan counter kunci, status portal, dan overlay game state.
extends CanvasLayer

@onready var key_label: Label       = $KeyLabel
@onready var portal_label: Label    = $PortalLabel
@onready var overlay_panel: Panel   = $OverlayPanel
@onready var overlay_label: Label   = $OverlayPanel/OverlayLabel
@onready var restart_hint: Label    = $OverlayPanel/RestartHint

const TOTAL_KEYS := 5

func _ready() -> void:
	overlay_panel.hide()
	update_keys(0)
	update_portal_status(false)

func update_keys(count: int) -> void:
	key_label.text = "KEYS: %d / %d" % [count, TOTAL_KEYS]

func update_portal_status(is_open: bool) -> void:
	if is_open:
		portal_label.text = "PORTAL: [ OPEN ]"
		portal_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
	else:
		portal_label.text = "PORTAL: [ LOCKED ]"
		portal_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))

func show_game_over() -> void:
	overlay_label.text = "SYSTEM BREACH\nGAME OVER"
	overlay_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))
	overlay_panel.show()
	restart_hint.show()

func show_win() -> void:
	overlay_label.text = "EXTRACTION COMPLETE\nYOU WIN"
	overlay_label.add_theme_color_override("font_color", Color(0.0, 1.0, 0.6))
	overlay_panel.show()
	restart_hint.show()
