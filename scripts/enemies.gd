extends Node2D
## World/Enemies: musuh & boss disimulasikan di host; client menampilkan posisi hasil
## sinkronisasi. Peluru musuh, ranjau, dan hantaman boss dikirim sebagai event lalu
## disimulasikan di tiap peer; tiap peer hanya melukai prajuritnya sendiri.

signal boss_changed(boss: Node)  # boss baru muncul, atau null saat boss tumbang
signal announce(text: String)
## Peluru pemain lokal mengenai musuh (untuk statistik run).
signal local_hit(data: WeaponData, amount: int)
## Musuh tumbang oleh pukulan terakhir pemain lokal.
signal kill_credited(kind: String, is_boss: bool)

const Enemy := preload("res://scenes/enemy.tscn")
const EnemyBullet := preload("res://scripts/enemy_bullet.gd")
const Mine := preload("res://scripts/mine.gd")
const Slam := preload("res://scripts/slam.gd")
const Fx := preload("res://scripts/fx.gd")
const SYNC_INTERVAL := 0.05
const KETUPAT_CHANCE := 0.06

## Jenis musuh: pengali stat dari nilai dasar wave + perilaku khusus.
const TYPES := {
	"serdadu": {"tex": preload("res://assets/sprites/serdadu_besi.svg"), "hp": 1.0, "speed": 1.0, "dmg": 1.0, "scale": 1.5, "radius": 9.0},
	"anjing": {"tex": preload("res://assets/sprites/anjing_pelacak.svg"), "hp": 0.5, "speed": 1.8, "dmg": 0.7, "scale": 1.5, "radius": 8.0},
	"penembak": {"tex": preload("res://assets/sprites/penembak.svg"), "hp": 0.8, "speed": 0.8, "dmg": 1.0, "scale": 1.5, "radius": 9.0, "ranged": true},
	"perisai": {"tex": preload("res://assets/sprites/serdadu_perisai.svg"), "hp": 3.0, "speed": 0.6, "dmg": 1.5, "scale": 1.8, "radius": 11.0},
	"ranjau": {"tex": preload("res://assets/sprites/tukang_ranjau.svg"), "hp": 0.9, "speed": 0.9, "dmg": 1.0, "scale": 1.5, "radius": 9.0, "miner": true},
	"kavaleri": {"tex": preload("res://assets/sprites/kavaleri_besi.svg"), "hp": 1.3, "speed": 1.1, "dmg": 1.5, "scale": 1.7, "radius": 11.0},
	"granat": {"tex": preload("res://assets/sprites/pelempar_granat.svg"), "hp": 0.9, "speed": 0.8, "dmg": 1.0, "scale": 1.5, "radius": 9.0, "ranged": true},
	"tabib": {"tex": preload("res://assets/sprites/tabib_besi.svg"), "hp": 1.2, "speed": 0.85, "dmg": 0.8, "scale": 1.5, "radius": 9.0, "ranged": true},
	"raksasa": {"tex": preload("res://assets/sprites/raksasa_baja.svg"), "hp": 6.0, "speed": 0.45, "dmg": 2.5, "scale": 2.4, "radius": 17.0},
	"laksamana": {"tex": preload("res://assets/sprites/laksamana_besi.svg"), "hp": 1.0, "speed": 0.8, "dmg": 2.0, "scale": 2.8, "radius": 18.0, "boss": "LAKSAMANA BESI"},
	"komandan": {"tex": preload("res://assets/sprites/komandan_besi.svg"), "hp": 1.0, "speed": 0.9, "dmg": 1.5, "scale": 2.6, "radius": 16.0, "boss": "KOMANDAN BESI"},
	"mandor": {"tex": preload("res://assets/sprites/mandor_kejam.svg"), "hp": 1.0, "speed": 0.8, "dmg": 2.0, "scale": 2.8, "radius": 18.0, "boss": "MANDOR KEJAM"},
	"gubernur": {"tex": preload("res://assets/sprites/gubernur_jenderal.svg"), "hp": 1.0, "speed": 0.85, "dmg": 2.5, "scale": 3.2, "radius": 20.0, "boss": "GUBERNUR JENDERAL BESI"},
}

