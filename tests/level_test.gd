extends SceneTree
## XP & level up: 30 XP -> level 3 (butuh 10 + 15), 2 pilihan ilmu tertunda.
## Akhir wave: layar ilmu muncul dulu, setelah 2 pilihan baru toko terbuka.
## Ketupat: heal +3 tapi tidak lewat HP maks.
## Jalankan: godot --headless -s res://tests/level_test.gd

var frames := 0


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").start_solo()
	var main := root.get_node_or_null("Main")
	if main == null or frames < 10:
		return false
	var p = main.local_player
	var hp_before: int = p.stats.max_hp
	p.gain_xp(30)
	var ok: bool = p.level == 3 and p.xp == 5 and p.pending_levels == 2 and p.stats.max_hp == hp_before + 2
	main._on_wave_ended(1)
	ok = ok and main.level_up.visible and not main.shop.visible
	var stats_before: Dictionary = p.stats.duplicate()
	main.level_up.choose(main.level_up.UPGRADES[0])
	ok = ok and main.level_up.visible and p.pending_levels == 1
	main.level_up.choose(main.level_up.UPGRADES[1])
	ok = ok and not main.level_up.visible and main.shop.visible and p.pending_levels == 0
	ok = ok and p.stats.max_hp == stats_before.max_hp + 3 and p.stats.damage == stats_before.damage + 8
	p._invuln = 0.0
	p.take_damage(5)
	var hurt: int = p.hp
	p.heal(3)
	ok = ok and p.hp == hurt + 3
	p.heal(100)
	ok = ok and p.hp == p.stats.max_hp
	print("level=%d xp=%d max_hp=%d damage=%d shop=%s -> %s" % [p.level, p.xp, p.stats.max_hp, p.stats.damage, main.shop.visible, "OK" if ok else "FAIL"])
	quit(0 if ok else 1)
	return true
