extends Node2D
## World/Pickups: rempah, ketupat, & Peti Pusaka dibuat host saat musuh mati. Pemain lokal yang
## mendekat "mengklaim" ke host; host memberi ke pengklaim pertama.

const Rempah := preload("res://scenes/rempah.tscn")
const KETUPAT_TEXTURE := preload("res://assets/sprites/ketupat.png")
const PETI_TEXTURE := preload("res://assets/sprites/peti_pusaka.png")
## Rempah tampil acak (nilainya sama): pala, cengkeh, lada, kayu manis, bunga lawang, kepeng.
const REMPAH_TEXTURES := [
	preload("res://assets/sprites/rempah.png"),
	preload("res://assets/sprites/rempah_cengkeh.png"),
	preload("res://assets/sprites/rempah_lada.png"),
	preload("res://assets/sprites/rempah_kayu_manis.png"),
	preload("res://assets/sprites/rempah_bunga_lawang.png"),
	preload("res://assets/sprites/rempah_kepeng.png"),
]

## Pemain lokal membuka Peti Pusaka (main memberi isinya).
signal chest_opened
const KETUPAT_HEAL := 3

var local_player: Node2D  # diisi main
var _next_id := 1


## Host saja.
func spawn(pos: Vector2, value: int, kind := "rempah") -> void:
	_spawn.rpc(_next_id, pos + Vector2(randf_range(-6, 6), randf_range(-6, 6)), value, kind)
	_next_id += 1


@rpc("authority", "call_local", "reliable")
func _spawn(id: int, pos: Vector2, value: int, kind: String) -> void:
	var r := Rempah.instantiate()
	r.name = "R%d" % id
	r.id = id
	r.value = value
	r.kind = kind
	r.position = pos
	if kind == "ketupat":
		r.texture = KETUPAT_TEXTURE
	elif kind == "peti":
		r.texture = PETI_TEXTURE
	else:
		r.texture = REMPAH_TEXTURES.pick_random()
		r.flip_h = randf() < 0.5
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
		if r.kind == "ketupat":
			local_player.heal(KETUPAT_HEAL)
			Sfx.play("heal", -4.0, 0.0)
		elif r.kind == "peti":
			chest_opened.emit()
			Sfx.play("levelup", -2.0, 0.0)
		else:
			local_player.collect_rempah(r.value)
			Sfx.play("pickup", -10.0, 0.12)
	r.queue_free()


## Host saja.
func clear() -> void:
	_clear.rpc()


@rpc("authority", "call_local", "reliable")
func _clear() -> void:
	for r in get_children():
		r.queue_free()
