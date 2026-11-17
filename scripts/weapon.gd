extends Node2D
## Senjata jarak jauh yang menembak otomatis ke musuh terdekat.

const Projectile := preload("res://scenes/projectile.tscn")

@export var damage := 5
@export var fire_interval := 0.6
@export var attack_range := 220.0
@export var projectile_speed := 400.0

var _cooldown := 0.0


func _process(delta: float) -> void:
	_cooldown -= delta
	if _cooldown > 0:
		return
	# Cari target hanya saat siap menembak, bukan tiap frame.
	var target := _nearest_enemy()
	if target == null:
		return
	_cooldown = fire_interval

	# shortcut: instantiate per tembakan, ganti ke object pool kalau peluru > ~100 di layar.
	var p := Projectile.instantiate()
	p.position = global_position
	p.direction = global_position.direction_to(target.global_position)
	p.speed = projectile_speed
	p.damage = damage
	p.lifetime = attack_range / projectile_speed * 1.5
	owner.get_parent().add_child(p)  # owner = Player, parent-nya = World


func _nearest_enemy() -> Node2D:
	var best: Node2D = null
	var best_d := attack_range * attack_range
	for e: Node2D in get_tree().get_nodes_in_group("enemies"):
		var d := global_position.distance_squared_to(e.global_position)
		if d < best_d:
			best_d = d
			best = e
	return best
