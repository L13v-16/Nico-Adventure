extends VBoxContainer
const Ui=preload("res://world/Scripts/ui_style.gd")
var pending_action:=""
var pending_slot:=0
var buttons:Dictionary={}
var feedback:Label
var scroll:ScrollContainer
var _reset_armed:=false
func _ready() -> void:
	name="KeyboardControls"
	process_mode=Node.PROCESS_MODE_ALWAYS;add_theme_constant_override("separation",6)
	var intro:=Ui.label("Escolha uma tecla e pressione a nova. Esc cancela.\nBotão direito limpa a alternativa. Mouse continua ativo.",10,Ui.MUTED_COLOR);add_child(intro)
	scroll=ScrollContainer.new();scroll.custom_minimum_size=Vector2(460,112);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;scroll.follow_focus=true;add_child(scroll)
	var rows:=VBoxContainer.new();rows.size_flags_horizontal=Control.SIZE_EXPAND_FILL;rows.add_theme_constant_override("separation",3);scroll.add_child(rows)
	var group:=""
	for data:Array in Controls.ROWS:
		if data[2]!=group:
			group=data[2];var title:=Ui.label(group,11,Ui.TITLE_COLOR,HORIZONTAL_ALIGNMENT_LEFT);rows.add_child(title)
		var row:=HBoxContainer.new();rows.add_child(row)
		var label:=Ui.label(data[1],10,Ui.TEXT_COLOR,HORIZONTAL_ALIGNMENT_LEFT);label.custom_minimum_size.x=240;label.size_flags_vertical=Control.SIZE_SHRINK_CENTER;row.add_child(label)
		for slot in 2:
			var button:=Ui.button("",11);button.custom_minimum_size=Vector2(88,24);row.add_child(button)
			var action:String=data[0];buttons[action+str(slot)]=button;button.pressed.connect(listen.bind(action,slot));button.gui_input.connect(_button_input.bind(action,slot))
	feedback=Ui.label("Setas, Enter e Esc continuam disponíveis nos menus.",10,Ui.MUTED_COLOR);feedback.custom_minimum_size=Vector2(460,28);feedback.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(feedback)
	var restore:=Ui.button("Restaurar teclas padrão",11);restore.name="RestoreDefaults";restore.pressed.connect(_restore.bind(restore));add_child(restore)
	Controls.changed.connect(_refresh);_refresh()
func _button_input(event:InputEvent,action:String,slot:int) -> void:
	if slot==1 and event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT:
		cancel_listening();var error:=Controls.clear_secondary(action);feedback.text="Alternativa removida." if error.is_empty() else error;get_viewport().set_input_as_handled()
func listen(action:String,slot:int) -> void:
	pending_action=action;pending_slot=slot;_reset_armed=false;_refresh();feedback.text="Pressione uma tecla · Esc cancela."
func cancel_listening() -> void:
	pending_action="";_refresh()
func _input(event:InputEvent) -> void:
	if pending_action.is_empty() or not event is InputEventKey:return
	if not event.pressed or event.echo:return
	get_viewport().set_input_as_handled()
	var code:int=event.physical_keycode if event.physical_keycode else event.keycode
	if code==KEY_ESCAPE:cancel_listening();feedback.text="Troca cancelada.";return
	if event.alt_pressed or event.meta_pressed or (event.ctrl_pressed and code!=KEY_CTRL) or (event.shift_pressed and code!=KEY_SHIFT):feedback.text="Use uma tecla sem combinação.";return
	var error:=Controls.assign(pending_action,pending_slot,code)
	if not error.is_empty():feedback.text=error;return
	cancel_listening();feedback.text="Teclas salvas. A mudança já está ativa.";Sfx.select()
func _refresh() -> void:
	for data:Array in Controls.ROWS:
		for slot in 2:
			var button:Button=buttons[data[0]+str(slot)];button.text="…" if pending_action==data[0] and pending_slot==slot else Controls.key_label(data[0],slot)
func _restore(button:Button) -> void:
	cancel_listening()
	if not _reset_armed:_reset_armed=true;button.text="Confirmar restauração";return
	var error:=Controls.restore_defaults();feedback.text="Teclas padrão restauradas." if error.is_empty() else error;button.text="Restaurar teclas padrão";_reset_armed=false
