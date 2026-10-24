extends "res://world/Scripts/Corp2D/cutscene.gd"
var record_id:="forest"
var page:=0
var image_view:TextureRect
var _page_label:Label
const Polish=preload("res://world/Scripts/Corp2D/polish_art.gd")
const GREEN=Color("a5ffc1")
func _ready() -> void:
	mode="record";super._ready();_stage.hide()
	_text("CORP / ARQUIVO RECUPERADO",10,Rect2(105,59,420,18))
	_text(record_title,13,Rect2(105,80,430,29))
	var content:=_text(record_text,11,Rect2(105,121,201,127));content.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	image_view=TextureRect.new();image_view.position=Vector2(322,119);image_view.size=Vector2(211,119);image_view.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;image_view.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED;image_view.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var shader:=Shader.new();shader.code="shader_type canvas_item; void fragment(){vec4 t=texture(TEXTURE,UV);float l=dot(t.rgb,vec3(.299,.587,.114));float scan=.91+.09*step(.5,fract(UV.y*120.0));COLOR=vec4(vec3(l*scan),t.a);}"
	var material:=ShaderMaterial.new();material.shader=shader;image_view.material=material;_canvas.add_child(image_view)
	_page_label=_text("",9,Rect2(322,243,211,20))
	_button("‹ Registro",Rect2(106,268,112,24),func():_change_page(-1))
	_button("Registro ›",Rect2(225,268,112,24),func():_change_page(1))
	var close:=_button("Fechar  [E]",Rect2(417,268,117,24),finish);close.grab_focus()
	_change_page(0)
func _text(text:String,size:int,rect:Rect2) -> Label:
	var node:=Label.new();node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;node.text=text;node.position=rect.position;node.size=rect.size;node.add_theme_font_size_override("font_size",size);node.add_theme_color_override("font_color",GREEN);node.mouse_filter=Control.MOUSE_FILTER_IGNORE;_canvas.add_child(node);return node
func _button(text:String,rect:Rect2,action:Callable) -> Button:
	var button:=preload("res://world/Scripts/ui_style.gd").button(text,10);button.position=rect.position;button.size=rect.size;button.pressed.connect(action);button.add_theme_color_override("font_color",GREEN);_canvas.add_child(button);return button
func _change_page(direction:int) -> void:
	page=posmod(page+direction,3)
	var path:="res://world/Arte/CorpV86/evidence_%d.png"%page
	if ResourceLoader.exists(path):image_view.texture=load(path)
	_page_label.text="CAM %02d · NICO EM AÇÃO · %d / 3"%[page+1,page+1]
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
