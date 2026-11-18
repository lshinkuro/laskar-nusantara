extends SceneTree
## Karakter: Pendekar mulai dengan keris & bonus melee/penalti ranged; panen +30% rempah;
## menghindar maks 60%; karakter terbuka sesuai wave tertinggi; 10 karakter bergambar; tingkat kesulitan.
## Jalankan: godot --headless -s res://tests/character_test.gd

var frames := 0
var saved_best := 0


func _process(_delta: float) -> bool:
	frames += 1
	var net := root.get_node("Net")
	if frames == 2:
		saved_best = net.best_wave
		net.my_character = 0  # Pendekar Silat
		net.start_solo()
		return false
	var main := root.get_node_or_null("Main")
	if main == null or main.state != main.State.PLAYING:
		return false
	var p = main.local_player
	var checks := {}
	checks.keris = p.weapon_ring.get_child(0).data.title == "Keris"
	checks.melee = is_equal_approx(p.damage_multiplier("melee"), 1.5)
	checks.ranged = is_equal_approx(p.damage_multiplier("ranged"), 0.7)
	p.apply_stats({"harvest": 30})
	var before: int = p.rempah
	p.collect_rempah(10)
	checks.harvest = p.rempah == before + 13
	p.apply_stats({"dodge": 100, "max_hp": 1000})
	p.hp = p.stats.max_hp
	var hits := 0
	for i in 200:
		p._invuln = 0.0
		var hp_before: int = p.hp
		p.take_damage(1)
		if p.hp < hp_before:
			hits += 1
	checks.dodge = hits > 40 and hits < 120  # ~40% kena (maks 60% menghindar)
	net.best_wave = 0
	var unlocked: Array = net.record_wave(4).map(func(c): return c.title)
	var unlocked2: Array = net.record_wave(8).map(func(c): return c.title)
	checks.unlock = unlocked == ["Pemburu Dayak", "Dukun"] and unlocked2 == ["Pecalang Bali", "Pelaut Bugis"] and net.record_wave(5).is_empty()
	checks.portraits = net.characters.size() == 10 and net.characters.all(func(c): return c.portrait != null and c.start_weapon != null)
	# Kesulitan: Neraka membuat musuh wave 10 jauh lebih tebal dari Mudah.
	var hp := {}
	for d in [0, 3]:
		net.difficulty = d
		main.waves._start(10)
		hp[d] = main.enemies.base_hp
	net.difficulty = 1
	main.waves.stop()
	checks.difficulty = hp[3] > hp[0] * 3
	# Kembalikan progres asli.
	net.best_wave = -1
	net.record_wave(saved_best)
	var ok := checks.values().all(func(v): return v)
	print(checks, " hits=", hits, " -> ", "OK" if ok else "FAIL")
	quit(0 if ok else 1)
	return true
