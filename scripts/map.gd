extends Node2D
## Medan perang: tanah + objek penghalang (pohon, bangunan, batu). Map berganti
## sesuai wave. Layout dibuat dari seed tetap, jadi semua peer co-op melihat medan
## yang sama tanpa sinkronisasi jaringan.
##
## Penghalang tidak memakai physics: pemain, musuh, dan peluru memanggil
## resolve()/blocks() (lebih murah untuk 150 musuh dan sama di semua peer).

const Obstacle := preload("res://scripts/obstacle.gd")

## Urutan medan dalam satu run. `layout` menentukan tanah & objek (lihat _build/_draw_ground).
const MAPS := [
	{"name": "LEMBAH SUNGAI", "until_wave": 4, "layout": "lembah"},
	{"name": "HUTAN KALIMANTAN", "until_wave": 8, "layout": "hutan"},
	{"name": "PELABUHAN SUNDA KELAPA", "until_wave": 12, "layout": "pelabuhan"},
	{"name": "DESA & CANDI", "until_wave": 16, "layout": "desa"},
	{"name": "BENTENG BESI", "until_wave": 999, "layout": "benteng"},
]
const SEA_TOP := 445.0  # pelabuhan: laut di bawah garis ini tidak bisa diinjak

## Bentuk penghalang per jenis: "r" = lingkaran di dasar, "rect" = kotak tapak.
const SHAPES := {
	"pohon": {"r": 6.0},
	"beringin": {"r": 12.0},
	"kelapa": {"r": 4.0},
	"batu": {"r": 8.0},
	"pisang": {"r": 5.0},
	"orang_orangan": {"r": 4.0},
	"gubuk": {"rect": Rect2(-15, -9, 30, 9)},
	"joglo": {"rect": Rect2(-23, -11, 46, 11)},
	"lumbung": {"rect": Rect2(-11, -6, 22, 6)},
	"candi": {"rect": Rect2(-36, -14, 72, 14)},
	"peti": {"rect": Rect2(-9, -8, 18, 8)},
	"tong": {"r": 6.0},
	"mercusuar": {"r": 12.0},
	"tembok": {"rect": Rect2(-40, -10, 80, 10)},
	"tembok_v": {"rect": Rect2(-6, -60, 12, 60)},
	"meriam_benteng": {"rect": Rect2(-12, -8, 24, 8)},
	"menara": {"rect": Rect2(-14, -12, 28, 12)},
}

const CENTER_CLEAR := 110.0
## Lantai tiap medan (tools/make_art.py). Sungai, jalan, dermaga, dan laut di gambar memakai
## angka yang sama dengan layout di bawah (_river_points, SEA_TOP).
const GROUNDS := {
	"lembah": preload("res://assets/sprites/medan_lembah.svg"),
	"hutan": preload("res://assets/sprites/medan_hutan.svg"),
	"desa": preload("res://assets/sprites/medan_desa.svg"),
	"pelabuhan": preload("res://assets/sprites/medan_pelabuhan.svg"),
	"benteng": preload("res://assets/sprites/medan_benteng.svg"),
}
## Warna di luar tepi arena (terlihat saat kamera di pinggir).
const OUTSIDE := {
	"lembah": Color(0.24, 0.48, 0.2),
	"hutan": Color(0.13, 0.22, 0.12),
	"desa": Color(0.4, 0.32, 0.2),
	"pelabuhan": Color(0.72, 0.62, 0.42),
	"benteng": Color(0.16, 0.15, 0.16),
}

@export var arena_size := Vector2(960, 540)
@export var map_index := 0

var _colliders: Array[Dictionary] = []
var _placed: Array[Vector2] = []
var _ground: Node2D


static func index_for_wave(wave: int) -> int:
	for i in MAPS.size():
		if wave <= MAPS[i].until_wave:
			return i
	return MAPS.size() - 1


func _ready() -> void:
	y_sort_enabled = true
	_ground = Node2D.new()
	_ground.z_index = -10
	_ground.draw.connect(_draw_ground)
	add_child(_ground)
	_build()


