extends Node
## Autoload "Net": lobby co-op online.
##
## Host membuat room dengan kode 5 huruf. Pemain saling ketemu lewat broker MQTT
## publik (cuma tukar SDP/ICE, topik per room), lalu data game lewat WebRTC.
## Topologi bintang: host = peer 1 dan memegang musuh, wave, dan rempah.
## ENet (host_enet/join_enet) hanya untuk tes lokal di desktop.

signal players_changed
signal status_changed(text: String)

## shortcut: broker publik gratis tanpa jaminan uptime & isi topik bisa dibaca orang lain;
## ganti ke broker/server signaling sendiri kalau game sudah dirilis serius.
const SIGNALING_URL := "wss://broker.emqx.io:8084/mqtt"
const TOPIC := "laskarnus/v1/%s/%s"  # room, id signaling penerima
const CODE_CHARS := "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
const MAX_PLAYERS := 4
const JOIN_TIMEOUT := 12.0
const ICE_CONFIG := {"iceServers": [{"urls": ["stun:stun.l.google.com:19302", "stun:stun1.l.google.com:19302"]}]}
const GAME_SCENE := "res://scenes/main.tscn"
const CHARACTER_DIR := "res://data/characters/"
const SETTINGS := "user://settings.cfg"
const MENU_SCENE := "res://scenes/menu.tscn"

## Seragam yang bisa dipilih pemain ("ganti baju").
const KERAJAAN := [
	{"name": "Majapahit", "texture": preload("res://assets/sprites/prajurit_majapahit.png"), "color": Color(0.85, 0.2, 0.15)},
	{"name": "Sriwijaya", "texture": preload("res://assets/sprites/prajurit_sriwijaya.png"), "color": Color(0.3, 0.55, 0.95)},
	{"name": "Mataram", "texture": preload("res://assets/sprites/prajurit_mataram.png"), "color": Color(0.3, 0.75, 0.35)},
	{"name": "Pajajaran", "texture": preload("res://assets/sprites/prajurit_pajajaran.png"), "color": Color(0.7, 0.4, 0.9)},
	{"name": "Samudra Pasai", "texture": preload("res://assets/sprites/prajurit_samudra_pasai.png"), "color": Color(0.9, 0.3, 0.3)},
	{"name": "Gowa", "texture": preload("res://assets/sprites/prajurit_gowa.png"), "color": Color(0.9, 0.7, 0.3)},
	{"name": "Kutai", "texture": preload("res://assets/sprites/prajurit_kutai.png"), "color": Color(0.95, 0.55, 0.2)},
	{"name": "Ternate", "texture": preload("res://assets/sprites/prajurit_ternate.png"), "color": Color(0.3, 0.75, 0.75)},
]

## Tingkat kesulitan (dipakai host saat spawn musuh): pengali HP, damage, dan jumlah musuh.
const DIFFICULTIES := [
	{"name": "Mudah", "hp": 0.7, "dmg": 0.7, "count": 0.8, "color": Color(0.5, 0.85, 0.45)},
	{"name": "Normal", "hp": 1.0, "dmg": 1.0, "count": 1.0, "color": Color(0.95, 0.85, 0.4)},
	{"name": "Sulit", "hp": 1.6, "dmg": 1.4, "count": 1.3, "color": Color(0.95, 0.55, 0.25)},
	{"name": "Neraka", "hp": 2.5, "dmg": 2.0, "count": 1.6, "color": Color(0.95, 0.25, 0.25)},
]

var players := {}  # peer_id -> {"name": String, "outfit": int, "char": int}
var room_code := ""
var my_name := "Pejuang"
var my_outfit := 0
var my_character := 0
var difficulty := 1
## Karakter dari data/characters/, urut sesuai `order`.
var characters: Array[CharacterData] = []
## Wave tertinggi yang pernah dicapai (membuka karakter baru), disimpan di settings.
var best_wave := 0
var in_game := false
var online := false
## Pesan yang ditampilkan menu setelah kembali (misal "Host keluar").
var last_message := ""
## Link ?room= hanya dipakai sekali per sesi (bukan tiap kembali ke menu).
var url_join_used := false

var _hosting := false  # peran di signaling; multiplayer.is_server() true juga saat offline
var _ws: WebSocketPeer
var _ws_state := WebSocketPeer.STATE_CLOSED
var _heartbeat := 0.0
var _sid := ""  # id signaling kita: "host" atau acak untuk client
var _rx := PackedByteArray()
var _rtc: WebRTCMultiplayerPeer
var _conns := {}  # signaling id -> WebRTCPeerConnection
var _host_signal_id := ""
var _next_peer_id := 2
var _join_timer := 0.0


