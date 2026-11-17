extends SceneTree
## Boss & musuh baru: tiap boss muncul, Gubernur menembak cincin peluru, memanggil pasukan,
## dan masuk fase 2 di bawah 50% HP; ranjau meledak melukai pemain; gabung senjata menaikkan tier.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/boss_test.gd

const EnemyBullet := preload("res://scripts/enemy_bullet.gd")

var frames := 0
var main: Node
var checks := {}
var hp_before := 0


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").start_solo()
		return false
	main = root.get_node_or_null("Main")
	if main == null or main.state != main.State.PLAYING:
		return false
	var e = main.enemies
	var p = main.local_player
	match frames:
		30:
			# Gabung senjata: sumpit awal + 2 sumpit = 1 slot tier 3, 3 peluru per tembakan.
			var sumpit := load("res://data/weapons/sumpit.tres")
			p.add_weapon(sumpit)
			p.add_weapon(sumpit)
			var w = p.weapon_ring.get_child(0)
			checks.merge_tier = p.weapons.size() == 1 and w.tier == 3
			p.position = Vector2(150, 270)
			e.wave = 20
			e.spawn("gubernur", Vector2(480, 270), 400, 40.0, 3)
			e.spawn("mandor", Vector2(700, 270), 200, 40.0, 3)
			for k in ["anjing", "penembak", "perisai", "ranjau"]:
				e.spawn_basic(k, Vector2(600, 100))
		40:
			checks.boss_hud = main.get_node("HUD/Boss").visible
			checks.all_kinds = ["gubernur", "mandor", "anjing", "penembak", "perisai", "ranjau"].all(
				func(k): return e.get_children().any(func(x): return x.kind == k))
		300:
			checks.bullets = main.projectiles.get_children().any(func(x): return x.get_script() == EnemyBullet)
			checks.summoned = e.get_children().filter(func(x): return x.kind == "serdadu").size() >= 3
			var g = e.get_children().filter(func(x): return x.kind == "gubernur")[0]
			g.hp = g.max_hp / 2 - 1
		330:
			var g = e.get_children().filter(func(x): return x.kind == "gubernur")[0]
			checks.phase2 = g.phase == 2
			# Ranjau tepat di bawah pemain harus meledak & melukai.
			p.revive()
			p._invuln = 0.0
			hp_before = p.hp
			e.place_mine(p.position)
		400:
			checks.mine_hurt = p.hp < hp_before or not p.alive
			var ok := checks.size() == 7 and checks.values().all(func(v): return v)
			print(checks, " -> ", "OK" if ok else "FAIL")
			quit(0 if ok else 1)
			return true
	return false
