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
	"projectiles": "Peluru Ekstra",
	"melee_damage": "Dmg Dekat %",
	"ranged_damage": "Dmg Jauh %",
	"magic_damage": "Dmg Magis %",
	"dodge": "Menghindar %",
	"harvest": "Panen %",
}
const GOLD := Color(0.88, 0.69, 0.29)
const REMPAH_ICON := preload("res://assets/sprites/rempah.svg")
const Synergy := preload("res://scripts/synergy.gd")
const RARITY_NAMES := ["Biasa", "Langka", "Epik", "Legendaris"]
const RARITY_COLORS := [Color(0.75, 0.7, 0.62), Color(0.4, 0.65, 1.0), Color(0.75, 0.45, 1.0), Color(1.0, 0.6, 0.2)]
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
var _stats: RichTextLabel
var _weapons: HBoxContainer
var _items: HFlowContainer
var _bag_detail: RichTextLabel
var _combine_btn: Button
var _sell_btn: Button
var _weapon_count: Label
var _item_count: Label
## Slot tas yang dipilih: {"weapon": Node} atau {"item": index}.
var _sel := {}
var _swatches := {}
var _shown_rempah := 0
var _frame: Control
var _rempah_tween: Tween
var _synergies: Label
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
	_sel = {}
	_roll()
	_ready_btn.disabled = false
	_ready_btn.text = "Siap Berperang! [Enter]"
	_shown_rempah = player.rempah
	_refresh()
	show()
	# Pasar "naik" dari bawah, lalu kartu dibagikan.
	# Geser layernya, bukan panelnya: mengubah position Control berjangkar ikut membekukan ukurannya.
	offset.y = 40
	_frame.modulate.a = 0.0
	var t := create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(self, "offset:y", 0.0, 0.35)
	t.tween_property(_frame, "modulate:a", 1.0, 0.2)
	_deal_cards()


func set_ready_count(n: int, total: int) -> void:
	_ready_label.text = "" if total <= 1 else "Pejuang siap: %d/%d" % [n, total]


func price_of(data: Resource) -> int:
	return roundi(data.price * (1.0 + 0.12 * (wave - 1)))


func _roll() -> void:
	var kept := _offers.filter(func(o): return o.locked and not o.sold)
	_offers.clear()
	_offers.append_array(kept)
	var choices := _pool.filter(func(d): return not _offers.any(func(o): return o.data == d))
	while _offers.size() < OFFER_COUNT and not choices.is_empty():
		var pick := _weighted_pick(choices)
		choices.erase(pick)
		_offers.append({"data": pick, "locked": false, "sold": false})


## Barang langka makin sering muncul di wave akhir dan dengan Hoki tinggi.
func _rarity_weight(rarity: int) -> float:
	var luck: float = player.stats.luck if player else 0.0
	match rarity:
		1: return 25.0 + wave * 3.0 + luck
		2: return 6.0 + wave * 2.0 + luck * 0.5
		3: return 1.0 + wave * 0.8 + luck * 0.25
	return 100.0


func _weighted_pick(choices: Array) -> Resource:
	var total := 0.0
	for d in choices:
		total += _rarity_weight(d.rarity)
	var r := randf() * total
	for d in choices:
		r -= _rarity_weight(d.rarity)
		if r <= 0:
			return d
	return choices.back()


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
	Sfx.play("buy", -4.0, 0.0)
	var card: Control = _cards.get_child(i)
	_fly_to_bag(_icon_of(o.data), card.global_position + Vector2(8, 8), o.data is WeaponData)
	_refresh()


func _toggle_lock(i: int) -> void:
	_offers[i].locked = not _offers[i].locked
	_refresh()


func _on_reroll() -> void:
	if player.spend(_reroll_cost):
		_reroll_cost += 1
		_roll()
		_refresh()
		_deal_cards()


func _unhandled_input(event: InputEvent) -> void:
	# Enter = Siap Berperang, supaya tetap bisa lanjut walau tombolnya tak terlihat.
	if visible and not _ready_btn.disabled and event is InputEventKey and event.pressed and not event.echo \
			and event.keycode in [KEY_ENTER, KEY_KP_ENTER]:
		get_viewport().set_input_as_handled()
		_on_ready()


