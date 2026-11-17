extends Node2D
## Hantaman boss: lingkaran merah mengisi selama `delay`, lalu meledak.

const Fx := preload("res://scripts/fx.gd")

var radius := 60.0
var delay := 1.0
var damage := 4
var local_player: Node2D
var _t := 0.0


func _draw() -> void:
	var k := clampf(_t / delay, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(0.9, 0.1, 0.1, 0.15))
	draw_circle(Vector2.ZERO, radius * k, Color(0.9, 0.15, 0.1, 0.3))
	draw_arc(Vector2.ZERO, radius, 0, TAU, 40, Color(1, 0.25, 0.2, 0.9), 2.0)


func _physics_process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t < delay:
		return
	Fx.explosion(get_parent(), position, radius * 0.5)
	Sfx.play("enemy_die", 0.0, 0.0)
	if local_player and local_player.alive:
		var d := position.distance_to(local_player.position)
		if d < radius:
			local_player.take_damage(damage)
		if d < radius * 3:
			local_player.shake(6.0)
	queue_free()
