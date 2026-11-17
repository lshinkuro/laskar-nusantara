extends CanvasLayer
## Layar "Ilmu Baru": tiap level yang didapat saat wave, pilih 1 dari 4 upgrade stat.

signal finished

const CHOICES := 4
const UPGRADES := [
	{"title": "Tulang Besi", "desc": "Badan makin kokoh.", "stats": {"max_hp": 3}},
	{"title": "Otot Kawat", "desc": "Pukulan makin keras.", "stats": {"damage": 8}},
	{"title": "Tangan Cekatan", "desc": "Serangan makin cepat.", "stats": {"attack_speed": 8}},
	{"title": "Langkah Kijang", "desc": "Lari makin gesit.", "stats": {"speed": 6}},
	{"title": "Kulit Badak", "desc": "Tahan pukulan.", "stats": {"armor": 1}},
	{"title": "Mata Elang", "desc": "Melihat musuh dari jauh.", "stats": {"range": 10}},
	{"title": "Napas Panjang", "desc": "Luka cepat pulih.", "stats": {"hp_regen": 2}},
	{"title": "Berkah Leluhur", "desc": "Rezeki makin lancar.", "stats": {"luck": 8}},
	{"title": "Tangan Panjang", "desc": "Rempah jauh pun teraih.", "stats": {"pickup_range": 20}},
	{"title": "Hujan Panah", "desc": "Satu tembakan, banyak anak panah.", "stats": {"projectiles": 1, "damage": -4}},
]
const GOLD := Color(0.88, 0.69, 0.29)
const UiAnim := preload("res://scripts/ui_anim.gd")

var player

var _title: Label
var _cards: HBoxContainer


func _ready() -> void:
	_build()
	hide()


func open(p) -> void:
	player = p
	show()
	_show_choices()


func choose(upgrade: Dictionary) -> void:
	player.apply_stats(upgrade.stats)
	player.pending_levels -= 1
	if player.pending_levels > 0:
		_show_choices()
	else:
		hide()
		finished.emit()


func _unhandled_input(event: InputEvent) -> void:
	# Tombol angka 1-4 memilih kartu ilmu.
	if not visible or not (event is InputEventKey and event.pressed and not event.echo):
		return
	var n: int = event.physical_keycode - KEY_1
	if n >= 0 and n < _choices.size():
		get_viewport().set_input_as_handled()
		choose(_choices[n])


var _choices := []


func _show_choices() -> void:
	_title.text = "NAIK LEVEL %d!  Pilih ilmu baru%s" % [
		player.level - player.pending_levels + 1,
		"  (%d tersisa)" % player.pending_levels if player.pending_levels > 1 else ""]
	var options := UPGRADES.duplicate()
	options.shuffle()
	_choices = options.slice(0, CHOICES)
	for c in _cards.get_children():
		_cards.remove_child(c)
		c.queue_free()
	for u in _choices:
		_cards.add_child(_card(u))
	UiAnim.deal(_cards)


func _card(u: Dictionary) -> Control:
	var card := PanelContainer.new()
	card.theme_type_variation = &"Card"
	card.mouse_entered.connect(func(): UiAnim.hover(card, true))
	card.mouse_exited.connect(func(): UiAnim.hover(card, false))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)
	var title := _label(u.title, 9)
	title.modulate = GOLD
	box.add_child(title)
	var desc := _label(u.desc, 7)
	desc.theme_type_variation = &"Muted"
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(desc)
	var parts := PackedStringArray()
	for key in u.stats:
		parts.append("%+d %s" % [u.stats[key], preload("res://scripts/shop.gd").STAT_NAMES[key]])
	var effect := _label(", ".join(parts), 8)
	effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(effect)
	var btn := Button.new()
	btn.text = "[%d] Pilih" % (_cards.get_child_count() + 1)
	btn.add_theme_font_size_override("font_size", 8)
	btn.pressed.connect(choose.bind(u))
	box.add_child(btn)
	return card


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
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 110)
	center.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel.add_child(root)
	_title = _label("", 11)
	_title.theme_type_variation = &"Title"
	_title.add_theme_font_size_override("font_size", 11)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(_title)
	_cards = HBoxContainer.new()
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 6)
	root.add_child(_cards)
