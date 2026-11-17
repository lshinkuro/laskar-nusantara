extends Area2D
## Serdadu Besi: mengejar pemain lurus.

@export var speed := 50.0
@export var max_hp := 10
@export var damage := 2

var target: Node2D
var hp := 0


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	if target:
		position += position.direction_to(target.position) * speed * delta


func take_damage(amount: int) -> void:
	hp -= amount
	if hp <= 0:
		queue_free()
