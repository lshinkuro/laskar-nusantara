extends Node
## Root game. Selalu jalan (process_mode ALWAYS); World di-pause saat toko & akhir.
## Host mengatur alur: tunggu semua scene siap -> wave -> toko -> semua siap -> wave berikut.

enum State { WAITING, PLAYING, SHOP, OVER }

const PlayerScene := preload("res://scenes/player.tscn")
const START_WEAPON := preload("res://data/weapons/sumpit.tres")

var state := State.WAITING
var local_player

var _loaded := {}  # host: peer -> true
var _ready_peers := {}  # host: peer -> true
var _resend_loaded := 0.0

@onready var players: Node2D = $World/Players
@onready var enemies: Node2D = $World/Enemies
@onready var pickups: Node2D = $World/Pickups
@onready var projectiles: Node2D = $World/Projectiles
@onready var waves = $World/WaveManager
@onready var shop = $Shop
@onready var level_up = $LevelUp
@onready var xp_bar: ProgressBar = $HUD/TopLeft/XPBar
@onready var xp_label: Label = $HUD/TopLeft/XPBar/Label
@onready var hp_bar: ProgressBar = $HUD/TopLeft/HPBar
@onready var hp_label: Label = $HUD/TopLeft/HPBar/Label
@onready var rempah_label: Label = $HUD/TopLeft/Rempah/Label
@onready var wave_label: Label = $HUD/WaveLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var team_list: VBoxContainer = $HUD/Team
@onready var message: Label = $HUD/Message
@onready var joystick: Control = $HUD/TouchJoystick
@onready var end_screen: CanvasLayer = $EndScreen


func _ready() -> void:
	get_tree().paused = true
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

	var ids := Net.players.keys()
	ids.sort()
	for i in ids.size():
		_spawn_player(ids[i], i, ids.size())
	local_player = players.get_node(str(multiplayer.get_unique_id()))
	pickups.local_player = local_player
	local_player.hp_changed.connect(_on_hp_changed)
	local_player.rempah_changed.connect(func(n): rempah_label.text = str(n))
	local_player.died.connect(_on_local_died)
	local_player.xp_changed.connect(_on_xp_changed)
	local_player.leveled_up.connect(func(lv): _show_message("NAIK LEVEL %d!" % lv, 0.8))
	_on_xp_changed(0, local_player.xp_needed(), 1)
	local_player.add_weapon(START_WEAPON)
	_on_hp_changed(local_player.hp, local_player.stats.max_hp)

	waves.wave_started.connect(_on_wave_started)
	waves.wave_ended.connect(_on_wave_ended)
	shop.ready_pressed.connect(func(): _player_ready.rpc_id(1))
	level_up.finished.connect(_open_shop)
	$EndScreen/Panel/Box/Buttons/Again.pressed.connect(Net.start_game)
	$EndScreen/Panel/Box/Buttons/Menu.pressed.connect(func(): Net.leave())
	end_screen.hide()
	joystick.hide()
	_show_message("Bersiap...")

	if multiplayer.is_server():
		_mark_loaded(1)


func _spawn_player(id: int, slot: int, total: int) -> void:
	var p := PlayerScene.instantiate()
	p.name = str(id)
	p.set_multiplayer_authority(id)
	p.display_name = Net.name_of(id)
	p.kerajaan = Net.kerajaan_of(id)
	p.projectiles = projectiles
	p.position = waves.arena_size / 2 + Vector2(slot - (total - 1) / 2.0, 0) * 30
	p.died.connect(_check_all_dead)
	players.add_child(p)


func _process(delta: float) -> void:
	wave_label.text = "WAVE %d" % waves.wave if waves.wave > 0 else ""
	timer_label.text = str(ceili(waves.time_left)) if state == State.PLAYING else ""
	_update_team_list()
	# Client mengulang laporan "siap" sampai host memulai (RPC pertama bisa datang
	# sebelum scene host selesai dimuat).
	if state == State.WAITING and not multiplayer.is_server():
		_resend_loaded -= delta
		if _resend_loaded <= 0:
			_resend_loaded = 1.0
			_client_loaded.rpc_id(1)


# --- Alur wave (host) ---------------------------------------------------------

@rpc("any_peer", "reliable")
func _client_loaded() -> void:
	if multiplayer.is_server():
		_mark_loaded(multiplayer.get_remote_sender_id())


func _mark_loaded(id: int) -> void:
	_loaded[id] = true
	_check_all_loaded()


