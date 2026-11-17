class_name ItemData
extends Resource
## Item toko. Nambah item baru cukup bikin file .tres baru di data/items/.

@export var title := ""
@export_multiline var description := ""
@export var price := 20
@export var color := Color.WHITE
## Perubahan stat pemain, kunci sesuai Player.BASE_STATS. Contoh: {"max_hp": 5}
@export var stats := {}