func _on_ready() -> void:
	_ready_btn.disabled = true
	_ready_btn.text = "Menunggu teman..."
	ready_pressed.emit()


# --- Tampilan -----------------------------------------------------------------

func _refresh() -> void:
	_set_rempah_label(player.rempah)
	_reroll.text = "Kocok ulang (%d)" % _reroll_cost
	_reroll.disabled = player.rempah < _reroll_cost

	for c in _cards.get_children():
		_cards.remove_child(c)
		c.queue_free()
	for i in _offers.size():
		_cards.add_child(_card(i))

	_show_stats({})

	_refresh_bag()
	var syn_lines := PackedStringArray()
	for sdef in Synergy.LIST:
		var n := Synergy.progress(sdef, player)
		if n > 0:
			syn_lines.append("%s %s %d/%d" % ["+" if n >= sdef.need else "-", sdef.name, mini(n, sdef.need), sdef.need])
	_synergies.text = "-" if syn_lines.is_empty() else "\n".join(syn_lines)
	_synergies.tooltip_text = "\n".join(Synergy.LIST.map(func(x): return "%s (%s): %s" % [x.name, x.desc, _effects_dict(x.stats)]))


# --- Tas Pusaka ------------------------------------------------------------------

func _refresh_bag() -> void:
	for c in _weapons.get_children() + _items.get_children():
		c.get_parent().remove_child(c)
		c.queue_free()
	if _sel.has("weapon") and not is_instance_valid(_sel.weapon):
		_sel = {}
	if _sel.has("item") and _sel.item >= player.items.size():
		_sel = {}
	var weapon_nodes: Array = player.weapon_ring.get_children()
	_weapon_count.text = "Senjata %d/%d" % [weapon_nodes.size(), player.MAX_WEAPONS]
	for w in weapon_nodes:
		var b := _slot_button(w.data.texture, "" if w.tier == 1 else str(w.tier), w.TIER_COLORS[w.tier - 1])
		b.tooltip_text = "%s (Tier %d)\nDamage %d x %d peluru\n%.1f serangan/dtk, jarak %d%s" % [w.data.title, w.tier,
			w.shot_damage(), w.shot_count(), 1.0 / w.shot_interval(), w.shot_range(),
			"\nEfek: " + _effect_name(w.data) if _effect_name(w.data) != "" else ""]
		b.modulate = Color(1.3, 1.2, 0.6) if _sel.get("weapon") == w else Color.WHITE
		b.pressed.connect(func(): _sel = {"weapon": w}; _refresh_bag())
		_weapons.add_child(b)
	_item_count.text = "Item %d" % player.items.size()
	for i in player.items.size():
		var it: ItemData = player.items[i]
		var lv: int = player.item_levels[i]
		var b := _slot_button(_icon_of(it), "" if lv == 1 else str(lv), RARITY_COLORS[it.rarity])
		b.tooltip_text = "%s (Lv%d)\n%s" % [it.title, lv, _item_effect(i, false).replace(", ", "\n")]
		b.modulate = Color(1.3, 1.2, 0.6) if _sel.get("item", -1) == i else Color.WHITE
		b.pressed.connect(func(): _sel = {"item": i}; _refresh_bag())
		_items.add_child(b)

	_combine_btn.disabled = true
	_sell_btn.disabled = true
	if _sel.has("weapon"):
		var w = _sel.weapon
		var partner = player.weapon_combine_partner(w)
		_bag_detail.text = "[color=#e0b04a]%s[/color] Tier %d  -  %s" % [w.data.title, w.tier,
			"bisa digabung jadi Tier %d!" % (w.tier + 1) if partner else "gabung butuh 1 lagi yang setier"]
		_combine_btn.disabled = partner == null
		_sell_btn.disabled = weapon_nodes.size() <= 1
		_sell_btn.text = "Lepas +%d" % player.weapon_sell_value(w)
	elif _sel.has("item"):
		var i: int = _sel.item
		var it: ItemData = player.items[i]
		var lv: int = player.item_levels[i]
		var effect := _item_effect(i, true)
		var hint := "bisa digabung jadi Lv%d!" % (lv + 1) if player.item_combine_partner(i) >= 0 \
			else ("level maks" if lv >= player.MAX_ITEM_LEVEL else "gabung butuh 1 lagi yang selevel")
		_bag_detail.text = "[color=#e0b04a]%s[/color] Lv%d: %s  -  %s" % [it.title, lv, effect, hint]
		_combine_btn.disabled = player.item_combine_partner(i) < 0
		_sell_btn.disabled = false
		_sell_btn.text = "Lepas +%d" % player.item_sell_value(i)
	else:
		_bag_detail.text = "[color=#b8a080]Klik isi tas: gabung 2 yang sama, atau lepas jadi rempah.[/color]"
		_sell_btn.text = "Lepas"


