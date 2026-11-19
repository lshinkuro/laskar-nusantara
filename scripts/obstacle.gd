extends Node2D
## Objek medan (pohon, bangunan, batu, kapal, ...) bergambar SVG dari tools/make_art.py.
## Titik origin = kaki/dasar objek, supaya y-sort pas dengan prajurit.

const TEXTURES := {
	"pohon": preload("res://assets/sprites/objek_pohon.svg"),
	"beringin": preload("res://assets/sprites/objek_beringin.svg"),
	"kelapa": preload("res://assets/sprites/objek_kelapa.svg"),
	"batu": preload("res://assets/sprites/objek_batu.svg"),
	"semak": preload("res://assets/sprites/objek_semak.svg"),
	"pisang": preload("res://assets/sprites/objek_pisang.svg"),
	"orang_orangan": preload("res://assets/sprites/objek_orang_orangan.svg"),
	"bebek": preload("res://assets/sprites/objek_bebek.svg"),
	"gubuk": preload("res://assets/sprites/objek_gubuk.svg"),
	"joglo": preload("res://assets/sprites/objek_joglo.svg"),
	"lumbung": preload("res://assets/sprites/objek_lumbung.svg"),
	"candi": preload("res://assets/sprites/objek_candi.svg"),
	"peti": preload("res://assets/sprites/objek_peti.svg"),
	"tong": preload("res://assets/sprites/objek_tong.svg"),
	"mercusuar": preload("res://assets/sprites/objek_mercusuar.svg"),
	"pinisi": preload("res://assets/sprites/objek_pinisi.svg"),
	"tembok": preload("res://assets/sprites/objek_tembok.svg"),
	"tembok_v": preload("res://assets/sprites/objek_tembok_v.svg"),
	"meriam_benteng": preload("res://assets/sprites/objek_meriam_benteng.svg"),
	"menara": preload("res://assets/sprites/objek_menara.svg"),
	"panji": preload("res://assets/sprites/objek_panji.svg"),
}

var kind := "pohon"
var variant := 0.0  # 0..1, variasi kecil ukuran & arah

var _home := Vector2.ZERO
var _t := 0.0


func _ready() -> void:
	# Bebek berenang pelan bolak-balik (hiasan, tidak disinkronkan).
	set_process(kind == "bebek")
	_home = position


func _process(delta: float) -> void:
	_t += delta
	var p := _home + Vector2(sin(_t * 0.4 + variant * 9) * 22, cos(_t * 0.3 + variant * 5) * 14)
	scale.x = -1 if p.x < position.x else 1
	position = p


## Gambar bertumpu di kaki (3 piksel di atas tepi bawah); bebek mengapung di tengahnya.
func _draw() -> void:
	var tex: Texture2D = TEXTURES[kind]
	var size := tex.get_size() / Art.SCALE
	if kind == "bebek":
		draw_texture_rect(tex, Rect2(-size / 2, size), false)
		return
	var k := 0.85 + variant * 0.3 if kind in ["pohon", "batu", "semak"] else 1.0
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(-k if variant < 0.5 else k, k))  # cermin acak
	draw_texture_rect(tex, Rect2(-size.x / 2, 3 - size.y, size.x, size.y), false)
