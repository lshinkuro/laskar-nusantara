extends SceneTree
## Musik berganti sesuai suasana: menu -> medan wave 1 -> boss -> medan -> pasar (toko);
## semua lagu ter-loop; crossfade menghentikan lagu lama.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/music_test.gd

var frames := 0
var start := -1
var checks := {}


func _process(_delta: float) -> bool:
	frames += 1
	var sfx = root.get_node("Sfx")
	if frames == 1:
		change_scene_to_file("res://scenes/menu.tscn")
	if frames == 10:
		checks.menu = sfx.current_track() == "menu"
		checks.loops = sfx.MUSIC.values().all(func(s): return s.loop_mode != AudioStreamWAV.LOOP_DISABLED)
		root.get_node("Net").start_solo()
	var main := root.get_node_or_null("Main")
	if frames > 900:
		print(checks, " -> FAIL (timeout)")
		quit(1)
		return true
	if main == null or (start < 0 and main.state != main.State.PLAYING):
		return false
	if start < 0:
		start = frames
		checks.map_track = sfx.current_track() == "lembah"
		main.enemies.spawn("komandan", Vector2(200, 200), 9999, 0.0, 1)
		return false
	var f := frames - start
	if f == 3:
		checks.boss = sfx.current_track() == "boss"
		main.enemies._clear()
	if f == 6:
		checks.back_to_map = sfx.current_track() == "lembah"
		main.waves._end(1)
	if f == 9:
		checks.pasar = sfx.current_track() == "pasar"
	if f == 120:
		var playing: Array = sfx._music_players.filter(func(p): return p.playing)
		checks.one_playing_after_fade = playing.size() == 1
		var ok := checks.size() == 7 and checks.values().all(func(v): return v)
		print(checks, " -> ", "OK" if ok else "FAIL")
		quit(0 if ok else 1)
		return true
	return false
