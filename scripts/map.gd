extends Node2D
## Medan perang: tanah + objek penghalang (pohon, bangunan, batu). Map berganti
## sesuai wave. Layout dibuat dari seed tetap, jadi semua peer co-op melihat medan
## yang sama tanpa sinkronisasi jaringan.
##
## Penghalang tidak memakai physics: pemain, musuh, dan peluru memanggil
## resolve()/blocks() (lebih murah untuk 150 musuh dan sama di semua peer).

const Obstacle := preload("res://scripts/obstacle.gd")

const MAPS := [
	{"name": "SAWAH", "until_wave": 6},
	{"name": "HUTAN KALIMANTAN", "until_wave": 13},
	{"name": "DESA & CANDI", "until_wave": 999},
]

## Bentuk penghalang per jenis: "r" = lingkaran di dasar, "rect" = kotak tapak.
const SHAPES := {
	"pohon": {"r": 6.0},
	"beringin": {"r": 12.0},
	"kelapa": {"r": 4.0},
	"batu": {"r": 8.0},
	"gubuk": {"rect": Rect2(-15, -9, 30, 9)},
	"joglo": {"rect": Rect2(-23, -11, 46, 11)},
	"lumbung": {"rect": Rect2(-11, -6, 22, 6)},
	"candi": {"rect": Rect2(-36, -14, 72, 14)},
}

const CENTER_CLEAR := 110.0

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
	match map_index:
		0:  # Sawah: gubuk di pematang, kelapa di pinggir
			for p in [Vector2(240, 120), Vector2(720, 120), Vector2(240, 420), Vector2(720, 420)]:
				_add("gubuk", p, rng)
			for i in 10:
				_add("kelapa", Vector2(rng.randf_range(30, arena_size.x - 30), 24 if i % 2 == 0 else arena_size.y - 10), rng)
			_scatter("batu", 4, rng)
			_scatter("semak", 6, rng)
		1:  # Hutan Kalimantan: pohon rapat, beringin besar
			for p in [Vector2(160, 150), Vector2(800, 140), Vector2(300, 450), Vector2(700, 430), Vector2(480, 70)]:
				_add("beringin", p, rng)
			_scatter("pohon", 38, rng)
			_scatter("batu", 8, rng)
			_scatter("semak", 26, rng)
		2:  # Desa & candi: candi di utara, joglo & lumbung di sekeliling alun-alun
			_add("candi", Vector2(480, 130), rng)
			for p in [Vector2(170, 170), Vector2(790, 170), Vector2(190, 440), Vector2(770, 440)]:
				_add("joglo", p, rng)
			for p in [Vector2(320, 110), Vector2(640, 110), Vector2(90, 300), Vector2(870, 300)]:
				_add("lumbung", p, rng)
			for i in 8:
				_add("kelapa", Vector2(rng.randf_range(30, arena_size.x - 30), 24 if i % 2 == 0 else arena_size.y - 10), rng)
			_scatter("pohon", 8, rng)
			_scatter("semak", 12, rng)
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
	var g := _ground
	var rng := RandomNumberGenerator.new()
	rng.seed = 17 + map_index
	var full := Rect2(Vector2.ZERO, arena_size)
	match map_index:
		0:
			g.draw_rect(full.grow(200), Color(0.42, 0.29, 0.17))
			g.draw_rect(full, Color(0.55, 0.42, 0.25))
			for x in range(0, int(arena_size.x), 120):
				for y in range(0, int(arena_size.y), 120):
					var petak := Rect2(x + 4, y + 4, 112, 112).intersection(full.grow(-4))
					g.draw_rect(petak, Color(0.33, 0.5, 0.28))
					for py in range(int(petak.position.y) + 6, int(petak.end.y) - 4, 10):
						for px in range(int(petak.position.x) + 6, int(petak.end.x) - 4, 9):
							_tuft(g, Vector2(px + rng.randi_range(-1, 1), py),
								Color(0.5, 0.7, 0.3) if rng.randf() > 0.3 else Color(0.36, 0.55, 0.22))
		1:
			g.draw_rect(full.grow(200), Color(0.13, 0.22, 0.12))
			g.draw_rect(full, Color(0.2, 0.33, 0.17))
			for i in 60:
				var c := Vector2(rng.randf() * arena_size.x, rng.randf() * arena_size.y)
				g.draw_circle(c, rng.randf_range(12, 40), Color(0.24, 0.38, 0.19, 0.6))
			# Jalan setapak berkelok
			var path := PackedVector2Array()
			for i in 17:
				path.append(Vector2(i * 60, arena_size.y / 2 + sin(i * 0.8) * 70))
			g.draw_polyline(path, Color(0.4, 0.3, 0.18), 22.0)
			g.draw_polyline(path, Color(0.47, 0.36, 0.22), 16.0)
			for i in 500:
				var p := Vector2(rng.randf() * arena_size.x, rng.randf() * arena_size.y)
				if rng.randf() < 0.5:
					_tuft(g, p, Color(0.3, 0.5, 0.24))
				else:
					g.draw_rect(Rect2(p, Vector2(2, 2)), [Color(0.55, 0.4, 0.15), Color(0.6, 0.25, 0.12)][rng.randi() % 2])
		2:
			g.draw_rect(full.grow(200), Color(0.4, 0.32, 0.2))
			g.draw_rect(full, Color(0.6, 0.5, 0.34))
			# Alun-alun berbatu di tengah + jalan silang
			g.draw_rect(Rect2(0, arena_size.y / 2 - 20, arena_size.x, 40), Color(0.66, 0.56, 0.4))
			g.draw_rect(Rect2(arena_size.x / 2 - 20, 0, 40, arena_size.y), Color(0.66, 0.56, 0.4))
			var plaza := Rect2(arena_size / 2 - Vector2(150, 90), Vector2(300, 180))
			g.draw_rect(plaza, Color(0.62, 0.6, 0.55))
			for x in range(int(plaza.position.x), int(plaza.end.x), 15):
				g.draw_line(Vector2(x, plaza.position.y), Vector2(x, plaza.end.y), Color(0.52, 0.5, 0.46), 1.0)
			for y in range(int(plaza.position.y), int(plaza.end.y), 15):
				g.draw_line(Vector2(plaza.position.x, y), Vector2(plaza.end.x, y), Color(0.52, 0.5, 0.46), 1.0)
			g.draw_rect(plaza, Color(0.4, 0.38, 0.34), false, 2.0)
			for i in 260:
				var p := Vector2(rng.randf() * arena_size.x, rng.randf() * arena_size.y)
				if not plaza.has_point(p):
					_tuft(g, p, Color(0.45, 0.55, 0.28))
	g.draw_rect(full, Color(0.2, 0.12, 0.06), false, 3.0)


func _tuft(g: Node2D, p: Vector2, c: Color) -> void:
	g.draw_line(p, p + Vector2(-2, -4), c)
	g.draw_line(p, p + Vector2(0, -5), c)
	g.draw_line(p, p + Vector2(2, -4), c)
