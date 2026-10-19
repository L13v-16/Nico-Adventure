extends CanvasLayer
## Tela de resultados da fase (GDD §39 e §40): tempo, inimigos, cerejas,
## segredos, mortes e a nota de S a D.

signal replay_requested
signal menu_requested
signal next_requested

const UiStyle := preload("res://world/Scripts/ui_style.gd")

## Expressões do Nico (64x64), na mesma ordem da HUD.
const ROSTOS := [
	preload("res://world/Arte/Nico/rosto_1.png"),
	preload("res://world/Arte/Nico/rosto_2.png"),
	preload("res://world/Arte/Nico/rosto_3.png"),
	preload("res://world/Arte/Nico/rosto_4.png"),
]

var _replay_button: Button


func setup(title: String, subtitle: String, stats: Dictionary, new_record: bool, next_available: bool = false) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 8
	_build(title, subtitle, stats, new_record, next_available)


func _build(title: String, subtitle: String, stats: Dictionary, new_record: bool, next_available: bool) -> void:
	var dim := ColorRect.new()
	dim.color = UiStyle.DIM_COLOR
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430.0, 0.0)
	panel.add_theme_stylebox_override("panel", UiStyle.panel_style())
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 14 if next_available else 18)
	margin.add_theme_constant_override("margin_bottom", 14 if next_available else 20)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 6 if next_available else 10)
	margin.add_child(column)

	column.add_child(UiStyle.label(title, 22, UiStyle.TITLE_COLOR))
	column.add_child(UiStyle.label(subtitle, 12, UiStyle.MUTED_COLOR))
	column.add_child(UiStyle.divider())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	column.add_child(body)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 4)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(grid)

	var rows := [
		["Tempo", _format_time(float(stats.get("time", 0.0)))],
		["Inimigos derrotados", "%d / %d" % [int(stats.get("enemies", 0)), int(stats.get("total_enemies", 0))]],
		["Cerejas", "%d / %d" % [int(stats.get("cherries", 0)), int(stats.get("total_cherries", 0))]],
		["Segredos", "%d / %d" % [int(stats.get("secrets", 0)), int(stats.get("total_secrets", 0))]],
		["Mortes", str(int(stats.get("deaths", 0)))],
	]
	for row: Array in rows:
		grid.add_child(UiStyle.label(row[0], 13, UiStyle.MUTED_COLOR, HORIZONTAL_ALIGNMENT_LEFT))
		var value := UiStyle.label(row[1], 13, UiStyle.TEXT_COLOR, HORIZONTAL_ALIGNMENT_RIGHT)
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(value)

	var rank_box := VBoxContainer.new()
	rank_box.add_theme_constant_override("separation", 0)
	rank_box.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(rank_box)
	var rank := String(stats.get("rank", "D"))
	var face := TextureRect.new()
	face.texture = ROSTOS[1 if new_record else _rosto_da_nota(rank, int(stats.get("deaths", 0)))]
	face.custom_minimum_size = Vector2(64.0, 64.0)
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rank_box.add_child(face)
	rank_box.add_child(UiStyle.label("NOTA", 11, UiStyle.MUTED_COLOR))
	var rank_color: Color = UiStyle.RANK_COLORS.get(rank, UiStyle.TEXT_COLOR)
	rank_box.add_child(UiStyle.label(rank, 44, rank_color))

	if new_record:
		column.add_child(UiStyle.label("NOVO RECORDE!  ·  Saldo guardado: %d" % Save.get_cherry_balance(), 13, UiStyle.GOLD_COLOR))
	else:
		column.add_child(UiStyle.label("Saldo guardado: %d cerejas" % Save.get_cherry_balance(), 13, UiStyle.MUTED_COLOR))

	column.add_child(UiStyle.divider())

	var next_button: Button
	if next_available:
		next_button = UiStyle.button("Próxima ilha  →")
		next_button.custom_minimum_size = Vector2(312.0, 0.0)
		next_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		next_button.pressed.connect(_on_next)
		column.add_child(next_button)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)

	_replay_button = UiStyle.button("Jogar novamente")
	_replay_button.custom_minimum_size = Vector2(150.0, 0.0)
	_replay_button.pressed.connect(_on_replay)
	buttons.add_child(_replay_button)

	var menu_button := UiStyle.button("Menu principal")
	menu_button.custom_minimum_size = Vector2(150.0, 0.0)
	menu_button.pressed.connect(_on_menu)
	buttons.add_child(menu_button)

	if next_button != null:
		next_button.grab_focus()
	else:
		_replay_button.grab_focus()


func _on_next() -> void:
	Sfx.select()
	next_requested.emit()


func _on_replay() -> void:
	Sfx.select()
	replay_requested.emit()


func _on_menu() -> void:
	Sfx.select()
	menu_requested.emit()


static func _format_time(seconds: float) -> String:
	var total := int(maxf(seconds, 0.0))
	return "%d:%02d" % [total / 60, total % 60]


## Cara do Nico conforme a partida: comemora nas melhores, se espanta na pior e
## fecha os olhos quando a travessia foi sofrida.
static func _rosto_da_nota(rank: String, mortes: int) -> int:
	if mortes >= 5:
		return 2
	if rank == "S" or rank == "A":
		return 1
	if rank == "D":
		return 3
	return 0
