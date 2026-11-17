extends SceneTree
## Semangat Rakyat: warga muncul sendiri saat wave berjalan; berdiri di dekatnya membebaskan
## (+35 semangat); kill menambah semangat; Pekik Merdeka saat penuh melukai & mendorong musuh,
## memulihkan HP, dan mengosongkan meter.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/semangat_test.gd

var frames := 0
var start := -1
var checks := {}
var p
var e1
var e1_pos := Vector2.ZERO


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").start_solo()
		return false
	var main := root.get_node_or_null("Main")
	if main == null or main.state != main.State.PLAYING:
		return false
	if start < 0:
		start = frames
		p = main.local_player
		p.stats.max_hp = 999
		p.hp = 999
		return false
	var f := frames - start
	var v = main.villagers
	if f == 60 * 6:
		checks.auto_spawn = v.get_child_count() >= 1
		main.waves.stop()
		get_root().get_node("Main/World/Enemies")._clear()
		v._clear()
		v._spawn(99, Vector2(300, 300))
		p.position = Vector2(300, 300)
	if f == 60 * 6 + 2:
		p.position = Vector2(300, 300)  # tetap di dekat warga selama dibebaskan
	if f == 60 * 8:
		checks.rescued = v.get_node_or_null("W99") == null and p.semangat >= 35.0
		p.add_semangat(100)
		p.hp = 500
		main.enemies.spawn("perisai", p.position + Vector2(60, 0), 9999, 0.0, 1)
	if f == 60 * 8 + 3:
		e1 = main.enemies.get_child(main.enemies.get_child_count() - 1)
		e1_pos = e1.position
		checks.pekik_ready = main.get_node("HUD/Pekik").visible
		main._use_semangat()
		checks.used = p.semangat == 0.0 and p.hp > 500
	if f == 60 * 8 + 6:
		checks.pekik_hit = e1.hp < 9999 and e1.position.x > e1_pos.x + 20
		var ok := checks.size() == 5 and checks.values().all(func(x): return x)
		print(checks, " -> ", "OK" if ok else "FAIL")
		quit(0 if ok else 1)
		return true
	return false
