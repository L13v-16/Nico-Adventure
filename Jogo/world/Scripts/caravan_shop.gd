extends Node2D
## Caravana sem colisão: position é o contato das rodas com o chão.
## O saldo e os efeitos pertencem ao jogador e à fase; a loja só apresenta e compra.

signal purchased(item_id: String, price: int)

const UiStyle := preload("res://world/Scripts/ui_style.gd")
const CARAVAN := preload("res://world/Arte/Caravan/caravana_movel.png")
const RAT_BLINK := preload("res://world/Arte/Friends/V47/oliver_body_01.tres")
const RAT := preload("res://world/Arte/Friends/V47/oliver_body_00.tres")
const PORTRAIT := preload("res://world/Arte/Friends/V47/oliver_portrait_neutral.tres")
const ACTOR_SHADER := preload("res://world/Scripts/characters_cutout.gdshader")
const CHERRY := preload("res://Sunny-land-files/assets/Misc/Sunnyland items/cherry.png")
const Catalog := preload("res://world/Scripts/equipment_catalog.gd")
const PRICES := {"heart": 4, "acai": 7, "shield": 10}
const CATEGORIES := ["supplies", "equipment", "style"]
const CATEGORY_LABELS := ["Suprimentos", "Equipamentos", "Estilo"]
const COUNTER_ART_PATH := "res://world/Arte/Friends/V47/oliver_body_06.tres"
const SHOP_CREAM := Color("f5e7c9")
const SHOP_MUTED := Color("c9bda1")
const SHOP_GOLD := Color("ebc27a")
const SHOP_SUCCESS := Color("d4e5ae")
## Interior da janela no sprite da caravana, antes da borda do balcão.
const MERCHANT_WINDOW := Rect2(-29, -59, 56, 20)

@export var travel_offset := Vector2(16, 0)
@export_range(0.0, 40.0, 0.5) var travel_speed := 3.0
@export_range(24.0, 150.0, 1.0) var interaction_radius := 70.0

var _origin := Vector2.ZERO
var _time := 0.0
var _is_open := false
var _buy_busy := false
var _was_paused := false
var _pause_was_available := false
var _player: Node2D
var _level: Node
var _pause_menu: Node
var _wagon: Sprite2D
var _rat: Sprite2D
var _merchant_window: Control
var _hint: Label
var _canvas: CanvasLayer
var _screen: Control
var _wallet: Label
var _feedback: Label
var _buttons: Dictionary = {}
var _close_button: Button
var _model: Node
var _category := "supplies"
var _tabs: Dictionary = {}
var _groups: Dictionary = {}
var _scroll: ScrollContainer
var _has_met := false
var _reminded := false
var _departing := false
var _departure_time := 0.0
var _origin_global := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("caravan_shops")
	_origin = position
	_origin_global = global_position
	_level = get_parent()
	_has_met = bool(_level.get_meta("caravan_has_met", false))
	if bool(_level.get_meta("caravan_vanished", false)):
		queue_free()
		return
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if is_instance_valid(_player):
		for signal_name: String in ["died", "respawned", "tree_exiting"]:
			if _player.has_signal(signal_name):
				_player.connect(signal_name, close)
		if _player.has_method("get_equipment"):
			_model = _player.call("get_equipment") as Node
		if _player.has_signal("cherry_balance_changed"):
			_player.connect("cherry_balance_changed", _on_wallet_changed)
	_build_world()
	_build_menu()
	if is_instance_valid(_model) and _model.has_signal("changed"):
		_model.connect("changed", _refresh_stock)


func is_open() -> bool:
	return _is_open


