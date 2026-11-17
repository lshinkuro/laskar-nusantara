extends VBoxContainer
## Dua slider volume terpisah: musik latar & efek suara. Dipakai di menu dan layar jeda.


func _ready() -> void:
	add_theme_constant_override("separation", 4)
	_row("Musik", Sfx.music_volume, Sfx.set_music_volume)
	_row("Efek suara", Sfx.sfx_volume, func(v):
		Sfx.set_sfx_volume(v)
		Sfx.play("pickup", -6.0, 0.0))  # contoh bunyi supaya terasa bedanya


func _row(title: String, value: float, on_change: Callable) -> void:
	var row := HBoxContainer.new()
	add_child(row)
	var l := Label.new()
	l.text = title
	l.custom_minimum_size = Vector2(70, 0)
	row.add_child(l)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 5
	slider.value = value * 100
	slider.custom_minimum_size = Vector2(110, 14)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(slider)
	var pct := Label.new()
	pct.custom_minimum_size = Vector2(30, 0)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.text = "%d%%" % slider.value
	row.add_child(pct)
	slider.value_changed.connect(func(v):
		pct.text = "%d%%" % v
		on_change.call(v / 100.0))
