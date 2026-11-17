extends Node2D
## Ranjau dari Tukang Ranjau. Meledak saat prajurit lokal mendekat (host yang memutuskan).

const TEX := preload("res://assets/sprites/ranjau.png")
const TRIGGER_RADIUS := 20.0

var id := 0
var enemies: Node  # World/Enemies
var _armed := 0.8
var _requested := false
var _t := 0.0


func _draw() -> void:
	draw_texture_rect(TEX, Rect2(-6, -6, 12, 12), false)
	if _armed <= 0 and fmod(_t, 0.8) < 0.2:
		draw_circle(Vector2(0, -4), 1.5, Color(1, 0.2, 0.2))


func _physics_process(delta: float) -> void:
	_t += delta
	_armed -= delta
	queue_redraw()
	var p = enemies.local_player
	if _armed <= 0 and not _requested and p and p.alive and position.distance_to(p.position) < TRIGGER_RADIUS:
		_requested = true
		enemies.request_detonate(id)
