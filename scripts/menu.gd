extends Control
## Menu utama: 1. pejuang (baju & nama), 2. karakter, 3. mulai (sendiri / online) + lobby.

const SETTINGS := "user://settings.cfg"
const AudioSettings := preload("res://scripts/audio_settings.gd")
const HowToPlay := preload("res://scripts/how_to_play.gd")
const SELECTED := Color(1.0, 0.85, 0.35)

@onready var main_panel: Control = %MainPanel
@onready var lobby_panel: Control = %LobbyPanel
@onready var name_edit: LineEdit = %NameEdit
@onready var code_edit: LineEdit = %CodeEdit
@onready var code_label: Label = %CodeLabel
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_btn: Button = %StartBtn
@onready var status: Label = %Status

var _how: Control
var _t := 0.0


func _ready() -> void:
	get_tree().paused = false
	var cfg := ConfigFile.new()
	var first_time := true
	if cfg.load(SETTINGS) == OK:
		Net.my_name = cfg.get_value("player", "name", Net.my_name)
		Net.my_outfit = cfg.get_value("player", "outfit", Net.my_outfit)
		Net.my_character = cfg.get_value("player", "character", Net.my_character)
		first_time = not cfg.get_value("player", "tutorial_seen", false)
	if not Net.is_unlocked(Net.characters[Net.my_character % Net.characters.size()]):
		Net.my_character = 0
	name_edit.text = Net.my_name
	status.text = Net.last_message
	name_edit.text_changed.connect(func(_t): _save())

	_build_outfits()
	_build_characters()
	%SettingsPanel.add_child(AudioSettings.new())
	%SettingsPanel.hide()
	%SettingsBtn.pressed.connect(func(): %SettingsPanel.visible = not %SettingsPanel.visible)
	Sfx.play_music()
	%SoloBtn.pressed.connect(func(): _save(); Net.start_solo())
	%HostBtn.pressed.connect(func(): _save(); Net.host_room())
	%JoinBtn.pressed.connect(_on_join)
	%HowBtn.pressed.connect(_open_how)
	code_edit.text_submitted.connect(func(_t): _on_join())
	code_edit.text_changed.connect(func(t):
		var col := code_edit.caret_column
		code_edit.text = t.to_upper()
		code_edit.caret_column = col)
	start_btn.pressed.connect(Net.start_game)
	%CopyBtn.pressed.connect(func():
		DisplayServer.clipboard_set(Net.invite_link())
		status.text = "Link undangan disalin! Kirim ke temanmu.")
	%LeaveBtn.pressed.connect(func(): Net.leave())
	Net.players_changed.connect(_refresh)
	Net.status_changed.connect(func(t): status.text = t; _refresh())
	_refresh()

	var room := Net.room_from_url()
	if room != "" and not Net.url_join_used:
		Net.url_join_used = true
		code_edit.text = room
		_on_join()
	elif first_time:
		_open_how()


func _process(delta: float) -> void:
	# Pratinjau prajurit bernapas/melompat kecil.
	_t += delta
	var preview: TextureRect = %Preview
	preview.pivot_offset = preview.size / 2
	preview.scale = Vector2.ONE * (1.0 + absf(sin(_t * 3.0)) * 0.06)


func _open_how() -> void:
	if _how == null:
		_how = HowToPlay.new()
		_how.closed.connect(func():
			var cfg := ConfigFile.new()
			cfg.load(SETTINGS)
			cfg.set_value("player", "tutorial_seen", true)
			cfg.save(SETTINGS))
		add_child(_how)
	_how.show()


func _on_join() -> void:
	if code_edit.text.strip_edges().length() != 5:
		status.text = "Masukkan 5 huruf kode room dari temanmu."
		return
	_save()
	Net.join_room(code_edit.text)


func _save() -> void:
	var n := name_edit.text.strip_edges().substr(0, 12)
	Net.my_name = n if n != "" else "Pejuang"
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)  # jangan hapus pengaturan lain (volume, progres)
	cfg.set_value("player", "name", Net.my_name)
	cfg.set_value("player", "outfit", Net.my_outfit)
	cfg.set_value("player", "character", Net.my_character)
	cfg.save(SETTINGS)


# --- Baju & karakter ----------------------------------------------------------

func _build_outfits() -> void:
	for i in Net.KERAJAAN.size():
		var k: Dictionary = Net.KERAJAAN[i]
		var b := Button.new()
		b.icon = k.texture
		b.tooltip_text = "Prajurit " + k.name
		b.custom_minimum_size = Vector2(32, 26)
		b.expand_icon = true
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func():
			Net.set_outfit(i)
			_save()
			_refresh())
		%OutfitGrid.add_child(b)


func _build_characters() -> void:
	for i in Net.characters.size():
		var c: CharacterData = Net.characters[i]
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.icon = c.start_weapon.texture
		b.custom_minimum_size = Vector2(0, 30)
		b.add_theme_font_size_override("font_size", 8)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func():
			Net.set_character(i)
			_save()
			_refresh())
		%CharList.add_child(b)


func _refresh() -> void:
	Net.expose_state()
	var outfit: Dictionary = Net.KERAJAAN[Net.my_outfit]
	%Preview.texture = outfit.texture
	%OutfitName.text = "Prajurit " + outfit.name
	%OutfitName.modulate = outfit.color.lightened(0.4)
	for i in %OutfitGrid.get_child_count():
		%OutfitGrid.get_child(i).modulate = SELECTED if i == Net.my_outfit else Color(1, 1, 1, 0.75)

	for i in %CharList.get_child_count():
		var b: Button = %CharList.get_child(i)
		var c: CharacterData = Net.characters[i]
		var unlocked := Net.is_unlocked(c)
		var picked := i == Net.my_character
		b.disabled = not unlocked
		b.text = ("> " if picked else "") + c.title + "\n" + (
			"%s   |   %s" % [c.pros, c.cons] if unlocked else "Terkunci: capai wave %d (terbaik %d)" % [c.unlock_wave, Net.best_wave])
		b.tooltip_text = "Senjata awal: %s" % c.start_weapon.title
		b.modulate = SELECTED if picked else Color.WHITE

	var online := Net.online
	main_panel.visible = not online
	lobby_panel.visible = online
	name_edit.editable = not online
	if not online:
		return
	code_label.text = "KODE: %s" % Net.room_code if Net.room_code != "" else "Room lokal"
	start_btn.visible = Net.is_room_host()
	%CopyBtn.visible = Net.is_room_host() and Net.invite_link() != ""
	for c in player_list.get_children():
		c.queue_free()
	var ids := Net.players.keys()
	ids.sort()
	for id in ids:
		var k := Net.kerajaan_of(id)
		var row := HBoxContainer.new()
		var icon := TextureRect.new()
		icon.texture = k.texture
		icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
		row.add_child(icon)
		var l := Label.new()
		l.text = "%s%s\n%s" % [Net.name_of(id), "  [host]" if id == 1 else "", Net.character_of(id).title]
		l.add_theme_font_size_override("font_size", 8)
		l.modulate = k.color.lightened(0.4)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(l)
		player_list.add_child(row)
	if ids.is_empty():
		var l := Label.new()
		l.text = "Menyambung..."
		player_list.add_child(l)
