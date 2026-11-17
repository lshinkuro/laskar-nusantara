extends Node2D
## Latar map Sawah: petak-petak padi dipisah pematang, dikelilingi tanah.

@export var arena_size := Vector2(960, 540)

const TANAH := Color(0.42, 0.29, 0.17)
const PEMATANG := Color(0.55, 0.42, 0.25)
const AIR := Color(0.33, 0.5, 0.28)
const PADI := Color(0.5, 0.7, 0.3)
const PADI_GELAP := Color(0.36, 0.55, 0.22)
const PETAK := 120


func _draw() -> void:
	draw_rect(Rect2(Vector2(-200, -200), arena_size + Vector2(400, 400)), TANAH)
	draw_rect(Rect2(Vector2.ZERO, arena_size), PEMATANG)
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	for x in range(0, int(arena_size.x), PETAK):
		for y in range(0, int(arena_size.y), PETAK):
			var petak := Rect2(x + 4, y + 4, PETAK - 8, PETAK - 8).intersection(Rect2(Vector2(4, 4), arena_size - Vector2(8, 8)))
			draw_rect(petak, AIR)
			# Barisan rumpun padi.
			for py in range(int(petak.position.y) + 6, int(petak.end.y) - 4, 10):
				for px in range(int(petak.position.x) + 6, int(petak.end.x) - 4, 9):
					var c := PADI if rng.randf() > 0.3 else PADI_GELAP
					var p := Vector2(px + rng.randi_range(-1, 1), py)
					draw_line(p, p + Vector2(-2, -4), c)
					draw_line(p, p + Vector2(0, -5), c)
					draw_line(p, p + Vector2(2, -4), c)
	draw_rect(Rect2(Vector2.ZERO, arena_size), Color(0.2, 0.12, 0.06), false, 3.0)
