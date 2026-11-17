extends Control
## Menu utama + lobby room online.

const SETTINGS := "user://settings.cfg"
const AudioSettings := preload("res://scripts/audio_settings.gd")

@onready var main_panel: Control = %MainPanel
@onready var lobby_panel: Control = %LobbyPanel
@onready var name_edit: LineEdit = %NameEdit
@onready var code_edit: LineEdit = %CodeEdit
@onready var code_label: Label = %CodeLabel
@onready var player_list: VBoxContainer = %PlayerList
@onready var start_btn: Button = %StartBtn
@onready var status: Label = %Status


func _ready() -> void:
	get_tree().paused = false
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		Net.my_name = cfg.get_value("player", "name", Net.my_name)
		Net.my_outfit = cfg.get_value("player", "outfit", Net.my_outfit)
	name_edit.text = Net.my_name
	status.text = Net.last_message

	%PrevBtn.pressed.connect(func(): _change_outfit(-1))
	%NextBtn.pressed.connect(func(): _change_outfit(1))
	%SettingsPanel.add_child(AudioSettings.new())
	%SettingsPanel.hide()
	%SettingsBtn.pressed.connect(func(): %SettingsPanel.visible = not %SettingsPanel.visible)
	Sfx.play_music()
	%SoloBtn.pressed.connect(func(): _save_name(); Net.start_solo())
	%HostBtn.pressed.connect(func(): _save_name(); Net.host_room())
	%JoinBtn.pressed.connect(_on_join)
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


func _on_join() -> void:
	if code_edit.text.strip_edges().length() != 5:
		status.text = "Masukkan 5 huruf kode room."
		return
	_save_name()
	Net.join_room(code_edit.text)


func _save_name() -> void:
	var n := name_edit.text.strip_edges().substr(0, 12)
	Net.my_name = n if n != "" else "Pejuang"
	var cfg := ConfigFile.new()
	cfg.set_value("player", "name", Net.my_name)
	cfg.set_value("player", "outfit", Net.my_outfit)
	cfg.save(SETTINGS)


func _change_outfit(step: int) -> void:
	Net.set_outfit(Net.my_outfit + step)
	_save_name()
	_refresh()


func _refresh() -> void:
	Net.expose_state()
	var outfit: Dictionary = Net.KERAJAAN[Net.my_outfit]
	%OutfitIcon.texture = outfit.texture
	%OutfitName.text = "Prajurit " + outfit.name
	%OutfitName.modulate = outfit.color.lightened(0.4)
	main_panel.visible = not Net.online
	lobby_panel.visible = Net.online
	if not Net.online:
		return
	code_label.text = "KODE ROOM:  %s" % Net.room_code if Net.room_code != "" else "Room lokal"
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
		l.text = "%s  -  Prajurit %s%s" % [Net.name_of(id), k.name, "  (host)" if id == 1 else ""]
		l.modulate = k.color.lightened(0.4)
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(l)
		player_list.add_child(row)
	if ids.is_empty():
		var l := Label.new()
		l.text = "..."
		player_list.add_child(l)
