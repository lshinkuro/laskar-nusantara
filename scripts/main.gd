extends Node
## Root game. Selalu jalan (process_mode ALWAYS); World di-pause antar wave & saat game over.

enum State { PLAYING, BETWEEN_WAVES, OVER }

var state := State.PLAYING

@onready var world: Node2D = $World
@onready var player = $World/Player
@onready var waves = $World/WaveManager
@onready var hp_bar: ProgressBar = $HUD/HPBar
@onready var hp_label: Label = $HUD/HPBar/Label
@onready var wave_label: Label = $HUD/WaveLabel
@onready var message: Label = $HUD/Message


func _ready() -> void:
	player.hp_changed.connect(_on_hp_changed)
	player.died.connect(_on_player_died)
	waves.wave_started.connect(func(_w): message.hide())
	waves.wave_cleared.connect(_on_wave_cleared)
	_on_hp_changed(player.hp, player.max_hp)
	waves.start_next_wave()


func _process(_delta: float) -> void:
	wave_label.text = "Wave %d/%d   %ds" % [waves.wave, waves.LAST_WAVE, ceili(maxf(waves.time_left, 0))]


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed) \
		or (event is InputEventScreenTouch and event.pressed)
	if not pressed:
		return
	match state:
		State.BETWEEN_WAVES:
			state = State.PLAYING
			get_tree().paused = false
			waves.start_next_wave()
		State.OVER:
			get_tree().paused = false
			get_tree().reload_current_scene()


func _on_hp_changed(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [hp, max_hp]


func _on_wave_cleared(wave: int) -> void:
	get_tree().paused = true
	if wave >= waves.LAST_WAVE:
		state = State.OVER
		_show("MERDEKA!\nKekaisaran Besi mundur.\n\n[Enter / klik] main lagi")
	else:
		state = State.BETWEEN_WAVES
		player.heal_full()  # shortcut: belum ada toko (M2), langsung lanjut wave
		_show("Wave %d selesai!\n\n[Enter / klik] lanjut" % wave)


func _on_player_died() -> void:
	waves.stop()
	get_tree().paused = true
	state = State.OVER
	_show("GUGUR di wave %d\n\n[Enter / klik] coba lagi" % waves.wave)


func _show(text: String) -> void:
	message.text = text
	message.show()
