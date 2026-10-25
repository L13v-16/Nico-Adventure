extends HBoxContainer
const Catalog=preload("res://world/Scripts/memories_catalog.gd")
const UI=preload("res://world/Scripts/ui_style.gd")
var cards:Array[Button]=[]
var _image:TextureRect
var _title:Label
var _caption:Label
var _progress:Label
var _open:Button
var _viewer:Control
var _selected:=0
func _ready() -> void:
	name="MemoriesPage";custom_minimum_size.y=202;add_theme_constant_override("separation",12)
	var list:=VBoxContainer.new();list.custom_minimum_size.x=168;add_child(list)
	_progress=UI.label("%d fragmentos · %d / 6 lembranças"%[Save.fragment_count(),Catalog.unlocked_count(Save.fragment_count())],9,Color("e3bf76"),HORIZONTAL_ALIGNMENT_LEFT);list.add_child(_progress)
	for i in Catalog.ENTRIES.size():
		var entry:Dictionary=Catalog.ENTRIES[i];var unlocked:=Save.fragment_count()>=int(entry.need)
		var button:=UI.button(("✓ " if unlocked else "◇ ")+str(entry.title),10);button.custom_minimum_size=Vector2(168,25);button.alignment=HORIZONTAL_ALIGNMENT_LEFT;list.add_child(button);cards.append(button)
		button.pressed.connect(_select.bind(i));button.focus_entered.connect(_select.bind(i))
	var detail:=VBoxContainer.new();detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL;detail.add_theme_constant_override("separation",3);add_child(detail)
	_title=UI.label("",12,Color("eaf0db"),HORIZONTAL_ALIGNMENT_LEFT);detail.add_child(_title)
	_image=TextureRect.new();_image.name="MemoryPreview";_image.custom_minimum_size=Vector2(350,137);_image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;_image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;detail.add_child(_image)
	_caption=UI.label("",9,Color("a2b9af"),HORIZONTAL_ALIGNMENT_LEFT);_caption.custom_minimum_size=Vector2(350,25);_caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;detail.add_child(_caption)
	_open=UI.button("Ampliar lembrança",10);_open.custom_minimum_size.y=22;_open.pressed.connect(_show_image);detail.add_child(_open);_select(0)
func _select(index:int) -> void:
	_selected=index
	var entry:Dictionary=Catalog.ENTRIES[index];var count:=Save.fragment_count();var unlocked:=count>=int(entry.need)
	_title.text=str(entry.title)
	_image.texture=load(Catalog.image_path(index)) if unlocked else null
	_caption.text=str(entry.text) if unlocked else "Encontre mais %d fragmento(s) para revelar esta imagem.
Progresso: %d / %d. Colete nas ilhas; eles não são gastos."%[int(entry.need)-count,count,int(entry.need)]
	_open.disabled=not unlocked
func _show_image() -> void:
	if _open.disabled:return
	_viewer=Control.new();_viewer.name="MemoryViewer";_viewer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_viewer.z_index=100;get_parent().get_parent().get_parent().get_parent().add_child(_viewer)
	var dim:=ColorRect.new();dim.color=Color("091b23");dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_viewer.add_child(dim)
	var picture:=TextureRect.new();picture.position=Vector2(24,24);picture.size=Vector2(592,282);picture.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;picture.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED;picture.texture=_image.texture;picture.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;_viewer.add_child(picture)
	var back:=UI.button("Voltar ao álbum · Esc",11);back.position=Vector2(209,320);back.size=Vector2(222,27);_viewer.add_child(back);back.pressed.connect(_close_image);back.grab_focus()
func _close_image() -> void:
	if is_instance_valid(_viewer):_viewer.queue_free();_viewer=null
	cards[_selected].grab_focus()
func _input(event:InputEvent) -> void:
	if is_instance_valid(_viewer) and event.is_action_pressed("ui_cancel"):
		_close_image();get_viewport().set_input_as_handled()
