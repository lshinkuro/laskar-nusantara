extends SceneTree
## Smoke test solo tanpa input: pemain diam, wave 1 harus berakhir (toko terbuka atau gugur)
## dan senjata harus menembak. Jalankan:
##   godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd

var frames := 0
var saw_projectile := false
var saw_enemy := false


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").start_solo()
		return false
	var main := root.get_node_or_null("Main")
	if main == null:
		return false
	saw_projectile = saw_projectile or main.projectiles.get_child_count() > 0
	saw_enemy = saw_enemy or main.enemies.get_child_count() > 0
	if frames < 60 * 23:
		return false
	var ok: bool = saw_projectile and saw_enemy and main.state != main.State.PLAYING and main.state != main.State.WAITING
	print("wave=%d state=%d hp=%d rempah=%d enemy=%s projectile=%s shop=%s -> %s" % [
		main.waves.wave, main.state, main.local_player.hp, main.local_player.rempah,
		saw_enemy, saw_projectile, main.shop.visible, "OK" if ok else "FAIL"])
	quit(0 if ok else 1)
	return true
