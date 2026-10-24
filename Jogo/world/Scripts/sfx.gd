extends Node
## Sfx — efeitos sintetizados e reprodução da trilha de cada cenário.
##
## Registrado como autoload (ver project.godot). Na inicialização, sintetiza
## pequenos sons (pulo, aterrissagem, golpe, coleta, dano, bandeira, chegada...)
## e uma trilha de fundo em laço, e os toca por um conjunto de tocadores.
## Também controla o volume e o mudo dos barramentos "SFX" e "Music", guardando
## a preferência em user://settings.cfg.

const RATE := 22050
const POOL_SIZE := 14
const SETTINGS_PATH := "user://settings.cfg"
const BUS_SFX := "SFX"
const BUS_MUSIC := "Music"
const INVENTORY_MUSIC_PATH := "res://world/Audio/Caravan/pixels_and_trinkets.wav"

# Formas de onda para a síntese.
enum Wave { SINE, SQUARE, TRIANGLE, SAW, NOISE }

var _streams: Dictionary = {}
var _pool: Array[AudioStreamPlayer] = []
var _pool_index := 0
var _music_player: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()
var _audio_enabled := true
var _synthetic_music: AudioStreamWAV
var _music_owner: WeakRef
var _music_owner_id := 0
var _music_owner_exit := Callable()
var _music_override: AudioStream
var _shutting_down := false
var _inventory_music_player: AudioStreamPlayer
var _inventory_music: AudioStreamWAV
var _inventory_owners: Dictionary = {}
var _inventory_owner_exits: Dictionary = {}
var _dialogue_owners: Dictionary = {}
var _dialogue_owner_exits: Dictionary = {}

var _sfx_volume := 0.8
var _music_volume := 0.55


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Sem dispositivo de áudio (ex.: execução headless) não há o que tocar; evita
	# trabalho desnecessário e vazamento do playback no encerramento.
	_audio_enabled = DisplayServer.get_name() != "headless"
	_rng.seed = 0xC0FFEE
	_setup_buses()
	_build_streams()
	_load_settings()
	_apply_volumes()
	if not _audio_enabled:
		return
	_build_players()
	_start_music()


# --- Barramentos e tocadores --------------------------------------------------

func _setup_buses() -> void:
	_ensure_bus(BUS_SFX)
	_ensure_bus(BUS_MUSIC)


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	var index := AudioServer.bus_count
	AudioServer.add_bus(index)
	AudioServer.set_bus_name(index, bus_name)
	AudioServer.set_bus_send(index, "Master")


func _build_players() -> void:
	for _index in POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = BUS_SFX
		add_child(player)
		_pool.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = BUS_MUSIC
	# A pausa normal suspende a trilha; conversas mantêm sua reprodução.
	_music_player.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(_music_player)


# --- Síntese ------------------------------------------------------------------

func _wave(shape: int, phase: float) -> float:
	var p := fposmod(phase, 1.0)
	match shape:
		Wave.SINE:
			return sin(phase * TAU)
		Wave.SQUARE:
			return 1.0 if p < 0.5 else -1.0
		Wave.TRIANGLE:
			return 4.0 * absf(p - 0.5) - 1.0
		Wave.SAW:
			return 2.0 * p - 1.0
		_:
			return _rng.randf_range(-1.0, 1.0)


## Envelope simples: sobe no ataque e desce na liberação.
func _env(t: float, duration: float, attack: float, release: float) -> float:
	var up: float = 1.0 if attack <= 0.0 else clampf(t / attack, 0.0, 1.0)
	var down: float = 1.0 if release <= 0.0 else clampf((duration - t) / release, 0.0, 1.0)
	return minf(up, down)


## Um tom com varredura de frequência, vibrato e mistura de ruído.
func _synth(
	duration: float, f_start: float, f_end: float, shape: int,
	volume: float, attack: float, release: float,
	vibrato: float = 0.0, noise: float = 0.0
) -> AudioStreamWAV:
	var frames := int(RATE * duration)
	var buffer := PackedFloat32Array()
	buffer.resize(frames)
	var phase := 0.0
	for i in frames:
		var t := float(i) / RATE
		var freq := lerpf(f_start, f_end, t / duration)
		if vibrato > 0.0:
			freq *= 1.0 + sin(t * TAU * 6.0) * vibrato
		phase += freq / RATE
		var sample := _wave(shape, phase)
		if noise > 0.0:
			sample = lerpf(sample, _rng.randf_range(-1.0, 1.0), noise)
		buffer[i] = sample * volume * _env(t, duration, attack, release)
	return _to_wav(buffer)


