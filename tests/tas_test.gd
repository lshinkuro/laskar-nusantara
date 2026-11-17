extends SceneTree
## Tas Pusaka: 2 item sama -> Lv2 (efek 2.5x, stat tidak bocor), lepas item mengembalikan stat
## & memberi rempah; senjata baru mengisi slot, 2 setier digabung -> tier naik & slot lega;
## senjata terakhir tidak bisa dilepas; Peti Pusaka dari boss memberi isi ke tas.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/tas_test.gd

var frames := 0
var start := -1
var checks := {}


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").start_solo()
		return false
	var main := root.get_node_or_null("Main")
	if main == null or main.state != main.State.PLAYING:
		return false
	var p = main.local_player
	if start < 0:
		start = frames
		main.waves.stop()
		var rendang: ItemData = load("res://data/items/rendang.tres")  # +5 HP maks
		var hp0: int = p.stats.max_hp
		p.apply_item(rendang)
		p.apply_item(rendang)
		var hp2: int = p.stats.max_hp
		checks.combine_item = p.combine_item(0) and p.items.size() == 1 and p.item_levels[0] == 2
		checks.lv2_stronger = p.stats.max_hp == hp0 + roundi(5 * 2.5) and p.stats.max_hp > hp2
		var refund: int = p.remove_item(0)
		checks.remove_item = p.stats.max_hp == hp0 and p.items.is_empty() and refund > 0
		# Senjata: beli yang sama -> slot baru, lalu gabung manual.
		var start_w = p.weapon_ring.get_child(0)
		p.add_weapon(start_w.data)
		checks.new_slot = p.weapons.size() == 2
		checks.combine_weapon = p.combine_weapon(start_w) and p.weapons.size() == 1 and start_w.tier == 2
		checks.keep_last = p.sell_weapon(start_w) == 0 and p.weapons.size() == 1
		# Wayang Lv2 -> 2 sekutu, dilepas -> 0.
		var wayang: ItemData = load("res://data/items/wayang_kulit.tres")
		p.apply_item(wayang)
		p.apply_item(wayang)
		p.combine_item(0)
		var allies_lv2: int = p.get_node("Allies").get_child_count()
		p.remove_item(0)
		checks.wayang_allies = allies_lv2 >= 2 and p.get_node("Allies").get_child_count() == 0
		# Peti Pusaka dari boss (senjata dimatikan supaya boss mati lewat tes).
		p.weapon_ring.process_mode = Node.PROCESS_MODE_DISABLED
		main.enemies.spawn("komandan", p.position + Vector2(150, 0), 5, 0.0, 1)
		return false
	var f := frames - start
	if f == 3:
		var boss = main.enemies.boss()
		main.enemies._apply_hit(boss.id, 999, "", 0.0, Vector2.ZERO, 1)
	if f == 4:
		checks.chest_dropped = main.pickups.get_children().any(func(r): return r.kind == "peti")
		_bag_before = p.items.size() + p.weapons.size() + p.weapon_ring.get_children().reduce(func(a, w): return a + w.tier, 0)
		p.position = main.pickups.get_children().filter(func(r): return r.kind == "peti")[0].position
	if f == 90:
		var bag_after: int = p.items.size() + p.weapons.size() + p.weapon_ring.get_children().reduce(func(a, w): return a + w.tier, 0)
		checks.chest_loot = bag_after > _bag_before or p.rempah >= 20
		var ok := checks.size() == 9 and checks.values().all(func(v): return v)
		print(checks, " -> ", "OK" if ok else "FAIL")
		quit(0 if ok else 1)
		return true
	return false


var _bag_before := 0
