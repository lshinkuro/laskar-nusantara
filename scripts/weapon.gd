extends Node2D
## Satu senjata milik pemain lokal: menembak otomatis ke musuh terdekat dalam jangkauan.
## Tier naik dengan menggabung senjata yang sama: +1 peluru & damage x1.5 per tier.

const TIER_COLORS := [Color(0.7, 0.7, 0.7), Color(0.35, 0.6, 1.0), Color(0.75, 0.4, 1.0), Color(1.0, 0.3, 0.25)]
const SPREAD_DEFAULT := 10.0

var data: WeaponData
var player  # Player pemilik
var tier := 1

var _cooldown := 0.0
var _flash := 0.0
var _kick := 0.0


func _draw() -> void:
	var c: Color = TIER_COLORS[tier - 1]
	draw_circle(Vector2.ZERO, 6.0, Color(c, 0.35))
	draw_arc(Vector2.ZERO, 6.0, 0, TAU, 16, c, 1.0)
	var tex := data.texture
	draw_texture(tex, -tex.get_size() / 2 + Vector2(-_kick, 0))
	if _flash > 0:  # kilatan moncong
		var tip := Vector2(tex.get_size().x / 2 + 2 - _kick, 0)
		var r := 3.0 + _flash * 40.0
		draw_circle(tip, r, Color(1, 0.95, 0.6, 0.9))
		draw_circle(tip, r * 0.5, Color(1, 1, 1))


func _process(delta: float) -> void:
	if _flash > 0 or _kick > 0:
		_flash = maxf(_flash - delta, 0.0)
		_kick = maxf(_kick - delta * 20.0, 0.0)
		queue_redraw()
	if not player.alive:
		return
	_cooldown -= delta
	if _cooldown > 0:
		return
	var stats: Dictionary = player.stats
	var attack_range := data.attack_range * maxf(0.3, 1.0 + stats.range / 100.0)
	# Cari target hanya saat siap menembak, bukan tiap frame.
	var target := _nearest_enemy(attack_range)
	if target == null:
		return
	_cooldown = data.fire_interval / maxf(0.2, 1.0 + stats.attack_speed / 100.0)
	var damage := maxi(1, roundi(data.damage * (1.0 + 0.5 * (tier - 1)) * maxf(0.1, 1.0 + stats.damage / 100.0)))
	var dir := global_position.direction_to(target.global_position)
	rotation = dir.angle()
	var count: int = data.projectile_count + (tier - 1) + stats.projectiles
	var spread := data.spread if data.spread > 0 else SPREAD_DEFAULT
	var dirs := PackedVector2Array()
	for i in count:
		dirs.append(dir.rotated(deg_to_rad((i - (count - 1) / 2.0) * spread)))
	player.projectiles.fire(global_position, dirs, data, damage, attack_range)
	Sfx.play("shoot", -14.0, 0.15)
	_flash = 0.07
	_kick = 3.0
	queue_redraw()


func _nearest_enemy(attack_range: float) -> Node2D:
	var best: Node2D = null
	var best_d := attack_range * attack_range
	for e: Node2D in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
