extends SceneTree
## Smoke test tanpa input: pemain diam, wave 1 harus berakhir (selesai atau gugur) dalam ~21 detik.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/smoke_test.gd

var main: Node
var frames := 0
var saw_projectile := false


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frames += 1
	saw_projectile = saw_projectile or get_node_count_in_group("projectiles") > 0
	if frames < 60 * 21:
		return false
	var ok: bool = saw_projectile and main.state != main.State.PLAYING
	print("wave=%d state=%d hp=%d projectile=%s -> %s" % [main.waves.wave, main.state, main.player.hp, saw_projectile, "OK" if ok else "FAIL"])
	quit(0 if ok else 1)
	return true