func _build_world() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_wagon = Sprite2D.new()
	_wagon.name = "CaravanSprite"
	_wagon.texture = CARAVAN
	_wagon.hframes = 2
	_wagon.position.y = -48
	add_child(_wagon)
	_merchant_window = Control.new()
	_merchant_window.name = "MerchantWindow"
	_merchant_window.position = MERCHANT_WINDOW.position
	_merchant_window.size = MERCHANT_WINDOW.size
	_merchant_window.clip_contents = true
	_merchant_window.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_merchant_window)
	_rat = Sprite2D.new()
	_rat.name = "MerchantSprite"
	_rat.texture = RAT
	_rat.scale=Vector2(24,36)/RAT.get_size()
	_rat.centered = false
	# A cabeça fica centralizada; o corpo termina atrás da madeira do balcão.
	_rat.position = Vector2(16, -10)
	var merchant_material := ShaderMaterial.new()
	merchant_material.shader = ACTOR_SHADER
	_rat.material = merchant_material
	_merchant_window.add_child(_rat)
	var hint_layer:=CanvasLayer.new()
	hint_layer.layer=14
	add_child(hint_layer)
	_hint = UiStyle.shadowed_label("E · Loja do Oliver", 9, Color("fff0bd"))
	_hint.size = Vector2(116,18)
	_hint.add_theme_stylebox_override("normal",UiStyle.panel_style())
	_hint.hide()
	hint_layer.add_child(_hint)


func _process(delta: float) -> void:
	if bool(_level.get_meta("caravan_vanished", false)) and not _departing:
		queue_free()
		return
	if _is_open:
		if not _player_is_available():
			close()
		return
	if get_tree().paused:
		_hint.hide()
		return
	_time += delta
	if _departing:
		_departure_time += delta
		position.x += 58.0 * delta
		modulate.a = maxf(1.0 - _departure_time / 1.2, 0.0)
		_wagon.frame = int(_time * 8.0) % 2
		if _departure_time >= 1.2:
			queue_free()
		return
	if _player_is_available() and not bool(_level.get("intro_active")) and not bool(_level.get("completed")):
		if not _has_met and _player.global_position.distance_to(_origin_global + Vector2(0, -10)) <= 150.0:
			_mark_met()
		var away := absf(_player.global_position.x - _origin_global.x)
		if _has_met and away > 300.0:
			_depart()
			return
		if _has_met and away > 230.0 and not _reminded:
			_reminded = true
			_notice("Oliver Gancho: a caravana partirá quando você seguir viagem. Confira a mochila [I]!")
	var span := travel_offset.length()
	if span > 0.001:
		position = _origin + travel_offset * sin(_time * travel_speed / span)
	_wagon.frame = int(_time * 3.0) % 2 if span > 0.001 else 0
	# Uma piscada curta, com o sprite no tamanho nativo, sem tremor por escala.
	_rat.texture = RAT_BLINK if fposmod(_time, 2.0) > 1.82 else RAT
	_hint.visible = _can_open()
	var screen_at:Vector2=get_global_transform_with_canvas()*Vector2(0,-30)
	_hint.position=Vector2(clampf(screen_at.x-58,12,512),clampf(screen_at.y-9,112,306))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if _is_open:
		if event is InputEventKey and event.pressed and event.physical_keycode == KEY_I:
			get_viewport().set_input_as_handled()
			_open_inventory()
			return
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			close()
		elif event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
			var direction := 1 if event.is_action_pressed("ui_right") else -1
			var next_index := posmod(CATEGORIES.find(_category) + direction, CATEGORIES.size())
			_set_category(CATEGORIES[next_index], true)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("interagir"):
			# E não pode abrir outra loja ou um diálogo por trás do painel.
			get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("interagir") and _can_open():
		get_viewport().set_input_as_handled()
		open()


func _player_is_available() -> bool:
	return is_instance_valid(_player) and not bool(_player.call("is_dead"))


func _can_open() -> bool:
	if _departing or get_tree().paused or not _player_is_available():
		return false
	if bool(_level.get("intro_active")) or bool(_level.get("completed")):
		return false
	return _player.global_position.distance_to(global_position + Vector2(0, -10)) <= interaction_radius