## Sequência de notas tocadas em seguida (ex.: moeda, fanfarra).
func _sequence(notes: Array, shape: int, volume: float, attack: float, release: float) -> AudioStreamWAV:
	var total := 0.0
	for note in notes:
		total += float(note[1])
	var buffer := PackedFloat32Array()
	buffer.resize(int(RATE * total))
	var offset := 0
	for note in notes:
		var freq := float(note[0])
		var duration := float(note[1])
		var count := int(RATE * duration)
		var phase := 0.0
		for i in count:
			var index := offset + i
			if index < 0 or index >= buffer.size():
				break
			var t := float(i) / RATE
			phase += freq / RATE
			buffer[index] += _wave(shape, phase) * volume * _env(t, duration, attack, release)
		offset += count
	return _to_wav(buffer)


## Mixa uma nota dentro de um buffer já existente (usado pela trilha).
func _place(
	buffer: PackedFloat32Array, start_sec: float, duration: float, freq: float,
	shape: int, volume: float, attack: float, release: float
) -> void:
	var start := int(start_sec * RATE)
	var count := int(duration * RATE)
	var phase := 0.0
	for i in count:
		var index := start + i
		if index < 0 or index >= buffer.size():
			continue
		var t := float(i) / RATE
		phase += freq / RATE
		buffer[index] += _wave(shape, phase) * volume * _env(t, duration, attack, release)