@export var players: Node2D  # World/Players
@export var pickups: Node  # World/Pickups
@export var map: Node2D  # World/Map
@export var hazards: Node2D  # World/Projectiles (peluru musuh, ranjau, hantaman ikut dibersihkan di akhir wave)

var local_player: Node2D  # diisi main
## Stat dasar musuh wave ini (diisi wave manager di host), dipakai juga untuk panggilan boss.
var wave := 1
var base_hp := 9
var base_speed := 47.0
var base_damage := 2

var _next_id := 1
var _next_mine := 1
var _sync := 0.0
var _boss_hp_sent := -1


# --- Spawn & mati -------------------------------------------------------------

## Host saja.
func spawn(kind: String, pos: Vector2, max_hp: int, speed: float, damage: int) -> void:
	_spawn.rpc(_next_id, kind, pos, max_hp, speed, damage)
	_next_id += 1


## Host saja: musuh biasa dengan stat dasar wave ini.
func spawn_basic(kind: String, pos: Vector2, hp_factor := 1.0) -> void:
	var t: Dictionary = TYPES[kind]
	spawn(kind, map.resolve(pos, t.radius), maxi(1, roundi(base_hp * t.hp * hp_factor)), base_speed * t.speed, maxi(1, roundi(base_damage * t.dmg)))


@rpc("authority", "call_local", "reliable")
func _spawn(id: int, kind: String, pos: Vector2, max_hp: int, speed: float, damage: int) -> void:
	var e := Enemy.instantiate()
	e.name = "E%d" % id
	e.id = id
	e.kind = kind
	e.def = TYPES[kind]
	e.position = pos
	e.max_hp = max_hp
	e.speed = speed
	e.damage = damage
	e.players = players
	e.map = map
	e.enemies = self
	e.simulate = multiplayer.is_server()
	add_child(e)
	if e.is_boss():
		boss_changed.emit(e)


func boss() -> Node:
	for e in get_children():
		if e.is_boss() and e.hp > 0:
			return e
	return null


## Lama tiap efek status (detik).
const STATUS_DURATION := {"burn": 2.5, "poison": 3.5, "bleed": 2.0, "slow": 1.5}


## Dipanggil peluru milik pemain lokal.
func hit(enemy: Node, amount: int, data: WeaponData = null, dir := Vector2.ZERO) -> void:
	var effect := data.effect if data else ""
	var power := data.effect_power if data else 0.0
	if local_player:
		var mod: Array = local_player.modify_hit(effect, power)
		effect = mod[0]
		power = mod[1]
		local_player.on_hit(amount)
	enemy.flash(amount)
	Fx.spark(get_parent(), enemy.position + Vector2(0, -8), Fx.EFFECT_COLORS.get(effect, Color(1, 0.9, 0.5)))
	if data and data.category == "melee":
		Fx.slash(get_parent(), enemy.position + Vector2(0, -8), dir.angle())
	Sfx.play("hit", -10.0)
	local_hit.emit(data, amount)
	if multiplayer.is_server():
		_apply_hit(enemy.id, amount, effect, power, dir, 1)
	else:
		_request_hit.rpc_id(1, enemy.id, amount, effect, power, dir)


@rpc("any_peer", "reliable")
func _request_hit(id: int, amount: int, effect: String, power: float, dir: Vector2) -> void:
	if multiplayer.is_server():
		_apply_hit(id, amount, effect, power, dir, multiplayer.get_remote_sender_id())


## Host saja: damage per detik dari status (terbakar/racun/berdarah).
func status_damage(e: Node, amount: int, effect: String) -> void:
	if e.hp <= 0:
		return
	var DamageNumber := preload("res://scripts/damage_number.gd")
	DamageNumber.spawn(self, e.position + Vector2(randf_range(-6, 6), -10 - e.def.radius), amount, Fx.EFFECT_COLORS[effect])
	_apply_hit(e.id, amount)


