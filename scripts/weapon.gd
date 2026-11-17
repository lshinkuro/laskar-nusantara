extends Node2D
## Satu senjata milik pemain lokal: menembak otomatis ke musuh terdekat dalam jangkauan.

var data: WeaponData
var player  # Player pemilik

var _cooldown := 0.0


func _draw() -> void:
	var tex := data.texture
	draw_texture(tex, -tex.get_size() / 2)


func _process(delta: float) -> void:
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
	var damage := maxi(1, roundi(data.damage * maxf(0.1, 1.0 + stats.damage / 100.0)))
	var dir := global_position.direction_to(target.global_position)
	rotation = dir.angle()
	Sfx.play("shoot", -14.0, 0.15)
	for i in data.projectile_count:
		var angle := deg_to_rad((i - (data.projectile_count - 1) / 2.0) * data.spread)
		player.projectiles.fire(global_position, dir.rotated(angle), data, damage, attack_range)


func _nearest_enemy(attack_range: float) -> Node2D:
	var best: Node2D = null
	var best_d := attack_range * attack_range
	for e: Node2D in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