func _to_wav(buffer: PackedFloat32Array, looping: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(buffer.size() * 2)
	for i in buffer.size():
		data.encode_s16(i * 2, int(roundf(clampf(buffer[i], -1.0, 1.0) * 32767.0)))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = RATE
	stream.stereo = false
	stream.data = data
	if looping:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = buffer.size()
	return stream


func _build_streams() -> void:
	_streams["jump"] = _synth(0.16, 330.0, 680.0, Wave.SQUARE, 0.42, 0.004, 0.10, 0.02)
	_streams["land"] = _synth(0.11, 190.0, 90.0, Wave.TRIANGLE, 0.45, 0.002, 0.09, 0.0, 0.18)
	_streams["swing"] = _synth(0.12, 820.0, 260.0, Wave.SAW, 0.30, 0.004, 0.08, 0.0, 0.6)
	_streams["hit"] = _synth(0.09, 260.0, 90.0, Wave.SQUARE, 0.50, 0.001, 0.07, 0.0, 0.35)
	_streams["enemy_death"] = _synth(0.30, 620.0, 110.0, Wave.SQUARE, 0.42, 0.004, 0.20, 0.03, 0.15)
	_streams["cherry"] = _sequence([[988.0, 0.055], [1319.0, 0.13]], Wave.SQUARE, 0.38, 0.003, 0.06)
	_streams["hurt"] = _synth(0.24, 470.0, 150.0, Wave.SQUARE, 0.48, 0.003, 0.16, 0.05, 0.12)
	_streams["death"] = _synth(0.55, 640.0, 70.0, Wave.SQUARE, 0.48, 0.006, 0.35, 0.06, 0.10)
	_streams["respawn"] = _synth(0.30, 200.0, 900.0, Wave.TRIANGLE, 0.34, 0.010, 0.18)
	_streams["checkpoint"] = _sequence([[523.25, 0.09], [659.25, 0.09], [783.99, 0.16]], Wave.TRIANGLE, 0.38, 0.004, 0.07)
	_streams["finish"] = _sequence(
		[[523.25, 0.12], [659.25, 0.12], [783.99, 0.12], [1046.5, 0.12], [1318.5, 0.34]],
		Wave.SQUARE, 0.40, 0.005, 0.10
	)
	_streams["start"] = _sequence([[392.0, 0.10], [523.25, 0.10], [659.25, 0.10], [783.99, 0.22]], Wave.TRIANGLE, 0.36, 0.006, 0.08)
	_streams["alert"] = _synth(0.10, 1000.0, 1500.0, Wave.SQUARE, 0.24, 0.002, 0.07)
	_streams["menu"] = _synth(0.07, 660.0, 660.0, Wave.TRIANGLE, 0.32, 0.003, 0.05)
	_streams["select"] = _synth(0.09, 880.0, 1180.0, Wave.SQUARE, 0.32, 0.003, 0.06)
	_streams["secret"] = _sequence([[783.99, 0.07], [987.77, 0.07], [1174.66, 0.18]], Wave.TRIANGLE, 0.34, 0.004, 0.08)
	_streams["intro_wing"] = _synth(.22,180,65,Wave.TRIANGLE,.35,.02,.17,0,.7)
	_streams["intro_step"] = _synth(.13,105,48,Wave.TRIANGLE,.4,.002,.11,0,.22)
	_streams["intro_impact"] = _synth(.42,130,28,Wave.TRIANGLE,.6,.002,.37,0,.5)
	_streams["intro_ring_bell"] = _synth(.65,1320,1290,Wave.SINE,.35,.001,.6,.012,.04)
	_streams["intro_reveal"] = _sequence([[196,.08],[294,.08],[392,.24]],Wave.TRIANGLE,.3,.008,.15)
	_streams["lab_machine"] = _synth(1.1,52,48,Wave.TRIANGLE,.12,.18,.3,0,.12)
	_streams["lab_alarm"] = _sequence([[660,.12],[440,.12],[660,.12],[440,.2]],Wave.SQUARE,.18,.01,.06)
	_streams["lab_scan"] = _synth(.16,940,1400,Wave.SINE,.22,.005,.12)
	_streams["lab_door"] = _synth(.42,180,65,Wave.NOISE,.2,.03,.3)
	_streams["lab_dart"] = _synth(.13,760,170,Wave.TRIANGLE,.32,.002,.1,0,.3)
	_streams["lab_pressure"] = _synth(.48,150,600,Wave.NOISE,.25,.03,.3)
	_streams["lab_splash"] = _synth(.4,160,40,Wave.TRIANGLE,.35,.002,.35,0,.55)
	_streams["lab_bubble"] = _sequence([[110,.08],[190,.1],[75,.13]],Wave.SINE,.27,.006,.07)
	_streams["lab_clink"] = _synth(.18,1720,1300,Wave.SINE,.3,.001,.16,.01)
	_streams["sky_fall"] = _synth(2.9,760,55,Wave.TRIANGLE,0.38,0.06,0.7,0.04,0.3)
	# The guardian has a heavier palette than ordinary enemies. Every cue is
	# event-driven (never restarted every frame), through the normal SFX bus.
	_streams["warden_roar"] = _synth(1.15, 105, 43, Wave.SAW, 0.42, 0.14, 0.65, 0.12, 0.35)
	_streams["warden_chain"] = _sequence([[740, 0.07], [185, 0.08], [990, 0.06], [247, 0.13]], Wave.SQUARE, 0.27, 0.001, 0.05)
	_streams["warden_slam"] = _synth(0.48, 135, 27, Wave.TRIANGLE, 0.63, 0.001, 0.4, 0, 0.55)
	_streams["warden_rise"] = _synth(0.85, 58, 165, Wave.SAW, 0.32, 0.16, 0.4, 0.06, 0.4)
	_streams["warden_break"] = _synth(0.42, 610, 115, Wave.SQUARE, 0.38, 0.001, 0.37, 0, 0.7)
	_streams["warden_hurt"] = _synth(0.27, 125, 55, Wave.SAW, 0.36, 0.006, 0.23, 0.09, 0.3)
	_streams["warden_fire_charge"] = _synth(0.75, 105, 510, Wave.SAW, 0.28, 0.16, 0.2, 0.025, 0.28)
	_streams["warden_ice_charge"] = _sequence([[523, 0.15], [784, 0.15], [1046, 0.18], [1568, 0.25]], Wave.TRIANGLE, 0.34, 0.015, 0.1)
	_streams["warden_cannon"] = _synth(0.58, 230, 32, Wave.TRIANGLE, 0.63, 0.001, 0.48, 0, 0.65)
	_streams["warden_fizzle"] = _synth(0.19, 480, 90, Wave.NOISE, 0.22, 0.002, 0.16)
	_streams["warden_freed"] = _sequence([[196, 0.15], [294, 0.15], [392, 0.17], [587, 0.45]], Wave.TRIANGLE, 0.4, 0.02, 0.15)


## Trilha calma em laço: baixo, acorde sustentado e arpejo sobre I-V-vi-IV.
func _build_music() -> AudioStreamWAV:
	var length := 8.0
	var bar := 2.0
	var buffer := PackedFloat32Array()
	buffer.resize(int(RATE * length))
	var chords := [
		{"root": 130.81, "tones": [261.63, 329.63, 392.00]},  # Dó maior
		{"root": 98.00, "tones": [293.66, 392.00, 493.88]},   # Sol maior
		{"root": 110.00, "tones": [261.63, 329.63, 440.00]},  # Lá menor
		{"root": 87.31, "tones": [261.63, 349.23, 440.00]},   # Fá maior
	]
	for index in chords.size():
		var chord: Dictionary = chords[index]
		var start: float = float(index) * bar
		var root := float(chord["root"])
		var tones: Array = chord["tones"]
		for beat in 4:
			_place(buffer, start + beat * 0.5, 0.45, root, Wave.TRIANGLE, 0.16, 0.01, 0.18)
		for tone in tones:
			_place(buffer, start, bar, float(tone), Wave.SINE, 0.055, 0.25, 0.35)
		var pattern: Array = [tones[0], tones[1], tones[2], tones[1]]
		for step in 8:
			_place(buffer, start + step * 0.25, 0.24, float(pattern[step % 4]), Wave.TRIANGLE, 0.11, 0.008, 0.10)
	return _to_wav(buffer, true)


# --- Reprodução ---------------------------------------------------------------

func _free_player() -> AudioStreamPlayer:
	for player in _pool:
		if not player.playing:
			return player
	_pool_index = (_pool_index + 1) % _pool.size()
	return _pool[_pool_index]


func play(stream_name: String, volume_db: float = 0.0, pitch_variation: float = 0.0) -> void:
	if not _audio_enabled or not _streams.has(stream_name):
		return
	var player := _free_player()
	player.stream = _streams[stream_name]
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + _rng.randf_range(-pitch_variation, pitch_variation)
	player.play()


func jump() -> void:
	play("jump", -4.0, 0.06)


func land(strength: float) -> void:
	if not _audio_enabled:
		return
	strength = clampf(strength, 0.0, 1.0)
	var player := _free_player()
	player.stream = _streams["land"]
	player.volume_db = lerpf(-13.0, -3.0, strength)
	player.pitch_scale = lerpf(1.12, 0.9, strength)
	player.play()


func swing() -> void:
	play("swing", -6.0, 0.08)


func hit() -> void:
	play("hit", -3.0, 0.05)


func enemy_death() -> void:
	play("enemy_death", -3.0, 0.05)


func cherry() -> void:
	play("cherry", -5.0, 0.03)


func hurt() -> void:
	play("hurt", -3.0, 0.03)


func death() -> void:
	play("death", -2.0, 0.0)


func respawn() -> void:
	play("respawn", -5.0, 0.0)


func checkpoint() -> void:
	play("checkpoint", -4.0, 0.0)


func finish() -> void:
	play("finish", -2.0, 0.0)


func start() -> void:
	play("start", -4.0, 0.0)


func alert() -> void:
	play("alert", -9.0, 0.08)


func menu() -> void:
	play("menu", -6.0, 0.0)


func select() -> void:
	play("select", -5.0, 0.0)


func secret() -> void:
	play("secret", -4.0, 0.0)


# --- Música e volume ----------------------------------------------------------

func _start_music() -> void:
	if not _audio_enabled or _shutting_down or not is_instance_valid(_music_player):
		return
	if _synthetic_music == null:
		_synthetic_music = _build_music()
	_set_music_stream(_synthetic_music)


## O cenário controla a trilha da fase; ao sair, volta a música padrão.
## Loja e mochila a suspendem enquanto sua faixa temporária está tocando.
func use_scene_music(scene_owner: Node, stream: AudioStream) -> void:
	if _shutting_down or not is_instance_valid(scene_owner) or stream == null:
		return
	var owner_id := scene_owner.get_instance_id()
	if owner_id != _music_owner_id:
		_disconnect_music_owner()
		_music_owner = weakref(scene_owner)
		_music_owner_id = owner_id
		_music_owner_exit = _on_music_owner_exiting.bind(owner_id)
		scene_owner.tree_exiting.connect(_music_owner_exit, CONNECT_ONE_SHOT)
	_music_override = stream
	_set_music_stream(stream)


func release_scene_music(scene_owner: Node) -> void:
	if not is_instance_valid(scene_owner) or scene_owner.get_instance_id() != _music_owner_id:
		return
	_disconnect_music_owner()
	_music_override = null
	_start_music()


func _on_music_owner_exiting(owner_id: int) -> void:
	if owner_id != _music_owner_id:
		return
	_music_owner = null
	_music_owner_id = 0
	_music_owner_exit = Callable()
	_music_override = null
	_start_music()


func _disconnect_music_owner() -> void:
	var previous: Node = _music_owner.get_ref() as Node if _music_owner != null else null
	if is_instance_valid(previous) and _music_owner_exit.is_valid() and previous.tree_exiting.is_connected(_music_owner_exit):
		previous.tree_exiting.disconnect(_music_owner_exit)
	_music_owner = null
	_music_owner_id = 0
	_music_owner_exit = Callable()


func _set_music_stream(stream: AudioStream) -> void:
	if not _audio_enabled or not is_instance_valid(_music_player):
		return
	if _music_player.stream == stream and _music_player.playing:
		return
	_music_player.stop()
	_music_player.stream = stream
	_music_player.play()
	_music_player.stream_paused = not _inventory_owners.is_empty() or not _music_player.can_process()


## A conversa pausa o mundo, mas conserva a trilha no mesmo ponto, sem reinício.
## Donos separados permitem transições e limpeza ao sair/pular uma cutscene.
func begin_dialogue_music(dialogue_owner: Node) -> void:
	if _shutting_down or not is_instance_valid(dialogue_owner):
		return
	var owner_id := dialogue_owner.get_instance_id()
	if _dialogue_owners.has(owner_id):
		return
	_dialogue_owners[owner_id] = weakref(dialogue_owner)
	var on_exit := _release_dialogue_owner.bind(owner_id)
	_dialogue_owner_exits[owner_id] = on_exit
	dialogue_owner.tree_exiting.connect(on_exit, CONNECT_ONE_SHOT)
	_sync_dialogue_music()


func end_dialogue_music(dialogue_owner: Node) -> void:
	if is_instance_valid(dialogue_owner):
		_release_dialogue_owner(dialogue_owner.get_instance_id())


func is_dialogue_music_active() -> bool:
	return not _dialogue_owners.is_empty()


func _release_dialogue_owner(owner_id: int) -> void:
	if not _dialogue_owners.has(owner_id):
		return
	var dialogue_node: Node = (_dialogue_owners[owner_id] as WeakRef).get_ref() as Node
	var on_exit: Callable = _dialogue_owner_exits[owner_id]
	if is_instance_valid(dialogue_node) and dialogue_node.tree_exiting.is_connected(on_exit):
		dialogue_node.tree_exiting.disconnect(on_exit)
	_dialogue_owners.erase(owner_id)
	_dialogue_owner_exits.erase(owner_id)
	_sync_dialogue_music()


func _sync_dialogue_music() -> void:
	if _shutting_down or not is_instance_valid(_music_player):
		return
	_music_player.process_mode = Node.PROCESS_MODE_ALWAYS if is_dialogue_music_active() else Node.PROCESS_MODE_PAUSABLE
	# A faixa da caravana continua tendo prioridade se um painel estiver aberto.
	_music_player.stream_paused = not _inventory_owners.is_empty() or not _music_player.can_process()


## A música dos painéis continua com o mundo pausado. A trilha da fase fica
## suspensa na mesma posição e retoma quando o último painel é fechado.
func begin_inventory_music(panel_owner: Node) -> void:
	if _shutting_down or not is_instance_valid(panel_owner):
		return
	var owner_id := panel_owner.get_instance_id()
	if _inventory_owners.has(owner_id):
		return
	_inventory_owners[owner_id] = weakref(panel_owner)
	var on_exit := _release_inventory_owner.bind(owner_id)
	_inventory_owner_exits[owner_id] = on_exit
	panel_owner.tree_exiting.connect(on_exit, CONNECT_ONE_SHOT)
	if not _audio_enabled:
		return
	if _inventory_music == null:
		var source := load(INVENTORY_MUSIC_PATH) as AudioStreamWAV
		if source == null:
			push_error("Não foi possível carregar Pixels and Trinkets.")
			return
		_inventory_music = source.duplicate() as AudioStreamWAV
		_inventory_music.loop_mode = AudioStreamWAV.LOOP_FORWARD
		_inventory_music.loop_begin = 0
		_inventory_music.loop_end = int(round(_inventory_music.get_length() * _inventory_music.mix_rate))
	if not is_instance_valid(_inventory_music_player):
		_inventory_music_player = AudioStreamPlayer.new()
		_inventory_music_player.name = "InventoryMusic"
		_inventory_music_player.bus = BUS_MUSIC
		_inventory_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_inventory_music_player)
		_inventory_music_player.stream = _inventory_music
	if is_instance_valid(_music_player):
		_music_player.stream_paused = true
	if not _inventory_music_player.playing:
		_inventory_music_player.play()


