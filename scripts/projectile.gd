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
		enemies.hit(enemy, damage)
	pierce -= 1
	if pierce < 0:
		queue_free()
