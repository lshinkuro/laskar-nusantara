extends Node2D
## World/Projectiles: peluru pemain lokal memberi damage; salinannya dikirim ke
## peer lain hanya sebagai tampilan.

const Projectile := preload("res://scenes/projectile.tscn")

@export var enemies: Node  # World/Enemies
@export var map: Node2D  # World/Map


func fire(pos: Vector2, dir: Vector2, data: WeaponData, damage: int, attack_range: float) -> void:
	var lifetime := attack_range / data.projectile_speed * 1.2
	_spawn(pos, dir, data.projectile_speed, lifetime, data.resource_path, data.pierce, damage)
	_remote_fire.rpc(pos, dir, data.projectile_speed, lifetime, data.resource_path, data.pierce)


@rpc("any_peer", "unreliable")
func _remote_fire(pos: Vector2, dir: Vector2, speed: float, lifetime: float, weapon_path: String, pierce: int) -> void:
	_spawn(pos, dir, speed, lifetime, weapon_path, pierce, 0)


func _spawn(pos: Vector2, dir: Vector2, speed: float, lifetime: float, weapon_path: String, pierce: int, damage: int) -> void:
	# shortcut: instantiate per tembakan, ganti ke object pool kalau peluru > ~200 di layar.
	var p := Projectile.instantiate()
	p.position = pos
	p.direction = dir
	p.speed = speed
	p.lifetime = lifetime
	p.pierce = pierce
	p.damage = damage
	p.enemies = enemies
	p.map = map
	p.texture = (load(weapon_path) as WeaponData).texture
	add_child(p)


func clear() -> void:
	for p in get_children():
		p.queue_free()
