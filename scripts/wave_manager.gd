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
@export var arena_size := Vector2(960, 540)

var wave := 0
var time_left := 0.0
var running := false
var _spawn_cooldown := 0.0


## Host saja.
func start_wave(n: int) -> void:
	_start.rpc(n)


@rpc("authority", "call_local", "reliable")
func _start(n: int) -> void:
	wave = n
	time_left = minf(20.0 + (n - 1) * 5.0, 60.0)
	_spawn_cooldown = 1.0
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
	if time_left <= 0:
		running = false
		enemies.clear()
		pickups.clear()
		_end.rpc(wave)
		return
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0:
		# shortcut: kurva kesulitan hardcode, pindah ke data/waves/*.tres di M4.
		_spawn_cooldown = maxf(1.2 - wave * 0.08, 0.3)
		var alive := _alive_players()
		var count := (1 + wave / 3) * (1.0 + 0.6 * (players.get_child_count() - 1))
		for i in roundi(count):
			if enemies.get_child_count() >= MAX_ENEMIES or alive.is_empty():
				break
			enemies.spawn(_spawn_point(alive), 6 + wave * 3, 45.0 + wave * 2.0, 2 + wave / 4)


@rpc("authority", "call_local", "reliable")
func _end(n: int) -> void:
	running = false
	time_left = 0.0
	projectiles.clear()
	wave_ended.emit(n)


func _alive_players() -> Array:
	return players.get_children().filter(func(p): return p.alive)


func _spawn_point(alive: Array) -> Vector2:
	var p := Vector2.ZERO
	for i in 10:
		p = Vector2(randf_range(16, arena_size.x - 16), randf_range(16, arena_size.y - 16))
		if alive.all(func(pl): return p.distance_to(pl.position) >= MIN_SPAWN_DISTANCE):
			break
	return map.resolve(p, 12.0)
