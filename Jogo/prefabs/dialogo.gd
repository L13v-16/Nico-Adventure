extends CanvasLayer
## Caixa de diálogo da vila: retrato, nome, fala, perguntas e seta de continuar.
##
## Abre com a tecla de interagir quando o Nico está perto de um morador e
## congela o jogo enquanto a conversa acontece. Depois das falas de abertura o
## morador oferece uma lista de perguntas: o Nico escolhe com cima/baixo e
## confirma com a tecla de interagir.

signal conversa_terminou

## Distância (em pixels) em que o Nico consegue puxar conversa.
@export var raio: float = 34.0

const MODO_FALAS := 0
const MODO_PERGUNTAS := 1
const MODO_RESPOSTA := 2

## Rosto do Nico enquanto ele é quem está falando (a lista de perguntas).
const ROSTO_NICO := preload("res://world/Arte/Nico/rosto_1.png")

var _falas: PackedStringArray = PackedStringArray()
var _perguntas: Array = []
var _nome_npc: String = ""
var _npc: Node = null
var _indice: int = 0
var _selecao: int = 0
var _modo: int = MODO_FALAS
var _aberta: bool = false
var _tempo: float = 0.0
var _seta_y: float = 0.0
var _pause_menu: Node
var _pause_was_available := true

@onready var caixa: Panel = $Caixa
@onready var placa: Panel = $Caixa/Placa
@onready var retrato: TextureRect = $Caixa/Retrato
@onready var texto: Label = $Caixa/Texto
@onready var opcoes: RichTextLabel = $Caixa/Opcoes
@onready var seta: TextureRect = $Caixa/Seta
@onready var dica: Label = $Dica


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	caixa.visible = false
	dica.visible = false
	opcoes.visible = false
	var fonte := texto.get_theme_font("font")
	if fonte != null:
		opcoes.add_theme_font_override("normal_font", fonte)
	opcoes.add_theme_font_size_override("normal_font_size", texto.get_theme_font_size("font_size"))
	_seta_y = seta.position.y


func _process(delta: float) -> void:
	if _aberta:
		_tempo += delta
		if seta.visible:
			seta.position.y = _seta_y + roundf(sin(_tempo * 6.0) * 1.5)
		return
	var perto := _npc_perto()
	dica.visible = perto != null
	if perto != null:
		dica.text = "E: falar"


func _unhandled_input(event: InputEvent) -> void:
	if _aberta:
		if _modo == MODO_PERGUNTAS:
			if event.is_action_pressed("ui_up") or _tecla(event, KEY_W):
				_selecao = wrapi(_selecao - 1, 0, _perguntas.size())
				Sfx.select()
				_mostra_perguntas()
				get_viewport().set_input_as_handled()
				return
			if event.is_action_pressed("ui_down") or _tecla(event, KEY_S):
				_selecao = wrapi(_selecao + 1, 0, _perguntas.size())
				Sfx.select()
				_mostra_perguntas()
				get_viewport().set_input_as_handled()
				return
			if event.is_action_pressed("interagir") or event.is_action_pressed("ui_accept"):
				_confirma()
				get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("interagir") or event.is_action_pressed("ui_accept"):
			_avanca()
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interagir"):
		if get_tree().paused:
			return
		var npc := _npc_perto()
		if npc != null:
			_abre(npc)
			get_viewport().set_input_as_handled()


## Tecla física pressionada (para atalhos que não estão no mapa de entrada).
func _tecla(event: InputEvent, codigo: Key) -> bool:
	var k := event as InputEventKey
	return k != null and k.pressed and not k.echo and k.physical_keycode == codigo


func _npc_perto() -> Node:
	var jogador := get_tree().get_first_node_in_group("player") as Node2D
	if jogador == null:
		return null
	var melhor: Node = null
	var dist := raio
	for candidato in get_tree().get_nodes_in_group("npcs"):
		var npc := candidato as Node2D
		if npc == null:
			continue
		if absf(npc.global_position.y - jogador.global_position.y) > 34.0:
			continue
		var d: float = absf(npc.global_position.x - jogador.global_position.x)
		if d < dist:
			dist = d
			melhor = npc
	return melhor


## Troca quem aparece na caixa: o morador ou o próprio Nico.
func _mostra_retrato(textura: Texture2D, nome: String) -> void:
	retrato.texture = textura
	retrato.visible = textura != null
	placa.get_node("Nome").text = nome