func open() -> void:
	if _is_open or not _can_open():
		return
	_mark_met()
	_is_open = true
	_player.call("_cancel_attack")
	_was_paused = get_tree().paused
	_pause_menu = _level.get("pause_menu") as Node
	if is_instance_valid(_pause_menu):
		_pause_was_available = bool(_pause_menu.get("can_open"))
		_pause_menu.set("can_open", false)
	var fx := get_node_or_null("/root/Fx")
	if fx != null:
		fx.call("cancel_hitstop")
	get_tree().paused = true
	Sfx.begin_inventory_music(self)
	_hint.hide()
	_screen.show()
	_feedback.text = "A caravana partirá quando você seguir viagem."
	_feedback.add_theme_color_override("font_color", SHOP_MUTED)
	_refresh_stock()
	_set_category(_category, true)
	_play_sound("menu")


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	Sfx.end_inventory_music(self)
	if is_instance_valid(_screen):
		_screen.hide()
	if is_inside_tree():
		get_tree().paused = _was_paused
	if is_instance_valid(_pause_menu):
		_pause_menu.set("can_open", _pause_was_available)
	if _player_is_available():
		_player.set("_invulnerability_timer", maxf(float(_player.get("_invulnerability_timer")), 0.3))
	_play_sound("menu")
	if not _departing:
		_notice("Oliver Gancho: não demore! Vou partir quando você se afastar. Sua mochila abre com I.")


func _exit_tree() -> void:
	Sfx.end_inventory_music(self)
	if _is_open and is_instance_valid(get_tree()):
		get_tree().paused = _was_paused
		if is_instance_valid(_pause_menu):
			_pause_menu.set("can_open", _pause_was_available)
	_is_open = false


func _buy(item_id: String) -> void:
	if not _is_open or _buy_busy or not _player_is_available():
		return
	_buy_busy = true
	_unlock_purchase.call_deferred()
	if Catalog.ITEMS.has(item_id):
		if not is_instance_valid(_model):
			_show_feedback("A mochila ainda não está disponível.", false)
			return
		var result: Dictionary = _model.call("buy_item", item_id)
		var success := bool(result.get("ok", false))
		_show_feedback(str(result.get("message", "Compra concluída." if success else "Não foi possível comprar.")), success)
		if success:
			purchased.emit(item_id, int(Catalog.ITEMS[item_id]["price"]))
			_play_sound("select")
		return
	var price: int = PRICES[item_id]
	var rejection := _rejection(item_id)
	if not rejection.is_empty():
		_show_feedback(rejection, false)
		return
	if int(_player.call("get_cherry_balance")) < price:
		_show_feedback("Faltam cerejas para esta compra. Escolha outro item.", false)
		return
	# Sem await entre validação, efeito e débito: o mundo está pausado e a
	# transação ocorre uma vez, no mesmo quadro de entrada do botão.
	var applied := false
	match item_id:
		"heart": applied = bool(_player.call("heal_one"))
		"acai": applied = bool(_level.call("buy_acai_power"))
		"shield": applied = bool(_player.call("grant_shop_shield", 3))
	if not applied:
		_show_feedback("Este item não pode ser usado agora.", false)
		return
	if not bool(_player.call("try_spend_cherries", price)):
		push_error("CaravanShop: o saldo mudou durante uma transação síncrona.")
		_show_feedback("Não foi possível concluir a compra.", false)
		return
	var message: String = {
		"heart": "Um coração recuperado. Boa viagem!",
		"acai": "Açaí pronto! Proteção e golpes congelantes por 12 s.",
		"shield": "Escudo equipado: absorve os próximos 3 golpes."
	}[item_id]
	_show_feedback(message, true)
	_refresh_stock()
	purchased.emit(item_id, price)
	_play_sound("select")


func _play_sound(sound_name: String) -> void:
	var sfx := get_node_or_null("/root/Sfx")
	if sfx != null and sfx.has_method(sound_name):
		sfx.call(sound_name)


func _unlock_purchase() -> void:
	_buy_busy = false


