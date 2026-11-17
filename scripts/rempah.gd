extends Sprite2D
## Rempah (pala) yang dijatuhkan musuh. Tertarik ke pemain lokal yang mendekat.

var id := 0
var value := 1
var granted := false  # dipakai host
var _claimed := false


func _physics_process(delta: float) -> void:
	var player = get_parent().local_player
	if player == null or not player.alive:
		return
	var d := position.distance_to(player.position)
	if not _claimed and d < player.pickup_range():
		_claimed = true
		get_parent().claim(self)
	if _claimed and d > 4:
		position = position.move_toward(player.position, 260.0 * delta)
