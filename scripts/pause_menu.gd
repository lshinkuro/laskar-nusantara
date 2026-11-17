extends CanvasLayer
## Layar "JEDA": lanjut, atur volume musik/efek, keluar ke menu.

signal resume_pressed

const AudioSettings := preload("res://scripts/audio_settings.gd")
const HowToPlay := preload("res://scripts/how_to_play.gd")

var _by: Label


func _ready() -> void:
	layer = 4
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.03, 0.02, 0.65)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(240, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)

	var title := Label.new()
	title.text = "JEDA"
	title.theme_type_variation = &"Title"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	_by = Label.new()
	_by.theme_type_variation = &"Muted"
	_by.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_by)
	box.add_child(AudioSettings.new())

	var resume := Button.new()
	resume.text = "Lanjut Berperang"
	resume.pressed.connect(func(): resume_pressed.emit())
	box.add_child(resume)
	var how := Button.new()
	how.text = "? Cara Main"
	how.pressed.connect(func():
		var h := HowToPlay.new()
		h.closed.connect(h.queue_free)
		add_child(h))
	box.add_child(how)
	var quit := Button.new()
	quit.text = "Keluar ke Menu"
	quit.pressed.connect(func(): Net.leave())
	box.add_child(quit)
	hide()


func open(by_name: String) -> void:
	_by.text = "" if by_name == "" else "Dijeda oleh %s" % by_name
	_by.visible = by_name != ""
	show()
