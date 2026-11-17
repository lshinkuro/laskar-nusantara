extends CharacterBody2D
## Prajurit. Tiap peer menggerakkan prajuritnya sendiri (authority = peer id)
## dan mengirim posisi/HP ke peer lain. Stat, senjata, rempah hanya diurus pemiliknya.

signal hp_changed(hp: int, max_hp: int)
signal rempah_changed(amount: int)
signal stats_changed
signal xp_changed(xp: int, needed: int, level: int)
signal leveled_up(level: int)
signal died

const Weapon := preload("res://scripts/weapon.gd")
const Synergy := preload("res://scripts/synergy.gd")
const Fx := preload("res://scripts/fx.gd")
const WAYANG := preload("res://data/allies/wayang.tres")
const WAYANG_ICON := preload("res://assets/sprites/wayang.png")
const PULSE_INTERVAL := 6.0
const KENTONGAN_HIT := preload("res://data/allies/kentongan_hit.tres")
const DamageNumber := preload("res://scripts/damage_number.gd")
const OBJECT_SCALE := 1.5
const MAX_TIER := 4
const MAX_WEAPONS := 6
const BASE_SPEED := 120.0
const BASE_PICKUP_RANGE := 40.0
const SYNC_INTERVAL := 0.05
const BASE_STATS := {
	"max_hp": 20,
	"hp_regen": 0,      # tiap poin = 0.2 HP/detik
	"armor": 0,         # mengurangi damage yang diterima
	"speed": 0,         # % kecepatan gerak
	"damage": 0,        # % damage
	"attack_speed": 0,  # % kecepatan serangan
	"range": 0,         # % jangkauan
	"luck": 0,          # % peluang rempah dobel
	"pickup_range": 0,  # piksel jangkauan ambil rempah
	"projectiles": 0,   # peluru tambahan per tembakan, semua senjata
	"melee_damage": 0,  # % damage senjata jarak dekat
	"ranged_damage": 0, # % damage senjata jarak jauh
	"magic_damage": 0,  # % damage senjata magis
	"dodge": 0,         # % peluang menghindar (maks 60)
	"harvest": 0,       # % rempah tambahan
}

@export var arena_size := Vector2(960, 540)
@export var invuln_time := 0.6

var display_name := ""
var kerajaan := {}
var stats := BASE_STATS.duplicate()
var hp := 20
var alive := true
var rempah := 0
var rempah_total := 0  # rempah terkumpul sepanjang run (statistik)
var level := 1
var xp := 0
## Level yang belum dipilih upgrade-nya (dipilih di akhir wave).
var pending_levels := 0
var items: Array[ItemData] = []
var weapons: Array[WeaponData] = []  # satu entri per slot; tier ada di node senjata
var projectiles: Node  # World/Projectiles, diisi main
var enemies: Node  # World/Enemies, diisi main
## Efek khusus dari item: nama -> nilai (ditumpuk kalau punya lebih dari satu).
var specials := {}
var _synergy_applied := {}
var _pulse := PULSE_INTERVAL
var _death_save_ready := true
var _rempah_heal_count := 0
var map: Node2D  # World/Map, diisi main

var _invuln := 0.0
var _regen := 0.0
var _sync := 0.0
var _target_pos := Vector2.ZERO
var _bob := 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var hurtbox: Area2D = $Hurtbox
@onready var weapon_ring: Node2D = $Weapons


func _ready() -> void:
	hp = stats.max_hp
	_target_pos = position
	sprite.texture = kerajaan.texture
	$Name.text = display_name
	$Name.modulate = kerajaan.color
	$Camera2D.enabled = is_local()
	if is_local():
		$Camera2D.make_current()


var _shake := 0.0


## Guncang kamera (hanya pemain lokal).
func shake(amount: float) -> void:
	if is_local():
		_shake = maxf(_shake, amount)


func _process(delta: float) -> void:
	if is_local() and alive and specials.has("pulse"):
		_pulse -= delta
		if _pulse <= 0:
			_pulse = PULSE_INTERVAL
			Sfx.play("hit", -2.0, 0.0)
			_hit_around(90.0, int(specials.pulse), KENTONGAN_HIT)
	if _shake > 0:
		_shake = maxf(_shake - delta * 25.0, 0.0)
		$Camera2D.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake


func is_local() -> bool:
	return is_multiplayer_authority()


