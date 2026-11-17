extends SceneTree
## Efek senjata saat kena: terbakar/racun/berdarah memberi damage per detik, lambat,
## dorong, ledakan area, dan peluru memantul ke musuh lain. Semua senjata baru termuat.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/weapon_test.gd

var frames := 0
var checks := {}
var e := {}
var start := {}


func _w(name: String) -> WeaponData:
	return load("res://data/weapons/%s.tres" % name)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").start_solo()
		return false
	var main := root.get_node_or_null("Main")
	if main == null or main.state != main.State.PLAYING:
		return false
	var en = main.enemies
	if e.is_empty():
		main.waves.stop()  # tanpa spawn acak
		main.local_player.position = Vector2(60, 60)
		main.local_player.stats.max_hp = 9999
		main.local_player.hp = 9999
		var spots := {"burn": Vector2(300, 400), "slow": Vector2(400, 400), "push": Vector2(500, 400),
			"boom": Vector2(700, 150), "boom2": Vector2(715, 150), "b1": Vector2(300, 150), "b2": Vector2(360, 150)}
		for k in spots:
			en.spawn("perisai", spots[k], 500, 0.0, 1)
			e[k] = en.get_child(en.get_child_count() - 1)
			start[k] = spots[k]
		# Dua senjata, dua musuh dalam jangkauan: masing-masing membidik musuh berbeda.
		var p = main.local_player
		p.add_weapon(_w("kunai"))
		var t0 = p.weapon_ring.get_child(0).pick_target(2000.0)
		var t1 = p.weapon_ring.get_child(1).pick_target(2000.0)
		checks.spread_targets = t0 != null and t1 != null and t0 != t1
		checks.new_weapons = ["kunai", "shuriken", "tombak", "bambu_runcing", "kujang", "golok"].all(func(n): return _w(n) != null)
		return false
	match frames - _first_frame():
		1:
			en.hit(e.burn, 1, _w("mantra_api"), Vector2.RIGHT)
			en.hit(e.slow, 1, _w("ketapel"), Vector2.RIGHT)
			en.hit(e.push, 1, _w("tombak"), Vector2.RIGHT)
			en.hit(e.boom, 10, _w("meriam_lela"), Vector2.RIGHT)
			# Shuriken ditembak ke b1: harus memantul ke b2.
			main.projectiles.fire(Vector2(260, 150), PackedVector2Array([Vector2.RIGHT]), _w("shuriken"), 5, 300.0)
		2:
			checks.slow = e.slow.statuses.has("slow")
			checks.knockback = e.push.position.x > start.push.x + 20
			checks.explode = e.boom2.hp < 500
		90:
			checks.burn_dot = e.burn.hp < 499 and e.burn.statuses.has("burn")
			checks.bounce = e.b1.hp < 500 and e.b2.hp < 500
			var ok := checks.size() == 7 and checks.values().all(func(v): return v)
			print(checks, " -> ", "OK" if ok else "FAIL")
			quit(0 if ok else 1)
			return true
	return false


var _ff := -1
func _first_frame() -> int:
	if _ff < 0:
		_ff = frames
	return _ff
