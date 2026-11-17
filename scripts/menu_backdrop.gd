extends Control
## Latar menu bergerak: senja di Nusantara. Gunung berapi berasap, siluet candi,
## awan & burung, kunang-kunang, dan barisan prajurit 8 kerajaan membawa merah putih.

const SKY := [
	[0.0, Color(0.1, 0.07, 0.22)],
	[0.35, Color(0.38, 0.17, 0.36)],
	[0.55, Color(0.82, 0.38, 0.32)],
	[0.7, Color(0.99, 0.72, 0.38)],
]
const GUNUNG_JAUH := Color(0.42, 0.22, 0.38)
const GUNUNG_DEKAT := Color(0.26, 0.13, 0.26)
const SILUET := Color(0.13, 0.07, 0.14)
const SAWAH := [Color(0.1, 0.17, 0.12), Color(0.13, 0.22, 0.14), Color(0.08, 0.13, 0.1)]

var _t := 0.0
var _clouds := []
var _fireflies := []
var _birds := []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	for i in 6:
		_clouds.append({"x": rng.randf(), "y": rng.randf_range(0.08, 0.38), "s": rng.randf_range(0.6, 1.3), "v": rng.randf_range(0.004, 0.012)})
	for i in 30:
		_fireflies.append({"x": rng.randf(), "y": rng.randf_range(0.72, 0.98), "p": rng.randf() * TAU})
	for i in 5:
		_birds.append({"x": rng.randf(), "y": rng.randf_range(0.15, 0.4), "p": rng.randf() * TAU, "v": rng.randf_range(0.02, 0.035)})


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	_draw_sky(w, h)
	_draw_sun(Vector2(w * 0.86, h * 0.58), h * 0.12)
	for c in _clouds:
		var x: float = fposmod(c.x + _t * c.v, 1.3) - 0.15
		_cloud(Vector2(x * w, c.y * h), c.s * h * 0.05)
	_draw_mountains(w, h)
	var sc := h / 360.0
	_draw_candi(Vector2(w * 0.86, h * 0.71), sc)
	_palm(Vector2(w * 0.05, h * 0.88), sc * 1.2, 1)
	_palm(Vector2(w * 0.95, h * 0.86), sc * 1.1, -1)
	_palm(Vector2(w * 0.72, h * 0.8), sc * 0.8, -1)
	for b in _birds:
		var x: float = fposmod(b.x + _t * b.v, 1.2) - 0.1
		_bird(Vector2(x * w, b.y * h + sin(_t + b.p) * 6), sin(_t * 8 + b.p))
	_draw_sawah(w, h)
	_draw_march(w, h)
	for f in _fireflies:
		var p := Vector2(f.x * w + sin(_t * 0.7 + f.p) * 14, f.y * h + cos(_t * 0.9 + f.p) * 8)
		var a := 0.35 + 0.65 * maxf(0.0, sin(_t * 2.0 + f.p))
		draw_circle(p, 3.0, Color(1, 0.9, 0.4, a * 0.25))
		draw_circle(p, 1.2, Color(1, 0.95, 0.6, a))


func _draw_sky(w: float, h: float) -> void:
	for i in SKY.size() - 1:
		var y0: float = SKY[i][0] * h
		var y1: float = SKY[i + 1][0] * h
		draw_polygon(PackedVector2Array([Vector2(0, y0), Vector2(w, y0), Vector2(w, y1), Vector2(0, y1)]),
			PackedColorArray([SKY[i][1], SKY[i][1], SKY[i + 1][1], SKY[i + 1][1]]))
	draw_rect(Rect2(0, SKY[-1][0] * h, w, h), SKY[-1][1])
	for i in 24:  # bintang redup di langit atas
		var p := Vector2(fposmod(i * 97.3, 1.0) * w, fposmod(i * 41.7, 1.0) * h * 0.3)
		draw_circle(p, 0.8, Color(1, 1, 1, 0.3 + 0.3 * sin(_t * 1.5 + i)))


func _draw_sun(c: Vector2, r: float) -> void:
	for i in 5:
		draw_circle(c, r * (2.2 - i * 0.25), Color(1, 0.75, 0.4, 0.06))
	draw_circle(c, r, Color(1, 0.86, 0.52))
	for i in 4:  # garis-garis senja di bawah matahari
		var y := c.y + r * (0.15 + i * 0.22)
		draw_line(Vector2(c.x - r, y), Vector2(c.x + r, y), Color(0.96, 0.6, 0.38), 1.5 + i * 0.8)


func _cloud(p: Vector2, r: float) -> void:
	var col := Color(1, 0.7, 0.6, 0.55)
	draw_circle(p, r, col)
	draw_circle(p + Vector2(r * 1.1, r * 0.2), r * 0.8, col)
	draw_circle(p + Vector2(-r * 1.1, r * 0.25), r * 0.7, col)
	draw_circle(p + Vector2(r * 0.3, -r * 0.5), r * 0.75, col)


