extends CanvasLayer
const Ui=preload("res://world/Scripts/ui_style.gd")
const Catalog=preload("res://world/Scripts/equipment_catalog.gd")
var level:Node3D
var _root:Control
var _rows:VBoxContainer
var _wallet:Label
var _feedback:Label
var _open:=false
var _pause_available:=false
var _close:Button
func _ready() -> void:
	layer=44;process_mode=Node.PROCESS_MODE_ALWAYS
	_root=Control.new();_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(_root)
	var dim:=ColorRect.new();dim.color=Color("101923",.9);dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_root.add_child(dim)
	var center:=CenterContainer.new();center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_root.add_child(center)
	var panel:=PanelContainer.new();panel.custom_minimum_size=Vector2(530,308);panel.add_theme_stylebox_override("panel",Ui.panel_style());center.add_child(panel)
	var column:=VBoxContainer.new();column.add_theme_constant_override("separation",6);panel.add_child(column)
	column.add_child(Ui.label("OLIVER GANCHO  /  CARAVANA",20,Color("e9c581")))
	column.add_child(Ui.label("Equipamentos persistem entre as ilhas. I abre a mochila.",10,Ui.MUTED_COLOR))
	_wallet=Ui.label("",13,Ui.TITLE_COLOR);column.add_child(_wallet)
	var quick:=HBoxContainer.new();quick.alignment=BoxContainer.ALIGNMENT_CENTER;column.add_child(quick)
	for pair in [["Coração · 4","heart"],["Açaí · 7","acai"],["Escudo · 10","shield"]]:
		var button:=Ui.button(pair[0],10);quick.add_child(button);button.pressed.connect(_quick_buy.bind(pair[1]))
	var scroll:=ScrollContainer.new();scroll.custom_minimum_size=Vector2(510,164);column.add_child(scroll)
	_rows=VBoxContainer.new();_rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;scroll.add_child(_rows)
	_feedback=Ui.label("",10,Ui.TEXT_COLOR);_feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;_feedback.custom_minimum_size=Vector2(480,26);column.add_child(_feedback)
	_close=Ui.button("Continuar viagem",12);_close.pressed.connect(close);column.add_child(_close);_root.hide()
func _quick_buy(id:String) -> void:
	var price:int={"heart":4,"acai":7,"shield":10}[id]
	if id=="heart" and level.player.health>=3:_feedback.text="Sua vida já está cheia.";return
	if id=="shield" and level.player.shop_shield_hits>0:_feedback.text="Você já tem um escudo.";return
	if not level.player.try_spend_cherries(price):_feedback.text="Cerejas insuficientes ou compra não salva.";return
	if id=="heart":level.player.heal_one()
	elif id=="shield":level.player.grant_shop_shield(3)
	else:level.buy_acai_power()
	_feedback.text="Pronto para a viagem!";_refresh();Sfx.select()
func open() -> void:
	if _open or get_tree().paused:return
	_open=true;_pause_available=level.pause_menu.can_open;level.pause_menu.can_open=false;level.player._cancel_attack();get_tree().paused=true
	Sfx.begin_inventory_music(self);_root.show();_refresh();_close.grab_focus()
func close() -> void:
	if not _open:return
	_open=false;_root.hide();Sfx.end_inventory_music(self);get_tree().paused=false;level.pause_menu.can_open=_pause_available;level.player._invulnerability_timer=maxf(.4,level.player._invulnerability_timer)
func _unhandled_input(event:InputEvent) -> void:
	if _open and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir")):get_viewport().set_input_as_handled();close()
func _exit_tree() -> void:
	Sfx.end_inventory_music(self)
	if _open and get_tree()!=null:get_tree().paused=false
func _refresh() -> void:
	_wallet.text="Saldo: %d cerejas"%Save.get_cherry_balance()
	for child in _rows.get_children():_rows.remove_child(child);child.queue_free()
	for id:String in Catalog.ORDER:
		if not Catalog.is_for_sale(id):continue
		var item:Dictionary=Catalog.ITEMS[id]
		var row:=HBoxContainer.new();_rows.add_child(row)
		var icon:=TextureRect.new();icon.texture=load(item.icon);icon.material=Catalog.icon_material(id);icon.custom_minimum_size=Vector2(28,28);icon.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;icon.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;row.add_child(icon)
		var text:=Ui.label(item.name+" · "+str(item.price)+" cerejas",11,Ui.TEXT_COLOR,HORIZONTAL_ALIGNMENT_LEFT);text.size_flags_horizontal=Control.SIZE_EXPAND_FILL;text.tooltip_text=Catalog.description(id);row.add_child(text)
		var owned:bool=level.player.equipment.owns(id)
		var button:=Ui.button("Comprar" if not owned or Catalog.is_consumable(id) else "Na mochila",10);button.disabled=owned and not Catalog.is_consumable(id);row.add_child(button)
		button.pressed.connect(func():
			var result:Dictionary=level.player.equipment.buy_item(id);_feedback.text=result.message;_refresh()
		)
