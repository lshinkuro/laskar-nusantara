extends CanvasLayer
## Pasar Rakyat: toko antar-wave. Tiap pemain belanja sendiri dengan rempahnya,
## lalu menekan "Siap"; wave berikut mulai setelah semua siap.

signal ready_pressed

const OFFER_COUNT := 4
const ITEM_DIR := "res://data/items/"
const WEAPON_DIR := "res://data/weapons/"
const STAT_NAMES := {
	"max_hp": "HP Maks",
	"hp_regen": "Regen HP",
	"armor": "Armor",
	"speed": "Kecepatan %",
	"damage": "Damage %",
	"attack_speed": "Kec. Serang %",
	"range": "Jangkauan %",
	"luck": "Hoki %",
	"pickup_range": "Jarak Ambil",
}
const GOLD := Color(0.88, 0.69, 0.29)
const WEAPON_COLOR := Color(0.95, 0.6, 0.45)

var player
var wave := 0

var _pool: Array[Resource] = []
var _offers: Array[Dictionary] = []  # {data, locked, sold}
var _reroll_cost := 1

var _title: Label
var _rempah: Label
var _cards: HBoxContainer
var _reroll: Button
var _stats: Label
var _weapons: HBoxContainer
var _items: Label
var _ready_label: Label
var _ready_btn: Button


func _ready() -> void:
	for dir in [ITEM_DIR, WEAPON_DIR]:
		for file in ResourceLoader.list_directory(dir):
			if file.ends_with(".tres"):
				_pool.append(load(dir + file))
	_build()
	hide()


func open(p, finished_wave: int) -> void:
	player = p
	wave = finished_wave
	_reroll_cost = 1 + wave / 2
	_title.text = "PASAR RAKYAT  -  Wave %d selesai" % wave
	_roll()
	_ready_btn.disabled = false
	_ready_btn.text = "Siap Berperang!"
	_refresh()
	show()


func set_ready_count(n: int, total: int) -> void:
	_ready_label.text = "" if total <= 1 else "Pejuang siap: %d/%d" % [n, total]


func price_of(data: Resource) -> int:
	return roundi(data.price * (1.0 + 0.12 * (wave - 1)))


func _roll() -> void:
	var kept := _offers.filter(func(o): return o.locked and not o.sold)
	_offers.clear()
	_offers.append_array(kept)
	var choices := _pool.filter(func(d): return not _offers.any(func(o): return o.data == d))
	choices.shuffle()
	while _offers.size() < OFFER_COUNT and not choices.is_empty():
		_offers.append({"data": choices.pop_back(), "locked": false, "sold": false})


func _buy(i: int) -> void:
	var o := _offers[i]
	if o.sold or not player.spend(price_of(o.data)):
		return
	if o.data is WeaponData:
		player.add_weapon(o.data)
	else:
		player.apply_item(o.data)
	o.sold = true
	o.locked = false
	_refresh()


func _toggle_lock(i: int) -> void:
	_offers[i].locked = not _offers[i].locked
	_refresh()


func _on_reroll() -> void:
	if player.spend(_reroll_cost):
		_reroll_cost += 1
		_roll()
		_refresh()


func _on_ready() -> void:
	_ready_btn.disabled = true
	_ready_btn.text = "Menunggu teman..."
	ready_pressed.emit()


# --- Tampilan -----------------------------------------------------------------

func _refresh() -> void:
	_rempah.text = "Rempah: %d" % player.rempah
	_reroll.text = "Kocok ulang (%d)" % _reroll_cost
	_reroll.disabled = player.rempah < _reroll_cost

	for c in _cards.get_children():
		c.queue_free()
	for i in _offers.size():
		_cards.add_child(_card(i))

	var lines := PackedStringArray()
	for key in STAT_NAMES:
		lines.append("%s: %d" % [STAT_NAMES[key], player.stats[key]])
	_stats.text = "\n".join(lines)

	for c in _weapons.get_children():
		c.queue_free()
	for w: WeaponData in player.weapons:
		var icon := TextureRect.new()
		icon.texture = w.texture
		icon.tooltip_text = w.title
		icon.custom_minimum_size = Vector2(14, 14)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		_weapons.add_child(icon)
	var names: Array = player.items.map(func(it): return it.title)
	_items.text = "-" if names.is_empty() else ", ".join(names)


