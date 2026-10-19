extends CanvasLayer
## Mochila independente da loja: I abre/fecha, ESC fecha, sem cobrar para trocar.

const Catalog := preload("res://world/Scripts/equipment_catalog.gd")
const Ui := preload("res://world/Scripts/ui_style.gd")
var model: Node
var player: Node
var _screen: Control
var _rows: VBoxContainer
var _feedback: Label
var _summary: Label
var _close_button: Button
var _buttons: Dictionary = {}
var _category := "all"
var _is_open := false
var _was_paused := false
var _pause_was_available := false
var _pause_menu: Node
var _busy := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 45
	_build()
	model.changed.connect(_refresh)
	player.died.connect(close)
	player.respawned.connect(close)
	_screen.hide()


func is_open() -> bool:
	return _is_open


func _can_open() -> bool:
	if not is_instance_valid(player) or player.is_dead() or get_tree().paused:
		return false
	var level: Node = player.get_parent()
	return not bool(level.get("intro_active")) and not bool(level.get("completed"))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	var inventory_key: bool = event is InputEventKey and event.pressed and event.physical_keycode == KEY_I
	if _is_open:
		if inventory_key or event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close()
		elif event.is_action_pressed("interagir"):
			get_viewport().set_input_as_handled()
	elif inventory_key and _can_open():
		get_viewport().set_input_as_handled()
		open()


func open() -> void:
	if _is_open or not _can_open():
		return
	_is_open = true
	_was_paused = get_tree().paused
	_pause_menu = player.get_parent().get("pause_menu") as Node
	if is_instance_valid(_pause_menu):
		_pause_was_available = bool(_pause_menu.get("can_open"))
		_pause_menu.set("can_open", false)
	Fx.cancel_hitstop()
	get_tree().paused = true
	Sfx.begin_inventory_music(self)
	_screen.show()
	_feedback.text = "Escolha um item para equipar, retirar ou usar. As roupas aparecem no Nico."
	_refresh()
	_focus_first()
	Sfx.menu()


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	Sfx.end_inventory_music(self)
	_screen.hide()
	if is_inside_tree():
		get_tree().paused = _was_paused
	if is_instance_valid(_pause_menu):
		_pause_menu.set("can_open", _pause_was_available)
	if is_instance_valid(player) and not player.is_dead():
		player.set("_invulnerability_timer", maxf(float(player.get("_invulnerability_timer")), 0.3))
	Sfx.menu()


func _exit_tree() -> void:
	Sfx.end_inventory_music(self)
	if _is_open and is_instance_valid(get_tree()):
		get_tree().paused = _was_paused
		if is_instance_valid(_pause_menu):
			_pause_menu.set("can_open", _pause_was_available)


func _refresh() -> void:
	if not is_node_ready() or not _is_open:
		return
	var focused := ""
	for id: String in _buttons:
		if (_buttons[id] as Button).has_focus():
			focused = id
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.queue_free()
	_buttons.clear()
	for id: String in Catalog.ORDER:
		if not model.owns(id) or (_category != "all" and Catalog.category(id) != _category):
			continue
		var item: Dictionary = Catalog.ITEMS[id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_rows.add_child(row)
		var icon := TextureRect.new()
		if ResourceLoader.exists(str(item["icon"])):
			icon.texture = load(str(item["icon"]))
		icon.custom_minimum_size = Vector2(28, 28)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_constant_override("separation", 0)
		row.add_child(text)
		var title: String = str(item["name"]) + (" ×%d" % model.get_quantity(id) if id == "frozen_acai" else "")
		text.add_child(Ui.label(title, 12, Ui.TITLE_COLOR if model.is_equipped(id) else Ui.TEXT_COLOR, HORIZONTAL_ALIGNMENT_LEFT))
		var description := Ui.label(str(item["description"]), 9, Ui.MUTED_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.custom_minimum_size.x = 300
		text.add_child(description)
		var button := Ui.button("Usar" if id == "frozen_acai" else ("Retirar" if model.is_equipped(id) else "Equipar"), 11)
		button.custom_minimum_size = Vector2(66, 29)
		button.pressed.connect(_toggle.bind(id))
		row.add_child(button)
		_buttons[id] = button
	if _buttons.is_empty():
		var empty := Ui.label("Nenhum item nesta categoria.\nCompre equipamentos na caravana para usá-los aqui.", 12, Ui.MUTED_COLOR)
		empty.custom_minimum_size.y = 94
		_rows.add_child(empty)
	_summary.text = "Ataque +%d%%  ·  Corrida +%d%%  ·  Gelo %.0f s%s" % [roundi((model.get_damage_multiplier() - 1.0) * 100.0), roundi((model.get_speed_multiplier() - 1.0) * 100.0), model.get_freeze_duration(), "  ·  Açaí gelado %.0f s" % ceilf(model.get_frost_boost_left()) if model.get_frost_boost_left() > 0.0 else ""]
	if _buttons.has(focused):
		(_buttons[focused] as Button).grab_focus()


func _toggle(id: String) -> void:
	if _busy or not _is_open:
		return
	_busy = true
	_unlock.call_deferred()
	var result: Dictionary = model.toggle_item(id)
	_feedback.text = str(result["message"])
	Sfx.select()
	if _buttons.has(id):
		(_buttons[id] as Button).grab_focus()
	else:
		_focus_first()


func _unlock() -> void:
	_busy = false


func _set_category(category: String) -> void:
	_category = category
	_refresh()


func _focus_first() -> void:
	if _buttons.is_empty():
		_close_button.grab_focus()
	else:
		(_buttons.values()[0] as Button).grab_focus()


func _build() -> void:
	_screen = Control.new()
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_screen)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.04, 0.08, 0.83)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 312)
	panel.add_theme_stylebox_override("panel", Ui.panel_style())
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 12)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6)
	margin.add_child(column)
	column.add_child(Ui.label("MOCHILA DO NICO", 18, Ui.GOLD_COLOR, HORIZONTAL_ALIGNMENT_LEFT))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 5)
	column.add_child(tabs)
	for entry in [["Tudo", "all"], ["Equipamentos", "equipment"], ["Estilo", "style"]]:
		var button := Ui.button(str(entry[0]), 11)
		button.pressed.connect(_set_category.bind(str(entry[1])))
		tabs.add_child(button)
	column.add_child(Ui.divider())
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(492, 148)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.follow_focus = true
	column.add_child(scroll)
	_rows = VBoxContainer.new()
	_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_rows.add_theme_constant_override("separation", 9)
	scroll.add_child(_rows)
	_summary = Ui.label("", 10, Color("bae9f1"), HORIZONTAL_ALIGNMENT_LEFT)
	column.add_child(_summary)
	_feedback = Ui.label("", 10, Ui.MUTED_COLOR, HORIZONTAL_ALIGNMENT_LEFT)
	_feedback.custom_minimum_size = Vector2(492, 25)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_feedback)
	_close_button = Ui.button("Voltar à aventura  ·  I / Esc", 12)
	_close_button.pressed.connect(close)
	column.add_child(_close_button)
