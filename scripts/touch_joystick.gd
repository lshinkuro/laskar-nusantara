extends Control
## Joystick virtual mengambang untuk HP: sentuh di mana saja lalu geser untuk bergerak.
## Menekan action move_* supaya player.gd tidak perlu tahu soal sentuhan.

const RADIUS := 40.0
const KNOB_RADIUS := 14.0

var _touch := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_touch = -1
		_apply(Vector2.ZERO)
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch == -1:
			_touch = event.index
			_origin = event.position
			_knob = _origin
		elif not event.pressed and event.index == _touch:
			_touch = -1
			_apply(Vector2.ZERO)
		queue_redraw()
	elif event is InputEventScreenDrag and event.index == _touch:
		var offset: Vector2 = (event.position - _origin).limit_length(RADIUS)
		_knob = _origin + offset
		_apply(offset / RADIUS)
		queue_redraw()


func _exit_tree() -> void:
	_apply(Vector2.ZERO)  # jangan sampai action tertahan saat scene di-reload


func _apply(v: Vector2) -> void:
	_set_axis("move_left", "move_right", v.x)
	_set_axis("move_up", "move_down", v.y)


func _set_axis(negative: StringName, positive: StringName, value: float) -> void:
	if value < 0:
		Input.action_press(negative, -value)
		Input.action_release(positive)
	elif value > 0:
		Input.action_press(positive, value)
		Input.action_release(negative)
	else:
		Input.action_release(negative)
		Input.action_release(positive)


func _draw() -> void:
	if _touch == -1:
		return
	draw_circle(_origin, RADIUS, Color(1, 1, 1, 0.15))
	draw_circle(_knob, KNOB_RADIUS, Color(1, 1, 1, 0.45))
