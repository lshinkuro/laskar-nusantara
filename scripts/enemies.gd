extends Node2D
## World/Enemies: musuh & boss disimulasikan di host; client menampilkan posisi hasil
## sinkronisasi. Peluru musuh, ranjau, dan hantaman boss dikirim sebagai event lalu
## disimulasikan di tiap peer; tiap peer hanya melukai prajuritnya sendiri.

signal boss_changed(boss: Node)  # boss baru muncul, atau null saat boss tumbang
signal announce(text: String)

const Enemy := preload("res://scenes/enemy.tscn")
const EnemyBullet := preload("res://scripts/enemy_bullet.gd")
const Mine := preload("res://scripts/mine.gd")
const Slam := preload("res://scripts/slam.gd")
const Fx := preload("res://scripts/fx.gd")
const SYNC_INTERVAL := 0.05
const KETUPAT_CHANCE := 0.06

## Jenis musuh: pengali stat dari nilai dasar wave + perilaku khusus.
const TYPES := {
	"serdadu": {"tex": preload("res://assets/sprites/serdadu_besi.png"), "hp": 1.0, "speed": 1.0, "dmg": 1.0, "scale": 1.5, "radius": 9.0},
	"anjing": {"tex": preload("res://assets/sprites/anjing_pelacak.png"), "hp": 0.5, "speed": 1.8, "dmg": 0.7, "scale": 1.5, "radius": 8.0},
	"penembak": {"tex": preload("res://assets/sprites/penembak.png"), "hp": 0.8, "speed": 0.8, "dmg": 1.0, "scale": 1.5, "radius": 9.0, "ranged": true},
	"perisai": {"tex": preload("res://assets/sprites/serdadu_perisai.png"), "hp": 3.0, "speed": 0.6, "dmg": 1.5, "scale": 1.8, "radius": 11.0},
	"ranjau": {"tex": preload("res://assets/sprites/tukang_ranjau.png"), "hp": 0.9, "speed": 0.9, "dmg": 1.0, "scale": 1.5, "radius": 9.0, "miner": true},
	"komandan": {"tex": preload("res://assets/sprites/komandan_besi.png"), "hp": 1.0, "speed": 0.9, "dmg": 1.5, "scale": 2.6, "radius": 16.0, "boss": "KOMANDAN BESI"},
	"mandor": {"tex": preload("res://assets/sprites/mandor_kejam.png"), "hp": 1.0, "speed": 0.8, "dmg": 2.0, "scale": 2.8, "radius": 18.0, "boss": "MANDOR KEJAM"},
	"gubernur": {"tex": preload("res://assets/sprites/gubernur_jenderal.png"), "hp": 1.0, "speed": 0.85, "dmg": 2.5, "scale": 3.2, "radius": 20.0, "boss": "GUBERNUR JENDERAL BESI"},
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


## Dipanggil peluru milik pemain lokal.
func hit(enemy: Node, amount: int) -> void:
	enemy.flash(amount)
	Fx.spark(get_parent(), enemy.position + Vector2(0, -8))
	Sfx.play("hit", -10.0)
	if multiplayer.is_server():
		_apply_hit(enemy.id, amount)
	else:
		_request_hit.rpc_id(1, enemy.id, amount)


@rpc("any_peer", "reliable")
func _request_hit(id: int, amount: int) -> void:
	if multiplayer.is_server():
		_apply_hit(id, amount)


func _apply_hit(id: int, amount: int) -> void:
	var e := get_node_or_null("E%d" % id)
	if e == null or e.hp <= 0:
		return
	e.hp -= amount
	if e.hp > 0:
		return
	if e.is_boss():
		for i in 12:
			pickups.spawn(e.position + Vector2.from_angle(TAU * i / 12) * 18, 1)
		pickups.spawn(e.position + Vector2(-10, 0), 0, true)
		pickups.spawn(e.position + Vector2(10, 0), 0, true)
	else:
		pickups.spawn(e.position, 1)
		if randf() < KETUPAT_CHANCE:
			pickups.spawn(e.position, 0, true)
	_kill.rpc(id)


@rpc("authority", "call_local", "reliable")
func _kill(id: int) -> void:
	var e := get_node_or_null("E%d" % id)
	if e == null:
		return
	e.hp = 0
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


func summon(pos: Vector2, count: int) -> void:
	for i in count:
		spawn_basic("serdadu", pos + Vector2.from_angle(TAU * i / count + randf()) * 40)


@rpc("authority", "call_local", "reliable")
func telegraph(id: int) -> void:
	var e := get_node_or_null("E%d" % id)
	if e:
		e.start_telegraph()


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