func end_inventory_music(panel_owner: Node) -> void:
	if is_instance_valid(panel_owner):
		_release_inventory_owner(panel_owner.get_instance_id())


func is_inventory_music_active() -> bool:
	return not _inventory_owners.is_empty()


func _release_inventory_owner(owner_id: int) -> void:
	if not _inventory_owners.has(owner_id):
		return
	var panel: Node = (_inventory_owners[owner_id] as WeakRef).get_ref() as Node
	var on_exit: Callable = _inventory_owner_exits[owner_id]
	if is_instance_valid(panel) and panel.tree_exiting.is_connected(on_exit):
		panel.tree_exiting.disconnect(on_exit)
	_inventory_owners.erase(owner_id)
	_inventory_owner_exits.erase(owner_id)
	# Loja -> mochila transfere o dono no mesmo quadro, sem reiniciar a faixa.
	if _inventory_owners.is_empty() and not _shutting_down:
		_finish_inventory_music.call_deferred()


func _finish_inventory_music() -> void:
	if not _inventory_owners.is_empty() or _shutting_down:
		return
	if is_instance_valid(_inventory_music_player):
		_inventory_music_player.stop()
	if is_instance_valid(_music_player):
		_music_player.stream_paused = not _music_player.can_process()


## Libera os tocadores antes da árvore ser desmontada, evitando vazamento de
## AudioStreamPlayback ao fechar (importante no encerramento headless).
func _exit_tree() -> void:
	_shutdown()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_shutdown()


