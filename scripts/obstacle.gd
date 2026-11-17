extends Node2D
## Objek medan (pohon, bangunan, batu, semak) digambar prosedural.
## Titik origin = kaki/dasar objek, supaya y-sort pas dengan prajurit.

var kind := "pohon"
var variant := 0.0  # 0..1, variasi kecil warna/ukuran

var _home := Vector2.ZERO
var _t := 0.0

const OUTLINE := Color(0.1, 0.07, 0.04)
const SHADOW := Color(0, 0, 0, 0.25)
const DAUN := [Color(0.16, 0.36, 0.16), Color(0.24, 0.48, 0.2), Color(0.36, 0.6, 0.26)]
const KAYU := Color(0.42, 0.27, 0.14)
const KAYU_GELAP := Color(0.28, 0.17, 0.08)
const ATAP_JERAMI := Color(0.68, 0.53, 0.27)
const BATU := Color(0.55, 0.52, 0.48)
const BATU_GELAP := Color(0.4, 0.37, 0.34)


func _draw() -> void:
	match kind:
		"pohon": _pohon()
		"beringin": _beringin()
		"kelapa": _kelapa()
		"batu": _batu()
		"semak": _semak()
		"gubuk": _gubuk()
		"joglo": _joglo()
		"lumbung": _lumbung()
		"candi": _candi()
		"pisang": _pisang()
		"orang_orangan": _orang_orangan()
		"bebek": _bebek()
		"peti": _peti()
		"tong": _tong()
		"mercusuar": _mercusuar()
		"pinisi": _pinisi()
		"tembok": _tembok(Vector2(80, 22))
		"tembok_v": _tembok_v()
		"meriam_benteng": _meriam_benteng()
		"menara": _menara()
		"panji": _panji()


func _ready() -> void:
	# Bebek berenang pelan bolak-balik (hiasan, tidak disinkronkan).
	set_process(kind == "bebek")
	_home = position



func _process(delta: float) -> void:
	_t += delta
	var p := _home + Vector2(sin(_t * 0.4 + variant * 9) * 22, cos(_t * 0.3 + variant * 5) * 14)
	scale.x = -1 if p.x < position.x else 1
	position = p
	queue_redraw()


func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var pts := PackedVector2Array()
	for i in 16:
		var a := TAU * i / 16
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _circle(center: Vector2, r: float, color: Color) -> void:
	draw_circle(center, r + 1, OUTLINE)
	draw_circle(center, r, color)


func _pohon() -> void:
	var s := 1.0 + variant * 0.3
	_ellipse(Vector2.ZERO, 12 * s, 4, SHADOW)
	draw_rect(Rect2(-3, -14, 6, 14), OUTLINE)
	draw_rect(Rect2(-2, -14, 4, 14), KAYU)
	_circle(Vector2(0, -26) * s, 13 * s, DAUN[0])
	draw_circle(Vector2(-5, -25) * s, 8 * s, DAUN[1])
	draw_circle(Vector2(5, -30) * s, 8 * s, DAUN[1])
	draw_circle(Vector2(-2, -33) * s, 5 * s, DAUN[2])


func _beringin() -> void:
	_ellipse(Vector2.ZERO, 30, 8, SHADOW)
	draw_rect(Rect2(-6, -22, 12, 22), OUTLINE)
	draw_rect(Rect2(-5, -22, 10, 22), KAYU)
	for x in [-12, -8, 8, 12]:
		draw_line(Vector2(x * 0.6, -26), Vector2(x, 0), KAYU_GELAP, 1.0)  # akar gantung
	_circle(Vector2(0, -40), 26, DAUN[0])
	_circle(Vector2(-18, -32), 14, DAUN[0])
	_circle(Vector2(18, -34), 14, DAUN[0])
	draw_circle(Vector2(-8, -44), 14, DAUN[1])
	draw_circle(Vector2(10, -48), 12, DAUN[1])
	draw_circle(Vector2(-2, -56), 8, DAUN[2])


