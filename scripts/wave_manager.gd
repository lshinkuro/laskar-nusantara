extends Node
## Mengatur timer wave dan spawn musuh. Musuh di-spawn ke parent (World).

signal wave_started(wave: int)
signal wave_cleared(wave: int)

const Enemy := preload("res://scenes/enemy.tscn")
const LAST_WAVE := 20
const MAX_ENEMIES := 150
const MIN_SPAWN_DISTANCE := 150.0

@export var player: Node2D

var wave := 0
var time_left := 0.0
var running := false
var _spawn_cooldown := 0.0


func start_next_wave() -> void:
	wave += 1
	time_left = minf(20.0 + (wave - 1) * 5.0, 60.0)
	_spawn_cooldown = 0.5
	running = true
	wave_started.emit(wave)


func stop() -> void:
	running = false


func _process(delta: float) -> void:
	if not running:
		return
	time_left -= delta
	if time_left <= 0:
		_end_wave()
		return
	_spawn_cooldown -= delta
	if _spawn_cooldown <= 0:
		# shortcut: kurva kesulitan hardcode, pindah ke data/waves/*.tres di M3–M4.
		_spawn_cooldown = maxf(1.2 - wave * 0.08, 0.3)
		for i in 1 + wave / 3:
			_spawn()


func _spawn() -> void:
	if get_tree().get_node_count_in_group("enemies") >= MAX_ENEMIES:
		return
	var e := Enemy.instantiate()
	e.max_hp = 6 + wave * 3
	e.speed = 50.0 + wave * 2.0
	e.target = player
	e.position = _spawn_point()
	get_parent().add_child(e)


func _spawn_point() -> Vector2:
	var arena: Vector2 = player.arena_size
	var p := Vector2.ZERO
	for i in 10:
		p = Vector2(randf_range(16, arena.x - 16), randf_range(16, arena.y - 16))
		if p.distance_to(player.position) >= MIN_SPAWN_DISTANCE:
			break
	return p


func _end_wave() -> void:
	running = false
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("projectiles", "queue_free")
	wave_cleared.emit(wave)
