extends CharacterBody2D

signal hp_changed(hp: int, max_hp: int)
signal died

@export var speed := 150.0
@export var max_hp := 20
@export var invuln_time := 0.5
@export var arena_size := Vector2(960, 540)

var hp := 0
var _invuln := 0.0

@onready var hurtbox: Area2D = $Hurtbox
@onready var sprite: Polygon2D = $Sprite


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	velocity = Input.get_vector("move_left", "move_right", "move_up", "move_down") * speed
	move_and_slide()
	position = position.clamp(Vector2(8, 8), arena_size - Vector2(8, 8))

	_invuln -= delta
	sprite.modulate.a = 0.4 if _invuln > 0 else 1.0
	if _invuln <= 0:
		for enemy in hurtbox.get_overlapping_areas():
			take_damage(enemy.damage)
			break


func take_damage(amount: int) -> void:
	if hp <= 0:
		return
	hp = max(hp - amount, 0)
	_invuln = invuln_time
	hp_changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()


func heal_full() -> void:
	hp = max_hp
	hp_changed.emit(hp, max_hp)
