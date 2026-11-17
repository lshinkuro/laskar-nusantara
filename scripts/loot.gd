extends RefCounted
## Isi Peti Pusaka: item/senjata acak, lebih condong ke barang langka daripada toko.

const DIRS := ["res://data/items/", "res://data/weapons/"]

static var _pool: Array[Resource] = []


static func pool() -> Array[Resource]:
	if _pool.is_empty():
		for dir in DIRS:
			for file in ResourceLoader.list_directory(dir):
				if file.ends_with(".tres"):
					_pool.append(load(dir + file))
	return _pool


static func weight(rarity: int, wave: int, luck: float) -> float:
	match rarity:
		1: return 45.0 + wave * 3.0 + luck
		2: return 18.0 + wave * 2.0 + luck * 0.5
		3: return 5.0 + wave * 1.0 + luck * 0.25
	return 40.0


static func pick(wave: int, luck: float) -> Resource:
	var all := pool()
	var total := 0.0
	for d in all:
		total += weight(d.rarity, wave, luck)
	var r := randf() * total
	for d in all:
		r -= weight(d.rarity, wave, luck)
		if r <= 0:
			return d
	return all.back()
