extends Area2D
## damage > 0: peluru asli milik pemain lokal. damage = 0: salinan tampilan dari peer lain.

var direction := Vector2.RIGHT
var speed := 400.0
var damage := 0
var lifetime := 1.0
var pierce := 0
var texture: Texture2D
var enemies: Node

var _hit := {}


func _ready() -> void:
	$Sprite.texture = texture
	rotation = direction.angle()
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
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
