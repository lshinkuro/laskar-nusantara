extends Node2D
## Satu senjata milik pemain lokal: menembak otomatis ke musuh terdekat dalam jangkauan.
## Tier naik dengan menggabung senjata yang sama: +1 peluru & damage x1.5 per tier.

const TIER_COLORS := [Color(0.7, 0.7, 0.7), Color(0.35, 0.6, 1.0), Color(0.75, 0.4, 1.0), Color(1.0, 0.3, 0.25)]
const SPREAD_DEFAULT := 10.0
## Suara serangan per senjata (nama file .tres); yang tidak terdaftar memakai "shoot".
const SOUNDS := {
	"keris": "w_tebas", "golok": "w_tebas", "kujang": "w_tebas",
	"tombak": "w_tusuk", "bambu_runcing": "w_tusuk",
	"shuriken": "w_lempar", "kunai": "w_lempar", "cakra": "w_lempar",
	"panah": "w_panah", "sumpit": "w_panah", "ketapel": "w_ketapel",
	"meriam_lela": "w_meriam", "meriam_jaga": "w_meriam", "mantra_api": "w_api",
}

var data: WeaponData
var player  # Player pemilik
var tier := 1
## Sekutu (wayang): ikon sendiri & mengorbit prajurit, bukan slot senjata.
var icon_texture: Texture2D
var orbit := false
## Meriam Jaga: diam di arena & membidik dari posisinya sendiri, bukan dari prajurit.
var turret := false
var _orbit_t := randf() * TAU

var _cooldown := 0.0
var _flash := 0.0
var _kick := 0.0


func _draw() -> void:
	if not orbit:
		var c: Color = TIER_COLORS[tier - 1]
		draw_circle(Vector2.ZERO, 6.0, Color(c, 0.35))
		draw_arc(Vector2.ZERO, 6.0, 0, TAU, 16, c, 1.0)
	var tex := icon_texture if icon_texture else data.texture
	var size := tex.get_size() / Art.SCALE
	draw_texture_rect(tex, Rect2(-size / 2 + Vector2(-_kick, 0), size), false)
	if _flash > 0:  # kilatan moncong
		var tip := Vector2(size.x / 2 + 2 - _kick, 0)
		var r := 3.0 + _flash * 40.0
		draw_circle(tip, r, Color(1, 0.95, 0.6, 0.9))
		draw_circle(tip, r * 0.5, Color(1, 1, 1))


func _process(delta: float) -> void:
	if orbit:
		_orbit_t += delta * 1.5
		position = Vector2.from_angle(_orbit_t + get_index() * TAU / get_parent().get_child_count()) * 34.0
		rotation = 0.0
	if _flash > 0 or _kick > 0:
		_flash = maxf(_flash - delta, 0.0)
		_kick = maxf(_kick - delta * 20.0, 0.0)
		queue_redraw()
	if not player.alive:
		return
	_cooldown -= delta
	if _cooldown > 0:
		return
	var attack_range := shot_range()
	# Cari target hanya saat siap menembak, bukan tiap frame.
	var target := pick_target(attack_range)
	if target == null:
		return
	_cooldown = shot_interval()
	var damage := shot_damage()
	var dir := global_position.direction_to(target.global_position)
	if not orbit:
		rotation = dir.angle()
	var count := shot_count()
	var spread := data.spread if data.spread > 0 else SPREAD_DEFAULT
	var dirs := PackedVector2Array()
	for i in count:
		dirs.append(dir.rotated(deg_to_rad((i - (count - 1) / 2.0) * spread)))
	player.projectiles.fire(global_position, dirs, data, damage, attack_range)
	Sfx.play(SOUNDS.get(data.resource_path.get_file().get_basename(), "shoot"), -14.0, 0.15)
	_flash = 0.07
	_kick = 3.0
	queue_redraw()


# Angka tembakan dengan tier & stat prajurit saat ini (dipakai juga tooltip Tas Pusaka).
func shot_damage() -> int:
	return maxi(1, roundi(data.damage * (1.0 + 0.5 * (tier - 1)) * player.damage_multiplier(data.category)))


func shot_count() -> int:
	return data.projectile_count + (tier - 1) + player.stats.projectiles


func shot_interval() -> float:
	return data.fire_interval / maxf(0.2, 1.0 + player.stats.attack_speed / 100.0)


func shot_range() -> float:
	return data.attack_range * maxf(0.3, 1.0 + player.stats.range / 100.0)


## Tiap senjata membidik musuh berbeda: senjata ke-i mengambil musuh terdekat ke-i
## (berputar kalau musuh dalam jangkauan lebih sedikit dari jumlah senjata).
func pick_target(attack_range: float) -> Node2D:
	var in_range := []
	var max_d := attack_range * attack_range
	var origin: Vector2 = global_position if turret else player.global_position
	for e: Node2D in get_tree().get_nodes_in_group("enemies"):
		var d: float = origin.distance_squared_to(e.global_position)
		if d < max_d:
			in_range.append([d, e])
	if in_range.is_empty():
		return null
	in_range.sort_custom(func(a, b): return a[0] < b[0])
	return in_range[get_index() % in_range.size()][1]
