extends SceneTree
## Simulasi sentuh + geser ke kanan: pemain harus bergerak ke kanan, lalu berhenti saat jari diangkat.
## Jalankan: godot --headless --fixed-fps 60 -s res://tests/touch_test.gd

var main: Node
var frames := 0
var start_x := 0.0
var moved_x := 0.0


func _initialize() -> void:
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)


func _process(_delta: float) -> bool:
	frames += 1
	if frames == 5:
		start_x = main.player.position.x
		_touch(true, Vector2(100, 200))
		var drag := InputEventScreenDrag.new()
		drag.position = Vector2(160, 200)
		Input.parse_input_event(drag)
	elif frames == 35:
		moved_x = main.player.position.x
		_touch(false, Vector2(160, 200))
	elif frames == 40:
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