func set_map(index: int) -> void:
	if index == map_index and not _colliders.is_empty():
		return
	map_index = index
	_build()


func map_name() -> String:
	return MAPS[map_index].name


## Dorong posisi keluar dari penghalang (dipakai pemain & musuh).
func resolve(pos: Vector2, radius: float) -> Vector2:
	for o in _colliders:
		if o.has("r"):
			var d: Vector2 = pos - o.c
			var min_d: float = o.r + radius
			if d.length_squared() < min_d * min_d:
				pos = o.c + (d.normalized() if d.length_squared() > 0.01 else Vector2.DOWN) * min_d
		else:
			var r: Rect2 = o.rect.grow(radius)
			if r.has_point(pos):
				var left := pos.x - r.position.x
				var right := r.end.x - pos.x
				var top := pos.y - r.position.y
				var bottom := r.end.y - pos.y
				var m := minf(minf(left, right), minf(top, bottom))
				if m == left:
					pos.x = r.position.x
				elif m == right:
					pos.x = r.end.x
				elif m == top:
					pos.y = r.position.y
				else:
					pos.y = r.end.y
	return pos


## Apakah titik ini di dalam penghalang (dipakai peluru).
func blocks(pos: Vector2) -> bool:
	for o in _colliders:
		if o.has("r"):
			if pos.distance_squared_to(o.c) < o.r * o.r:
				return true
		elif o.rect.has_point(pos):
			return true
	return false


# --- Layout ---------------------------------------------------------------------

func _build() -> void:
	for c in get_children():
		if c != _ground:
			c.queue_free()
	_colliders.clear()
	_placed.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1000 + map_index
	match MAPS[map_index].layout:
		"lembah":  # Lembah sungai: terasering melengkung, sungai berkelok, gubuk & kelapa
			for p in [Vector2(250, 205), Vector2(330, 420), Vector2(860, 110)]:
				_add("gubuk", p, rng)
			for p in [Vector2(150, 95), Vector2(240, 470), Vector2(890, 470)]:
				_add("orang_orangan", p, rng)
			var river := _river_points()
			for i in range(3, river.size() - 2, 4):  # kelapa & batu di tepi sungai
				var side := 34.0 if i % 8 == 3 else -34.0
				_add("kelapa" if i % 3 else "batu", river[i] + Vector2(side, 0), rng)
			for i in range(2, river.size() - 2, 6):  # bebek berenang di sungai
				_add("bebek", river[i] + Vector2(rng.randf_range(-6, 6), 0), rng)
			for i in 6:
				_add("pisang", Vector2(14 if i % 2 == 0 else 600, rng.randf_range(60, arena_size.y - 40)), rng)
			_scatter("semak", 14, rng)
			_scatter("batu", 3, rng)
		"hutan":  # Hutan Kalimantan: pohon rapat, beringin besar
			for p in [Vector2(160, 150), Vector2(800, 140), Vector2(300, 450), Vector2(700, 430), Vector2(480, 70)]:
				_add("beringin", p, rng)
			_scatter("pohon", 38, rng)
			_scatter("batu", 8, rng)
			_scatter("semak", 26, rng)
		"desa":  # Desa & candi: candi di utara, joglo & lumbung di sekeliling alun-alun
			_add("candi", Vector2(480, 130), rng)
			for p in [Vector2(170, 170), Vector2(790, 170), Vector2(190, 440), Vector2(770, 440)]:
				_add("joglo", p, rng)
			for p in [Vector2(320, 110), Vector2(640, 110), Vector2(90, 300), Vector2(870, 300)]:
				_add("lumbung", p, rng)
			for i in 8:
				_add("kelapa", Vector2(rng.randf_range(30, arena_size.x - 30), 24 if i % 2 == 0 else arena_size.y - 10), rng)
			_scatter("pohon", 8, rng)
			_scatter("semak", 12, rng)
		"pelabuhan":  # Pelabuhan: dermaga, peti & tong, pinisi di laut, mercusuar
			_colliders.append({"rect": Rect2(-50, SEA_TOP, arena_size.x + 100, 200)})
			_add("mercusuar", Vector2(900, SEA_TOP - 18), rng)
			for p in [Vector2(150, 510), Vector2(520, 500), Vector2(760, 520)]:
				_add("pinisi", p, rng)
			for p in [Vector2(120, 90), Vector2(300, 80), Vector2(700, 100), Vector2(860, 200), Vector2(90, 330)]:
				for k in 3:  # tumpukan peti & tong dekat gudang
					_add("peti" if k != 1 else "tong", p + Vector2(k * 16 - 16, (k % 2) * 10), rng)
			for p in [Vector2(220, 200), Vector2(760, 330), Vector2(400, 380), Vector2(610, 160)]:
				_add("tong", p, rng)
			_add("gubuk", Vector2(470, 70), rng)
			_scatter("peti", 6, rng)
		"benteng":  # Benteng Besi: tembok berlubang, meriam, menara, panji
			for p in [Vector2(200, 130), Vector2(760, 130), Vector2(200, 420), Vector2(760, 420)]:
				_add("tembok", p, rng)
			for p in [Vector2(330, 250), Vector2(630, 250)]:
				_add("tembok_v", p + Vector2(0, 50), rng)
			for p in [Vector2(40, 60), Vector2(920, 60), Vector2(40, 520), Vector2(920, 520)]:
				_add("menara", p, rng)
			for p in [Vector2(480, 70), Vector2(120, 270), Vector2(840, 270), Vector2(480, 480)]:
				_add("meriam_benteng", p, rng)
			for p in [Vector2(260, 100), Vector2(700, 100), Vector2(260, 450), Vector2(700, 450)]:
				_add("panji", p, rng)
			_scatter("tong", 6, rng)
			_scatter("peti", 6, rng)
	_ground.queue_redraw()


