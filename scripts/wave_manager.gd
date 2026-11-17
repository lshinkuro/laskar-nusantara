extends Node
## Timer wave & spawn musuh. Hanya host yang spawn dan mengakhiri wave;
## semua peer menghitung mundur sendiri untuk tampilan.

signal wave_started(wave: int)
signal wave_ended(wave: int)

const LAST_WAVE := 20
const MAX_ENEMIES := 150
const MIN_SPAWN_DISTANCE := 150.0

@export var enemies: Node
@export var pickups: Node
@export var projectiles: Node
@export var players: Node2D
@export var map: Node2D
@export var villagers: Node
@export var arena_size := Vector2(960, 540)

var wave := 0
var time_left := 0.0
var running := false
var _spawn_cooldown := 0.0
var _duration := 20.0
var _boss_spawned := false

## Musuh yang mulai muncul di wave tertentu, dengan bobot peluang.
const ENEMY_TABLE := [
	{"kind": "serdadu", "from": 1, "weight": 6},
	{"kind": "anjing", "from": 3, "weight": 3},
	{"kind": "penembak", "from": 5, "weight": 2},
	{"kind": "perisai", "from": 7, "weight": 2},
	{"kind": "ranjau", "from": 9, "weight": 1},
	{"kind": "kavaleri", "from": 6, "weight": 2},
	{"kind": "granat", "from": 8, "weight": 2},
	{"kind": "tabib", "from": 11, "weight": 1},
	{"kind": "raksasa", "from": 13, "weight": 1},
]


## Host saja.
func start_wave(n: int) -> void:
	_start.rpc(n)


@rpc("authority", "call_local", "reliable")
func _start(n: int) -> void:
	wave = n
	time_left = minf(20.0 + (n - 1) * 5.0, 60.0)
	_duration = time_left
	_boss_spawned = false
	_spawn_cooldown = 1.0
	enemies.wave = n
	enemies.base_hp = 6 + n * 3
	enemies.base_speed = 45.0 + n * 2.0
	enemies.base_damage = 2 + n / 4
	running = true
	wave_started.emit(n)


func stop() -> void:
	running = false


func _process(delta: float) -> void:
	if not running:
		return
	time_left = maxf(time_left - delta, 0.0)
	if not multiplayer.is_server():
		return
	var player_factor := 1.0 + 0.6 * (players.get_child_count() - 1)
	# Boss tiap wave muncul di pertengahan (wave terakhir: di awal). Wave terakhir baru
	# selesai kalau Gubernur Jenderal tumbang, bukan karena waktu habis.
	if not _boss_spawned and (time_left <= _duration * 0.55 or (wave == LAST_WAVE and time_left <= _duration - 3.0)):
		_boss_spawned = true
		_spawn_boss(player_factor)
	var finished := time_left <= 0
	if wave == LAST_WAVE:
		finished = _boss_spawned and enemies.boss() == null
	if finished:
		running = false
		enemies.clear()
		pickups.clear()
		villagers.clear()
		_end.rpc(wave)
		return
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0:
		# shortcut: kurva kesulitan hardcode, pindah ke data/waves/*.tres di M4.
		_spawn_cooldown = maxf(1.2 - wave * 0.08, 0.3)
		var alive := _alive_players()
		for i in roundi((1 + wave / 3) * player_factor):
			if enemies.get_child_count() >= MAX_ENEMIES or alive.is_empty():
				break
			enemies.spawn_basic(_pick_kind(), _spawn_point(alive))


@rpc("authority", "call_local", "reliable")
func _end(n: int) -> void:
	running = false
	time_left = 0.0
	projectiles.clear()
	wave_ended.emit(n)


func _pick_kind() -> String:
	var options := ENEMY_TABLE.filter(func(t): return wave >= t.from)
	var total := 0
	for t in options:
		total += t.weight
	var r := randi() % total
	for t in options:
		r -= t.weight
		if r < 0:
			return t.kind
	return "serdadu"


func _spawn_boss(player_factor: float) -> void:
	var alive := _alive_players()
	if alive.is_empty():
		return
	var kind := "gubernur" if wave == LAST_WAVE else "mandor" if wave in [10, 15] \
		else "laksamana" if wave in [9, 12, 17] else "komandan"
	var hp: float = (30 + wave * 35) * player_factor * {"gubernur": 3.0, "mandor": 1.6, "laksamana": 1.8}.get(kind, 1.0)
	var t: Dictionary = enemies.TYPES[kind]
	enemies.spawn(kind, map.resolve(_spawn_point(alive), t.radius), roundi(hp),
		(45.0 + wave * 2.0) * t.speed, roundi((2 + wave / 4) * t.dmg))


func _alive_players() -> Array:
	return players.get_children().filter(func(p): return p.alive)


func _spawn_point(alive: Array) -> Vector2:
	var p := Vector2.ZERO
	for i in 10:
		p = Vector2(randf_range(16, arena_size.x - 16), randf_range(16, arena_size.y - 16))
		if alive.all(func(pl): return p.distance_to(pl.position) >= MIN_SPAWN_DISTANCE):
			break
	return map.resolve(p, 12.0)
