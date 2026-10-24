extends Control
## Menu principal: panorama distante da floresta, amigos animados e ações à esquerda.

const UiStyle := preload("res://world/Scripts/ui_style.gd")
const CollectionPanel := preload("res://world/Scripts/collection_panel.gd")

const LEVEL_SCENE := "res://world/word_01.tscn"
const BEACH_SCENE := "res://world/beach_02.tscn"
const MAGIC_SCENE := "res://world/magic_03.tscn"
const UNDERWORLD_SCENE := "res://world/underworld_04.tscn"
const CORP_SCENE := "res://world/corporation_06.tscn"
const LAB_SCENE := "res://world/lab_05.tscn"
const LEVEL_ID := "fase_1"

const LOGO_TEXTURE := preload("res://world/Arte/logo.png")
const LOGO_HEIGHT := 78.0

var _ambience:Control
var _menu_column: VBoxContainer
var _title_art: Control
var _subtitle_label: Label
var _panel_holder: Control
var _first_button: Button
var _resume_button: Button
var _free_mode_button: Button
var _free_mode_hint: Label
var _clear_button: Button
var _main_layout: VBoxContainer
var _navigation_hint: Label
var _clear_armed := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build()
	_show_main()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and _panel_holder.get_child_count() > 0:
		_show_main()
		get_viewport().set_input_as_handled()


# --- Construção -----------------------------------------------------------------

func _build() -> void:
	_ambience=preload("res://world/Scripts/menu_forest.gd").new();_ambience.name="ForestPanorama";add_child(_ambience)
	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	column.anchor_left = 0.055
	column.anchor_right = 0.36
	column.anchor_top = 0.31
	column.anchor_bottom = 0.925
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 5)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(column)
	_main_layout = column

	_title_art = TextureRect.new()
	_title_art.texture = LOGO_TEXTURE
	_title_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_title_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_title_art.custom_minimum_size = Vector2(LOGO_HEIGHT * 3.0, LOGO_HEIGHT)
	_title_art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_title_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_title_art.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_title_art.offset_left=-LOGO_HEIGHT*1.5;_title_art.offset_right=LOGO_HEIGHT*1.5
	_title_art.offset_top=15;_title_art.offset_bottom=15+LOGO_HEIGHT
	add_child(_title_art)

	_subtitle_label = UiStyle.shadowed_label("Uma aventura entre ilhas.", 11, UiStyle.MUTED_COLOR)
	_subtitle_label.modulate = Color(1, 1, 1, 0.8)
	_subtitle_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_subtitle_label.offset_left=-150;_subtitle_label.offset_right=150
	_subtitle_label.offset_top=95;_subtitle_label.offset_bottom=110
	_subtitle_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	add_child(_subtitle_label)

	_menu_column = VBoxContainer.new()
	_menu_column.add_theme_constant_override("separation", 2)
	_menu_column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(_menu_column)

	_first_button = _add_menu_button("Jogar", _play_from_start)
	_resume_button = _add_menu_button("Continuar", _play_resume)
	_free_mode_button = _add_menu_button("Modo livre", _open_free_mode)
	_free_mode_hint = UiStyle.label("Conclua a aventura para desbloquear.", 9, Color(0.64, 0.73, 0.64))
	_free_mode_hint.custom_minimum_size.x = 184.0
	_free_mode_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_free_mode_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_menu_column.add_child(_free_mode_hint)
	_add_menu_button("Coleção", _open_collection)
	_add_menu_button("Opções", _open_options)
	_add_menu_button("Créditos", _open_credits)
	_add_menu_button("Sair", _quit)

	var footer := UiStyle.label("↑ ↓ selecionar    ·    Enter confirmar", 9, Color(0.62, 0.73, 0.75))
	_navigation_hint = footer
	footer.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_top = -22.0
	footer.offset_bottom = -8.0
	footer.offset_left=42;footer.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT
	add_child(footer)

	_panel_holder = Control.new()
	_panel_holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel_holder)


