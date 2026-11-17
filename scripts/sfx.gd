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

var muted := false

var _pool: Array[AudioStreamPlayer] = []
var _last := {}
var _music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.stream = preload("res://assets/audio/music_gamelan.wav")
	_music.volume_db = -9.0
	_music.finished.connect(_music.play)
	add_child(_music)
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		set_muted(cfg.get_value("audio", "muted", false), false)
	# Semua tombol berbunyi "klik" tanpa perlu disambung satu per satu.
	get_tree().node_added.connect(func(n):
		if n is BaseButton:
			n.pressed.connect(play.bind("click", -6.0, 0.0)))


func play(sound: String, volume_db := 0.0, pitch_variation := 0.08) -> void:
	var now := Time.get_ticks_msec()
	if now - int(_last.get(sound, -100000)) < MIN_GAP_MS:
		return
	_last[sound] = now
	for p in _pool:
		if not p.playing:
			p.stream = SOUNDS[sound]
			p.volume_db = volume_db
			p.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
			p.play()
			return


func play_music() -> void:
	if not _music.playing:
		_music.play()


func set_muted(value: bool, save := true) -> void:
	muted = value
	AudioServer.set_bus_mute(0, muted)
	if save:
		var cfg := ConfigFile.new()
		cfg.load(SETTINGS)
		cfg.set_value("audio", "muted", muted)
		cfg.save(SETTINGS)
