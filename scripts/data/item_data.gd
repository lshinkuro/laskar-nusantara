class_name ItemData
extends Resource
## Item toko. Nambah item baru cukup bikin file .tres baru di data/items/.

@export var title := ""
@export_multiline var description := ""
@export var price := 20
@export var color := Color.WHITE
## Ikon pixel art 16x16 (dibuat tools/make_icons.py).
@export var icon: Texture2D
## Perubahan stat pemain, kunci sesuai Player.BASE_STATS. Contoh: {"max_hp": 5}
@export var stats := {}
## 0 Biasa, 1 Langka, 2 Epik, 3 Legendaris (peluang muncul di toko).
@export_range(0, 3) var rarity := 0
## Label sinergi, mis. "kuliner", "busana", "pusaka" (lihat scripts/synergy.gd).
@export var tags: PackedStringArray = []
## Efek khusus (lihat Player.apply_item): wayang, lifesteal, burn_chance, thorns, pulse,
## death_save, rempah_heal, turret. Nilainya di special_value.
@export var special := ""
@export var special_value := 0.0