func _on_combine() -> void:
	var ok := false
	if _sel.has("weapon"):
		ok = player.combine_weapon(_sel.weapon)
	elif _sel.has("item"):
		var it: ItemData = player.items[_sel.item]
		var lv: int = player.item_levels[_sel.item] + 1
		ok = player.combine_item(_sel.item)
		_sel = {"item": player.items.size() - 1} if ok and player.items.back() == it and player.item_levels.back() == lv else {}
	if ok:
		Sfx.play("levelup", -4.0, 0.0)
		_refresh()


func _on_sell() -> void:
	var value := 0
	if _sel.has("weapon"):
		value = player.sell_weapon(_sel.weapon)
	elif _sel.has("item"):
		value = player.remove_item(_sel.item)
	if value > 0:
		player.rempah += value
		player.rempah_changed.emit(player.rempah)
		Sfx.play("buy", -4.0, 0.0)
	_sel = {}
	_refresh()


func _slot_button(icon: Texture2D, badge: String, border: Color) -> Button:
	var b := Button.new()
	b.icon = icon
	b.text = badge
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(20, 20)
	b.add_theme_font_size_override("font_size", 7)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(border, 0.25)
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(2)
	style.set_content_margin_all(2)
	for st in ["normal", "hover", "pressed"]:
		b.add_theme_stylebox_override(st, style)
	return b


## Ikon kotak warna untuk item (di-cache per warna).
func _swatch(color: Color) -> Texture2D:
	if not _swatches.has(color):
		var img := Image.create(10, 10, false, Image.FORMAT_RGBA8)
		img.fill(Color(0.1, 0.07, 0.04))
		img.fill_rect(Rect2i(1, 1, 8, 8), color)
		_swatches[color] = ImageTexture.create_from_image(img)
	return _swatches[color]


