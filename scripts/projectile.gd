extends Area2D
## damage > 0: peluru asli milik pemain lokal. damage = 0: salinan tampilan dari peer lain.

var direction := Vector2.RIGHT
var speed := 400.0
var damage := 0
var lifetime := 1.0
var pierce := 0
var texture: Texture2D
var enemies: Node
var map: Node2D
var spin := false
var data: WeaponData

var _hit := {}


func _ready() -> void:
	$Sprite.texture = texture
	rotation = direction.angle()
	area_entered.connect(_on_area_entered)


func _draw() -> void:
	# Jejak peluru (lokal: sumbu -x = arah belakang).
	var trail := minf(speed * 0.04, 18.0)
	draw_line(Vector2(-trail, 0), Vector2.ZERO, Color(1, 0.95, 0.8, 0.35), 3.0)
	draw_line(Vector2(-trail * 0.5, 0), Vector2.ZERO, Color(1, 1, 1, 0.5), 1.5)


func _physics_process(delta: float) -> void:
	if spin:
		$Sprite.rotation += 18.0 * delta
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0 or map.blocks(position):
		queue_free()


func _on_area_entered(enemy: Area2D) -> void:
	if is_queued_for_deletion() or _hit.has(enemy):
		return
	_hit[enemy] = true
	if damage > 0:
		enemies.hit(enemy, damage, data, direction)
	pierce -= 1
	if pierce < 0:
		queue_free()
	elif data.effect == "bounce":
		_bounce_from(enemy)


## Pantul ke musuh terdekat lain yang belum kena.
func _bounce_from(from: Node2D) -> void:
	var best: Node2D = null
	var best_d := 160.0 * 160.0
	for e: Node2D in get_tree().get_nodes_in_group("enemies"):
		if e == from or _hit.has(e):
			continue
		var d := position.distance_squared_to(e.position)
		if d < best_d:
			best_d = d
			best = e
	if best:
		direction = position.direction_to(best.position)
		rotation = direction.angle()
		lifetime = maxf(lifetime, 0.6)
