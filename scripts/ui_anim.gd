extends RefCounted
## Animasi UI bersama (gaya "memantul"): muncul, dibagikan, meluncur, berdenyut.


## Muncul dari kecil & transparan dengan pantulan.
static func pop_in(node: Control, delay := 0.0, from_scale := 0.7) -> void:
	node.pivot_offset = node.size / 2
	node.modulate.a = 0.0
	node.scale = Vector2.ONE * from_scale
	var t := node.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_callback(func(): node.pivot_offset = node.size / 2).set_delay(delay)
	t.tween_property(node, "modulate:a", 1.0, 0.18).set_delay(delay)
	t.tween_property(node, "scale", Vector2.ONE, 0.32).set_delay(delay)


## Anak-anak container muncul satu per satu (kartu dibagikan).
static func deal(container: Control, step := 0.07, spin := true) -> void:
	for i in container.get_child_count():
		var c: Control = container.get_child(i)
		pop_in(c, i * step, 0.6)
		if spin:
			c.rotation = -0.25
			c.create_tween().tween_property(c, "rotation", 0.0, 0.35).set_delay(i * step).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Meluncur masuk dari `offset` (relatif) sambil memudar masuk.
static func slide_in(node: Control, offset: Vector2, delay := 0.0) -> void:
	var target := node.position
	node.position = target + offset
	node.modulate.a = 0.0
	var t := node.create_tween().set_parallel().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "position", target, 0.4).set_delay(delay)
	t.tween_property(node, "modulate:a", 1.0, 0.25).set_delay(delay)


## Denyut singkat (angka berubah, slot terisi).
static func bump(node: Control, amount := 1.3) -> void:
	node.pivot_offset = node.size / 2
	node.scale = Vector2.ONE * amount
	node.create_tween().tween_property(node, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Terangkat & sedikit miring saat disorot (kartu).
static func hover(node: Control, on: bool) -> void:
	node.pivot_offset = node.size / 2
	node.z_index = 1 if on else 0
	var t := node.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(node, "scale", Vector2.ONE * (1.05 if on else 1.0), 0.15)
	t.tween_property(node, "rotation", (0.02 if node.get_index() % 2 else -0.02) if on else 0.0, 0.15)
