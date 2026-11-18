extends SceneTree
## Pasar dengan tas berisi banyak item (tak terbatas) harus tetap muat di layar (tombol Siap terlihat).
var f := 0
func _process(_d):
	f += 1
	var m = root.get_node_or_null("Main")
	if f == 1:
		change_scene_to_file("res://scenes/menu.tscn")
	elif f == 10:
		root.get_node("Net").start_solo()
	elif f == 120:
		var p = m.local_player
		p.collect_rempah(500)
		for w in ["keris", "panah", "kunai", "shuriken", "cakra"]:
			p.add_weapon(load("res://data/weapons/%s.tres" % w))
		for n in ["rendang", "ulos", "songket", "jamu_kunyit", "kopi_tubruk", "wayang_kulit", "batu_akik", "kentongan", "obor_bambu", "lurik", "gudeg", "kerupuk", "rendang", "ulos", "songket", "jamu_kunyit", "kopi_tubruk", "batu_akik", "lurik", "gudeg", "kerupuk", "rendang", "ulos", "songket"]:
			p.apply_item(load("res://data/items/%s.tres" % n))
		m.waves.wave = 5
		m.local_player.pending_levels = 0
		m._on_wave_ended(5)
	elif f == 200:
		var vp: Vector2 = root.get_visible_rect().size
		var frame: Rect2 = m.shop._frame.get_global_rect()
		var ready: Rect2 = m.shop._ready_btn.get_global_rect()
		var ok: bool = frame.end.x <= vp.x + 1 and ready.end.x <= vp.x and ready.end.y <= vp.y
		print("frame=", frame, " ready=", ready, " vp=", vp, " -> ", "PASS" if ok else "FAIL")
		quit(0 if ok else 1)
	return false
