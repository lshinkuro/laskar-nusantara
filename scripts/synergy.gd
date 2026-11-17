extends RefCounted
## Sinergi: bonus otomatis kalau punya cukup senjata satu kategori atau item satu label.

const LIST := [
	{"name": "Jurus Silat", "need": 3, "weapon": "melee", "desc": "3 senjata jarak dekat", "stats": {"melee_damage": 20, "armor": 2}},
	{"name": "Barisan Pemanah", "need": 3, "weapon": "ranged", "desc": "3 senjata jarak jauh", "stats": {"attack_speed": 10, "range": 15}},
	{"name": "Ilmu Kebatinan", "need": 3, "weapon": "magic", "desc": "3 senjata magis", "stats": {"magic_damage": 25, "hp_regen": 2}},
	{"name": "Kuliner Nusantara", "need": 3, "tag": "kuliner", "desc": "3 item kuliner", "stats": {"max_hp": 6, "hp_regen": 2}},
	{"name": "Busana Adat", "need": 3, "tag": "busana", "desc": "3 item busana", "stats": {"armor": 2, "dodge": 8}},
	{"name": "Pusaka Leluhur", "need": 2, "tag": "pusaka", "desc": "2 item pusaka", "stats": {"damage": 10, "luck": 15}},
]


## Jumlah yang dimiliki pemain untuk satu sinergi.
static func progress(s: Dictionary, player) -> int:
	if s.has("weapon"):
		return player.weapon_ring.get_children().filter(func(w): return w.data.category == s.weapon).size()
	return player.items.filter(func(it): return s.tag in it.tags).size()


static func active(player) -> Array:
	return LIST.filter(func(s): return progress(s, player) >= s.need)