func _kelapa() -> void:
	_ellipse(Vector2.ZERO, 8, 3, SHADOW)
	var lean := -6.0 if variant < 0.5 else 6.0
	var top := Vector2(lean, -38)
	var pts := PackedVector2Array()
	for i in 9:
		var t := i / 8.0
		pts.append(Vector2(lean * t * t, -38 * t))
	draw_polyline(pts, OUTLINE, 5.0)
	draw_polyline(pts, KAYU, 3.0)
	for i in range(1, 8, 2):
		draw_line(pts[i] + Vector2(-2, 0), pts[i] + Vector2(2, 0), KAYU_GELAP, 1.0)
	for i in 6:
		var a := PI + i * PI / 5.0 + 0.1
		var tip := top + Vector2(cos(a), sin(a) * 0.6 + 0.35) * 18
		var side := Vector2(cos(a + 1.57), sin(a + 1.57)) * 3
		draw_colored_polygon(PackedVector2Array([top, tip + side, tip, tip - side * 0.3]), DAUN[1 if i % 2 else 0])
	draw_circle(top + Vector2(-2, 3), 2.5, KAYU_GELAP)
	draw_circle(top + Vector2(2, 3), 2.5, KAYU_GELAP)


func _batu() -> void:
	var s := 0.8 + variant * 0.6
	_ellipse(Vector2(0, 1), 10 * s, 3 * s, SHADOW)
	var pts := PackedVector2Array([Vector2(-10, 0), Vector2(-8, -7), Vector2(-2, -10), Vector2(6, -9), Vector2(10, -3), Vector2(8, 1)])
	for i in pts.size():
		pts[i] *= s
	draw_colored_polygon(pts, BATU_GELAP)
	draw_polyline(pts + PackedVector2Array([pts[0]]), OUTLINE, 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(-6, -6) * s, Vector2(-2, -9) * s, Vector2(4, -8) * s, Vector2(-1, -5) * s]), BATU)


func _semak() -> void:
	_ellipse(Vector2(0, 1), 10, 3, SHADOW)
	_circle(Vector2(-5, -4), 5, DAUN[0])
	_circle(Vector2(4, -4), 5, DAUN[0])
	_circle(Vector2(0, -7), 5, DAUN[1])
	draw_circle(Vector2(-1, -9), 2, DAUN[2])


func _gubuk() -> void:
	_ellipse(Vector2(0, 1), 20, 5, SHADOW)
	var bambu := Color(0.78, 0.63, 0.36)
	draw_rect(Rect2(-15, -15, 30, 15), OUTLINE)
	draw_rect(Rect2(-14, -14, 28, 14), bambu)
	for x in range(-12, 14, 4):
		draw_line(Vector2(x, -14), Vector2(x, 0), bambu.darkened(0.25), 1.0)
	draw_rect(Rect2(-4, -10, 8, 10), KAYU_GELAP)
	var roof := PackedVector2Array([Vector2(-20, -12), Vector2(20, -12), Vector2(11, -30), Vector2(-11, -30)])
	draw_colored_polygon(roof, ATAP_JERAMI)
	draw_polyline(roof + PackedVector2Array([roof[0]]), OUTLINE, 1.0)
	for i in 4:
		var y := -15.0 - i * 4.5
		var w := 19.0 - i * 2.2
		draw_line(Vector2(-w, y), Vector2(w, y), ATAP_JERAMI.darkened(0.2), 1.0)


func _joglo() -> void:
	_ellipse(Vector2(0, 1), 30, 6, SHADOW)
	var dinding := Color(0.9, 0.83, 0.68)
	draw_rect(Rect2(-23, -17, 46, 17), OUTLINE)
	draw_rect(Rect2(-22, -16, 44, 16), dinding)
	for x in [-22, -9, 7, 20]:
		draw_rect(Rect2(x, -16, 2, 16), KAYU_GELAP)
	draw_rect(Rect2(-4, -12, 8, 12), KAYU)
	draw_rect(Rect2(-17, -11, 5, 5), KAYU_GELAP)
	draw_rect(Rect2(12, -11, 5, 5), KAYU_GELAP)
	var genteng := Color(0.6, 0.26, 0.15)
	var bawah := PackedVector2Array([Vector2(-30, -14), Vector2(30, -14), Vector2(19, -27), Vector2(-19, -27)])
	draw_colored_polygon(bawah, genteng)
	draw_polyline(bawah + PackedVector2Array([bawah[0]]), OUTLINE, 1.0)
	var atas := PackedVector2Array([Vector2(-15, -27), Vector2(15, -27), Vector2(6, -42), Vector2(-6, -42)])
	draw_colored_polygon(atas, genteng.darkened(0.2))
	draw_polyline(atas + PackedVector2Array([atas[0]]), OUTLINE, 1.0)
	for i in 3:
		var y := -17.0 - i * 3.5
		draw_line(Vector2(-27 + i * 3, y), Vector2(27 - i * 3, y), genteng.darkened(0.3), 1.0)
	draw_line(Vector2(-6, -42), Vector2(6, -42), Color(0.88, 0.69, 0.29), 2.0)


