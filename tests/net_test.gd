extends SceneTree
## Tes co-op lewat ENet lokal (logika sinkronisasi sama dengan WebRTC). Jalankan dua proses:
##   godot --headless -s res://tests/net_test.gd -- host
##   godot --headless -s res://tests/net_test.gd -- client
## Keduanya harus sampai wave 2 (lewat toko + tombol siap) dan melihat musuh yang sama.

const PORT := 47231
const TIMEOUT := 70.0

var role := ""
var elapsed := 0.0
var started := false
var readied_wave := 0
var max_enemies_seen := 0
var enemy_moved := false
var _first_pos := {}


func _initialize() -> void:
	role = OS.get_cmdline_user_args()[0]


func _process(delta: float) -> bool:
	elapsed += delta
	var net := root.get_node("Net")
	if not started:
		started = true
		net.my_name = role
		if role == "host":
			net.host_enet(PORT)
		else:
			net.join_enet("127.0.0.1", PORT)
		return false
	if role == "host" and not net.in_game and net.players.size() == 2:
		net.start_game()

	var main := root.get_node_or_null("Main")
	if main and main.local_player:
		var n: int = main.enemies.get_child_count()
		max_enemies_seen = maxi(max_enemies_seen, n)
		for e in main.enemies.get_children():
			if not _first_pos.has(e.name):
				_first_pos[e.name] = e.position
			elif e.position.distance_to(_first_pos[e.name]) > 10:
				enemy_moved = true
		if main.state == main.State.SHOP and readied_wave != main.waves.wave:
			readied_wave = main.waves.wave
			main.shop._on_ready()
		if main.waves.wave >= 2 and main.state == main.State.PLAYING:
			var ok: bool = main.players.get_child_count() == 2 and max_enemies_seen > 0 and enemy_moved
			_done(ok, main)
			return true
	if elapsed > TIMEOUT:
		_done(false, main)
		return true
	return false


func _done(ok: bool, main) -> void:
	print("[%s] players=%d wave=%d max_enemies=%d enemy_moved=%s -> %s" % [
		role, main.players.get_child_count() if main else 0, main.waves.wave if main else 0,
		max_enemies_seen, enemy_moved, "OK" if ok else "FAIL"])
	quit(0 if ok else 1)