## Para toda a reprodução de áudio. Deve ser chamado antes de encerrar o jogo,
## para o áudio não ficar pendurado no fechamento do programa.
func stop_all() -> void:
	_shutdown()


func _shutdown() -> void:
	_shutting_down = true
	for owner_id: int in _dialogue_owners.keys():
		_release_dialogue_owner(owner_id)
	for owner_id: int in _inventory_owners.keys():
		_release_inventory_owner(owner_id)
	if is_instance_valid(_inventory_music_player):
		_inventory_music_player.stop()
		_inventory_music_player.stream = null
	_inventory_music = null
	_disconnect_music_owner()
	_music_override = null
	if is_instance_valid(_music_player):
		_music_player.stop()
		_music_player.stream = null
	for player in _pool:
		if is_instance_valid(player):
			player.stop()
			player.stream = null


func get_sfx_volume() -> float:
	return _sfx_volume


func get_music_volume() -> float:
	return _music_volume


func set_sfx_volume(value: float) -> void:
	_sfx_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func set_music_volume(value: float) -> void:
	_music_volume = clampf(value, 0.0, 1.0)
	_apply_volumes()
	_save_settings()


func _apply_volumes() -> void:
	_set_bus_volume(BUS_SFX, _sfx_volume)
	_set_bus_volume(BUS_MUSIC, _music_volume)


func _set_bus_volume(bus_name: String, value: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	if value <= 0.001:
		AudioServer.set_bus_mute(index, true)
	else:
		AudioServer.set_bus_mute(index, false)
		AudioServer.set_bus_volume_db(index, linear_to_db(value))


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	_sfx_volume = clampf(float(config.get_value("audio", "sfx", _sfx_volume)), 0.0, 1.0)
	_music_volume = clampf(float(config.get_value("audio", "music", _music_volume)), 0.0, 1.0)


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "sfx", _sfx_volume)
	config.set_value("audio", "music", _music_volume)
	config.save(SETTINGS_PATH)
