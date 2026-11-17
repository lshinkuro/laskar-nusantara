extends RefCounted
## Angka damage/heal yang melayang lalu hilang.


static func spawn(parent: Node, pos: Vector2, amount: int, color := Color(1, 0.9, 0.5), prefix := "") -> void:
	var n := Label.new()
	n.text = prefix + str(amount)
	n.theme_type_variation = &"Hud"
	n.add_theme_font_size_override("font_size", 8)
	n.add_theme_color_override("font_color", color)
	n.position = pos - Vector2(10, 6)
	n.size = Vector2(20, 10)
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.z_index = 10
	parent.get_parent().add_child(n)  # ke World, supaya tidak ikut daftar musuh/pemain
	var t := n.create_tween()
	t.set_parallel()
	t.tween_property(n, "position:y", n.position.y - 12, 0.5)
	t.tween_property(n, "modulate:a", 0.0, 0.5).set_delay(0.2)
	t.chain().tween_callback(n.queue_free)