func _rejection(item_id: String) -> String:
	if item_id == "heart" and int(_player.get("health")) >= 3:
		return "Seus corações já estão cheios. Guarde suas cerejas."
	if item_id == "shield" and int(_player.get("shop_shield_hits")) > 0:
		return "Você já tem um escudo. Use-o antes de comprar outro."
	return ""


func _show_feedback(message: String, success: bool) -> void:
	_feedback.text = message
	_feedback.add_theme_color_override("font_color", SHOP_SUCCESS if success else SHOP_GOLD)
	_refresh_stock()


func _refresh_stock() -> void:
	if not is_instance_valid(_wallet) or not is_instance_valid(_player):
		return
	_wallet.text = "%d cerejas" % int(_player.call("get_cherry_balance"))
	(_buttons["heart"] as Button).text = "Coração  ·  4 cerejas" + ("  —  vida cheia" if int(_player.get("health")) >= 3 else "")
	(_buttons["shield"] as Button).text = "Escudo  ·  10 cerejas" + ("  —  equipado" if int(_player.get("shop_shield_hits")) > 0 else "")
	for item_id: String in Catalog.ORDER:
		var item: Dictionary = Catalog.ITEMS[item_id]
		var state := ""
		if is_instance_valid(_model):
			var quantity := int(_model.call("get_quantity", item_id))
			if bool(_model.call("is_equipped", item_id)):
				state = "  ·  equipado"
			elif quantity > 0 and item["slot"] == "use":
				state = "  ·  mochila ×%d" % quantity
			elif bool(_model.call("owns", item_id)):
				state = "  ·  comprado"
		(_buttons[item_id] as Button).text = "%s  ·  %d cerejas%s" % [item["name"], item["price"], state]


func _on_wallet_changed(_balance: int) -> void:
	_refresh_stock()


func _mark_met() -> void:
	if _has_met:
		return
	_has_met = true
	_level.set_meta("caravan_has_met", true)
	_notice("A caravana partirá quando você seguir viagem. E: loja de Oliver Gancho.")


func _notice(message: String) -> void:
	if is_instance_valid(_level) and _level.has_method("_show_notice"):
		_level.call("_show_notice", message)


func _depart() -> void:
	if _departing:
		return
	_departing = true
	_level.set_meta("caravan_vanished", true)
	close()
	_hint.hide()
	_notice("Oliver Gancho seguiu viagem. Seus equipamentos continuam na mochila [I].")


func _set_category(category_id: String, focus_first: bool = false) -> void:
	_category = category_id
	for key: String in CATEGORIES:
		(_groups[key] as Control).visible = key == _category
		(_tabs[key] as Button).button_pressed = key == _category
	_scroll.scroll_vertical = 0
	if focus_first:
		_focus_category_first.call_deferred(category_id)


func _focus_category_first(category_id: String) -> void:
	# As abas ocultam grupos de tamanhos diferentes. Aguarde o novo layout
	# antes de focar para a rolagem não usar a posição antiga da primeira linha.
	await get_tree().process_frame
	if not _is_open or category_id != _category:
		return
	_scroll.scroll_vertical = 0
	var first: String = "heart" if category_id == "supplies" else ("claws" if category_id == "equipment" else "straw_hat")
	(_buttons[first] as Button).grab_focus()


func _open_inventory() -> void:
	if not is_instance_valid(_model) or not _model.has_method("open_inventory"):
		_show_feedback("A mochila ainda não está disponível.", false)
		return
	get_viewport().set_input_as_handled()
	close()
	_model.call("open_inventory")


