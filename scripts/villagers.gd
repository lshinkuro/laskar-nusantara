extends Node2D
## World/Villagers: warga terkurung untuk mekanik Semangat Rakyat. Host memunculkan warga,
## pemain membebaskannya untuk mengisi meter Semangat.

const Warga := preload("res://scripts/warga.gd")
const Fx := preload("res://scripts/fx.gd")
const FIRST_SPAWN := 5.0
const SPAWN_INTERVAL := 13.0
const MAX_ALIVE := 2
const SEMANGAT_REWARD := 35.0

signal first_seen

@export var players: Node2D
@export var map: Node2D
@export var waves: Node

var local_player: Node2D  # diisi main
var _next_id := 1
var _timer := FIRST_SPAWN
var _seen := false


func _process(delta: float) -> void:
	if not multiplayer.is_server() or not waves.running:
		return
	for w in get_children():
		if w.age > w.LIFETIME:
			_remove.rpc(w.id, false)
	_timer -= delta
	if _timer > 0:
		return
	_timer = SPAWN_INTERVAL
	if get_child_count() >= MAX_ALIVE:
		return
	var alive := players.get_children().filter(func(p): return p.alive)
	if alive.is_empty():
		return
	var arena: Vector2 = waves.arena_size
	var pos := Vector2.ZERO
	for i in 15:
		pos = Vector2(randf_range(40, arena.x - 40), randf_range(50, arena.y - 30))
		if alive.all(func(p): return p.position.distance_to(pos) > 140):
			break
	_spawn.rpc(_next_id, map.resolve(pos, 16.0))
	_next_id += 1


@rpc("authority", "call_local", "reliable")
func _spawn(id: int, pos: Vector2) -> void:
	var w := Warga.new()
	w.name = "W%d" % id
	w.id = id
	w.position = pos
	w.villagers = self
	add_child(w)
	if not _seen:
		_seen = true
		first_seen.emit()


func request_rescue(id: int) -> void:
	if multiplayer.is_server():
		_grant(id, multiplayer.get_unique_id())
	else:
		_request_rescue.rpc_id(1, id)


@rpc("any_peer", "reliable")
func _request_rescue(id: int) -> void:
	if multiplayer.is_server():
		_grant(id, multiplayer.get_remote_sender_id())


func _grant(id: int, peer: int) -> void:
	if get_node_or_null("W%d" % id):
		_rescued.rpc(id, peer)


@rpc("authority", "call_local", "reliable")
func _rescued(id: int, peer: int) -> void:
	var w := get_node_or_null("W%d" % id)
	if w == null:
		return
	Fx.ring(get_parent(), w.position, 36.0, Color(1, 0.9, 0.4))
	Fx.spark(get_parent(), w.position + Vector2(0, -14), Color(1, 0.95, 0.6), 16)
	if peer == multiplayer.get_unique_id():
		local_player.add_semangat(SEMANGAT_REWARD)
		local_player.collect_rempah(3)
		Sfx.play("heal", -2.0, 0.0)
		var DamageNumber := preload("res://scripts/damage_number.gd")
		DamageNumber.spawn(self, w.position + Vector2(0, -40), 0, Color(1, 0.9, 0.4), "Terima kasih! ")
	w.queue_free()


@rpc("authority", "call_local", "reliable")
func _remove(id: int, _rescued_flag: bool) -> void:
	var w := get_node_or_null("W%d" % id)
	if w:
		Fx.spark(get_parent(), w.position, Color(0.5, 0.5, 0.5), 8)
		w.queue_free()


## Host saja.
func clear() -> void:
	_timer = FIRST_SPAWN
	_clear.rpc()


@rpc("authority", "call_local", "reliable")
func _clear() -> void:
	for w in get_children():
		w.queue_free()
