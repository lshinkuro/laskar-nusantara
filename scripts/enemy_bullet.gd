extends Node2D
## Peluru musuh. Disimulasikan di tiap peer dari event host; hanya melukai prajurit lokal.

const TEX := preload("res://assets/sprites/peluru_musuh.png")
const HIT_RADIUS := 9.0

var direction := Vector2.RIGHT
var speed := 130.0
var damage := 2
var lifetime := 4.0
var local_player: Node2D
var map: Node2D


func _draw() -> void:
	draw_line(-direction * 10, Vector2.ZERO, Color(1, 0.3, 0.2, 0.35), 3.0)
	draw_texture_rect(TEX, Rect2(-4, -4, 8, 8), false)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0 or map.blocks(position):
		queue_free()
		return
	if local_player and local_player.alive and position.distance_to(local_player.position) < HIT_RADIUS:
		local_player.take_damage(damage)
		queue_free()