func _build_menu() -> void:
	_canvas = CanvasLayer.new()
	_canvas.name = "CaravanShopUI"
	_canvas.layer = 40
	add_child(_canvas)
	_screen = Control.new()
	_screen.name = "ShopPanel"
	_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	_canvas.add_child(_screen)
	var dim := ColorRect.new()
	dim.color = Color(0.055, 0.035, 0.025, 0.82)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_screen.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(center)
	var panel := PanelContainer.new()
	panel.name = "ShopFrame"
	panel.custom_minimum_size = Vector2(584, 336)
	var wood := _shop_style(Color("30261f"), Color("a8804e"), 2, 8)
	wood.shadow_color = Color(0.015, 0.01, 0.005, 0.6)
	wood.shadow_size = 5
	panel.add_theme_stylebox_override("panel", wood)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 10)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 3)
	margin.add_child(column)
	var header := PanelContainer.new()
	header.name = "MerchantHeader"
	header.custom_minimum_size.y = 96
	var cloth := _shop_style(Color("344334"), Color("6d7550"), 1, 5)
	cloth.set_content_margin_all(0)
	header.add_theme_stylebox_override("panel", cloth)
	column.add_child(header)
	var heading := HBoxContainer.new()
	heading.add_theme_constant_override("separation", 10)
	header.add_child(heading)
	var counter_art := TextureRect.new()
	counter_art.name = "MerchantCounter"
	counter_art.custom_minimum_size = Vector2(216, 96)
	counter_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	counter_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	counter_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var counter_material := ShaderMaterial.new()
	counter_material.shader = ACTOR_SHADER
	counter_art.material = counter_material
	counter_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(COUNTER_ART_PATH):
		counter_art.texture = load(COUNTER_ART_PATH) as Texture2D
	heading.add_child(counter_art)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titles.alignment = BoxContainer.ALIGNMENT_CENTER
	titles.add_theme_constant_override("separation", 1)
	heading.add_child(titles)
	titles.add_child(UiStyle.label("OLIVER GANCHO", 18, SHOP_GOLD, HORIZONTAL_ALIGNMENT_LEFT))
	titles.add_child(UiStyle.label("Caravana das Marés", 12, SHOP_CREAM, HORIZONTAL_ALIGNMENT_LEFT))
	titles.add_child(UiStyle.label("Boas trocas, viajante!", 10, SHOP_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	var wallet_row := HBoxContainer.new()
	wallet_row.add_theme_constant_override("separation", 5)
	titles.add_child(wallet_row)
	var cherry := TextureRect.new()
	var cherry_region := AtlasTexture.new()
	cherry_region.atlas = CHERRY
	cherry_region.region = Rect2(0, 0, 21, 21)
	cherry.texture = cherry_region
	cherry.custom_minimum_size = Vector2(16, 16)
	cherry.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cherry.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cherry.mouse_filter = Control.MOUSE_FILTER_IGNORE
	wallet_row.add_child(cherry)
	_wallet = UiStyle.label("0 cerejas", 13, SHOP_CREAM, HORIZONTAL_ALIGNMENT_LEFT)
	wallet_row.add_child(_wallet)
	titles.add_child(UiStyle.label("← → abas  ·  ↑ ↓ itens  ·  Enter comprar", 9, SHOP_MUTED, HORIZONTAL_ALIGNMENT_LEFT))
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	column.add_child(tabs)
	for index in CATEGORIES.size():
		var tab := _shop_button(CATEGORY_LABELS[index], 12)
		tab.toggle_mode = true
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.pressed.connect(_set_category.bind(CATEGORIES[index], true))
		tabs.add_child(tab)
		_tabs[CATEGORIES[index]] = tab
	var divider := ColorRect.new()
	divider.custom_minimum_size.y = 1
	divider.color = Color(0.7, 0.52, 0.3, 0.65)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(divider)
	_scroll = ScrollContainer.new()
	_scroll.name = "StockScroll"
	_scroll.custom_minimum_size = Vector2(560, 125)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.follow_focus = true
	var scrollbar := _scroll.get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 6
	var track := _shop_style(Color("211d18"), Color.TRANSPARENT, 0, 3)
	track.content_margin_left = 3
	track.content_margin_right = 3
	scrollbar.add_theme_stylebox_override("scroll", track)
	for state: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var thumb := _shop_style(Color("a58c59") if state == "grabber" else SHOP_GOLD, Color.TRANSPARENT, 0, 3)
		thumb.content_margin_left = 3
		thumb.content_margin_right = 3
		scrollbar.add_theme_stylebox_override(state, thumb)
	column.add_child(_scroll)
	var stock := VBoxContainer.new()
	stock.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(stock)
	for category_id: String in CATEGORIES:
		var rows := VBoxContainer.new()
		rows.name = category_id.capitalize()
		rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rows.add_theme_constant_override("separation", 4)
		stock.add_child(rows)
		_groups[category_id] = rows
	for item_id: String in ["heart", "acai", "shield"]:
		var name_and_description: Array = {
			"heart": ["Coração", "Recupera 1 coração."],
			"acai": ["Açaí", "Proteção e golpes congelantes por 12 segundos."],
			"shield": ["Escudo", "Absorve 3 golpes; quedas no mar não contam."]
		}[item_id]
		_add_stock_row("supplies", item_id, name_and_description[0], name_and_description[1], "")
	for item_id: String in Catalog.ORDER:
		var item: Dictionary = Catalog.ITEMS[item_id]
		_add_stock_row(Catalog.category(item_id), item_id, item["name"], item["description"], item["icon"])
	(_buttons["acai"] as Button).text = "Açaí  ·  7 cerejas"
	_feedback = UiStyle.label("", 10, SHOP_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	_feedback.custom_minimum_size = Vector2(560, 24)
	_feedback.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(_feedback)
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 6)
	column.add_child(actions)
	var inventory_button := _shop_button("Equipar / mochila [I]", 12)
	inventory_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inventory_button.pressed.connect(_open_inventory)
	actions.add_child(inventory_button)
	_close_button = _shop_button("Sair da loja  ·  Esc", 12)
	_close_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_close_button.pressed.connect(close)
	actions.add_child(_close_button)
	_set_category("supplies")
	_screen.hide()


func _add_stock_row(category_id: String, item_id: String, item_name: String, description: String, icon_path: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	(_groups[category_id] as VBoxContainer).add_child(row)
	if not icon_path.is_empty():
		var icon := TextureRect.new()
		icon.custom_minimum_size = Vector2(20, 20)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if ResourceLoader.exists(icon_path):
			icon.texture = load(icon_path) as Texture2D
		if Catalog.ITEMS.has(item_id): icon.material = Catalog.icon_material(item_id)
		row.add_child(icon)
	var texts := VBoxContainer.new()
	texts.add_theme_constant_override("separation", 1)
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(texts)
	var button := _shop_button(item_name, 12)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.pressed.connect(_buy.bind(item_id))
	button.focus_entered.connect(_reveal_row.bind(row))
	texts.add_child(button)
	_buttons[item_id] = button
	var detail := UiStyle.label(description, 10, SHOP_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	texts.add_child(detail)


func _reveal_row(row: Control) -> void:
	# O foco deve revelar também a descrição que fica abaixo do botão.
	await get_tree().process_frame
	if _is_open and is_instance_valid(row) and row.is_visible_in_tree():
		_scroll.ensure_control_visible(row)


static func _shop_style(background: Color, border: Color, width: int = 1, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	return style


static func _shop_button(text: String, font_size: int = 12) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.custom_minimum_size.y = 24
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", SHOP_CREAM)
	button.add_theme_color_override("font_hover_color", Color("fff5dc"))
	button.add_theme_color_override("font_focus_color", Color("fff5dc"))
	button.add_theme_color_override("font_pressed_color", SHOP_GOLD)
	button.add_theme_color_override("font_disabled_color", Color("8b806b"))
	var states := {
		"normal": [Color("353c2e"), Color("746348")],
		"hover": [Color("46513b"), SHOP_GOLD],
		"pressed": [Color("44503a"), SHOP_GOLD],
		"focus": [Color(0, 0, 0, 0), SHOP_GOLD],
		"disabled": [Color("29271f"), Color("534a37")]
	}
	for state: String in states:
		var style := _shop_style(states[state][0], states[state][1], 2 if state == "focus" else 1, 4)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 3
		style.content_margin_bottom = 3
		button.add_theme_stylebox_override(state, style)
	return button
