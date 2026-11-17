extends RefCounted
## Efek visual sekali pakai: percikan kena, tebasan, ledakan.

const EFFECT_COLORS := {
	"burn": Color(1, 0.55, 0.2), "poison": Color(0.5, 1, 0.35), "bleed": Color(0.95, 0.15, 0.15),
	"slow": Color(0.5, 0.75, 1), "knockback": Color(1, 1, 1), "explode": Color(1, 0.6, 0.2), "bounce": Color(1, 0.9, 0.4),
}


## Gelombang lingkaran yang membesar lalu pudar.
static func ring(parent: Node, pos: Vector2, radius: float, color: Color) -> void:
	var l := Line2D.new()
	l.width = 3.0
	l.default_color = color
	for i in 33:
		l.add_point(Vector2.from_angle(TAU * i / 32) * radius)
	l.position = pos
	l.z_index = 6
	l.scale = Vector2(0.2, 0.2)
	parent.add_child(l)
	var t := l.create_tween()
	t.set_parallel()
	t.tween_property(l, "scale", Vector2.ONE, 0.3)
	t.tween_property(l, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(l.queue_free)


## Busur tebasan putih untuk senjata jarak dekat.
static func slash(parent: Node, pos: Vector2, angle: float) -> void:
	var l := Line2D.new()
	l.width = 3.0
	l.default_color = Color(1, 1, 1, 0.9)
	l.begin_cap_mode = Line2D.LINE_CAP_ROUND
	l.end_cap_mode = Line2D.LINE_CAP_ROUND
	for i in 7:
		var a := angle - 1.0 + i / 3.0
		l.add_point(Vector2.from_angle(a) * 13.0)
	l.position = pos
	l.z_index = 6
	parent.add_child(l)
	var t := l.create_tween()
	t.set_parallel()
	t.tween_property(l, "scale", Vector2(1.5, 1.5), 0.15)
	t.tween_property(l, "modulate:a", 0.0, 0.15)
	t.chain().tween_callback(l.queue_free)


static func spark(parent: Node, pos: Vector2, color := Color(1, 0.9, 0.5), amount := 6) -> void:
	_burst(parent, pos, color, amount, 0.25, Vector2(50, 120), 1.5)


static func explosion(parent: Node, pos: Vector2, radius: float) -> void:
	_burst(parent, pos, Color(1, 0.6, 0.2), 24, 0.45, Vector2(radius * 1.5, radius * 3.0), 3.0)
	_burst(parent, pos, Color(0.5, 0.45, 0.4, 0.8), 12, 0.7, Vector2(radius * 0.5, radius * 1.2), 4.0)


static func _burst(parent: Node, pos: Vector2, color: Color, amount: int, lifetime: float, velocity: Vector2, size: float) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.z_index = 5
	p.one_shot = true
	p.explosiveness = 1.0
	p.amount = amount
	p.lifetime = lifetime
	p.spread = 180.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = velocity.x
	p.initial_velocity_max = velocity.y
	p.damping_min = velocity.x
	p.damping_max = velocity.y
	p.scale_amount_min = size * 0.6
	p.scale_amount_max = size
	p.color = color
	p.emitting = true
	parent.add_child(p)
	p.finished.connect(p.queue_free)