func _lumbung() -> void:
	_ellipse(Vector2(0, 1), 14, 4, SHADOW)
	for x in [-9, -3, 3, 9]:
		draw_line(Vector2(x, -8), Vector2(x, 0), KAYU_GELAP, 2.0)
	draw_rect(Rect2(-12, -21, 24, 13), OUTLINE)
	draw_rect(Rect2(-11, -20, 22, 11), KAYU)
	for y in [-17, -13]:
		draw_line(Vector2(-11, y), Vector2(11, y), KAYU_GELAP, 1.0)
	var roof := PackedVector2Array([Vector2(-15, -18), Vector2(15, -18), Vector2(11, -33), Vector2(0, -40), Vector2(-11, -33)])
	draw_colored_polygon(roof, ATAP_JERAMI)
	draw_polyline(roof + PackedVector2Array([roof[0]]), OUTLINE, 1.0)


func _pisang() -> void:
	_ellipse(Vector2.ZERO, 10, 3, SHADOW)
	draw_rect(Rect2(-3, -18, 6, 18), OUTLINE)
	draw_rect(Rect2(-2, -18, 4, 18), Color(0.5, 0.55, 0.25))
	var top := Vector2(0, -18)
	for i in 5:
		var a := PI + 0.2 + i * (PI - 0.4) / 4.0
		var tip := top + Vector2(cos(a) * 18, sin(a) * 12 - 2)
		var mid := top.lerp(tip, 0.5) + Vector2(0, -4)
		var leaf := PackedVector2Array([top, mid + Vector2(0, -3), tip, mid + Vector2(0, 3)])
		draw_colored_polygon(leaf, DAUN[1] if i % 2 else DAUN[2])
		draw_line(top, tip, DAUN[0], 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(2, -16), Vector2(6, -14), Vector2(5, -8), Vector2(2, -10)]), Color(0.85, 0.8, 0.3))


func _orang_orangan() -> void:
	_ellipse(Vector2.ZERO, 6, 2, SHADOW)
	draw_line(Vector2(0, 0), Vector2(0, -20), KAYU_GELAP, 2.0)
	draw_line(Vector2(-10, -14), Vector2(10, -14), KAYU_GELAP, 2.0)
	draw_rect(Rect2(-5, -16, 10, 9), Color(0.75, 0.3, 0.2))  # baju
	draw_line(Vector2(-10, -14), Vector2(-12, -10), Color(0.85, 0.75, 0.4), 1.0)  # jerami
	draw_line(Vector2(10, -14), Vector2(12, -10), Color(0.85, 0.75, 0.4), 1.0)
	draw_circle(Vector2(0, -21), 4, Color(0.9, 0.82, 0.55))
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -23), Vector2(8, -23), Vector2(0, -30)]), ATAP_JERAMI)  # caping
	draw_line(Vector2(-8, -23), Vector2(8, -23), OUTLINE, 1.0)


func _bebek() -> void:
	_ellipse(Vector2(0, 1), 5, 1.5, Color(1, 1, 1, 0.25))  # riak air
	draw_circle(Vector2(0, -2), 4, Color(0.95, 0.93, 0.85))
	draw_circle(Vector2(3, -6), 2.5, Color(0.95, 0.93, 0.85))
	draw_rect(Rect2(5, -6.5, 2.5, 1.5), Color(0.95, 0.6, 0.15))
	draw_rect(Rect2(3, -7, 1, 1), OUTLINE)


const BESI := Color(0.36, 0.38, 0.42)
const BESI_GELAP := Color(0.2, 0.21, 0.24)
const MERAH_BESI := Color(0.55, 0.12, 0.1)


