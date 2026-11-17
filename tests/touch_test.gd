extends SceneTree
## Simulasi sentuh + geser ke kanan: pemain harus bergerak ke kanan, lalu berhenti saat jari diangkat.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/touch_test.gd

var frames := 0
var start_frame := -1
var start_x := 0.0
var moved_x := 0.0


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 2:
		root.get_node("Net").start_solo()
		return false
	var main := root.get_node_or_null("Main")
	if main == null or main.state != main.State.PLAYING:
		if frames > 600:
			print("game tidak mulai -> FAIL")
			quit(1)
			return true
		return false
	if start_frame < 0:
		start_frame = frames
		start_x = main.local_player.position.x
		_touch(true, Vector2(100, 200))
		var drag := InputEventScreenDrag.new()
		drag.position = Vector2(160, 200)
		Input.parse_input_event(drag)
	elif frames == start_frame + 30:
		moved_x = main.local_player.position.x
		_touch(false, Vector2(160, 200))
	elif frames == start_frame + 35:
		var still := not Input.is_action_pressed("move_right")
		var ok := moved_x > start_x + 20 and still
		print("start=%.1f moved=%.1f released=%s -> %s" % [start_x, moved_x, still, "OK" if ok else "FAIL"])
		quit(0 if ok else 1)
		return true
	return false


func _touch(pressed: bool, pos: Vector2) -> void:
	var t := InputEventScreenTouch.new()
	t.pressed = pressed
	t.position = pos
	Input.parse_input_event(t)