func _card(i: int) -> Control:
	var o := _offers[i]
	var data: Resource = o.data
	var is_weapon := data is WeaponData
	var price := price_of(data)
	var rc: Color = RARITY_COLORS[data.rarity]

	# Kartu ala Brotato: latar diwarnai kelangkaan, ikon besar, satu stat per baris.
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = rc.darkened(0.8) if data.rarity > 0 else Color(0.13, 0.105, 0.09)
	style.bg_color.a = 0.97
	style.border_color = Color(0.95, 0.85, 0.4) if o.locked else (rc if data.rarity > 0 else Color(0.3, 0.24, 0.17))
	style.set_border_width_all(3 if o.locked else 2)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(6)
	card.add_theme_stylebox_override("panel", style)
	card.custom_minimum_size = Vector2(92, 0)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.modulate = Color(1, 1, 1, 0.45) if o.sold else Color.WHITE
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	card.add_child(box)

	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 5)
	box.add_child(head)
	head.add_child(_icon_slot(_icon_of(data), rc, 26))
	var names := VBoxContainer.new()
	names.add_theme_constant_override("separation", 0)
	names.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(names)
	var title := _label(data.title, 9)
	title.add_theme_color_override("font_color", rc.lightened(0.25) if data.rarity > 0 else Color(0.97, 0.93, 0.84))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size.x = 50  # tanpa lebar minimum, label ber-wrap menghitung tinggi seolah lebar 0
	names.add_child(title)
	var kind_text: String = ("Senjata " + {"melee": "dekat", "ranged": "jauh", "magic": "magis"}[data.category]) if is_weapon else "Item"
	if not is_weapon and not data.tags.is_empty():
		kind_text += " - " + ", ".join(data.tags).capitalize()
	var kind := _label(kind_text, 7)
	kind.clip_text = true
	kind.custom_minimum_size.x = 50
	kind.tooltip_text = kind_text
	kind.add_theme_color_override("font_color", Color(0.7, 0.62, 0.52))
	names.add_child(kind)

	var merge = player.mergeable_weapon(data) if is_weapon and player.weapons.size() >= player.MAX_WEAPONS else null
	var desc := RichTextLabel.new()
	desc.bbcode_enabled = true
	desc.fit_content = true
	desc.scroll_active = false
	desc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	desc.add_theme_font_size_override("normal_font_size", 8)
	desc.custom_minimum_size.x = 78
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var lines := _effect_lines(data)
	if merge:
		lines.append("[color=#f0d860]Gabung -> Tier %d[/color]" % (merge.tier + 1))
	lines.append("[color=#a89880][font_size=7]%s[/font_size][/color]" % data.description)
	desc.text = "\n".join(lines)
	box.add_child(desc)
	if not is_weapon:
		card.mouse_entered.connect(func(): _show_stats(data.stats))
		card.mouse_exited.connect(func(): _show_stats({}))
	card.mouse_entered.connect(_hover.bind(card, true))
	card.mouse_exited.connect(_hover.bind(card, false))

	var buy := Button.new()
	buy.icon = REMPAH_ICON
	buy.add_theme_font_size_override("font_size", 9)
	buy.custom_minimum_size = Vector2(0, 18)
	if o.sold:
		buy.icon = null
		buy.text = "Terjual"
		buy.disabled = true
	elif is_weapon and not player.can_take_weapon(data):
		buy.icon = null
		buy.text = "Slot penuh"
		buy.disabled = true
	else:
		buy.text = " %d" % price
		if player.rempah < price:
			buy.disabled = true
			buy.tooltip_text = "Kurang %d rempah" % (price - player.rempah)
	buy.pressed.connect(_buy.bind(i))
	box.add_child(buy)

	var lock := Button.new()
	lock.text = "Terkunci" if o.locked else "Kunci"
	lock.disabled = o.sold
	lock.add_theme_font_size_override("font_size", 7)
	lock.tooltip_text = "Kartu terkunci tidak ikut dikocok & tetap ada di wave berikutnya."
	lock.pressed.connect(_toggle_lock.bind(i))
	box.add_child(lock)
	return card


## Satu baris per efek, angka berwarna (hijau naik, merah turun) seperti Brotato.
func _effect_lines(data: Resource) -> PackedStringArray:
	var lines := PackedStringArray()
	if data is WeaponData:
		lines.append("Damage [color=#f0d860]%d[/color]" % data.damage)
		lines.append("Serang [color=#f0d860]%.1f[/color]/dtk" % (1.0 / data.fire_interval))
		lines.append("Jarak [color=#f0d860]%d[/color]" % data.attack_range)
		if data.projectile_count > 1:
			lines.append("Peluru [color=#f0d860]x%d[/color]" % data.projectile_count)
		if data.pierce > 0 and data.effect != "bounce":
			lines.append("Tembus [color=#f0d860]%d[/color]" % data.pierce)
		var effect_text := _effect_name(data)
		if effect_text != "":
			lines.append("[color=#ffb070]%s[/color]" % effect_text)
		return lines
	for key in data.stats:
		var v: int = data.stats[key]
		lines.append("[color=%s]%+d[/color] %s" % ["#7fe07f" if v > 0 else "#ff7a6a", v, STAT_NAMES.get(key, key)])
	return lines


