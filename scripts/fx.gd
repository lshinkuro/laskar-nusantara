extends RefCounted
## Efek visual sekali pakai: percikan kena, ledakan.


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
