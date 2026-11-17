extends Node2D
## World/Enemies: musuh disimulasikan di host; client hanya menampilkan posisi
## hasil sinkronisasi. Damage dilaporkan pemilik peluru ke host.

const Enemy := preload("res://scenes/enemy.tscn")
const SYNC_INTERVAL := 0.05

@export var players: Node2D  # World/Players
@export var pickups: Node  # World/Pickups

var _next_id := 1
var _sync := 0.0


## Host saja.
func spawn(pos: Vector2, max_hp: int, speed: float, damage: int) -> void:
	_spawn.rpc(_next_id, pos, max_hp, speed, damage)
	_next_id += 1


@rpc("authority", "call_local", "reliable")
func _spawn(id: int, pos: Vector2, max_hp: int, speed: float, damage: int) -> void:
	var e := Enemy.instantiate()
	e.name = "E%d" % id
	e.id = id
	e.position = pos
	e.max_hp = max_hp
	e.speed = speed
	e.damage = damage
	e.players = players
	e.simulate = multiplayer.is_server()
	add_child(e)


## Dipanggil peluru milik pemain lokal.
func hit(enemy: Node, amount: int) -> void:
	enemy.flash(amount)
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
	if e.hp <= 0:
		pickups.spawn(e.position, 1)
		_kill.rpc(id)


@rpc("authority", "call_local", "reliable")
func _kill(id: int) -> void:
	var e := get_node_or_null("E%d" % id)
	if e:
		e.die()


## Host saja.
func clear() -> void:
	_clear.rpc()


@rpc("authority", "call_local", "reliable")
func _clear() -> void:
	for e in get_children():
		e.queue_free()


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


@rpc("authority", "unreliable_ordered")
func _sync_positions(ids: PackedInt32Array, positions: PackedVector2Array) -> void:
	for i in ids.size():
		var e := get_node_or_null("E%d" % ids[i])
		if e:
			e.target_pos = positions[i]
