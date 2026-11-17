class_name WeaponData
extends Resource
## Senjata. Nambah senjata baru cukup bikin file .tres baru di data/weapons/.

@export var title := ""
@export_multiline var description := ""
@export var price := 30
@export_range(0, 3) var rarity := 0
## "melee" (jarak dekat), "ranged" (jarak jauh), atau "magic" (magis): bonus damage karakter.
@export_enum("melee", "ranged", "magic") var category := "ranged"
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
## Efek saat kena: burn/poison/bleed = damage per 0.5 dtk (power), slow = melambat,
## knockback = dorong (power piksel), explode = ledakan area (power = radius),
## bounce = peluru memantul ke musuh berikutnya (jumlah pantulan = pierce).
@export var effect := ""  # "", burn, poison, bleed, slow, knockback, explode, bounce
@export var effect_power := 0.0