func _ready() -> void:
	for file in ResourceLoader.list_directory(CHARACTER_DIR):
		if file.ends_with(".tres"):
			characters.append(load(CHARACTER_DIR + file))
	characters.sort_custom(func(a, b): return a.order < b.order)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		best_wave = cfg.get_value("progress", "best_wave", 0)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(func(): _fail("Gagal terhubung ke host."))
	multiplayer.server_disconnected.connect(func(): leave("Host terputus."))


func is_host() -> bool:
	return multiplayer.is_server()


## Pembuat room di lobby (beda dengan is_host(): client yang belum tersambung juga "server" offline).
func is_room_host() -> bool:
	return _hosting


func kerajaan_of(peer_id: int) -> Dictionary:
	return KERAJAAN[int(players.get(peer_id, {}).get("outfit", 0)) % KERAJAAN.size()]


func name_of(peer_id: int) -> String:
	return str(players.get(peer_id, {}).get("name", "?"))


## Ganti baju. Di lobby online, host meneruskan ke semua pemain.
func set_outfit(outfit: int) -> void:
	my_outfit = posmod(outfit, KERAJAAN.size())
	var me := multiplayer.get_unique_id()
	if players.has(me):
		if is_host():
			players[me].outfit = my_outfit
			_set_players.rpc(players)
		else:
			_request_outfit.rpc_id(1, my_outfit)
	players_changed.emit()


