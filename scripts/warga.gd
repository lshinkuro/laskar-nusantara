extends Node2D
## Warga terkurung. Prajurit lokal yang berdiri di dekatnya membebaskannya (progres lokal,
## host yang memutuskan siapa yang berhasil).

const TEX := preload("res://assets/sprites/warga.png")
const RESCUE_RADIUS := 30.0
const RESCUE_TIME := 1.5
const LIFETIME := 22.0

var id := 0
var villagers: Node  # World/Villagers
var age := 0.0
var _progress := 0.0
var _requested := false


func _draw() -> void:
	var blink := age > LIFETIME - 5.0 and fmod(age, 0.4) < 0.2
	draw_set_transform(Vector2.ZERO)
	draw_circle(Vector2(0, 2), 10, Color(0, 0, 0, 0.25))
	if not blink:
		draw_texture_rect(TEX, Rect2(-12, -26, 24, 24), false)
	# Kurungan bambu
	var bambu := Color(0.72, 0.58, 0.32)
	draw_rect(Rect2(-14, -30, 28, 3), bambu)
	draw_rect(Rect2(-14, -1, 28, 3), bambu)
	for x in range(-13, 15, 6):
		draw_line(Vector2(x, -29), Vector2(x, 1), bambu.darkened(0.2), 2.0)
	# Tanda seru melompat
	var bob := -absf(sin(age * 4.0)) * 4.0
	draw_string(ThemeDB.fallback_font, Vector2(-3, -36 + bob), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1, 0.85, 0.3))
	if _progress > 0:
		draw_arc(Vector2(0, -14), 20, -PI / 2, -PI / 2 + TAU * _progress, 24, Color(1, 0.9, 0.4), 3.0)


func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	var p = villagers.local_player
	if p == null or _requested:
		return
	if p.alive and p.position.distance_to(position) < RESCUE_RADIUS:
		_progress += delta / RESCUE_TIME
		if _progress >= 1.0:
			_requested = true
			villagers.request_rescue(id)
	else:
		_progress = maxf(_progress - delta, 0.0)