func _draw_mountains(w: float, h: float) -> void:
	# Gunung berapi jauh (kawah datar) + asap
	var crater := Vector2(w * 0.2, h * 0.36)
	draw_colored_polygon(PackedVector2Array([Vector2(-w * 0.1, h * 0.72), Vector2(crater.x - w * 0.025, crater.y),
		Vector2(crater.x + w * 0.025, crater.y), Vector2(w * 0.5, h * 0.72)]), GUNUNG_JAUH)
	for i in 6:
		var k := fposmod(_t * 0.08 + i / 6.0, 1.0)
		draw_circle(crater + Vector2(sin(k * 5 + i) * 8 + k * 40, -k * h * 0.22), 4 + k * 22, Color(0.75, 0.62, 0.68, 0.35 * (1 - k)))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.35, h * 0.72), Vector2(w * 0.55, h * 0.47),
		Vector2(w * 0.62, h * 0.5), Vector2(w * 0.7, h * 0.44), Vector2(w * 1.1, h * 0.72)]), GUNUNG_JAUH.lightened(0.05))
	# Bukit dekat
	var pts := PackedVector2Array([Vector2(0, h)])
	for i in 13:
		var x := w * i / 12.0
		pts.append(Vector2(x, h * (0.66 + 0.04 * sin(i * 1.3) + 0.02 * sin(i * 3.1))))
	pts.append(Vector2(w, h))
	draw_colored_polygon(pts, GUNUNG_DEKAT)


func _draw_candi(base: Vector2, sc: float) -> void:
	# Siluet candi bertingkat dengan stupa-stupa kecil (lebar/tinggi dalam piksel @360p).
	var tiers := [[96, 7], [80, 6], [66, 6], [52, 6], [38, 5], [26, 5]]
	var y := base.y
	for t in tiers:
		var tw: float = t[0] * sc
		var th: float = t[1] * sc
		draw_rect(Rect2(base.x - tw / 2, y - th, tw, th), SILUET)
		for k in range(-2, 3):
			draw_circle(Vector2(base.x + k * tw / 5.0, y - th), 2.2 * sc, SILUET)
		y -= th
	draw_circle(Vector2(base.x, y - 3 * sc), 7 * sc, SILUET)
	draw_line(Vector2(base.x, y - 8 * sc), Vector2(base.x, y - 18 * sc), SILUET, 2.0 * sc)


func _palm(base: Vector2, sc: float, dir: float) -> void:
	var sway := sin(_t * 1.2 + base.x) * 3.0 * sc
	var top := base + Vector2(dir * 10 * sc + sway, -70 * sc)
	var pts := PackedVector2Array()
	for i in 9:
		var k := i / 8.0
		pts.append(base.lerp(top, k) + Vector2(dir * sin(k * PI) * 7 * sc, 0))
	draw_polyline(pts, SILUET, 4.0 * sc)
	for i in 7:
		var a := PI + i * PI / 6.0 + sin(_t * 1.5 + i) * 0.06
		var tip := top + Vector2(cos(a), sin(a) * 0.5 + 0.45) * 32 * sc
		var side := Vector2(cos(a + 1.57), sin(a + 1.57)) * 3 * sc
		draw_colored_polygon(PackedVector2Array([top, tip + side, tip, tip - side]), SILUET)


func _bird(p: Vector2, flap: float) -> void:
	var wing := Vector2(6, -3 * flap)
	draw_line(p, p + Vector2(-wing.x, wing.y), SILUET, 1.5)
	draw_line(p, p + wing, SILUET, 1.5)


func _draw_sawah(w: float, h: float) -> void:
	# Teras sawah melengkung, air memantulkan langit senja
	for i in 4:
		var y0 := h * (0.74 + i * 0.07)
		var pts := PackedVector2Array([Vector2(0, h)])
		for k in 17:
			var x := w * k / 16.0
			pts.append(Vector2(x, y0 + sin(k * 0.6 + i) * 6))
		pts.append(Vector2(w, h))
		draw_colored_polygon(pts, SAWAH[i % SAWAH.size()])
		for k in 8:
			var x := fposmod(k * 0.137 + i * 0.31, 1.0) * w
			var shimmer := 0.3 + 0.3 * sin(_t * 2 + k + i)
			draw_line(Vector2(x, y0 + 12), Vector2(x + 26, y0 + 12), Color(1, 0.65, 0.4, shimmer * 0.6), 1.0)


func _draw_march(w: float, h: float) -> void:
	var y := h * 0.93
	var spacing := 34.0
	var lead := fposmod(_t * 26.0, w + spacing * 10) - spacing
	for i in Net.KERAJAAN.size():
		var x := lead - i * spacing
		var bob := -absf(sin(_t * 7 + i)) * 3
		var tex: Texture2D = Net.KERAJAAN[i].texture
		draw_texture_rect(tex, Rect2(Vector2(x - 16, y - 32 + bob), Vector2(32, 32)), false)
		if i == 0:  # pembawa bendera merah putih
			var pole := Vector2(x + 12, y - 30 + bob)
			draw_line(pole, pole + Vector2(0, -26), Color(0.3, 0.2, 0.1), 2.0)
			var wave_off := sin(_t * 6) * 2
			draw_colored_polygon(PackedVector2Array([pole + Vector2(1, -26), pole + Vector2(19, -25 + wave_off), pole + Vector2(19, -19 + wave_off), pole + Vector2(1, -20)]), Color(0.85, 0.12, 0.12))
			draw_colored_polygon(PackedVector2Array([pole + Vector2(1, -20), pole + Vector2(19, -19 + wave_off), pole + Vector2(19, -13 + wave_off), pole + Vector2(1, -14)]), Color(0.97, 0.95, 0.9))
