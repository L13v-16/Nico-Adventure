extends Node
## Filho da fase da praia: troca a trilha conforme o estado real de Urus.
## O Sfx mantém a trilha da fase no barramento Music e restaura a trilha padrão
## quando este nó sai da árvore. Não altera o volume escolhido pelo jogador.

const SHORE_PATH := "res://world/Audio/Beach/pixel_shore_shenanigans.wav"
const BOSS_PATH := "res://world/Audio/Beach/tidal_wrath_royale.wav"

var current_track := ""
var _shore: AudioStreamWAV
var _boss_track: AudioStreamWAV
var _boss: Node
var _level: Node


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_level = get_parent()
	_boss = _level.get_node_or_null("Boss")
	_shore = _looping_wav(SHORE_PATH)
	_boss_track = _looping_wav(BOSS_PATH)
	_update_track()


func _process(_delta: float) -> void:
	_update_track()


func _update_track() -> void:
	var fighting := is_instance_valid(_boss) and bool(_boss.get("active"))
	if fighting and _boss.has_method("is_dead"):
		fighting = not _boss.is_dead()
	if is_instance_valid(_level) and bool(_level.get("completed")):
		fighting = false
	var desired := "boss" if fighting else "shore"
	if desired == current_track:
		return
	var stream := _boss_track if fighting else _shore
	if stream == null:
		return
	current_track = desired
	Sfx.use_scene_music(self, stream)


func _looping_wav(path: String) -> AudioStreamWAV:
	var source := load(path) as AudioStreamWAV
	if source == null:
		push_error("Não foi possível carregar a música: " + path)
		return null
	# Configura a reprodução sem regravar nem converter o WAV fornecido.
	var stream := source.duplicate() as AudioStreamWAV
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = int(round(stream.get_length() * stream.mix_rate))
	return stream
