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
var _nico:TextureRect
var _rank_label:Label
var _particles:Control
var _clock:=0.0
var _rank:="D"
var _record:=false
var _rank_revealed:=false
const Art=preload("res://world/Scripts/polish99_art.gd")


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
	panel.custom_minimum_size = Vector2(526.0, 0.0)
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

	var rank_box := HBoxContainer.new()
	rank_box.add_theme_constant_override("separation", 0)
	rank_box.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(rank_box)
	var rank := String(stats.get("rank", "D"))
	_rank=rank;_record=new_record
	var face := TextureRect.new()
	face.texture = Art.cell("presentation",0)
	face.material=Art.material()
	face.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	_nico=face
	face.custom_minimum_size = Vector2(94.0, 112.0)
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rank_box.add_child(face)
	var badge:=VBoxContainer.new();badge.alignment=BoxContainer.ALIGNMENT_CENTER;rank_box.add_child(badge)
	badge.add_child(UiStyle.label("NOTA", 11, UiStyle.MUTED_COLOR))
	var rank_color: Color = UiStyle.RANK_COLORS.get(rank, UiStyle.TEXT_COLOR)
	_rank_label=UiStyle.label("…",36,rank_color);badge.add_child(_rank_label)
	_particles=Control.new();_particles.mouse_filter=Control.MOUSE_FILTER_IGNORE;_particles.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_particles.draw.connect(_draw_particles);add_child(_particles)
	panel.pivot_offset=Vector2(263,155);panel.scale=Vector2.ONE*.94;panel.modulate.a=0
	var intro:=create_tween().set_parallel();intro.tween_property(panel,"scale",Vector2.ONE,.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT);intro.tween_property(panel,"modulate:a",1,.25)

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

func _process(delta:float) -> void:
	_clock+=delta
	if not is_instance_valid(_nico):return
	if _clock<.8:_nico.texture=Art.cell("presentation",0 if int(_clock*5)%2==0 else 4)
	else:
		if not _rank_revealed:
			_rank_revealed=true;_rank_label.text=_rank;Sfx.play("checkpoint" if _rank in ["S","A"] or _record else "select",-8)
		var pose:int=1 if _rank in ["S","A"] else (5 if _rank=="D" else 6)
		if pose==1 and _clock<2.2:pose=2 if int(_clock*6)%2==0 else 3
		if pose==5 and _clock<1.6:pose=7
		_nico.texture=Art.cell("presentation",pose)
	_particles.queue_redraw()
func _draw_particles() -> void:
	if _clock<.8:return
	var size:=get_viewport().get_visible_rect().size
	var festive:=_rank in ["S","A"] or _record
	for i in (32 if festive else 12):
		var age:=fposmod(_clock*.24+i*.131,1.0)
		var x:=fposmod(i*71.3+sin(_clock+i)*9,size.x)
		var y:=age*size.y
		var color:Color=[Color("f6d17c"),Color("86d7ae"),Color("bcebf4")][i%3]
		color.a=.7*(1-age) if festive else .22*(1-age)
		_particles.draw_rect(Rect2(x,y,3 if festive else 2,2),color)