func _physics_process(delta: float) -> void:
	if not is_local():
		var step := position.distance_to(_target_pos)
		position = position.lerp(_target_pos, minf(1.0, delta * 15.0))
		_animate(delta, step > 0.5, _target_pos.x - position.x)
		return
	if not alive:
		return

	var speed := BASE_SPEED * maxf(0.3, 1.0 + stats.speed / 100.0)
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
	move_and_slide()
	position = map.resolve(position.clamp(Vector2(12, 12), arena_size - Vector2(12, 12)), 8.0)
	_animate(delta, velocity.length() > 1, velocity.x)

	if stats.hp_regen > 0 and hp < stats.max_hp:
		_regen += stats.hp_regen * 0.2 * delta
		if _regen >= 1.0:
			_regen -= 1.0
			hp += 1
			hp_changed.emit(hp, stats.max_hp)

	_invuln -= delta
	sprite.modulate.a = 0.5 if _invuln > 0 and fmod(_invuln, 0.15) < 0.075 else 1.0
	if _invuln <= 0:
		for enemy in hurtbox.get_overlapping_areas():
			take_damage(enemy.damage)
			break

	_sync -= delta
	if _sync <= 0:
		_sync = SYNC_INTERVAL
		_sync_state.rpc(position, hp, stats.max_hp)


func _animate(delta: float, moving: bool, dir_x: float) -> void:
	if absf(dir_x) > 0.1:
		sprite.flip_h = dir_x < 0
	_bob = _bob + delta * 14.0 if moving else 0.0
	sprite.position.y = -absf(sin(_bob)) * 2.0


@rpc("authority", "unreliable_ordered")
func _sync_state(pos: Vector2, new_hp: int, max_hp: int) -> void:
	_target_pos = pos
	if new_hp != hp or max_hp != stats.max_hp:
		hp = new_hp
		stats.max_hp = max_hp
		hp_changed.emit(hp, max_hp)


func take_damage(amount: int) -> void:
	if not alive or _invuln > 0:
		return
	if hp - amount <= 0 and _death_save_ready and specials.has("death_save") and alive:
		# Jimat Rajah: selamat dengan 1 HP sekali tiap wave.
		_death_save_ready = false
		hp = 1
		_invuln = invuln_time * 2
		hp_changed.emit(hp, stats.max_hp)
		DamageNumber.spawn(get_parent(), position + Vector2(0, -24), 0, Color(1, 0.9, 0.4), "Jimat! ")
		Fx.ring(get_parent().get_parent(), position, 40.0, Color(1, 0.9, 0.4))
		return
	if randf() * 100.0 < minf(stats.dodge, 60.0):
		_invuln = invuln_time * 0.5
		DamageNumber.spawn(get_parent(), position + Vector2(0, -24), 0, Color(0.7, 0.9, 1), "Hindar! ")
		return
	var armor: int = stats.armor
	var factor := 10.0 / (10.0 + armor) if armor >= 0 else (10.0 - armor) / 10.0
	hp = maxi(hp - maxi(1, roundi(amount * factor)), 0)
	_invuln = invuln_time
	shake(3.0)
	if specials.has("thorns"):
		_hit_around(55.0, int(specials.thorns), null)
	hp_changed.emit(hp, stats.max_hp)
	Sfx.play("hurt", -4.0)
	if hp == 0:
		_set_alive.rpc(false, 0)


## Dipanggil pemilik di awal wave: hidup lagi dengan HP penuh.
func revive() -> void:
	_death_save_ready = true
	if is_local():
		_set_alive.rpc(true, stats.max_hp)


@rpc("authority", "call_local", "reliable")
func _set_alive(value: bool, new_hp: int) -> void:
	alive = value
	hp = new_hp
	_invuln = 0.0
	sprite.modulate = Color.WHITE if alive else Color(0.4, 0.4, 0.4, 0.5)
	weapon_ring.visible = alive
	$Hurtbox.monitoring = alive
	hp_changed.emit(hp, stats.max_hp)
	if not alive:
		died.emit()


func pickup_range() -> float:
	return BASE_PICKUP_RANGE + stats.pickup_range


func collect_rempah(value: int) -> void:
	if randf() * 100.0 < stats.luck:
		value *= 2
	# Bonus panen pecahan dibulatkan secara acak (30% -> kadang +1).
	var bonus: float = value * stats.harvest / 100.0
	value = maxi(0, value + int(bonus) + (1 if randf() < bonus - int(bonus) else 0))
	rempah += value
	rempah_total += value
	if specials.has("rempah_heal"):
		_rempah_heal_count += value
		var every := maxi(1, int(36.0 / specials.rempah_heal))  # 1 lumbung: tiap 6 rempah, 2: tiap 3
		while _rempah_heal_count >= every:
			_rempah_heal_count -= every
			heal(1, false)
	rempah_changed.emit(rempah)
	gain_xp(value)


func xp_needed() -> int:
	return 5 + level * 5


func gain_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_needed():
		xp -= xp_needed()
		level += 1
		pending_levels += 1
		stats.max_hp += 1
		hp += 1
		hp_changed.emit(hp, stats.max_hp)
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_needed(), level)