func _peti() -> void:
	_ellipse(Vector2(0, 1), 11, 3, SHADOW)
	draw_rect(Rect2(-10, -16, 20, 16), OUTLINE)
	draw_rect(Rect2(-9, -15, 18, 14), Color(0.62, 0.45, 0.24))
	draw_line(Vector2(-9, -15), Vector2(9, -1), KAYU_GELAP, 1.0)
	draw_line(Vector2(9, -15), Vector2(-9, -1), KAYU_GELAP, 1.0)
	draw_rect(Rect2(-9, -9, 18, 2), KAYU_GELAP)


func _tong() -> void:
	_ellipse(Vector2(0, 1), 8, 3, SHADOW)
	draw_rect(Rect2(-7, -16, 14, 16), OUTLINE)
	draw_rect(Rect2(-6, -15, 12, 14), Color(0.55, 0.33, 0.17))
	for y in [-13, -5]:
		draw_rect(Rect2(-6, y, 12, 2), BESI)
	_ellipse(Vector2(0, -15), 6, 2, Color(0.45, 0.27, 0.13))


func _mercusuar() -> void:
	_ellipse(Vector2(0, 2), 18, 5, SHADOW)
	var pts := PackedVector2Array([Vector2(-12, 0), Vector2(12, 0), Vector2(8, -58), Vector2(-8, -58)])
	draw_colored_polygon(pts, Color(0.95, 0.93, 0.88))
	for i in 3:  # garis merah
		var y0 := -12.0 - i * 16.0
		var w0 := 12.0 - (i * 16 + 12) * 4.0 / 58.0
		var w1 := 12.0 - (i * 16 + 20) * 4.0 / 58.0
		draw_colored_polygon(PackedVector2Array([Vector2(-w0, y0), Vector2(w0, y0), Vector2(w1, y0 - 8), Vector2(-w1, y0 - 8)]), Color(0.75, 0.15, 0.12))
	draw_polyline(pts + PackedVector2Array([pts[0]]), OUTLINE, 1.0)
	draw_rect(Rect2(-10, -66, 20, 8), OUTLINE)
	draw_rect(Rect2(-8, -65, 16, 6), Color(1, 0.9, 0.4))  # lampu
	draw_circle(Vector2(0, -62), 14, Color(1, 0.9, 0.4, 0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(-11, -66), Vector2(11, -66), Vector2(0, -76)]), Color(0.75, 0.15, 0.12))


func _pinisi() -> void:
	var sway := sin(variant * 20.0) * 1.5
	_ellipse(Vector2(0, 4), 36, 5, Color(0.1, 0.25, 0.35, 0.5))
	var hull := PackedVector2Array([Vector2(-36, -10), Vector2(36, -14), Vector2(28, 0), Vector2(-26, 2)])
	draw_colored_polygon(hull, Color(0.45, 0.27, 0.14))
	draw_polyline(hull + PackedVector2Array([hull[0]]), OUTLINE, 1.0)
	draw_line(Vector2(-34, -9), Vector2(34, -13), Color(0.8, 0.7, 0.45), 2.0)
	for m in [-12, 12]:  # dua tiang dengan layar segitiga khas pinisi
		var base := Vector2(m, -11)
		draw_line(base, base + Vector2(sway, -46), KAYU_GELAP, 2.0)
		draw_colored_polygon(PackedVector2Array([base + Vector2(sway, -44), base + Vector2(sway, -14), base + Vector2(18, -16)]), Color(0.95, 0.9, 0.78))
		draw_colored_polygon(PackedVector2Array([base + Vector2(sway, -44), base + Vector2(sway, -14), base + Vector2(-12, -18)]), Color(0.88, 0.82, 0.7))
	draw_line(Vector2(12, -57), Vector2(12, -62), Color(0.85, 0.12, 0.12), 3.0)  # bendera merah putih kecil
	draw_line(Vector2(12, -55), Vector2(12, -57), Color(1, 1, 1), 3.0)


func _tembok(size: Vector2) -> void:
	_ellipse(Vector2(0, 2), size.x / 2 + 4, 5, SHADOW)
	var r := Rect2(-size.x / 2, -size.y, size.x, size.y)
	draw_rect(r.grow(1), OUTLINE)
	draw_rect(r, BESI)
	for y in range(int(r.position.y) + 5, 0, 6):  # susunan bata
		draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), BESI_GELAP, 1.0)
	for x in range(int(r.position.x), int(r.end.x), 10):  # gerigi atas
		draw_rect(Rect2(x, r.position.y - 5, 6, 5), BESI)
		draw_rect(Rect2(x, r.position.y - 5, 6, 5), OUTLINE, false, 1.0)
	draw_rect(Rect2(r.position.x, -6, r.size.x, 2), MERAH_BESI)


