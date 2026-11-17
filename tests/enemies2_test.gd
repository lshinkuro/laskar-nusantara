extends SceneTree
## Musuh & map baru: Raksasa Baja pecah jadi 2 serdadu, Tabib memulihkan teman, Pelempar Granat
## membuat area ledakan, Kavaleri bersiap menyeruduk, Laksamana menembak kipas; laut Pelabuhan
## tidak bisa diinjak; urutan 5 medan per wave benar.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/enemies2_test.gd


var frames := 0
var start := -1
var checks := {}
var hurt


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").start_solo()
		return false
	var main := root.get_node_or_null("Main")
	if main == null or main.state != main.State.PLAYING:
		return false
	var e = main.enemies
	var p = main.local_player
	if start < 0:
		start = frames
		main.waves.stop()
		e._clear()
		p.stats.max_hp = 99999
		p.hp = 99999
		p.weapon_ring.process_mode = Node.PROCESS_MODE_DISABLED  # tanpa tembakan pemain
		p.position = Vector2(480, 270)
		e.wave = 12
		e.spawn("tabib", Vector2(300, 150), 100, 0.0, 1)
		e.spawn("serdadu", Vector2(320, 150), 100, 0.0, 1)
		e.spawn("granat", Vector2(600, 270), 100, 30.0, 1)
		e.spawn("kavaleri", Vector2(480, 120), 100, 30.0, 1)
		e.spawn("laksamana", Vector2(700, 400), 500, 20.0, 2)
		e.spawn("raksasa", Vector2(200, 400), 10, 0.0, 1)
		return false
	var f := frames - start
	if f == 2:
		hurt = e.get_children().filter(func(x): return x.kind == "serdadu")[0]
		hurt.hp = 40
		var raksasa = e.get_children().filter(func(x): return x.kind == "raksasa")[0]
		e._apply_hit(raksasa.id, 999, "", 0.0, Vector2.ZERO, 1)
	if f == 5:
		checks.raksasa_split = e.get_children().filter(func(x): return x.kind == "serdadu" and x.position.distance_to(Vector2(200, 400)) < 40).size() == 2
	if f == 60 * 5:
		checks.tabib_heal = hurt.hp > 40
		checks.kavaleri_dash = e.get_children().any(func(x): return x.kind == "kavaleri" and (x._dash > 0 or x._telegraph > 0 or x._timers.dash > 0))
		checks.fan_bullets = main.projectiles.get_children().any(func(x): return _is(x, "enemy_bullet.gd"))
		# Laut pelabuhan menghalangi.
		main.map.set_map(2)
		checks.sea_blocks = main.map.resolve(Vector2(400, 500), 8.0).y < main.map.SEA_TOP
		checks.map_order = ["LEMBAH SUNGAI", "HUTAN KALIMANTAN", "PELABUHAN SUNDA KELAPA", "DESA & CANDI", "BENTENG BESI"] == [1, 5, 9, 13, 17].map(func(w): return main.map.MAPS[main.map.index_for_wave(w)].name)
		checks.granat_slam = _slams > 0
		var ok := checks.values().all(func(v): return v)
		print(checks, " slams=", _slams, " -> ", "OK" if ok else "FAIL")
		quit(0 if ok else 1)
		return true
	_slams += main.projectiles.get_children().filter(func(x): return _is(x, "slam.gd")).size()
	return false


var _slams := 0


func _is(node: Node, script_file: String) -> bool:
	return node.get_script() != null and node.get_script().resource_path.ends_with(script_file)
