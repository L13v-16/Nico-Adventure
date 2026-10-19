extends Control

signal intro_finished

const INTRO_ENTER_TIME = 0.4
const INTRO_HOLD_TIME = 1.4
const INTRO_EXIT_TIME = 0.4

## Expressões do retrato (arte do Nico): 0 sorriso, 1 feliz, 2 olhos fechados, 3 surpreso.
const ROSTOS := [
	preload("res://world/Arte/Nico/hud_1.png"),
	preload("res://world/Arte/Nico/hud_2.png"),
	preload("res://world/Arte/Nico/hud_3.png"),
	preload("res://world/Arte/Nico/hud_4.png"),
]
const ROSTO_NORMAL := 0
const ROSTO_FELIZ := 1
const ROSTO_CAIDO := 2
const ROSTO_SUSTO := 3

@export var intro_autostart: bool = false
var intro_title := "VALE DAS COPAS"
var intro_act := 1

var intro_active: bool = false
var cherry_count: int = 0
var cherry_total: int = 0
var _wallet_mode := false
var _collected_total := 0
var _shield_status: Label
var health_current: int = 3
var health_maximum: int = 3
var _pending_intro: bool = false
var _intro_tween: Tween
var _counter_tween: Tween
var _ribbon_target_x: float = 0.0
var _pulse_time: float = 0.0
var _face_current: int = 0
var _face_time: float = 0.0

@onready var _portrait: TextureRect = $HealthPanel/Portrait
@onready var _count: Label = $CherryPanel/Count
@onready var _hearts: Array[Control] = [
	$HealthPanel/Hearts/Heart1,
	$HealthPanel/Hearts/Heart2,
	$HealthPanel/Hearts/Heart3
]
@onready var _intro_card: Control = $IntroCard
@onready var _dim: ColorRect = $IntroCard/Dim
@onready var _blue_band: Control = $IntroCard/BlueBand
@onready var _blue_shape: Polygon2D = $IntroCard/BlueBand/BlueShape
@onready var _blue_shadow: Polygon2D = $IntroCard/BlueBand/BlueShadow
@onready var _yellow_line: ColorRect = $IntroCard/BlueBand/YellowLine
@onready var _cyan_line: ColorRect = $IntroCard/BlueBand/CyanLine
@onready var _ribbon: Control = $IntroCard/RedRibbon


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.texture = ROSTOS[ROSTO_NORMAL]
	_intro_card.visible = false
	_refresh_counter()
	_apply_health()
	_apply_intro_text()
	resized.connect(_on_resized)
	if intro_autostart or _pending_intro:
		call_deferred("start_intro")


## Mantém o número de corações vivos pulsando quando resta apenas um.
func _process(delta: float) -> void:
	_pulse_time += delta
	if _face_time > 0.0:
		_face_time = maxf(_face_time - delta, 0.0)
		if _face_time <= 0.0 and _face_current != ROSTO_NORMAL:
			_face_current = ROSTO_NORMAL
			_portrait.texture = ROSTOS[ROSTO_NORMAL]
	var low_health: bool = health_current == 1 and health_maximum > 1
	for index: int in range(_hearts.size()):
		var heart: Control = _hearts[index]
		if low_health and index < health_current:
			heart.pivot_offset = heart.size * 0.5
			var beat: float = 1.0 + 0.16 * maxf(sin(_pulse_time * 5.0), 0.0)
			heart.scale = Vector2.ONE * beat
		elif heart.scale != Vector2.ONE:
			heart.scale = Vector2.ONE


func set_cherries(count: int, total: int = 0) -> void:
	var previous_count: int = cherry_count
	cherry_count = maxi(count, 0)
	cherry_total = maxi(total, 0)
	if not is_node_ready():
		return
	_refresh_counter()
	if cherry_count > previous_count:
		if is_instance_valid(_counter_tween):
			_counter_tween.kill()
		_count.pivot_offset = _count.size * 0.5
		_count.scale = Vector2(1.15, 1.15)
		_counter_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		_counter_tween.tween_property(_count, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _refresh_counter() -> void:
	# A HUD mostra apenas a quantidade atual; o total da fase fica nas estatísticas.
	_count.text = str(cherry_count)
	var complete: bool = cherry_total > 0 and (_collected_total if _wallet_mode else cherry_count) >= cherry_total
	_count.add_theme_color_override("font_color", Color(1.0, 0.9, 0.35) if complete else Color(1.0, 0.98, 0.88))


func set_cherry_wallet(balance: int, collected: int, total: int) -> void:
	if not _wallet_mode:
		_wallet_mode = true
		var panel: Control = $CherryPanel
		panel.tooltip_text = "Cerejas disponíveis para compras."
		_count.offset_top = 9.0
		_count.add_theme_font_size_override("font_size", 20)
		var caption := Label.new()
		caption.clip_text = true
		caption.add_theme_font_size_override("font_size", 7)
		caption.text = "SALDO"
		caption.position = Vector2(40, 3)
		caption.size = Vector2(60, 10)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color", Color("b5ced9"))
		caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(caption)
	_collected_total = maxi(collected, 0)
	set_cherries(balance, total)


func set_shop_shield(hits: int) -> void:
	if _shield_status == null:
		_shield_status = Label.new()
		_shield_status.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		_shield_status.offset_left = -148.0
		_shield_status.offset_right = -12.0
		_shield_status.offset_top = 84.0
		_shield_status.offset_bottom = 102.0
		_shield_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_shield_status.add_theme_font_size_override("font_size", 10)
		_shield_status.add_theme_color_override("font_color", Color("c2f3ff"))
		_shield_status.add_theme_color_override("font_shadow_color", Color("102332"))
		_shield_status.add_theme_constant_override("shadow_offset_x", 1)
		_shield_status.add_theme_constant_override("shadow_offset_y", 1)
		_shield_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_shield_status)
	_shield_status.text = "ESCUDO  " + "●".repeat(maxi(hits, 0))
	_shield_status.visible = hits > 0


