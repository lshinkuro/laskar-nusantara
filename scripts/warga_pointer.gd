extends Control
## Panah di tepi layar yang menunjuk warga terkurung di luar pandangan.

var villagers: Node


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if villagers == null:
		return
	var rect := Rect2(Vector2.ZERO, size).grow(-18)
	var xf := get_viewport().get_canvas_transform()
	for w in villagers.get_children():
		var p: Vector2 = xf * w.global_position
		if rect.grow(10).has_point(p):
			continue
		var center := size / 2
		var dir := (p - center).normalized()
		# Titik di tepi persegi panjang searah warga.
		var t := minf(absf(rect.size.x / 2 / dir.x) if dir.x != 0 else INF, absf(rect.size.y / 2 / dir.y) if dir.y != 0 else INF)
		var at := center + dir * t
		var tip := at + dir * 8
		var side := dir.orthogonal() * 6
		draw_colored_polygon(PackedVector2Array([tip, at - dir * 4 + side, at - dir * 4 - side]), Color(1, 0.85, 0.3))
		draw_string(get_theme_default_font(), at - dir * 14 + Vector2(-3, 4), "!", HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color(1, 0.85, 0.3))