## Retrato do morador na cara pedida (1 a 4). Sem folha de caras, devolve o
## retrato único dele.
func _retrato_do_npc(cara: int) -> Texture2D:
	if _npc == null:
		return null
	return _npc.call("retrato_da_cara", cara) as Texture2D


func _abre(npc: Node) -> void:
	if _aberta or get_tree().paused:
		return
	var falas: PackedStringArray = npc.call("conversa")
	var perguntas: Array = npc.call("perguntas")
	if falas.is_empty() and perguntas.is_empty():
		return
	_falas = falas
	_perguntas = perguntas
	_indice = 0
	_selecao = 0
	_modo = MODO_FALAS
	_aberta = true
	_npc = npc
	_nome_npc = str(npc.get("nome"))
	_mostra_retrato(_retrato_do_npc(1), _nome_npc)
	caixa.visible = true
	dica.visible = false
	texto.visible = true
	opcoes.visible = false
	seta.visible = true
	_mostra()
	var level := get_tree().current_scene
	if is_instance_valid(level) and "pause_menu" in level:
		_pause_menu = level.get("pause_menu") as Node
		if is_instance_valid(_pause_menu):
			_pause_was_available = bool(_pause_menu.get("can_open"))
			_pause_menu.set("can_open", false)
	Sfx.begin_dialogue_music(self)
	get_tree().paused = true
	Sfx.select()


func _mostra() -> void:
	if _indice >= _falas.size():
		_abre_perguntas()
		return
	_modo = MODO_FALAS
	texto.text = _falas[_indice]
	texto.visible = true
	opcoes.visible = false
	seta.visible = true
	dica.visible = false
	var cara := 1
	if _npc != null:
		cara = int(_npc.call("cara_da_fala", _indice))
	_mostra_retrato(_retrato_do_npc(cara), _nome_npc)
	_tempo = 0.0


func _abre_perguntas() -> void:
	if _perguntas.is_empty():
		_fecha()
		return
	_selecao = clampi(_selecao, 0, _perguntas.size() - 1)
	_mostra_perguntas()


func _mostra_perguntas() -> void:
	_modo = MODO_PERGUNTAS
	texto.visible = false
	opcoes.visible = true
	seta.visible = false
	dica.visible = true
	dica.text = "W/S ou setas: escolher  •  E: confirmar"
	_mostra_retrato(ROSTO_NICO, "Nico")
	var linhas := PackedStringArray()
	for i in _perguntas.size():
		var p: Dictionary = _perguntas[i]
		var rotulo := str(p.get("texto", "..."))
		if i == _selecao:
			linhas.append("[color=#ffd76b]> %s[/color]" % rotulo)
		else:
			linhas.append("[color=#a9bac9]   %s[/color]" % rotulo)
	opcoes.text = "\n".join(linhas)
	_tempo = 0.0


func _mostra_resposta(txt: String, cara: int) -> void:
	_modo = MODO_RESPOSTA
	texto.text = txt
	texto.visible = true
	opcoes.visible = false
	seta.visible = true
	dica.visible = true
	dica.text = "E: continuar"
	_mostra_retrato(_retrato_do_npc(cara), _nome_npc)
	_tempo = 0.0


func _confirma() -> void:
	if _perguntas.is_empty():
		_fecha()
		return
	var p: Dictionary = _perguntas[_selecao]
	if bool(p.get("fim", false)):
		Sfx.select()
		_fecha()
		return
	Sfx.select()
	_mostra_resposta(str(p.get("resposta", "...")), int(p.get("cara", 1)))


func _avanca() -> void:
	Sfx.select()
	if _modo == MODO_FALAS:
		_indice += 1
		if _indice >= _falas.size():
			_abre_perguntas()
		else:
			_mostra()
		return
	if _modo == MODO_RESPOSTA:
		_abre_perguntas()


func _fecha() -> void:
	Sfx.end_dialogue_music(self)
	_restore_pause_menu()
	_aberta = false
	caixa.visible = false
	dica.visible = false
	get_tree().paused = false
	conversa_terminou.emit()


func _restore_pause_menu() -> void:
	if is_instance_valid(_pause_menu):
		_pause_menu.set("can_open", _pause_was_available)
	_pause_menu = null


func _exit_tree() -> void:
	Sfx.end_dialogue_music(self)
	_restore_pause_menu()
	if _aberta and get_tree() != null:
		get_tree().paused = false