func set_health(current: int, maximum: int) -> void:
	health_maximum = maxi(maximum, 1)
	health_current = clampi(current, 0, health_maximum)
	if is_node_ready():
		_apply_health()


## Troca a cara do retrato por um tempo (0 = fica até outra troca).
func set_face(indice: int, duracao: float = 1.2) -> void:
	if not is_node_ready():
		return
	_face_current = clampi(indice, 0, ROSTOS.size() - 1)
	_portrait.texture = ROSTOS[_face_current]
	_face_time = maxf(duracao, 0.0)


## A mesma abertura acompanha cada ilha, com seu nome e número de ato.
func configure_intro(title: String, act: int) -> void:
	intro_title = title
	intro_act = maxi(act, 1)
	if is_node_ready():
		_apply_intro_text()


func _apply_intro_text() -> void:
	var title_label: Label = $IntroCard/BlueBand/Title
	title_label.text = intro_title
	# A praia tem um nome maior; mantenha o título dentro da faixa azul.
	var font: Font = title_label.get_theme_font("font")
	var font_size := 36
	while font_size > 22 and font.get_string_size(intro_title, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x > 405.0:
		font_size -= 1
	title_label.add_theme_font_size_override("font_size", font_size)
	$IntroCard/RedRibbon/Number.text = str(intro_act)


func start_intro() -> void:
	if not is_node_ready():
		_pending_intro = true
		return
	if intro_active:
		return
	_pending_intro = false
	intro_active = true
	_layout_intro()
	_intro_card.visible = true
	_dim.color.a = 0.0
	_blue_band.position.x = -size.x - 100.0
	_ribbon.position.x = size.x + 170.0
	_intro_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_intro_tween.tween_property(_blue_band, "position:x", 0.0, INTRO_ENTER_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_intro_tween.parallel().tween_property(_ribbon, "position:x", _ribbon_target_x, INTRO_ENTER_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_intro_tween.parallel().tween_property(_dim, "color:a", 0.26, INTRO_ENTER_TIME)
	_intro_tween.tween_interval(INTRO_HOLD_TIME)
	_intro_tween.tween_property(_blue_band, "position:x", size.x + 100.0, INTRO_EXIT_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_intro_tween.parallel().tween_property(_ribbon, "position:x", -190.0, INTRO_EXIT_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_intro_tween.parallel().tween_property(_dim, "color:a", 0.0, INTRO_EXIT_TIME)
	_intro_tween.tween_callback(_finish_intro)


func _finish_intro() -> void:
	intro_active = false
	_intro_card.visible = false
	intro_finished.emit()


func _apply_health() -> void:
	for index: int in range(_hearts.size()):
		_hearts[index].visible = index < health_maximum
		_hearts[index].set("filled", index < health_current)


func _on_resized() -> void:
	if is_node_ready():
		_layout_intro()


func _layout_intro() -> void:
	var band_width: float = maxf(size.x, 360.0)
	_blue_band.position.y = roundf(size.y * 0.5 - 62.0)
	_blue_band.size = Vector2(band_width, 124.0)
	_blue_shape.polygon = PackedVector2Array([
		Vector2(-80, 0), Vector2(band_width * 0.84, 0),
		Vector2(band_width * 0.76, 124), Vector2(-80, 124)
	])
	_blue_shadow.polygon = _blue_shape.polygon
	_yellow_line.size.x = band_width * 0.78
	_cyan_line.size.x = band_width * 0.72
	_ribbon_target_x = band_width - 176.0
	_ribbon.position.y = roundf(size.y * 0.5 - 94.0)