func _icon_of(data: Resource) -> Texture2D:
	if data is WeaponData:
		return data.texture
	return data.icon if data.icon else _swatch(data.color)


## Slot ikon membulat berwarna kelangkaan, ikon diperbesar tajam (pixel art).
func _icon_slot(tex: Texture2D, rc: Color, px: int) -> Control:
	var slot := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = rc.darkened(0.55)
	st.border_color = rc
	st.set_border_width_all(2)
	st.set_corner_radius_all(6)
	st.set_content_margin_all(2)
	slot.add_theme_stylebox_override("panel", st)
	var icon := TextureRect.new()
	icon.texture = tex
	icon.custom_minimum_size = Vector2(px - 6, px - 6)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icon)
	slot.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	return slot


## Kartu terangkat & sedikit miring saat disorot.
func _hover(card: Control, on: bool) -> void:
	card.pivot_offset = card.size / 2
	card.z_index = 1 if on else 0
	var t := card.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(card, "scale", Vector2.ONE * (1.04 if on else 1.0), 0.15)
	t.tween_property(card, "rotation", (-0.02 if card.get_index() % 2 else 0.02) if on else 0.0, 0.15)


## Kartu "dibagikan": muncul satu per satu sambil berputar & memantul.
func _deal_cards() -> void:
	for i in _cards.get_child_count():
		var c: Control = _cards.get_child(i)
		c.modulate.a = 0.0
		c.scale = Vector2(0.6, 0.6)
		c.rotation = -0.3
		var t := c.create_tween().set_parallel().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_callback(func(): c.pivot_offset = c.size / 2).set_delay(0.0)
		t.tween_property(c, "modulate:a", 1.0, 0.2).set_delay(0.07 * i)
		t.tween_property(c, "scale", Vector2.ONE, 0.35).set_delay(0.07 * i)
		t.tween_property(c, "rotation", 0.0, 0.35).set_delay(0.07 * i)


