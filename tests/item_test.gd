extends SceneTree
## Item unik & sinergi: bonus sinergi masuk sekali (tidak dobel), wayang menembak tanpa makan slot,
## kalung taring, obor, jimat, gelang akar bahar, kentongan, lumbung, meriam jaga, dan bobot kelangkaan toko.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/item_test.gd

var frames := 0
var start := -1
var checks := {}
var p
var e1
var e2


func _item(n: String) -> ItemData:
	return load("res://data/items/%s.tres" % n)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").my_character = 0  # Pendekar: mulai dengan keris (melee)
		root.get_node("Net").start_solo()
		return false
	var main := root.get_node_or_null("Main")
	if main == null or main.state != main.State.PLAYING:
		return false
	if start < 0:
		start = frames
		main.waves.stop()
		p = main.local_player
		p.position = Vector2(480, 270)
		# Sinergi Jurus Silat: 3 senjata jarak dekat.
		var melee_before: int = p.stats.melee_damage
		p.add_weapon(load("res://data/weapons/tombak.tres"))
		p.add_weapon(load("res://data/weapons/golok.tres"))
		checks.melee_before = melee_before
		# Sinergi Kuliner: 4 item kuliner tetap +6 HP maks sekali (bukan dobel).
		var hp_before: int = p.stats.max_hp
		for n in ["rendang", "kerupuk", "es_dawet", "kopi_tubruk"]:
			p.apply_item(_item(n))
		checks.kuliner_once = p.stats.max_hp == hp_before + 5 + 6  # rendang +5, sinergi +6
		for n in ["wayang_kulit", "kalung_taring", "obor_bambu", "jimat_rajah", "gelang_akar_bahar", "kentongan", "lumbung_padi"]:
			p.apply_item(_item(n))
		main.enemies.spawn("perisai", p.position + Vector2(40, 0), 999, 0.0, 1)
		main.enemies.spawn("perisai", p.position + Vector2(-150, 0), 999, 0.0, 1)
		return false
	var f := frames - start
	var en = main.enemies
	if f == 2:
		e1 = en.get_child(0)
		e2 = en.get_child(1)
		checks.jurus_silat = p.stats.melee_damage == checks.melee_before + 20
		checks.wayang = p.get_node("Allies").get_child_count() == 1 and p.weapons.size() == 3
		checks.burn = p.modify_hit("", 0.0)[0] == "burn" or p.specials.burn_chance == 15.0
		# Jimat: pukulan maut pertama -> 1 HP.
		p._invuln = 0.0
		p.take_damage(9999)
		checks.jimat = p.alive and p.hp == 1
		# Gelang akar bahar: pukulan biasa melukai musuh dekat.
		p.hp = p.stats.max_hp
		p._invuln = 0.0
		p.stats.dodge = 0
		var e1_before: int = e1.hp
		p.take_damage(1)
		checks.thorns = e1.hp < e1_before
		p._invuln = 0.0
		p.hp = p.stats.max_hp - 3
		p.collect_rempah(6)
		checks.lumbung = p.hp >= p.stats.max_hp - 2
		# Meriam Jaga: 2 item -> 2 meriam di arena saat wave mulai, dipasang ulang (tidak menumpuk).
		p.apply_item(_item("meriam_jaga"))
		p.apply_item(_item("meriam_jaga"))
		p.revive()
		p.revive()
		checks.turret = p._turrets.size() == 2 and p._turrets.all(func(t): return t.turret and t.get_parent() == p.get_parent().get_parent())
	if f == 3:
		# Kentongan saja: matikan senjata & sekutu, picu gelombang, musuh dalam 90 px kena.
		p.weapon_ring.process_mode = Node.PROCESS_MODE_DISABLED
		p.get_node("Allies").process_mode = Node.PROCESS_MODE_DISABLED
		e2.position = p.position + Vector2(-80, 0)
		e2.hp = 999
		p._pulse = 0.01
	if f == 20:
		checks.pulse = e2.hp < 999
		var shop = main.shop
		shop.player = p
		shop.wave = 1
		var w1: float = shop._rarity_weight(3)
		shop.wave = 20
		checks.rarity = shop._rarity_weight(3) > w1 * 2  # legendaris jauh lebih sering di wave akhir
		checks.erase("melee_before")
		var ok := checks.size() == 10 and checks.values().all(func(v): return v)
		print(checks, " -> ", "OK" if ok else "FAIL")
		quit(0 if ok else 1)
		return true
	return false
