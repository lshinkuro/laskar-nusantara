extends Area2D
## Musuh Kekaisaran Besi (semua jenis + boss). Di host: mengejar prajurit terdekat dan
## memakai kemampuan sesuai jenis. Di client: ikut posisi dari host.

const DamageNumber := preload("res://scripts/damage_number.gd")

var id := 0
var kind := "serdadu"
var def := {}
var max_hp := 10
var hp := 0
var speed := 50.0
var damage := 2
var simulate := false
var players: Node2D
var map: Node2D
var enemies: Node
var target_pos := Vector2.ZERO
var phase := 1

var _target: Node2D
var _retarget := 0.0
var _bob := randf() * TAU
var _timers := {}
var _telegraph := 0.0
var _dash := 0.0
var _dash_dir := Vector2.ZERO
var _ring_offset := 0.0

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	hp = max_hp
	target_pos = position
	sprite.texture = def.tex
	sprite.scale = Vector2.ONE * def.scale
	var shape := CircleShape2D.new()
	shape.radius = def.radius
	$CollisionShape2D.shape = shape
	$Shadow.scale = Vector2.ONE * def.scale / 1.5
	for k in ["shoot", "mine", "dash", "ring", "summon", "slam"]:
		_timers[k] = randf_range(1.5, 3.0)
	# Muncul pelan supaya pemain sempat menghindar.
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35)


func is_boss() -> bool:
	return def.has("boss")


func start_telegraph() -> void:
	_telegraph = 0.7


func _physics_process(delta: float) -> void:
	var old := position
	if simulate:
		_simulate(delta)
	else:
		position = position.lerp(target_pos, minf(1.0, delta * 12.0))
		_telegraph -= delta
	var dx := position.x - old.x
	if absf(dx) > 0.05:
		sprite.flip_h = dx < 0
	_bob += delta * (16.0 if _dash > 0 else 10.0)
	sprite.position.y = -absf(sin(_bob)) * def.scale
	if _telegraph > 0:
		sprite.modulate = Color(2.5, 0.6, 0.6) if fmod(_telegraph, 0.2) < 0.1 else Color.WHITE
	elif sprite.modulate == Color(2.5, 0.6, 0.6):
		sprite.modulate = Color.WHITE


func _simulate(delta: float) -> void:
	_retarget -= delta
	if _retarget <= 0 or not is_instance_valid(_target) or not _target.alive:
		_retarget = 0.5
		_target = _nearest_alive_player()
	if _target == null:
		return
	var to := _target.position - position
	var dir := to.normalized()
	var move := dir * speed
	if _dash > 0:
		_dash -= delta
		move = _dash_dir * speed * 3.5
	elif _telegraph > 0:
		_telegraph -= delta
		move = Vector2.ZERO
		if _telegraph <= 0:
			_dash = 0.5
			_dash_dir = dir
	elif def.get("ranged", false) and to.length() < 150:
		move = dir.orthogonal() * speed * 0.5  # jaga jarak sambil bergeser
	position = map.resolve(position + move * delta, def.radius * 0.8)
	_abilities(delta, dir)


func _abilities(delta: float, dir: Vector2) -> void:
	for k in _timers:
		_timers[k] -= delta
	if def.get("ranged", false) and _timers.shoot <= 0:
		_timers.shoot = 2.2
		enemies.fire_bullets(position, PackedVector2Array([dir]), 140.0, damage)
	if def.get("miner", false) and _timers.mine <= 0:
		_timers.mine = 4.0
		enemies.place_mine(position)
	match kind:
		"komandan":
			if _timers.dash <= 0:
				_timers.dash = 4.5
				enemies.telegraph.rpc(id)
			if enemies.wave >= 4 and _timers.ring <= 0:
				_timers.ring = 5.0
				enemies.fire_ring(position, 10, 120.0, damage / 2, randf() * TAU)
		"mandor":
			if _timers.summon <= 0:
				_timers.summon = 6.0
				enemies.summon(position, 3)
			if _timers.slam <= 0:
				_timers.slam = 5.5
				enemies.slam(_target.position, 60.0, 1.1, damage * 2)
		"gubernur":
			var enraged := hp < max_hp / 2
			if enraged and phase == 1:
				phase = 2
				speed *= 1.3
				enemies.shout.rpc("GUBERNUR JENDERAL MURKA!")
			if _timers.ring <= 0:
				_timers.ring = 2.0 if enraged else 3.2
				enemies.fire_ring(position, 16 if enraged else 12, 130.0, damage / 2, _ring_offset)
				_ring_offset += 0.25
			if _timers.summon <= 0:
				_timers.summon = 8.0
				enemies.summon(position, 4)
			if _timers.dash <= 0:
				_timers.dash = 6.0
				enemies.telegraph.rpc(id)
			if enraged and _timers.slam <= 0:
				_timers.slam = 5.0
				enemies.slam(_target.position, 70.0, 1.0, damage * 2)


func _nearest_alive_player() -> Node2D:
	var best: Node2D = null
	var best_d := INF
	for p in players.get_children():
		if p.alive:
			var d := position.distance_squared_to(p.position)
			if d < best_d:
				best_d = d
				best = p
	return best


func flash(amount: int) -> void:
	sprite.modulate = Color(4, 4, 4)
	create_tween().tween_property(sprite, "modulate", Color.WHITE, 0.12)
	DamageNumber.spawn(get_parent(), position + Vector2(0, -12 - def.radius), amount)


func die() -> void:
	Sfx.play("enemy_die", -8.0 if not is_boss() else 2.0, 0.15)
	remove_from_group("enemies")
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.4, 0.2), 0.12 if not is_boss() else 0.4)
	t.tween_callback(queue_free)
