extends Node2D
## World/Pickups: rempah dibuat host saat musuh mati. Pemain lokal yang mendekat
## "mengklaim" ke host; host memberi ke pengklaim pertama.

const Rempah := preload("res://scenes/rempah.tscn")

var local_player: Node2D  # diisi main
var _next_id := 1


## Host saja.
func spawn(pos: Vector2, value: int) -> void:
	_spawn.rpc(_next_id, pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)), value)
	_next_id += 1


@rpc("authority", "call_local", "reliable")
func _spawn(id: int, pos: Vector2, value: int) -> void:
	var r := Rempah.instantiate()
	r.name = "R%d" % id
	r.id = id
	r.value = value
	r.position = pos
	add_child(r)


## Dipanggil rempah saat pemain lokal cukup dekat.
func claim(r: Node) -> void:
	if multiplayer.is_server():
		_grant(r.id, multiplayer.get_unique_id())
	else:
		_request_claim.rpc_id(1, r.id)


@rpc("any_peer", "reliable")
func _request_claim(id: int) -> void:
	if multiplayer.is_server():
		_grant(id, multiplayer.get_remote_sender_id())


func _grant(id: int, peer: int) -> void:
	var r := get_node_or_null("R%d" % id)
	if r == null or r.granted:
		return
	r.granted = true
	_collected.rpc(id, peer)


@rpc("authority", "call_local", "reliable")
func _collected(id: int, peer: int) -> void:
	var r := get_node_or_null("R%d" % id)
	if r == null:
		return
	if peer == multiplayer.get_unique_id():
		local_player.collect_rempah(r.value)
	r.queue_free()


## Host saja.
func clear() -> void:
	_clear.rpc()


@rpc("authority", "call_local", "reliable")
func _clear() -> void:
	for r in get_children():
		r.queue_free()