func _tembok_v() -> void:
	_ellipse(Vector2(0, 2), 10, 4, SHADOW)
	var r := Rect2(-6, -70, 12, 70)
	draw_rect(r.grow(1), OUTLINE)
	draw_rect(r, BESI.darkened(0.1))
	for y in range(-66, 0, 8):
		draw_line(Vector2(-6, y), Vector2(6, y), BESI_GELAP, 1.0)
	draw_rect(Rect2(-6, -12, 12, 12), BESI)  # muka depan


func _meriam_benteng() -> void:
	_ellipse(Vector2(0, 2), 14, 4, SHADOW)
	draw_rect(Rect2(-11, -8, 22, 8), OUTLINE)
	draw_rect(Rect2(-10, -7, 20, 6), KAYU)
	draw_circle(Vector2(-7, -1), 3.5, KAYU_GELAP)
	draw_circle(Vector2(7, -1), 3.5, KAYU_GELAP)
	draw_colored_polygon(PackedVector2Array([Vector2(-8, -8), Vector2(-6, -13), Vector2(16, -19), Vector2(17, -14)]), BESI_GELAP)
	draw_circle(Vector2(17, -16.5), 2.5, OUTLINE)


func _menara() -> void:
	_ellipse(Vector2(0, 2), 20, 5, SHADOW)
	draw_rect(Rect2(-13, -50, 26, 50), OUTLINE)
	draw_rect(Rect2(-12, -49, 24, 48), BESI)
	for y in range(-45, 0, 7):
		draw_line(Vector2(-12, y), Vector2(12, y), BESI_GELAP, 1.0)
	draw_rect(Rect2(-4, -12, 8, 12), Color(0.1, 0.1, 0.1))
	draw_rect(Rect2(-16, -56, 32, 7), BESI.lightened(0.1))
	for x in range(-16, 16, 8):
		draw_rect(Rect2(x, -61, 5, 5), BESI.lightened(0.1))
	draw_line(Vector2(0, -61), Vector2(0, -80), BESI_GELAP, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -80), Vector2(16, -76), Vector2(1, -72)]), MERAH_BESI)


func _panji() -> void:
	_ellipse(Vector2(0, 1), 6, 2, SHADOW)
	draw_line(Vector2(0, 0), Vector2(0, -40), BESI_GELAP, 2.0)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -40), Vector2(14, -40), Vector2(14, -22), Vector2(7, -26), Vector2(1, -22)]), MERAH_BESI)
	draw_rect(Rect2(5, -36, 5, 5), BESI.lightened(0.3))  # lambang besi


func _candi() -> void:
	_ellipse(Vector2(0, 2), 42, 8, SHADOW)
	var tiers := [Rect2(-36, -10, 72, 10), Rect2(-29, -20, 58, 10), Rect2(-22, -30, 44, 10),
		Rect2(-15, -54, 30, 24), Rect2(-12, -60, 24, 6), Rect2(-9, -66, 18, 6), Rect2(-6, -71, 12, 5)]
	for i in tiers.size():
		var r: Rect2 = tiers[i]
		draw_rect(r.grow(1), OUTLINE)
		draw_rect(r, BATU if i % 2 == 0 else BATU.lightened(0.08))
		for y in range(int(r.position.y) + 3, int(r.end.y), 4):
			draw_line(Vector2(r.position.x, y), Vector2(r.end.x, y), BATU_GELAP, 1.0)
	# Pintu & relung
	draw_rect(Rect2(-5, -48, 10, 18), Color(0.12, 0.1, 0.08))
	draw_rect(Rect2(-6, -50, 12, 3), BATU.lightened(0.15))
	draw_rect(Rect2(-5, -30, 10, 30), BATU.darkened(0.15))  # tangga
	for y in range(-28, 0, 3):
		draw_line(Vector2(-5, y), Vector2(5, y), BATU_GELAP, 1.0)
	# Stupa puncak
	_circle(Vector2(0, -76), 5, BATU.lightened(0.1))
	draw_line(Vector2(0, -81), Vector2(0, -88), OUTLINE, 2.0)