func _add_menu_button(text: String, action: Callable, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_NONE if disabled else Control.FOCUS_ALL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.92, 0.94, 0.84))
	button.add_theme_color_override("font_hover_color", Color(0.96, 0.99, 0.95))
	button.add_theme_color_override("font_focus_color", Color(0.75, 0.95, 0.78))
	button.add_theme_color_override("font_pressed_color", Color(0.75, 0.95, 0.78))
	button.add_theme_color_override("font_disabled_color", Color(0.54, 0.64, 0.57))
	button.add_theme_stylebox_override("normal", _menu_button_style(Color.TRANSPARENT))
	button.add_theme_stylebox_override("hover", _menu_button_style(Color(0.1, 0.19, 0.22, 0.55)))
	button.add_theme_stylebox_override("pressed", _menu_button_style(Color(0.11, 0.23, 0.22, 0.75)))
	button.add_theme_stylebox_override("disabled", _menu_button_style(Color.TRANSPARENT))
	var focus_style := _menu_button_style(Color.TRANSPARENT)
	focus_style.border_width_left = 2
	focus_style.border_color = Color(0.65, 0.88, 0.7)
	button.add_theme_stylebox_override("focus", focus_style)
	button.custom_minimum_size = Vector2(190.0, 25.0)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.disabled = disabled
	button.mouse_default_cursor_shape = Control.CURSOR_ARROW if disabled else Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_action_pressed.bind(action))
	_menu_column.add_child(button)
	return button