func _apply_hit(id: int, amount: int, effect := "", power := 0.0, dir := Vector2.ZERO, by := 0) -> void:
	var e := get_node_or_null("E%d" % id)
	if e == null or e.hp <= 0:
		return
	if by > 0:
		e.last_hitter = by
	_apply_effect(e, amount, effect, power, dir)
	e.hp -= amount
	if e.hp > 0:
		return
	if e.is_boss():
		for i in 12:
			pickups.spawn(e.position + Vector2.from_angle(TAU * i / 12) * 18, 1)
		pickups.spawn(e.position + Vector2(-10, 0), 0, "ketupat")
		pickups.spawn(e.position + Vector2(10, 0), 0, "ketupat")
		for i in players.get_child_count():  # satu Peti Pusaka per pemain
			pickups.spawn(e.position + Vector2((i - (players.get_child_count() - 1) / 2.0) * 22, 14), 0, "peti")
	else:
		pickups.spawn(e.position, 1)
		if randf() < KETUPAT_CHANCE:
			pickups.spawn(e.position, 0, "ketupat")
	if e.kind == "raksasa":  # Raksasa Baja pecah jadi 2 serdadu
		for side in [-1, 1]:
			spawn_basic("serdadu", e.position + Vector2(side * 18, 0))
	_kill.rpc(id, e.last_hitter)


func _apply_effect(e: Node, amount: int, effect: String, power: float, dir: Vector2) -> void:
	match effect:
		"burn", "poison", "bleed", "slow":
			# Damage per tick ikut naik dengan kekuatan pukulan (upgrade/tier tetap terasa).
			e.add_status(effect, STATUS_DURATION[effect], maxf(power, amount * 0.35) if power > 0 else 0.0)
			_status_fx.rpc(e.id, effect, STATUS_DURATION[effect])
		"knockback":
			var push := power * (0.25 if e.is_boss() else 1.0)
			e.position = map.resolve(e.position + dir.normalized() * push, e.def.radius)
		"explode":
			_boom_fx.rpc(e.position, power)
			for other in get_children():
				if other != e and other.hp > 0 and other.position.distance_to(e.position) < power:
					_apply_hit(other.id, maxi(1, roundi(amount * 0.6)), "", 0.0, Vector2.ZERO, e.last_hitter)


@rpc("authority", "reliable")
func _status_fx(id: int, effect: String, duration: float) -> void:
	var e := get_node_or_null("E%d" % id)
	if e:
		e.add_status(effect, duration, 0.0)


@rpc("authority", "call_local", "reliable")
func _boom_fx(pos: Vector2, radius: float) -> void:
	Fx.explosion(get_parent(), pos, radius * 0.6)
	Sfx.play("enemy_die", -4.0, 0.2)


@rpc("authority", "call_local", "reliable")
func _kill(id: int, killer: int) -> void:
	var e := get_node_or_null("E%d" % id)
	if e == null:
		return
	e.hp = 0
	if killer == multiplayer.get_unique_id():
		kill_credited.emit(e.kind, e.is_boss())
	Fx.spark(get_parent(), e.position, Color(0.75, 0.78, 0.82), 10 if not e.is_boss() else 40)
	if e.is_boss():
		Fx.explosion(get_parent(), e.position, 40)
		boss_changed.emit(null)
	e.die()


## Host saja.
func clear() -> void:
	_clear.rpc()


@rpc("authority", "call_local", "reliable")
func _clear() -> void:
	for e in get_children():
		e.queue_free()
	boss_changed.emit(null)


# --- Kemampuan musuh (dipanggil musuh yang disimulasikan host) ----------------

func fire_bullets(pos: Vector2, dirs: PackedVector2Array, speed: float, damage: int) -> void:
	_bullets.rpc(pos, dirs, speed, damage)


func fire_ring(pos: Vector2, count: int, speed: float, damage: int, offset: float) -> void:
	var dirs := PackedVector2Array()
	for i in count:
		dirs.append(Vector2.from_angle(offset + TAU * i / count))
	_bullets.rpc(pos, dirs, speed, damage)


@rpc("authority", "call_local", "reliable")
func _bullets(pos: Vector2, dirs: PackedVector2Array, speed: float, damage: int) -> void:
	for d in dirs:
		var b := EnemyBullet.new()
		b.position = pos + d * 10
		b.direction = d
		b.speed = speed
		b.damage = maxi(1, damage)
		b.local_player = local_player
		b.map = map
		hazards.add_child(b)


func place_mine(pos: Vector2) -> void:
	_mine.rpc(_next_mine, pos)
	_next_mine += 1


