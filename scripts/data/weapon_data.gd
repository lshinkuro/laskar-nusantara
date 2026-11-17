class_name WeaponData
extends Resource
## Senjata. Nambah senjata baru cukup bikin file .tres baru di data/weapons/.

@export var title := ""
@export_multiline var description := ""
@export var price := 30
@export var texture: Texture2D
@export var damage := 5
@export var fire_interval := 0.6
@export var attack_range := 200.0
@export var projectile_speed := 400.0
@export var projectile_count := 1
## Sudut antar peluru (derajat) kalau projectile_count > 1.
@export var spread := 0.0
## Berapa musuh tambahan yang bisa ditembus.
@export var pierce := 0
## Peluru berputar (cakra, batu).
@export var spin := false