func _card(i: int) -> Control:
	var o := _offers[i]
	var data: Resource = o.data
	var is_weapon := data is WeaponData
	var price := price_of(data)

	var card := PanelContainer.new()
	card.theme_type_variation = &"CardLocked" if o.locked else &"Card"
	card.custom_minimum_size = Vector2(104, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	card.add_child(box)

	var head := HBoxContainer.new()
	box.add_child(head)
	if is_weapon:
		var icon := TextureRect.new()
		icon.texture = data.texture
		icon.custom_minimum_size = Vector2(12, 12)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		head.add_child(icon)
	else:
		var swatch := ColorRect.new()
		swatch.color = data.color
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(swatch)
	var title := _label(data.title, 10)
	title.modulate = WEAPON_COLOR if is_weapon else GOLD
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)

	var kind := _label("Senjata" if is_weapon else "Item", 8)
	kind.theme_type_variation = &"Muted"
	box.add_child(kind)

	var desc := _label(data.description + "\n" + _effects(data), 8)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(desc)

	var buy := Button.new()
	if o.sold:
		buy.text = "Terjual"
		buy.disabled = true
	elif is_weapon and player.weapons.size() >= player.MAX_WEAPONS:
		buy.text = "Slot penuh"
		buy.disabled = true
	else:
		buy.text = "Beli  %d" % price
		buy.disabled = player.rempah < price
	buy.pressed.connect(_buy.bind(i))
	box.add_child(buy)

	var lock := Button.new()
	lock.text = "Terkunci" if o.locked else "Kunci"
	lock.disabled = o.sold
	lock.add_theme_font_size_override("font_size", 8)
	lock.pressed.connect(_toggle_lock.bind(i))
	box.add_child(lock)
	return card


func _effects(data: Resource) -> String:
	if data is WeaponData:
		var s := "Dmg %d  |  %.1f/dtk  |  Jarak %d" % [data.damage, 1.0 / data.fire_interval, data.attack_range]
		if data.projectile_count > 1:
			s += "  |  x%d" % data.projectile_count
		if data.pierce > 0:
			s += "  |  Tembus %d" % data.pierce
		return s
	var parts := PackedStringArray()
	for key in data.stats:
		parts.append("%+d %s" % [data.stats[key], STAT_NAMES.get(key, key)])
	return ", ".join(parts)


func _label(text: String, font_size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", font_size)
	return l


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	add_child(margin)

	var panel := PanelContainer.new()
	margin.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_title = _label("", 14)
	_title.theme_type_variation = &"Title"
	_title.add_theme_font_size_override("font_size", 14)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var rempah_icon := TextureRect.new()
	rempah_icon.texture = preload("res://assets/sprites/rempah.png")
	rempah_icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	header.add_child(rempah_icon)
	_rempah = _label("", 12)
	_rempah.modulate = GOLD
	header.add_child(_rempah)

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	root.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	_cards = HBoxContainer.new()
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 5)
	left.add_child(_cards)
	_reroll = Button.new()
	_reroll.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_reroll.pressed.connect(_on_reroll)
	left.add_child(_reroll)

	var right := PanelContainer.new()
	right.theme_type_variation = &"Card"
	right.custom_minimum_size = Vector2(130, 0)
	body.add_child(right)
	var info := VBoxContainer.new()
	right.add_child(info)
	var stat_title := _label("Prajurit", 10)
	stat_title.modulate = GOLD
	info.add_child(stat_title)
	_stats = _label("", 8)
	info.add_child(_stats)
	var weapon_title := _label("Senjata", 10)
	weapon_title.modulate = GOLD
	info.add_child(weapon_title)
	_weapons = HBoxContainer.new()
	info.add_child(_weapons)
	var item_title := _label("Item", 10)
	item_title.modulate = GOLD
	info.add_child(item_title)
	_items = _label("", 8)
	_items.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_items.custom_minimum_size = Vector2(118, 0)
	info.add_child(_items)

	var footer := HBoxContainer.new()
	root.add_child(footer)
	_ready_label = _label("", 10)
	_ready_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	footer.add_child(_ready_label)
	_ready_btn = Button.new()
	_ready_btn.add_theme_font_size_override("font_size", 12)
	_ready_btn.pressed.connect(_on_ready)
	footer.add_child(_ready_btn)
