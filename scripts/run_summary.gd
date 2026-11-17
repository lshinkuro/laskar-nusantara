extends RefCounted
## Statistik satu run untuk pemain lokal + tampilannya di layar akhir.

const GOLD := Color(0.88, 0.69, 0.29)
const Synergy := preload("res://scripts/synergy.gd")

var kills := 0
var boss_kills := 0
var damage := 0
var max_hit := 0
var semangat_used := 0
var time := 0.0
## Nama senjata -> {"damage": int, "texture": Texture2D}
var by_weapon := {}


func record_hit(data: WeaponData, amount: int) -> void:
	damage += amount
	max_hit = maxi(max_hit, amount)
	var key := data.title if data else "Lainnya"
	var entry: Dictionary = by_weapon.get(key, {"damage": 0, "texture": data.texture if data else null})
	entry.damage += amount
	by_weapon[key] = entry


func record_kill(is_boss: bool) -> void:
	kills += 1
	if is_boss:
		boss_kills += 1


## Isi `box` dengan dua kolom: ringkasan angka & damage per senjata.
func build(box: Container, player, wave: int, character: String) -> void:
	for c in box.get_children():
		c.queue_free()
	var left := GridContainer.new()
	left.columns = 2
	left.add_theme_constant_override("h_separation", 10)
	box.add_child(left)
	var rows := [
		["Karakter", character],
		["Wave tercapai", str(wave)],
		["Waktu", "%d:%02d" % [int(time) / 60, int(time) % 60]],
		["Musuh tumbang", "%d  (boss %d)" % [kills, boss_kills]],
		["Total damage", str(damage)],
		["Pukulan terkuat", str(max_hit)],
		["Rempah terkumpul", str(player.rempah_total)],
		["Level", str(player.level)],
		["Pekik Merdeka", str(semangat_used)],
		["Item", str(player.items.size())],
		["Sinergi", ", ".join(Synergy.active(player).map(func(x): return x.name)) if not Synergy.active(player).is_empty() else "-"],
	]
	for r in rows:
		left.add_child(_label(r[0], 8, Color(0.72, 0.62, 0.5)))
		left.add_child(_label(r[1], 9, Color(0.95, 0.89, 0.76)))

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 2)
	box.add_child(right)
	right.add_child(_label("Damage per senjata", 9, GOLD))
	var entries := by_weapon.keys().map(func(k): return [k, by_weapon[k]])
	entries.sort_custom(func(a, b): return a[1].damage > b[1].damage)
	var top := maxi(1, entries[0][1].damage) if not entries.is_empty() else 1
	for e in entries.slice(0, 7):
		var row := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.texture = e[1].texture
		icon.custom_minimum_size = Vector2(14, 10)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(icon)
		var name := _label(e[0], 8, Color(0.95, 0.89, 0.76))
		name.custom_minimum_size = Vector2(62, 0)
		row.add_child(name)
		var bar := ProgressBar.new()
		bar.show_percentage = false
		bar.max_value = top
		bar.value = e[1].damage
		bar.custom_minimum_size = Vector2(70, 7)
		bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(bar)
		row.add_child(_label(str(e[1].damage), 8, GOLD))
		right.add_child(row)
	if entries.is_empty():
		right.add_child(_label("-", 8, Color(0.72, 0.62, 0.5)))


func _label(text: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
