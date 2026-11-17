extends Node2D
## World/Projectiles: peluru pemain lokal memberi damage; salinannya dikirim ke
## peer lain hanya sebagai tampilan.

const Projectile := preload("res://scenes/projectile.tscn")

@export var enemies: Node  # World/Enemies
@export var map: Node2D  # World/Map


## Satu tembakan bisa berisi banyak peluru (multi-tembak); dikirim ke peer lain sekali per tembakan.
func fire(pos: Vector2, dirs: PackedVector2Array, data: WeaponData, damage: int, attack_range: float) -> void:
	var lifetime := attack_range / data.projectile_speed * 1.2
	for dir in dirs:
		_spawn(pos, dir, data.projectile_speed, lifetime, data.resource_path, data.pierce, damage)
	_remote_fire.rpc(pos, dirs, data.projectile_speed, lifetime, data.resource_path, data.pierce)


@rpc("any_peer", "unreliable")
func _remote_fire(pos: Vector2, dirs: PackedVector2Array, speed: float, lifetime: float, weapon_path: String, pierce: int) -> void:
	for dir in dirs:
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
	var data := load(weapon_path) as WeaponData
	p.texture = data.texture
	p.spin = data.spin
	add_child(p)


func clear() -> void:
	for p in get_children():
		p.queue_free()
