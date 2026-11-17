extends Node
## Autoload "Sfx": efek suara & musik gamelan (dibuat oleh tools/make_sounds.py).

const SETTINGS := "user://settings.cfg"
const POOL_SIZE := 16
const MIN_GAP_MS := 45  # suara sama tidak diputar lebih rapat dari ini (tembakan beruntun)
const SOUNDS := {
	"shoot": preload("res://assets/audio/shoot.wav"),
	"hit": preload("res://assets/audio/hit.wav"),
	"enemy_die": preload("res://assets/audio/enemy_die.wav"),
	"pickup": preload("res://assets/audio/pickup.wav"),
	"buy": preload("res://assets/audio/buy.wav"),
	"heal": preload("res://assets/audio/heal.wav"),
	"levelup": preload("res://assets/audio/levelup.wav"),
	"hurt": preload("res://assets/audio/hurt.wav"),
	"click": preload("res://assets/audio/click.wav"),
	"wave_start": preload("res://assets/audio/wave_start.wav"),
	"wave_end": preload("res://assets/audio/wave_end.wav"),
	"game_over": preload("res://assets/audio/game_over.wav"),
	"victory": preload("res://assets/audio/victory.wav"),
}

## Volume 0..1 per bus, disimpan di settings.
var music_volume := 0.6
var sfx_volume := 0.8

## Lagu latar per suasana (dibuat tools/make_sounds.py, loop lewat import WAV).
const MUSIC := {
	"menu": preload("res://assets/audio/music_menu.wav"),
	"lembah": preload("res://assets/audio/music_lembah.wav"),
	"hutan": preload("res://assets/audio/music_hutan.wav"),
	"pelabuhan": preload("res://assets/audio/music_pelabuhan.wav"),
	"desa": preload("res://assets/audio/music_desa.wav"),
	"benteng": preload("res://assets/audio/music_benteng.wav"),
	"boss": preload("res://assets/audio/music_boss.wav"),
	"pasar": preload("res://assets/audio/music_pasar.wav"),
}
const MUSIC_DB := -6.0
const FADE := 0.8

var _music_players: Array[AudioStreamPlayer] = []
var _current := 0
var _track := ""
var _fade: Tween
var _pool: Array[AudioStreamPlayer] = []
var _next := 0
var _last := {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Bus "Music" & "SFX" didefinisikan di default_bus_layout.tres (bukan dibuat lewat kode):
	# di web, pemutaran mode sample hanya mengenal bus yang ada sejak engine mulai.
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		_pool.append(p)
	for i in 2:  # dua pemutar untuk crossfade antar lagu
		var m := AudioStreamPlayer.new()
		m.bus = "Music"
		m.volume_db = -60.0
		add_child(m)
		_music_players.append(m)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		music_volume = cfg.get_value("audio", "music", music_volume)
		sfx_volume = cfg.get_value("audio", "sfx", sfx_volume)
	_apply("Music", music_volume)
	_apply("SFX", sfx_volume)
	# Semua tombol berbunyi "klik" tanpa perlu disambung satu per satu.
	get_tree().node_added.connect(func(n):
		if n is BaseButton:
			n.pressed.connect(play.bind("click", -6.0, 0.0))
			_juice(n))


func play(sound: String, volume_db := 0.0, pitch_variation := 0.08) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last.get(sound, -100000)) < MIN_GAP_MS:
		return
	_last[sound] = now
	# Bergiliran (bukan cari yang `playing == false`): di web status playing tidak selalu kembali false.
	var p := _pool[_next]
	_next = (_next + 1) % _pool.size()
	p.stream = SOUNDS[sound]
	p.volume_db = volume_db
	p.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	p.play()


## Ganti lagu latar dengan crossfade (loop diatur di import WAV; sinyal finished tidak andal di web).
func play_music(track := "menu") -> void:
	if track == _track or not MUSIC.has(track):
		return
	_track = track
	# Pergantian cepat berturut-turut: batalkan fade sebelumnya supaya callback stop-nya
	# tidak menghentikan pemutar yang sekarang dipakai ulang.
	if _fade and _fade.is_valid():
		_fade.kill()
	var old := _music_players[_current]
	_current = 1 - _current
	var new := _music_players[_current]
	new.stop()
	new.stream = MUSIC[track]
	new.volume_db = -40.0
	new.play()
	_fade = create_tween().set_parallel()
	_fade.tween_property(new, "volume_db", MUSIC_DB, FADE)
	if old.playing:
		_fade.tween_property(old, "volume_db", -60.0, FADE)
		_fade.chain().tween_callback(old.stop)


func current_track() -> String:
	return _track


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_apply("Music", music_volume)
	_save()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_apply("SFX", sfx_volume)
	_save()


func _apply(bus: String, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus)
	if idx < 0:
		return
	AudioServer.set_bus_mute(idx, value <= 0.001)
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.001)))


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("audio", "music", music_volume)
	cfg.set_value("audio", "sfx", sfx_volume)
	cfg.save(SETTINGS)


## Tombol membesar sedikit saat disorot dan "memantul" saat ditekan (semua layar).
func _juice(b: BaseButton) -> void:
	var to := func(target: float, time: float):
		if not b.is_inside_tree() or b.disabled:
			return
		b.pivot_offset = b.size / 2
		b.create_tween().tween_property(b, "scale", Vector2.ONE * target, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	b.mouse_entered.connect(func(): to.call(1.05, 0.12))
	b.mouse_exited.connect(func(): to.call(1.0, 0.12))
	b.button_down.connect(func(): to.call(0.94, 0.06))
	b.button_up.connect(func(): to.call(1.05 if b.is_hovered() else 1.0, 0.15))