## Ikon barang yang dibeli terbang ke tas.
func _fly_to_bag(tex: Texture2D, from: Vector2, is_weapon: bool) -> void:
	var target_box: Control = _weapons if is_weapon else _items
	var fly := TextureRect.new()
	fly.texture = tex
	fly.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fly.size = Vector2(26, 26)
	fly.position = from
	fly.z_index = 10
	add_child(fly)
	var to := target_box.global_position + Vector2(target_box.size.x, 4)
	var t := fly.create_tween().set_parallel()
	t.tween_property(fly, "position", to, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(fly, "size", Vector2(14, 14), 0.4)
	t.chain().tween_callback(func():
		fly.queue_free()
		if target_box.get_child_count() > 0:
			var last: Control = target_box.get_child(target_box.get_child_count() - 1)
			last.pivot_offset = last.size / 2
			last.scale = Vector2(1.6, 1.6)
			last.create_tween().tween_property(last, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT))


## Angka rempah berubah bertahap (hitung naik/turun).
func _set_rempah_label(value: int) -> void:
	var from: int = _shown_rempah
	_shown_rempah = value
	if _rempah_tween and _rempah_tween.is_valid():
		_rempah_tween.kill()
	_rempah_tween = create_tween()
	_rempah_tween.tween_method(func(v: float): _rempah.text = "%d" % roundi(v), float(from), float(value), 0.35)
	_rempah.pivot_offset = _rempah.size / 2
	_rempah.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(_rempah, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)


## Tampilkan stat prajurit; `preview` = perubahan dari kartu yang sedang disorot
## (ditulis "lama>baru", hijau kalau naik, merah kalau turun).
func _show_stats(preview: Dictionary) -> void:
	var shown := PackedStringArray()
	for key in STAT_NAMES:
		# Stat inti selalu tampil; sisanya hanya kalau ada bonus/perubahan. Dua stat per baris.
		var now: int = player.stats[key]
		if not (key in ["max_hp", "armor", "damage", "attack_speed", "speed"] or now != 0 or preview.has(key)):
			continue
		var name: String = STAT_NAMES[key].replace(" %", "%")
		if preview.has(key):
			var after: int = now + preview[key]
			shown.append("[color=%s]%s %d>%d[/color]" % ["#7fe07f" if after > now else "#ff7a6a", name, now, after])
		else:
			shown.append("%s [color=#f0d860]%d[/color]" % [name, now])
	var lines := PackedStringArray()
	for i in range(0, shown.size(), 2):
		lines.append("  ".join(shown.slice(i, i + 2)))
	_stats.text = "\n".join(lines)


## Efek item di tas sesuai levelnya (stat dikali ITEM_MULT; efek khusus ditulis dari deskripsinya).
func _item_effect(i: int, colored: bool) -> String:
	var it: ItemData = player.items[i]
	var m: float = player.ITEM_MULT[player.item_levels[i] - 1]
	var scaled := {}
	for k in it.stats:
		scaled[k] = roundi(it.stats[k] * m)
	var effect := _effects_dict(scaled, colored)
	if it.special != "":
		var special: String = SPECIAL_TEXT[it.special] % roundi(it.special_value * m) if SPECIAL_TEXT.has(it.special) else it.description
		effect += (", " if effect != "" else "") + ("[color=#7fe07f]%s[/color]" % special if colored else special)
	return effect


## Efek khusus item dengan angka yang sudah dikali level (sisanya memakai deskripsi item).
const SPECIAL_TEXT := {
	"pulse": "Gelombang %d damage tiap 6 dtk",
	"thorns": "Balas %d damage saat terluka",
	"lifesteal": "%d%% peluang pulih 1 HP saat kena",
	"burn_chance": "%d%% peluang membakar",
	"wayang": "%d sekutu wayang",
	"turret": "%d Meriam Jaga tiap wave",
}


func _effect_name(data: WeaponData) -> String:
	return {"burn": "Membakar", "poison": "Meracun", "bleed": "Berdarah", "slow": "Memperlambat",
		"knockback": "Mendorong", "explode": "Meledak", "bounce": "Memantul %dx" % data.pierce}.get(data.effect, "")


func _effects(data: Resource) -> String:
	if data is WeaponData:
		var kind_name: String = {"melee": "Dekat", "ranged": "Jauh", "magic": "Magis"}[data.category]
		var s := "%s  |  Dmg %d  |  %.1f/dtk  |  Jarak %d" % [kind_name, data.damage, 1.0 / data.fire_interval, data.attack_range]
		if data.projectile_count > 1:
			s += "  |  x%d" % data.projectile_count
		if data.pierce > 0 and data.effect != "bounce":
			s += "  |  Tembus %d" % data.pierce
		var effect_text := _effect_name(data)
		if effect_text != "":
			s += "\nEfek: " + effect_text
		return s
	return _effects_dict(data.stats, true)


func _effects_dict(stats: Dictionary, colored := false) -> String:
	var parts := PackedStringArray()
	for key in stats:
		var t := "%+d %s" % [stats[key], STAT_NAMES.get(key, key)]
		if colored:
			t = "[color=%s]%s[/color]" % ["#7fe07f" if stats[key] > 0 else "#ff7a6a", t]
		parts.append(t)
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
	_frame = margin
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 48 if side in ["left", "right"] else 12)
	add_child(margin)

	var panel := PanelContainer.new()
	margin.add_child(panel)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 6)
	panel.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_title = _label("", 11)
	_title.theme_type_variation = &"Title"
	_title.add_theme_font_size_override("font_size", 11)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var rempah_icon := TextureRect.new()
	rempah_icon.texture = preload("res://assets/sprites/rempah.svg")
	rempah_icon.custom_minimum_size = Vector2(12, 12)
	rempah_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rempah_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(rempah_icon)
	_rempah = _label("", 12)
	_rempah.add_theme_color_override("font_color", Color(0.98, 0.8, 0.35))
	header.add_child(_rempah)

	# Isi tengah bisa digulir: kartu/tas yang tinggi tidak boleh mendorong tombol Siap keluar layar.
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 8)
	scroll.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(left)
	# Kartu digulir ke samping kalau terlalu lebar, supaya panel Prajurit di kanan tidak terdorong.
	var cards_scroll := ScrollContainer.new()
	cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left.add_child(cards_scroll)
	_cards = HBoxContainer.new()
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_cards.add_theme_constant_override("separation", 5)
	cards_scroll.add_child(_cards)
	var bag := PanelContainer.new()
	bag.theme_type_variation = &"Card"
	left.add_child(bag)
	var bag_box := VBoxContainer.new()
	bag_box.add_theme_constant_override("separation", 3)
	bag.add_child(bag_box)
	var slots_row := HBoxContainer.new()
	slots_row.add_theme_constant_override("separation", 3)
	bag_box.add_child(slots_row)
	var bag_title := _label("TAS PUSAKA", 8)
	bag_title.modulate = GOLD
	slots_row.add_child(bag_title)
	_weapon_count = _label("", 8)
	slots_row.add_child(_weapon_count)
	_weapons = HBoxContainer.new()
	_weapons.add_theme_constant_override("separation", 2)
	slots_row.add_child(_weapons)
	# Item tak terbatas: baris sendiri yang membungkus, supaya panel tidak melebar melewati layar.
	var items_row := HBoxContainer.new()
	items_row.add_theme_constant_override("separation", 3)
	bag_box.add_child(items_row)
	_item_count = _label("", 8)
	items_row.add_child(_item_count)
	_items = HFlowContainer.new()
	_items.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items.add_theme_constant_override("h_separation", 2)
	_items.add_theme_constant_override("v_separation", 2)
	items_row.add_child(_items)
	var action_row := HBoxContainer.new()
	bag_box.add_child(action_row)
	_bag_detail = RichTextLabel.new()
	_bag_detail.bbcode_enabled = true
	_bag_detail.fit_content = true
	_bag_detail.scroll_active = false
	_bag_detail.add_theme_font_size_override("normal_font_size", 8)
	_bag_detail.custom_minimum_size.x = 170
	_bag_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_row.add_child(_bag_detail)
	_combine_btn = Button.new()
	_combine_btn.text = "Gabung"
	_combine_btn.add_theme_font_size_override("font_size", 8)
	_combine_btn.pressed.connect(_on_combine)
	action_row.add_child(_combine_btn)
	_sell_btn = Button.new()
	_sell_btn.add_theme_font_size_override("font_size", 8)
	_sell_btn.pressed.connect(_on_sell)
	action_row.add_child(_sell_btn)
	_reroll = Button.new()
	_reroll.pressed.connect(_on_reroll)

	var right := PanelContainer.new()
	right.theme_type_variation = &"Card"
	right.custom_minimum_size = Vector2(120, 0)
	body.add_child(right)
	var info := VBoxContainer.new()
	right.add_child(info)
	var stat_title := _label("Prajurit", 10)
	stat_title.modulate = GOLD
	info.add_child(stat_title)
	_stats = RichTextLabel.new()
	_stats.bbcode_enabled = true
	_stats.fit_content = true
	_stats.scroll_active = false
	_stats.add_theme_font_size_override("normal_font_size", 7)
	_stats.custom_minimum_size.x = 108
	info.add_child(_stats)
	var syn_title := _label("Sinergi", 10)
	syn_title.modulate = GOLD
	syn_title.tooltip_text = "Kumpulkan senjata satu jenis atau item satu label untuk bonus."
	syn_title.mouse_filter = Control.MOUSE_FILTER_STOP
	info.add_child(syn_title)
	_synergies = _label("", 8)
	_synergies.mouse_filter = Control.MOUSE_FILTER_STOP
	info.add_child(_synergies)

	var footer := HBoxContainer.new()
	root.add_child(footer)
	footer.add_child(_reroll)
	_ready_label = _label("", 10)
	_ready_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ready_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(_ready_label)
	_ready_btn = Button.new()
	_ready_btn.add_theme_font_size_override("font_size", 9)
	_ready_btn.pressed.connect(_on_ready)
	footer.add_child(_ready_btn)
