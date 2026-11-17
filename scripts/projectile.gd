extends Area2D

var direction := Vector2.RIGHT
var speed := 400.0
var damage := 5
var lifetime := 1.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0:
		queue_free()


func _on_area_entered(enemy: Area2D) -> void:
	# Bisa kena dua musuh di frame yang sama; cukup satu.
	if is_queued_for_deletion():
		return
	enemy.take_damage(damage)
	queue_free()