func _check_all_loaded() -> void:
	if waves.wave == 0 and Net.players.keys().all(func(id): return _loaded.has(id)):
		waves.start_wave(1)


@rpc("any_peer", "call_local", "reliable")
func _player_ready() -> void:
	if not multiplayer.is_server():
		return
	var id := multiplayer.get_remote_sender_id()
	_ready_peers[id if id != 0 else 1] = true
	_ready_count.rpc(_ready_peers.size(), Net.players.size())
	_check_all_ready()


func _check_all_ready() -> void:
	if state == State.SHOP and Net.players.keys().all(func(id): return _ready_peers.has(id)):
		_ready_peers.clear()
		waves.start_wave(waves.wave + 1)


@rpc("authority", "call_local", "reliable")
func _ready_count(n: int, total: int) -> void:
	shop.set_ready_count(n, total)


func _check_all_dead() -> void:
	if not multiplayer.is_server() or state != State.PLAYING:
		return
	for p in players.get_children():
		if p.alive and not p.is_queued_for_deletion():
			return
	_game_over.rpc(waves.wave)


@rpc("authority", "call_local", "reliable")
func _game_over(wave: int) -> void:
	waves.stop()
	_finish(false, wave)


# --- Event semua peer ---------------------------------------------------------

func _on_wave_started(wave: int) -> void:
	state = State.PLAYING
	get_tree().paused = false
	shop.hide()
	level_up.hide()
	joystick.show()
	local_player.revive()
	Net.expose_state({"wave": wave, "players_in_game": players.get_child_count()})
	_show_message("WAVE TERAKHIR!" if wave == waves.LAST_WAVE else "WAVE %d" % wave, 1.2)


func _on_wave_ended(wave: int) -> void:
	get_tree().paused = true
	joystick.hide()
	if wave >= waves.LAST_WAVE:
		_finish(true, wave)
		return
	state = State.SHOP
	if local_player.pending_levels > 0:
		level_up.open(local_player)
	else:
		_open_shop()


func _open_shop() -> void:
	shop.open(local_player, waves.wave)
	shop.set_ready_count(0, Net.players.size())


func _on_local_died() -> void:
	if state == State.PLAYING and players.get_child_count() > 1:
		_show_message("Kamu gugur!\nBangkit lagi di wave berikutnya.", 2.5)


func _on_peer_disconnected(id: int) -> void:
	var p := players.get_node_or_null(str(id))
	if p:
		p.queue_free()
	if multiplayer.is_server():
		_loaded.erase(id)
		_ready_peers.erase(id)
		_check_all_loaded()
		_check_all_ready()
		_check_all_dead()


func _finish(won: bool, wave: int) -> void:
	state = State.OVER
	get_tree().paused = true
	shop.hide()
	level_up.hide()
	joystick.hide()
	message.hide()
	$EndScreen/Panel/Box/Title.text = "MERDEKA!" if won else "GUGUR"
	$EndScreen/Panel/Box/Sub.text = "Kekaisaran Besi mundur dari sawah!" if won \
		else "Pasukan bertahan sampai wave %d dari %d." % [wave, waves.LAST_WAVE]
	var host := multiplayer.is_server()
	$EndScreen/Panel/Box/Buttons/Again.visible = host
	$EndScreen/Panel/Box/Wait.visible = not host
	end_screen.show()


# --- HUD ----------------------------------------------------------------------

func _on_hp_changed(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [hp, max_hp]


func _on_xp_changed(xp: int, needed: int, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = xp
	xp_label.text = "Lv %d" % level


func _update_team_list() -> void:
	var others := players.get_children().filter(func(p): return p != local_player and not p.is_queued_for_deletion())
	while team_list.get_child_count() < others.size():
		var l := Label.new()
		l.theme_type_variation = &"Hud"
		l.add_theme_font_size_override("font_size", 8)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		team_list.add_child(l)
	for i in team_list.get_child_count():
		var l: Label = team_list.get_child(i)
		l.visible = i < others.size()
		if l.visible:
			var p = others[i]
			l.text = "%s  %s" % [p.display_name, "%d/%d" % [p.hp, p.stats.max_hp] if p.alive else "gugur"]
			l.modulate = p.kerajaan.color.lightened(0.3)


func _show_message(text: String, duration := 0.0) -> void:
	message.text = text
	message.show()
	message.modulate.a = 1.0
	if duration > 0:
		var t := create_tween()
		t.tween_interval(duration)
		t.tween_property(message, "modulate:a", 0.0, 0.3)
		t.tween_callback(message.hide)
