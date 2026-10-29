extends CanvasLayer
## Same CRT reader for 2D and 3D. Never expires while the player is reading.
signal finished
var level:Node
var mode:="record"
var record_title:=""
var record_text:=""
var custom_images:Array=[]
var clock:=0.0
var _done:=false
var _canvas:Control
var _old_pause:=false
var _old_intro:=false
var _old_menu:=false
var _old_timing:=false
var _has_timing:=false
var _hud_states:Dictionary={}
var _close:Button
var _previous:Button
var _next:Button
var record_id:="forest"
var page:=0
var image_view:TextureRect
var _page_label:Label
const Polish=preload("res://world/Scripts/Corp2D/polish_art.gd")
const GREEN=Color("a5ffc1")
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS;layer=90
	_old_pause=get_tree().paused;_old_intro=level.intro_active;_old_menu=level.pause_menu.can_open
	for property in level.get_property_list():
		if property.name=="_timing":_has_timing=true;_old_timing=bool(level.get("_timing"));level.set("_timing",false)
	for node in level.find_children("*","CanvasLayer",true,false):
		if node!=self and not is_ancestor_of(node) and node.layer>=0:_hud_states[node]=node.visible;node.hide()
	level.intro_active=true;level.pause_menu.can_open=false;get_tree().paused=true
	level.player._cancel_attack()
	Sfx.begin_dialogue_music(self)
	_canvas=Control.new();_canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_canvas.mouse_filter=Control.MOUSE_FILTER_STOP;_canvas.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;_canvas.draw.connect(_draw_scene);add_child(_canvas)
	_text("CORP / ARQUIVO RECUPERADO",10,Rect2(105,59,420,18))
	_text(record_title,13,Rect2(105,80,430,29))
	var content:=_text(record_text,11,Rect2(105,121,201,127));content.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	image_view=TextureRect.new();image_view.position=Vector2(322,119);image_view.size=Vector2(211,119);image_view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image_view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image_view.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var shader:=Shader.new();shader.code="shader_type canvas_item; void fragment(){vec4 t=texture(TEXTURE,UV);float l=dot(t.rgb,vec3(.299,.587,.114));float scan=.91+.09*step(.5,fract(UV.y*120.0));COLOR=vec4(vec3(l*scan),t.a);}"
	var material:=ShaderMaterial.new();material.shader=shader;image_view.material=material;_canvas.add_child(image_view)
	_page_label=_text("",9,Rect2(322,243,211,20))
	_previous=_button("‹ Registro",Rect2(106,268,112,24),func():_change_page(-1))
	_next=_button("Registro ›",Rect2(225,268,112,24),func():_change_page(1))
	_close=_button("Fechar [%s]"%Controls.key_label("interagir",0),Rect2(405,268,129,24),finish);_close.grab_focus()
	var buttons:Array[Button]=[_previous,_next,_close]
	for i in buttons.size():
		buttons[i].focus_next=buttons[(i+1)%3].get_path();buttons[i].focus_previous=buttons[posmod(i-1,3)].get_path()
		buttons[i].focus_neighbor_top=buttons[i].get_path();buttons[i].focus_neighbor_bottom=buttons[i].get_path()
	_change_page(0)
func _text(text:String,size:int,rect:Rect2) -> Label:
	var node:=Label.new();node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.text=text;node.position=rect.position;node.size=rect.size;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",GREEN);node.mouse_filter=Control.MOUSE_FILTER_IGNORE;_canvas.add_child(node);return node
func _button(text:String,rect:Rect2,action:Callable) -> Button:
	var button:=preload("res://world/Scripts/ui_style.gd").button(text,10);button.position=rect.position;button.size=rect.size;button.pressed.connect(action);button.add_theme_color_override("font_color",GREEN);_canvas.add_child(button);return button
const RECORD_IMAGES := {
	"forest":[["forest","VALE DAS COPAS"],["magic","FLORESTA VIOLETA"]],
	"beach":[["beach","COSTA DAS MARÉS"]],
	"underworld":[["underworld","SUBMUNDO"]],
	"lab":[["lab","LABORATÓRIO DOS EXECUTIVOS"]],
	"office":[["corporation","SEDE DA CORPORAÇÃO"]],
	"prototype":[["corporation","UNIDADE EXECUTIVA"]],
}
func _change_page(direction:int) -> void:
	var images:Array=custom_images if not custom_images.is_empty() else RECORD_IMAGES.get(record_id,RECORD_IMAGES.office)
	page=posmod(page+direction,images.size())
	var path:="res://world/Arte/MemoriesV96/evidence_"+str(images[page][0])+".png"
	image_view.texture=load(path) if ResourceLoader.exists(path) else null
	_previous.visible=images.size()>1;_next.visible=images.size()>1
	_page_label.text="%s · %d / %d"%[str(images[page][1]),page+1,images.size()]
func _process(delta:float) -> void:
	clock+=delta;_canvas.queue_redraw()
func _input(event:InputEvent) -> void:
	if event.is_echo() or clock<.3:return
	if event.is_action_pressed("ui_left") or event.is_action_pressed("ui_right"):
		_change_page(-1 if event.is_action_pressed("ui_left") else 1);get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled();finish()
func _draw_scene() -> void:
	_canvas.draw_rect(Rect2(0,0,640,360),Color(.01,.03,.02,.94))
	_canvas.draw_texture_rect(Polish.cell(9),Rect2(12,12,616,336),false)
	_canvas.draw_rect(Rect2(102,113,434,2),Color("39855b"))
	_canvas.draw_rect(Rect2(319,116,216,126),Color("071611"))
	_canvas.draw_circle(Vector2(526,64),2,Color("89ffba") if fposmod(clock,1)<.7 else Color("305b41"))

func finish() -> void:
	if _done:return
	_done=true;_restore();finished.emit();queue_free()
func _restore() -> void:
	if get_tree()!=null:get_tree().paused=_old_pause
	if is_instance_valid(level) and level.is_inside_tree():
		level.intro_active=_old_intro;level.pause_menu.can_open=_old_menu
		if _has_timing:level.set("_timing",_old_timing)
		for hud in _hud_states:
			if is_instance_valid(hud):hud.visible=_hud_states[hud]
	_hud_states.clear();Sfx.end_dialogue_music(self)
func _exit_tree() -> void:
	if not _done:_restore()
