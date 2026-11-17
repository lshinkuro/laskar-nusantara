extends Node2D
## Medan perang: tanah + objek penghalang (pohon, bangunan, batu). Map berganti
## sesuai wave. Layout dibuat dari seed tetap, jadi semua peer co-op melihat medan
## yang sama tanpa sinkronisasi jaringan.
##
## Penghalang tidak memakai physics: pemain, musuh, dan peluru memanggil
## resolve()/blocks() (lebih murah untuk 150 musuh dan sama di semua peer).

const Obstacle := preload("res://scripts/obstacle.gd")

const MAPS := [
	{"name": "LEMBAH SUNGAI", "until_wave": 6},
	{"name": "HUTAN KALIMANTAN", "until_wave": 13},
	{"name": "DESA & CANDI", "until_wave": 999},
]

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
		0:  # Lembah sungai: terasering melengkung, sungai berkelok, gubuk & kelapa
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
			g.draw_rect(full.grow(200), Color(0.26, 0.42, 0.2))
			g.draw_rect(full, Color(0.36, 0.56, 0.28))
			for i in 70:  # gradasi rumput alami
				var c := Vector2(rng.randf() * arena_size.x, rng.randf() * arena_size.y)
				var col := Color(0.42, 0.62, 0.3, 0.5) if rng.randf() < 0.5 else Color(0.3, 0.5, 0.24, 0.5)
				g.draw_circle(c, rng.randf_range(20, 60), col)
			for t in TERRACES:
				_draw_terrace(g, t.c, t.r, t.seed, rng)
			# Jalan setapak meliuk dari barat ke timur, menyeberang sungai lewat jembatan
			var path := PackedVector2Array()
			for i in 17:
				var x := i * 60.0
				path.append(Vector2(x, 300 + sin(i * 0.7) * 40 - i * 3))
			g.draw_polyline(path, Color(0.5, 0.38, 0.22), 18.0)
			g.draw_polyline(path, Color(0.62, 0.5, 0.32), 12.0)
			_draw_river(g)
			for i in 900:  # rumput & bunga liar
				var p := Vector2(rng.randf() * arena_size.x, rng.randf() * arena_size.y)
				if rng.randf() < 0.12:
					g.draw_circle(p, 1.5, [Color(0.95, 0.3, 0.3), Color(1, 0.95, 0.9), Color(1, 0.85, 0.3), Color(0.8, 0.5, 0.95)][rng.randi() % 4])
				else:
					_tuft(g, p, Color(0.48, 0.7, 0.34) if rng.randf() < 0.6 else Color(0.28, 0.46, 0.2))
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


## Kelompok sawah terasering: pusat, radius (x, y), seed bentuk.
const TERRACES := [
	{"c": Vector2(190, 140), "r": Vector2(150, 110), "seed": 1.0},
	{"c": Vector2(260, 450), "r": Vector2(140, 95), "seed": 2.5},
	{"c": Vector2(880, 470), "r": Vector2(120, 90), "seed": 4.0},
]
const TERRACE_COLORS := [Color(0.42, 0.62, 0.62), Color(0.4, 0.64, 0.3), Color(0.82, 0.7, 0.32), Color(0.34, 0.56, 0.26), Color(0.45, 0.66, 0.66)]


func _terrace_ring(c: Vector2, r: Vector2, k: float, seed_v: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 48:
		var a := TAU * i / 48
		var wobble := 1.0 + 0.09 * sin(3 * a + seed_v) + 0.05 * sin(5 * a + seed_v * 2)
		pts.append(c + Vector2(cos(a) * r.x, sin(a) * r.y) * k * wobble)
	return pts


func _draw_terrace(g: Node2D, c: Vector2, r: Vector2, seed_v: float, rng: RandomNumberGenerator) -> void:
	var rings := 8
	for i in rings:
		var k := 1.0 - i * 0.115
		var ring := _terrace_ring(c, r, k, seed_v)
		var col: Color = TERRACE_COLORS[(i + int(seed_v)) % TERRACE_COLORS.size()]
		g.draw_colored_polygon(ring, col)
		g.draw_polyline(ring + PackedVector2Array([ring[0]]), Color(0.48, 0.38, 0.22), 3.0)  # pematang
		g.draw_polyline(ring + PackedVector2Array([ring[0]]), Color(0.6, 0.5, 0.3), 1.0)
		# isi tiap lapis: padi atau kilau air
		var inner := k - 0.06
		for j in 30:
			var a := rng.randf() * TAU
			var wob := 1.0 + 0.09 * sin(3 * a + seed_v) + 0.05 * sin(5 * a + seed_v * 2)
			var p := c + Vector2(cos(a) * r.x, sin(a) * r.y) * inner * wob
			if col.b > 0.5:
				g.draw_line(p, p + Vector2(8, 0), Color(0.85, 0.95, 0.95, 0.6), 1.0)
			else:
				_tuft(g, p, col.lightened(0.25))


## Jalur sungai berkelok dari utara ke selatan (sama di semua peer).
func _river_points() -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 31:
		var y := -20.0 + i * 20.0
		pts.append(Vector2(640 + 50 * sin(y * 0.012) + 22 * sin(y * 0.031), y))
	return pts


func _draw_river(g: Node2D) -> void:
	var river := _river_points()
	g.draw_polyline(river, Color(0.78, 0.7, 0.48), 46.0)  # tepian pasir
	g.draw_polyline(river, Color(0.24, 0.42, 0.52), 34.0)
	g.draw_polyline(river, Color(0.32, 0.55, 0.65), 24.0)
	for i in range(0, river.size(), 2):
		var p := river[i] + Vector2(-8 + (i % 3) * 6, 4)
		g.draw_line(p, p + Vector2(12, 0), Color(0.8, 0.92, 0.95, 0.7), 1.0)
	# Jembatan kayu di tempat jalan setapak menyeberang
	var bridge_y := 300 + sin(640 / 60.0 * 0.7) * 40 - 640 / 60.0 * 3
	var bx := 640 + 50 * sin(bridge_y * 0.012) + 22 * sin(bridge_y * 0.031)
	for k in 9:
		g.draw_rect(Rect2(bx - 26 + k * 6, bridge_y - 9, 5, 18), Color(0.55, 0.38, 0.2))
		g.draw_line(Vector2(bx - 26 + k * 6, bridge_y - 9), Vector2(bx - 26 + k * 6, bridge_y + 9), Color(0.35, 0.22, 0.1), 1.0)
	g.draw_line(Vector2(bx - 27, bridge_y - 10), Vector2(bx + 27, bridge_y - 10), Color(0.35, 0.22, 0.1), 2.0)
	g.draw_line(Vector2(bx - 27, bridge_y + 10), Vector2(bx + 27, bridge_y + 10), Color(0.35, 0.22, 0.1), 2.0)


func _tuft(g: Node2D, p: Vector2, c: Color) -> void:
	g.draw_line(p, p + Vector2(-2, -4), c)
	g.draw_line(p, p + Vector2(0, -5), c)
	g.draw_line(p, p + Vector2(2, -4), c)
