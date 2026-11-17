extends Area2D
## Serdadu Besi. Di host: mengejar prajurit hidup terdekat. Di client: ikut posisi dari host.

const DamageNumber := preload("res://scripts/damage_number.gd")

var id := 0
var max_hp := 10
var hp := 0
var speed := 50.0
var damage := 2
var simulate := false
var players: Node2D
var map: Node2D
var target_pos := Vector2.ZERO

var _target: Node2D
var _retarget := 0.0
var _bob := randf() * TAU

@onready var sprite: Sprite2D = $Sprite


func _ready() -> void:
	hp = max_hp
	target_pos = position
	# Muncul pelan supaya pemain sempat menghindar.
	scale = Vector2(0.2, 0.2)
	create_tween().tween_property(self, "scale", Vector2.ONE, 0.35)


func _physics_process(delta: float) -> void:
	var old := position
	if simulate:
		_retarget -= delta
		if _retarget <= 0 or not is_instance_valid(_target) or not _target.alive:
			_retarget = 0.5
			_target = _nearest_alive_player()
		if _target:
			position = map.resolve(position + position.direction_to(_target.position) * speed * delta, 8.0)
	else:
		position = position.lerp(target_pos, minf(1.0, delta * 12.0))
	var dx := position.x - old.x
	if absf(dx) > 0.05:
		sprite.flip_h = dx < 0
	_bob += delta * 10.0
	sprite.position.y = -absf(sin(_bob)) * 1.5


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
	DamageNumber.spawn(get_parent(), position + Vector2(0, -16), amount)


func die() -> void:
	Sfx.play("enemy_die", -8.0, 0.15)
	remove_from_group("enemies")
	$CollisionShape2D.set_deferred("disabled", true)
	set_physics_process(false)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.4, 0.2), 0.12)
	t.tween_callback(queue_free)