@rpc("authority", "call_local", "reliable")
func _mine(id: int, pos: Vector2) -> void:
	var m := Mine.new()
	m.name = "M%d" % id
	m.id = id
	m.position = pos
	m.enemies = self
	hazards.add_child(m)


func request_detonate(id: int) -> void:
	if multiplayer.is_server():
		_detonate.rpc(id)
	else:
		_request_detonate.rpc_id(1, id)


@rpc("any_peer", "reliable")
func _request_detonate(id: int) -> void:
	if multiplayer.is_server() and hazards.get_node_or_null("M%d" % id):
		_detonate.rpc(id)


@rpc("authority", "call_local", "reliable")
func _detonate(id: int) -> void:
	var m := hazards.get_node_or_null("M%d" % id)
	if m == null:
		return
	_slam_at(m.position, 36.0, 0.0, base_damage * 2)
	m.queue_free()


func slam(pos: Vector2, radius: float, delay: float, damage: int) -> void:
	_slam.rpc(pos, radius, delay, damage)


@rpc("authority", "call_local", "reliable")
func _slam(pos: Vector2, radius: float, delay: float, damage: int) -> void:
	_slam_at(pos, radius, delay, damage)


func _slam_at(pos: Vector2, radius: float, delay: float, damage: int) -> void:
	var s := Slam.new()
	s.position = pos
	s.radius = radius
	s.delay = maxf(delay, 0.01)
	s.damage = damage
	s.local_player = local_player
	hazards.add_child(s)


func summon(pos: Vector2, count: int, kind := "serdadu") -> void:
	for i in count:
		spawn_basic(kind, pos + Vector2.from_angle(TAU * i / count + randf()) * 40)


@rpc("authority", "call_local", "reliable")
func telegraph(id: int) -> void:
	var e := get_node_or_null("E%d" % id)
	if e:
		e.start_telegraph()


## Tabib Besi: pulihkan musuh di sekitar (host), tampilkan cincin hijau di semua peer.
func heal_around(pos: Vector2, radius: float, fraction: float) -> void:
	for e in get_children():
		if e.hp > 0 and e.position.distance_to(pos) < radius:
			e.hp = mini(e.max_hp, e.hp + maxi(1, roundi(e.max_hp * fraction)))
	_heal_fx.rpc(pos, radius)


@rpc("authority", "call_local", "reliable")
func _heal_fx(pos: Vector2, radius: float) -> void:
	Fx.ring(get_parent(), pos, radius, Color(0.4, 1, 0.4))
	Fx.spark(get_parent(), pos + Vector2(0, -10), Color(0.5, 1, 0.5), 8)


## Kipas peluru ke arah `dir` (Laksamana Besi).
func fire_fan(pos: Vector2, dir: Vector2, count: int, spread_deg: float, speed: float, damage: int) -> void:
	var dirs := PackedVector2Array()
	for i in count:
		dirs.append(dir.rotated(deg_to_rad((i - (count - 1) / 2.0) * spread_deg / maxf(1, count - 1))))
	_bullets.rpc(pos, dirs, speed, damage)


@rpc("authority", "call_local", "reliable")
func shout(text: String) -> void:
	announce.emit(text)


# --- Sinkronisasi posisi & HP boss --------------------------------------------

func _physics_process(delta: float) -> void:
	if not multiplayer.is_server():
		return
	_sync -= delta
	if _sync > 0 or get_child_count() == 0:
		return
	_sync = SYNC_INTERVAL
	var ids := PackedInt32Array()
	var positions := PackedVector2Array()
	for e in get_children():
		ids.append(e.id)
		positions.append(e.position)
	_sync_positions.rpc(ids, positions)
	var b := boss()
	if b and b.hp != _boss_hp_sent:
		_boss_hp_sent = b.hp
		_sync_boss_hp.rpc(b.id, b.hp)


@rpc("authority", "unreliable_ordered")
func _sync_positions(ids: PackedInt32Array, positions: PackedVector2Array) -> void:
	for i in ids.size():
		var e := get_node_or_null("E%d" % ids[i])
		if e:
			e.target_pos = positions[i]


@rpc("authority", "unreliable_ordered")
func _sync_boss_hp(id: int, hp: int) -> void:
	var e := get_node_or_null("E%d" % id)
	if e and e.hp > 0:
		e.hp = hp
