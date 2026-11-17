extends Control
## Layar "Cara Main": beberapa halaman bergambar, bisa dibuka dari menu & layar jeda.

signal closed

const PAGES := [
	{"title": "Bergerak & Menembak", "tex": "res://assets/sprites/prajurit_majapahit.png",
		"text": "Gerak: WASD / tombol panah, atau sentuh & geser layar di HP.\nSenjata menembak OTOMATIS ke musuh terdekat - tugasmu menghindar!\nTiap senjata membidik musuh yang berbeda."},
	{"title": "Rempah & Pasar Rakyat", "tex": "res://assets/sprites/rempah.png",
		"text": "Musuh yang tumbang menjatuhkan rempah. Dekati untuk mengambil.\nSetelah tiap wave, belanja senjata & item di Pasar Rakyat.\nBeli senjata yang SAMA untuk menggabung: tier naik, peluru bertambah."},
	{"title": "Naik Level & Sinergi", "tex": "res://assets/sprites/ikon_bintang.png",
		"text": "Rempah juga XP. Tiap naik level, pilih 1 ilmu di akhir wave (tombol 1-4).\nKumpulkan 3 senjata sejenis atau item berlabel sama (Kuliner, Busana,\nPusaka) untuk bonus SINERGI."},
	{"title": "Semangat Rakyat", "tex": "res://assets/sprites/warga.png",
		"text": "Warga terkurung muncul di peta (ikuti panah \"!\"). Berdiri di dekatnya\nuntuk membebaskan dan mengisi meter Semangat.\nMeter penuh: tekan SPASI atau tombol PEKIK MERDEKA!"},
	{"title": "Boss & Kemenangan", "tex": "res://assets/sprites/gubernur_jenderal.png",
		"text": "Tiap wave ada boss. Lingkaran merah = hantaman, menyingkirlah!\nKetupat hijau memulihkan HP. Esc / P untuk jeda.\nBertahan 20 wave & kalahkan Gubernur Jenderal Besi. MERDEKA!"},
]

var _page := 0
var _title: Label
var _image: TextureRect
var _text: Label
var _dots: Label
var _prev: Button
var _next: Button


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.75)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(420, 230)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	var head := Label.new()
	head.text = "CARA MAIN"
	head.theme_type_variation = &"Muted"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(head)
	_title = Label.new()
	_title.theme_type_variation = &"Title"
	_title.add_theme_font_size_override("font_size", 16)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_title)
	_image = TextureRect.new()
	_image.custom_minimum_size = Vector2(0, 64)
	_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	box.add_child(_image)
	_text = Label.new()
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.add_theme_font_size_override("font_size", 9)
	_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(_text)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 10)
	box.add_child(nav)
	_prev = Button.new()
	_prev.text = "< Sebelumnya"
	_prev.pressed.connect(func(): _show(_page - 1))
	nav.add_child(_prev)
	_dots = Label.new()
	nav.add_child(_dots)
	_next = Button.new()
	_next.pressed.connect(func():
		if _page == PAGES.size() - 1:
			_close()
		else:
			_show(_page + 1))
	nav.add_child(_next)
	_show(0)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_right"):
		_show(_page + 1)
	elif event.is_action_pressed("ui_left"):
		_show(_page - 1)
	elif event.is_action_pressed("ui_cancel"):
		_close()
	else:
		return
	get_viewport().set_input_as_handled()


func _show(page: int) -> void:
	_page = clampi(page, 0, PAGES.size() - 1)
	var p: Dictionary = PAGES[_page]
	_title.text = p.title
	_image.texture = load(p.tex)
	_text.text = p.text
	var dots := ""
	for i in PAGES.size():
		dots += "[%d] " % (i + 1) if i == _page else "%d " % (i + 1)
	_dots.text = dots.strip_edges()
	_prev.disabled = _page == 0
	_next.text = "Siap Berperang!" if _page == PAGES.size() - 1 else "Lanjut >"
	# Gambar sedikit "melompat" saat ganti halaman.
	_image.pivot_offset = _image.size / 2
	_image.scale = Vector2(0.7, 0.7)
	create_tween().tween_property(_image, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _close() -> void:
	hide()
	closed.emit()
