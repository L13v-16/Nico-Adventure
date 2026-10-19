extends CanvasLayer
## Menu de pausa (ESC). É montado em código para ficar independente da cena da
## fase e continuar respondendo mesmo com a árvore pausada.

signal resumed
signal restart_requested

const TITLE_COLOR := Color(0.75, 0.95, 0.72)
const TEXT_COLOR := Color(0.86, 0.92, 0.96)
const DIM_COLOR := Color(0.02, 0.03, 0.07, 0.66)

## A fase controla isto: fica falso durante a abertura e depois da chegada.
var can_open: bool = true

var _root: Control
var _title: Label
var _summary: Label
var _continue_button: Button
var _open: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 5
	_build()
	_root.visible = false


func is_open() -> bool:
	return _open


## Texto livre com o progresso atual (cerejas, corações...).
func set_summary(text: String) -> void:
	_summary.text = text


func open() -> void:
	if _open:
		return
	_open = true
	Fx.cancel_hitstop()
	Sfx.menu()
	get_tree().paused = true
	_root.visible = true
	_continue_button.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	_root.visible = false
	get_tree().paused = false
	Sfx.menu()
	resumed.emit()


func toggle() -> void:
	if _open:
		close()
	elif can_open:
		open()


func _unhandled_input(event: InputEvent) -> void:
	var pressed: bool = event.is_action_pressed("ui_cancel")
	if not pressed and event is InputEventKey:
		var key := event as InputEventKey
		pressed = key.pressed and not key.echo and key.physical_keycode == KEY_ESCAPE
	if not pressed:
		return
	if _open or can_open:
		toggle()
		get_viewport().set_input_as_handled()


func _restart_pressed() -> void:
	Sfx.select()
	get_tree().paused = false
	_open = false
	restart_requested.emit()


func _quit_pressed() -> void:
	Sfx.select()
	get_tree().paused = false
	Sfx.stop_all()
	get_tree().quit()


func _menu_pressed() -> void:
	Sfx.select()
	get_tree().paused = false
	_open = false
	get_tree().change_scene_to_file("res://world/main_menu.tscn")


# --- Construção da interface --------------------------------------------------

func _build() -> void:
	_root = Control.new()
	_root.name = "PauseRoot"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)

	var dim := ColorRect.new()
	dim.color = DIM_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(258.0, 0.0)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	_title = _make_label("PAUSA", 24, TITLE_COLOR)
	column.add_child(_title)

	_summary = _make_label("", 13, TEXT_COLOR)
	_summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_summary)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0.0, 1.0)
	divider.color = Color(0.35, 0.5, 0.63, 0.55)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)

	_continue_button = _make_button("Continuar")
	_continue_button.pressed.connect(close)
	column.add_child(_continue_button)

	var restart_button := _make_button("Reiniciar fase")
	restart_button.pressed.connect(_restart_pressed)
	column.add_child(restart_button)

	var menu_button := _make_button("Menu principal")
	menu_button.pressed.connect(_menu_pressed)
	column.add_child(menu_button)

	var quit_button := _make_button("Sair do jogo")
	quit_button.pressed.connect(_quit_pressed)
	column.add_child(quit_button)

	var volume_title := _make_label("VOLUME", 11, Color(0.62, 0.72, 0.8))
	volume_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	column.add_child(volume_title)

	column.add_child(_make_slider_row("Efeitos", Sfx.get_sfx_volume(), _on_sfx_volume_changed, _preview_sfx))
	column.add_child(_make_slider_row("Música", Sfx.get_music_volume(), _on_music_volume_changed))

	var hint := _make_label("ESC para continuar  •  R volta à última bandeira", 11, Color(0.62, 0.72, 0.8))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(hint)


func _on_sfx_volume_changed(value: float) -> void:
	Sfx.set_sfx_volume(value)


func _on_music_volume_changed(value: float) -> void:
	Sfx.set_music_volume(value)


## Toca um som curto ao soltar o controle de efeitos, para servir de amostra.
func _preview_sfx(changed: bool) -> void:
	if changed:
		Sfx.select()


func _make_slider_row(title: String, value: float, on_change: Callable, on_release: Callable = Callable()) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)

	var label := Label.new()
	label.text = title
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", TEXT_COLOR)
	label.custom_minimum_size = Vector2(58.0, 0.0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(label)

	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.05
	slider.value = clampf(value, 0.0, 1.0)
	slider.custom_minimum_size = Vector2(140.0, 0.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.value_changed.connect(on_change)
	if on_release.is_valid():
		slider.drag_ended.connect(on_release)
	row.add_child(slider)
	return row


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _make_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(Color(0.07, 0.13, 0.2, 0.9), Color(0.3, 0.44, 0.56, 0.9)))
	button.add_theme_stylebox_override("hover", _button_style(Color(0.12, 0.22, 0.3, 0.95), Color(0.5, 0.78, 0.6, 1.0)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.05, 0.1, 0.16, 1.0), Color(0.5, 0.78, 0.6, 1.0)))
	button.add_theme_stylebox_override("focus", _button_style(Color(0.12, 0.22, 0.3, 0.95), Color(0.62, 0.9, 0.7, 1.0)))
	return button


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.045, 0.075, 0.14, 0.97)
	style.border_color = Color(0.55, 0.83, 0.57, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0.01, 0.02, 0.05, 0.45)
	style.shadow_size = 6
	return style


func _button_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 6.0
	style.content_margin_bottom = 6.0
	return style
