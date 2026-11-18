extends Sprite2D
## Rempah (pala) atau ketupat (+HP) yang dijatuhkan musuh. Tertarik ke pemain lokal yang mendekat.

var id := 0
var value := 1
var kind := "rempah"  # rempah / ketupat / peti
var granted := false  # dipakai host
var _claimed := false
var _t := randf() * TAU


func _physics_process(delta: float) -> void:
	_t += delta * 4.0
	offset.y = sin(_t) * 1.5 * Art.SCALE  # melayang naik-turun pelan (offset dalam piksel tekstur)
	var player = get_parent().local_player
	if player == null or not player.alive:
		return
	var d := position.distance_to(player.position)
	# Ketupat tidak diambil kalau HP masih penuh, biar tersisa untuk teman.
	if kind == "ketupat" and not _claimed and player.hp >= player.stats.max_hp:
		return
	if not _claimed and d < player.pickup_range():
		_claimed = true
		get_parent().claim(self)
	if _claimed and d > 4:
		position = position.move_toward(player.position, 260.0 * delta)