func heal(amount: int, show := true) -> void:
	if not alive:
		return
	var healed := mini(amount, stats.max_hp - hp)
	if healed <= 0:
		return
	hp += healed
	hp_changed.emit(hp, stats.max_hp)
	if show:
		DamageNumber.spawn(get_parent(), position + Vector2(0, -24), healed, Color(0.5, 1, 0.5), "+")


## Dipanggil Enemies saat serangan pemain lokal kena: efek item (obor, kalung taring).
func modify_hit(effect: String, power: float) -> Array:
	if effect == "" and specials.has("burn_chance") and randf() * 100.0 < specials.burn_chance:
		return ["burn", 2.0]
	return [effect, power]


func on_hit(_amount: int) -> void:
	if specials.has("lifesteal") and randf() * 100.0 < specials.lifesteal:
		heal(1, false)


## Lukai semua musuh dalam radius (gelang akar bahar, kentongan).
func _hit_around(radius: float, amount: int, data: WeaponData) -> void:
	if enemies == null:
		return
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.position.distance_to(position) < radius:
			enemies.hit(e, amount, data, position.direction_to(e.position))
	Fx.ring(get_parent().get_parent(), position, radius, Color(1, 0.85, 0.5))  # ke World, bukan daftar pemain


func spend(amount: int) -> bool:
	if rempah < amount:
		return false
	rempah -= amount
	rempah_changed.emit(rempah)
	return true


func apply_item(item: ItemData) -> void:
	items.append(item)
	apply_stats(item.stats)
	if item.special != "":
		specials[item.special] = specials.get(item.special, 0.0) + item.special_value
		if item.special == "wayang":
			_add_ally()
	recompute_synergies()


## Terapkan selisih bonus sinergi (yang baru aktif ditambah, yang hilang dikurangi).
func recompute_synergies() -> void:
	var target := {}
	for s in Synergy.active(self):
		for k in s.stats:
			target[k] = target.get(k, 0) + s.stats[k]
	var diff := {}
	for k in target.keys() + _synergy_applied.keys():
		var d: int = target.get(k, 0) - _synergy_applied.get(k, 0)
		if d != 0:
			diff[k] = d
	_synergy_applied = target
	if not diff.is_empty():
		apply_stats(diff)


func _add_ally() -> void:
	var allies := get_node_or_null("Allies")
	if allies == null:
		allies = Node2D.new()
		allies.name = "Allies"
		add_child(allies)
	var w := Weapon.new()
	w.data = WAYANG
	w.player = self
	w.icon_texture = WAYANG_ICON
	w.orbit = true
	w.scale = Vector2.ONE * 1.2
	allies.add_child(w)


## Tambah/kurangi stat (dari item atau upgrade level).
func apply_stats(changes: Dictionary) -> void:
	for key in changes:
		stats[key] += changes[key]
	stats.max_hp = maxi(stats.max_hp, 1)
	if changes.has("max_hp"):
		hp = clampi(hp + changes.max_hp, 1, stats.max_hp)
	hp_changed.emit(hp, stats.max_hp)
	stats_changed.emit()


## Senjata yang sama digabung jadi tier lebih tinggi (tidak makan slot).
func mergeable_weapon(data: WeaponData) -> Node:
	var best: Node = null
	for w in weapon_ring.get_children():
		if w.data == data and w.tier < MAX_TIER and (best == null or w.tier < best.tier):
			best = w
	return best


func can_take_weapon(data: WeaponData) -> bool:
	return mergeable_weapon(data) != null or weapons.size() < MAX_WEAPONS


## Terapkan karakter yang dipilih: stat awal + senjata awal.
func apply_character(c: CharacterData) -> void:
	apply_stats(c.stats)
	hp = stats.max_hp
	hp_changed.emit(hp, stats.max_hp)
	add_weapon(c.start_weapon)


## Pengali damage senjata: damage umum + bonus kategori (melee/ranged/magic).
func damage_multiplier(category: String) -> float:
	return maxf(0.1, 1.0 + (stats.damage + stats.get(category + "_damage", 0)) / 100.0)


func add_weapon(data: WeaponData) -> bool:
	var merge := mergeable_weapon(data)
	if merge:
		merge.tier += 1
		merge.queue_redraw()
		stats_changed.emit()
		return true
	if weapons.size() < MAX_WEAPONS:
		call_deferred("recompute_synergies")  # setelah node senjata masuk ring
	if weapons.size() >= MAX_WEAPONS:
		return false
	weapons.append(data)
	var w := Weapon.new()
	w.data = data
	w.player = self
	w.scale = Vector2.ONE * OBJECT_SCALE
	weapon_ring.add_child(w)
	# Senjata disusun melingkar di sekitar prajurit.
	var n := weapon_ring.get_child_count()
	for i in n:
		weapon_ring.get_child(i).position = Vector2.from_angle(TAU * i / n - PI / 2) * (19.0 + maxi(0, n - 3) * 3.0)
	stats_changed.emit()
	return true