static func _menu_button_style(background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.set_corner_radius_all(3)
	style.content_margin_left = 15.0
	style.content_margin_right = 15.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 3.0
	return style


func _on_action_pressed(action: Callable) -> void:
	Sfx.select()
	action.call()


# --- Painéis --------------------------------------------------------------------

func _show_main() -> void:
	_clear_armed = false
	_clear_panel()
	_refresh_progress_actions()
	_main_layout.show()
	_navigation_hint.show()
	_menu_column.visible = true
	_title_art.visible = true
	_subtitle_label.visible = true
	_ambience.set_active(true)
	_first_button.grab_focus()


func _refresh_progress_actions() -> void:
	var has_progress: bool = Save.has_progress()
	_resume_button.disabled = not has_progress
	_resume_button.focus_mode = Control.FOCUS_ALL if has_progress else Control.FOCUS_NONE
	_resume_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if has_progress else Control.CURSOR_ARROW
	var free_mode_unlocked: bool = Save.is_game_completed()
	_free_mode_button.disabled = not free_mode_unlocked
	_free_mode_button.focus_mode = Control.FOCUS_ALL if free_mode_unlocked else Control.FOCUS_NONE
	_free_mode_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if free_mode_unlocked else Control.CURSOR_ARROW
	_free_mode_button.text = "Modo livre" if free_mode_unlocked else "Modo livre · bloqueado"
	_free_mode_button.tooltip_text = "Revisite as ilhas com seu saldo de cerejas." if free_mode_unlocked else "Conclua a aventura para desbloquear o modo livre."
	_free_mode_hint.visible = not free_mode_unlocked


func _clear_panel() -> void:
	for child in _panel_holder.get_children():
		_panel_holder.remove_child(child)
		child.queue_free()


func _open_panel(title: String, build: Callable) -> void:
	_main_layout.hide()
	_title_art.hide();_subtitle_label.hide();_ambience.set_active(false)
	_navigation_hint.hide()
	_menu_column.visible = false
	_title_art.visible = false
	_subtitle_label.visible = false
	_clear_panel()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel_holder.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(360.0, 0.0)
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	column.add_child(UiStyle.label(title, 18, UiStyle.TITLE_COLOR))
	column.add_child(UiStyle.divider())
	build.call(column)
	column.add_child(UiStyle.divider())

	var back := UiStyle.button("Voltar")
	back.pressed.connect(_on_back_pressed)
	column.add_child(back)
	back.grab_focus()


func _on_back_pressed() -> void:
	Sfx.select()
	_show_main()


func _open_options(_unused = null) -> void:
	_clear_armed = false
	_open_panel("OPÇÕES", _build_options)


func _build_options(column: VBoxContainer) -> void:
	column.add_child(UiStyle.slider_row(
		"Efeitos", Sfx.get_sfx_volume(), _on_sfx_volume_changed, _preview_sfx
	))
	column.add_child(UiStyle.slider_row(
		"Música", Sfx.get_music_volume(), _on_music_volume_changed
	))
	column.add_child(UiStyle.check_row(
		"Tela cheia", Save.is_fullscreen(), _on_fullscreen_toggled
	))
	column.add_child(UiStyle.check_row(
		"Tremor da câmera", Save.is_camera_shake_enabled(), _on_camera_shake_toggled
	))
	_clear_button = UiStyle.button("Apagar progresso")
	_clear_button.pressed.connect(_on_clear_pressed)
	column.add_child(_clear_button)


func _on_sfx_volume_changed(value: float) -> void:
	Sfx.set_sfx_volume(value)


func _on_music_volume_changed(value: float) -> void:
	Sfx.set_music_volume(value)


func _preview_sfx(changed: bool) -> void:
	if changed:
		Sfx.select()


func _on_fullscreen_toggled(value: bool) -> void:
	Save.set_fullscreen(value)
	Sfx.select()


func _on_camera_shake_toggled(value: bool) -> void:
	Save.set_camera_shake_enabled(value)
	Sfx.select()


func _on_clear_pressed() -> void:
	if _clear_armed:
		Save.reset_progress()
		_refresh_progress_actions()
		_clear_armed = false
		_clear_button.text = "Apagar progresso"
		Sfx.select()
	else:
		_clear_armed = true
		_clear_button.text = "Confirmar? Clique de novo"


func _open_credits(_unused = null) -> void:
	_clear_armed = false
	_open_panel("CRÉDITOS", _build_credits)


func _build_credits(column: VBoxContainer) -> void:
	column.add_child(UiStyle.label("NICO'S ADVENTURE", 15, UiStyle.TEXT_COLOR))
	column.add_child(UiStyle.label("Um guaxinim atrás dos amigos que ama.", 11, UiStyle.MUTED_COLOR))
	column.add_child(UiStyle.label("Cenário: pacote Sunny Land", 11, UiStyle.MUTED_COLOR))
	column.add_child(UiStyle.label("Nico: arte gerada por IA e recortada no projeto", 11, UiStyle.MUTED_COLOR))
	column.add_child(UiStyle.label("Logo: arte gerada por IA", 11, UiStyle.MUTED_COLOR))
	column.add_child(UiStyle.label("Paisagem do menu: arte gerada por IA", 11, UiStyle.MUTED_COLOR))
	column.add_child(UiStyle.label("Código, sons e efeitos: gerados no projeto", 11, UiStyle.MUTED_COLOR))
	column.add_child(UiStyle.label("Feito em Godot 4.7", 11, UiStyle.MUTED_COLOR))


func _open_free_mode(_unused = null) -> void:
	if not Save.is_game_completed():
		_refresh_progress_actions()
		return
	_clear_armed = false
	_main_layout.hide()
	_title_art.hide();_subtitle_label.hide();_ambience.set_active(false)
	_navigation_hint.hide()
	_clear_panel()
	var map := preload("res://world/Scripts/island_map.gd").new()
	map.name = "FreeIslandMap"
	map.selection_mode = true
	map.back_requested.connect(_on_back_pressed)
	_panel_holder.add_child(map)


func _open_collection(_unused = null) -> void:
	_clear_armed = false
	_main_layout.hide()
	_title_art.hide();_subtitle_label.hide();_ambience.set_active(false)
	_navigation_hint.hide()
	_clear_panel()
	var collection := CollectionPanel.new()
	collection.name = "Collection"
	collection.back_requested.connect(_on_back_pressed)
	_panel_holder.add_child(collection)


# --- Ações ----------------------------------------------------------------------

func _play_from_start() -> void:
	_start_level(false, LEVEL_SCENE)


func _play_resume() -> void:
	if not Save.has_progress():
		_refresh_progress_actions()
		return
	_start_level(true, Save.get_continue_scene())


func _play_free_scene(scene: String) -> void:
	if not Save.is_game_completed() or scene not in [LEVEL_SCENE, BEACH_SCENE, MAGIC_SCENE, UNDERWORLD_SCENE, LAB_SCENE, CORP_SCENE]:
		return
	_start_level(true, scene, true)


func _start_level(skip_intro: bool, scene: String = LEVEL_SCENE, free_mode: bool = false) -> void:
	Save.request_play(skip_intro,free_mode)
	get_tree().paused = false
	get_tree().change_scene_to_file(scene)


func _quit() -> void:
	Sfx.stop_all()
	get_tree().quit()


static func _format_time(seconds: float) -> String:
	var total := int(maxf(seconds, 0.0))
	return "%d:%02d" % [total / 60, total % 60]