func _scatter(kind: String, count: int, rng: RandomNumberGenerator) -> void:
	var center := arena_size / 2
	var placed := 0
	for attempt in count * 20:
		if placed >= count:
			return
		var p := Vector2(rng.randf_range(24, arena_size.x - 24), rng.randf_range(30, arena_size.y - 12))
		if p.distance_to(center) < CENTER_CLEAR:
			continue
		var spacing := 14.0 if kind == "semak" else 26.0
		if _placed.any(func(q): return q.distance_to(p) < spacing):
			continue
		_add(kind, p, rng)
		placed += 1


func _add(kind: String, pos: Vector2, rng: RandomNumberGenerator) -> void:
	var o := Obstacle.new()
	o.kind = kind
	o.variant = rng.randf()
	o.position = pos
	add_child(o)
	_placed.append(pos)
	if SHAPES.has(kind):
		var shape: Dictionary = SHAPES[kind]
		if shape.has("r"):
			_colliders.append({"c": pos, "r": shape.r})
		else:
			_colliders.append({"rect": Rect2(shape.rect.position + pos, shape.rect.size)})


# --- Tanah ----------------------------------------------------------------------

func _draw_ground() -> void:
	var layout: String = MAPS[map_index].layout
	var full := Rect2(Vector2.ZERO, arena_size)
	_ground.draw_rect(full.grow(200), OUTSIDE[layout])
	if layout == "pelabuhan":  # laut berlanjut di luar tepi bawah arena
		_ground.draw_rect(Rect2(-200, SEA_TOP, arena_size.x + 400, 300), Color(0.2, 0.5, 0.68))
	_ground.draw_texture_rect(GROUNDS[layout], full, false)


## Jalur sungai berkelok dari utara ke selatan (sama di semua peer).
func _river_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 31:
		var y := -20.0 + i * 20.0
		pts.append(Vector2(640 + 50 * sin(y * 0.012) + 22 * sin(y * 0.031), y))
	return pts