@rpc("any_peer", "reliable")
func _request_outfit(outfit: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if is_host() and players.has(id) and not in_game:
		players[id].outfit = posmod(outfit, KERAJAAN.size())
		_set_players.rpc(players)


func _me() -> Dictionary:
	return {"name": my_name, "outfit": my_outfit, "char": my_character}


func character_of(peer_id: int) -> CharacterData:
	return characters[int(players.get(peer_id, {}).get("char", 0)) % characters.size()]


## Ganti karakter (hanya yang sudah terbuka). Di lobby online diteruskan lewat host.
func set_character(index: int) -> void:
	my_character = posmod(index, characters.size())
	var me := multiplayer.get_unique_id()
	if players.has(me):
		if is_host():
			players[me].char = my_character
			_set_players.rpc(players)
		else:
			_request_character.rpc_id(1, my_character)
	players_changed.emit()


@rpc("any_peer", "reliable")
func _request_character(index: int) -> void:
	var id := multiplayer.get_remote_sender_id()
	if is_host() and players.has(id) and not in_game:
		players[id].char = posmod(index, characters.size())
		_set_players.rpc(players)


func is_unlocked(c: CharacterData) -> bool:
	return best_wave >= c.unlock_wave


## Catat wave yang dicapai; kembalikan karakter yang baru terbuka karenanya.
func record_wave(wave: int) -> Array[CharacterData]:
	var newly: Array[CharacterData] = []
	if wave <= best_wave:
		return newly
	for c in characters:
		if not is_unlocked(c) and wave >= c.unlock_wave:
			newly.append(c)
	best_wave = wave
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("progress", "best_wave", best_wave)
	cfg.save(SETTINGS)
	return newly


# --- Mulai / keluar -----------------------------------------------------------

func start_solo() -> void:
	_reset()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	players = {1: _me()}
	start_game()


func host_room() -> void:
	_reset()
	online = true
	_hosting = true
	_rtc = WebRTCMultiplayerPeer.new()
	_rtc.create_server()
	multiplayer.multiplayer_peer = _rtc
	players = {1: _me()}
	room_code = _random_code()
	_open_signaling("host")
	_status("Membuat room...")
	players_changed.emit()


func join_room(code: String) -> void:
	_reset()
	online = true
	room_code = code.strip_edges().to_upper()
	_host_signal_id = "host"
	_join_timer = JOIN_TIMEOUT
	_open_signaling(_random_code() + _random_code())
	_status("Mencari room %s..." % room_code)


func host_enet(port: int) -> void:
	_reset()
	online = true
	var peer := ENetMultiplayerPeer.new()
	peer.create_server(port, MAX_PLAYERS)
	multiplayer.multiplayer_peer = peer
	_hosting = true
	players = {1: _me()}
	players_changed.emit()


func join_enet(address: String, port: int) -> void:
	_reset()
	online = true
	var peer := ENetMultiplayerPeer.new()
	peer.create_client(address, port)
	multiplayer.multiplayer_peer = peer


## Host saja: semua peer pindah ke scene game (dipakai juga untuk "main lagi").
func start_game() -> void:
	if not is_host():
		return
	in_game = true
	_close_signaling()  # room ditutup untuk pemain baru
	_load_game.rpc()


func leave(message := "") -> void:
	_reset()
	last_message = message
	get_tree().paused = false
	get_tree().change_scene_to_file(MENU_SCENE)


func _reset() -> void:
	_close_signaling()
	_conns.clear()
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	_rtc = null
	players = {}
	room_code = ""
	_hosting = false
	in_game = false
	online = false
	last_message = ""
	_next_peer_id = 2
	_join_timer = 0.0


func _fail(message: String) -> void:
	var was_online := online
	_reset()
	if was_online:
		_status(message)


func _status(text: String) -> void:
	status_changed.emit(text)


# --- RPC lobby ----------------------------------------------------------------

func _on_connected_to_server() -> void:
	_join_timer = 0.0
	_register.rpc_id(1, my_name, my_outfit, my_character)


@rpc("any_peer", "reliable")
func _register(player_name: String, outfit: int, character: int) -> void:
	if not is_host():
		return
	var id := multiplayer.get_remote_sender_id()
	if in_game or players.size() >= MAX_PLAYERS:
		multiplayer.multiplayer_peer.disconnect_peer(id)
		return
	players[id] = {"name": player_name.substr(0, 12), "outfit": posmod(outfit, KERAJAAN.size()),
		"char": posmod(character, characters.size())}
	_set_players.rpc(players)


@rpc("authority", "call_local", "reliable")
func _set_players(new_players: Dictionary) -> void:
	players = new_players
	expose_state()
	if not is_host():
		_status("Masuk room %s. Tunggu host memulai..." % room_code)
	players_changed.emit()


@rpc("authority", "call_local", "reliable")
func _load_game() -> void:
	in_game = true
	_close_signaling()
	get_tree().paused = false
	get_tree().change_scene_to_file(GAME_SCENE)


func _on_peer_connected(_id: int) -> void:
	pass  # pemain baru dihitung setelah _register


func _on_peer_disconnected(id: int) -> void:
	if players.erase(id) and is_host():
		_set_players.rpc(players)
	players_changed.emit()


# --- Signaling (MQTT 3.1.1 minimal di atas WebSocket) -------------------------

func _process(delta: float) -> void:
	if _join_timer > 0:
		_join_timer -= delta
		if _join_timer <= 0:
			_fail("Room %s tidak ditemukan atau penuh." % room_code)
			return
	if _ws == null:
		return
	_ws.poll()
	var state := _ws.get_ready_state()
	if state == WebSocketPeer.STATE_CLOSED:
		_ws = null
		_ws_state = state
		if _hosting and not in_game:
			_status("Koneksi ke server signaling putus. Teman baru tidak bisa masuk; buat room lagi.")
		elif _join_timer > 0:
			_fail("Tidak bisa menghubungi server signaling.")
		return
	if state != WebSocketPeer.STATE_OPEN:
		_ws_state = state
		return
	if _ws_state != WebSocketPeer.STATE_OPEN:
		_ws_state = state
		# CONNECT: protokol "MQTT" v4, clean session, keepalive 60 detik.
		var body := _mqtt_str("MQTT")
		body.append_array(PackedByteArray([4, 2, 0, 60]))
		body.append_array(_mqtt_str("ln-" + _sid + "-" + _random_code()))
		_ws.send(_mqtt_packet(0x10, body))
	while _ws.get_available_packet_count() > 0:
		_rx.append_array(_ws.get_packet())
	_parse_mqtt()
	_heartbeat -= delta
	if _heartbeat <= 0:
		_heartbeat = 30.0
		_ws.send(PackedByteArray([0xC0, 0]))  # PINGREQ


func _open_signaling(sid: String) -> void:
	_sid = sid
	_rx.clear()
	_heartbeat = 30.0
	_ws = WebSocketPeer.new()
	_ws.supported_protocols = PackedStringArray(["mqtt"])
	_ws.inbound_buffer_size = 1 << 18
	_ws_state = WebSocketPeer.STATE_CONNECTING
	if _ws.connect_to_url(SIGNALING_URL) != OK:
		_fail("Tidak bisa menghubungi server signaling.")


func _close_signaling() -> void:
	if _ws:
		_ws.close()
	_ws = null
	_ws_state = WebSocketPeer.STATE_CLOSED


func _send(dst: String, payload: Dictionary) -> void:
	if _ws == null or _ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	payload["from"] = _sid
	var body := _mqtt_str(TOPIC % [room_code, dst])
	body.append_array(JSON.stringify(payload).to_utf8_buffer())
	_ws.send(_mqtt_packet(0x30, body))  # PUBLISH QoS 0


func _parse_mqtt() -> void:
	while _rx.size() >= 2:
		# Panjang sisa paket: varint mulai byte ke-1.
		var length := 0
		var mult := 1
		var i := 1
		while true:
			if i >= _rx.size():
				return  # paket belum lengkap
			length += (_rx[i] & 127) * mult
			mult *= 128
			i += 1
			if _rx[i - 1] & 128 == 0:
				break
		if _rx.size() < i + length:
			return
		var type := _rx[0] >> 4
		var body := _rx.slice(i, i + length)
		_rx = _rx.slice(i + length)
		match type:
			2:  # CONNACK
				if body.size() < 2 or body[1] != 0:
					_fail("Server signaling menolak koneksi.")
					return
				var sub := PackedByteArray([0, 1])
				sub.append_array(_mqtt_str(TOPIC % [room_code, _sid]))
				sub.append(0)
				_ws.send(_mqtt_packet(0x82, sub))
			9:  # SUBACK: siap menerima pesan
				if _hosting:
					_status("Room siap! Bagikan kodenya.")
					players_changed.emit()
				else:
					_send("host", {"k": "join"})
			3:  # PUBLISH
				var topic_len := (body[0] << 8) | body[1]
				var msg = JSON.parse_string(body.slice(2 + topic_len).get_string_from_utf8())
				if msg is Dictionary:
					_on_signal_payload(str(msg.get("from", "")), msg)


func _mqtt_packet(header: int, body: PackedByteArray) -> PackedByteArray:
	var out := PackedByteArray([header])
	var n := body.size()
	while true:
		var digit := n % 128
		n /= 128
		out.append(digit | 128 if n > 0 else digit)
		if n == 0:
			break
	out.append_array(body)
	return out


func _mqtt_str(text: String) -> PackedByteArray:
	var b := text.to_utf8_buffer()
	var out := PackedByteArray([b.size() >> 8, b.size() & 255])
	out.append_array(b)
	return out


func _on_signal_payload(src: String, p: Dictionary) -> void:
	match p.get("k", ""):
		"join":
			if not _hosting:
				return
			if in_game or players.size() >= MAX_PLAYERS:
				_send(src, {"k": "reject", "reason": "Room penuh atau game sudah mulai."})
				return
			var id := _next_peer_id
			_next_peer_id += 1
			_send(src, {"k": "welcome", "id": id})
			var conn := _new_conn(src, id)
			conn.create_offer()
		"welcome":
			if _hosting or src != _host_signal_id:
				return
			_rtc = WebRTCMultiplayerPeer.new()
			_rtc.create_client(int(p.id))
			multiplayer.multiplayer_peer = _rtc
			_new_conn(src, 1)
			_status("Menyambung ke host...")
		"reject":
			_fail(str(p.get("reason", "Ditolak host.")))
		"sdp":
			if _conns.has(src):
				_conns[src].set_remote_description(str(p.type), str(p.sdp))
		"ice":
			if _conns.has(src):
				_conns[src].add_ice_candidate(str(p.mid), int(p.index), str(p.name))


func _new_conn(signal_id: String, peer_id: int) -> WebRTCPeerConnection:
	var conn := WebRTCPeerConnection.new()
	conn.initialize(ICE_CONFIG)
	conn.session_description_created.connect(func(type: String, sdp: String):
		conn.set_local_description(type, sdp)
		_send(signal_id, {"k": "sdp", "type": type, "sdp": sdp}))
	conn.ice_candidate_created.connect(func(mid: String, index: int, cand: String):
		_send(signal_id, {"k": "ice", "mid": mid, "index": index, "name": cand}))
	_rtc.add_peer(conn, peer_id)
	_conns[signal_id] = conn
	return conn


## Link undangan (web saja): membuka game langsung masuk ke room ini.
func invite_link() -> String:
	if not OS.has_feature("web") or room_code == "":
		return ""
	return str(JavaScriptBridge.eval("location.origin + location.pathname")) + "?room=" + room_code


## Kode room dari URL ?room=KODE (web saja).
func room_from_url() -> String:
	if not OS.has_feature("web"):
		return ""
	var v = JavaScriptBridge.eval("new URLSearchParams(location.search).get('room') || ''")
	return str(v).strip_edges().to_upper()


## Status ringkas di window.laskarState, dipakai tes browser otomatis.
func expose_state(extra := {}) -> void:
	if not OS.has_feature("web"):
		return
	var state := {"room": room_code, "players": players.size(), "online": online, "in_game": in_game}
	state.merge(extra)
	JavaScriptBridge.eval("window.laskarState = " + JSON.stringify(state))


func _random_code() -> String:
	var s := ""
	for i in 5:
		s += CODE_CHARS[randi() % CODE_CHARS.length()]
	return s
