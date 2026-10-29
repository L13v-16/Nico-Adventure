extends Control
const FriendArt = preload("res://world/Scripts/friend_art.gd")
## Álbum de personagens e recordes. A consulta não altera o progresso salvo.
signal back_requested
const UiStyle := preload("res://world/Scripts/ui_style.gd")
const CUTOUT := preload("res://world/Scripts/characters_cutout.gdshader")
const INK := Color("10252e")
const LINE := Color("476763")
const CREAM := Color("eaf0db")
const MUTED := Color("a2b9af")
const MINT := Color("b9dea1")
const GOLD := Color("e3bf76")
const CHARACTERS := [
 {"id":"nico", "name":"Nico", "short":"Nico", "art":"Nico/idle_1", "portrait":"Nico/rosto_1", "bio":"Um guaxinim de lenço verde e mochila. Viaja entre as ilhas para reunir os amigos.", "where":"A jornada começa no Vale das Copas."},
 {"id":"arara", "name":"Arara Minas", "short":"Arara", "art":"Amigos/arara_idle_1", "portrait":"Friends/V47/arara_portrait_neutral.tres", "bio":"Arara azul e amarela que escapou do sequestro. Guia Nico na viagem entre as ilhas.", "where":"Encontro: casa na árvore da floresta."},
 {"id":"turtle", "name":"Tartaruga", "short":"Tartaruga", "art":"Tartaruga/turtle_idle_1", "portrait":"Friends/V47/turtle_portrait_neutral.tres", "bio":"Uma companheira idosa, serena e de casco marcado por muitas travessias.", "where":"Resgate: Costa das Marés, após Urus."},
 {"id":"oliver", "name":"Oliver Gancho", "short":"Oliver", "art":"Caravan/V23/oliver_idle_1_v23", "portrait":"Caravan/V23/oliver_portrait_v23", "bio":"O rato de tapa-olho da caravana. Troca provisões, equipamentos e roupas por cerejas.", "where":"Encontro: caravana móvel da praia."},
 {"id":"remi", "name":"Remi", "short":"Remi", "art":"Magic/remi_idle.tres", "portrait":"Magic/remi_portrait.tres", "bio":"Um esquilo de cauda fofa, pelagem castanha e lenço azul. Conhece as árvores e os segredos das ilhas.", "where":"Resgate: Floresta Violeta, após Triple H."},
 {"id":"jose", "name":"José, o Bode", "short":"José", "art":"Underworld/jose_idle.tres", "portrait":"Underworld/jose_portrait_neutral.tres", "bio":"Um bode forte de chifres curvos e lenço laranja. Suas cabeçadas quebram paredes, derrubam pilares e empurram objetos pesados.", "where":"Resgate: início do Submundo. Depois, acompanha Nico até a saída."},
 {"id":"urso", "name":"Urso", "short":"Urso", "art":"Amigos/urso", "portrait":"Friends/V47/urso_portrait_neutral.tres", "bio":"Um urso-pardo grande e gentil, com um olhar cansado e um coração tranquilo.", "where":"Mantido em testes de resistência no Laboratório dos Executivos."},
 {"id":"mico", "name":"Mico-leão-dourado", "short":"Mico-leão", "art":"Amigos/mico_leao_dourado", "portrait":"Friends/V47/mico_portrait_neutral.tres", "bio":"Amigo de pelagem dourada, juba viva e cauda longa. Foi mantido na cela do presidente da corporação.", "where":"Resgate: sede da Corporação, após a batalha contra o Lobo Lázaro."},
]
var _cards:Array[Button]=[]
var _tabs:Array[Button]=[]
var _pages:Array[Control]=[]
var _selected := -1
var _page := 0
var _name_label:Label
var _status:Label
var _description:Label
var _location:Label
var _portrait:TextureRect
var _back:Button
var _textures:Dictionary={}

func _ready() -> void:
 set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 mouse_filter=Control.MOUSE_FILTER_STOP
 texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 _build()
 _select_character(0,false)
 _cards[0].call_deferred("grab_focus")

static func _style(bg:Color,border:Color,width:int=1,padding:int=0) -> StyleBoxFlat:
 var style:=StyleBoxFlat.new()
 style.bg_color=bg
 style.border_color=border
 style.set_border_width_all(width)
 style.set_corner_radius_all(3)
 style.set_content_margin_all(padding)
 return style

func _texture(path:String) -> Texture2D:
 if not _textures.has(path):_textures[path]=FriendArt.texture("res://world/Arte/"+path+("" if path.ends_with(".tres") else ".png"))
 return _textures[path] as Texture2D

func _art(path:String,minimum:Vector2) -> TextureRect:
 var art:=TextureRect.new()
 art.texture=_texture(path)
 art.custom_minimum_size=minimum
 art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
 art.mouse_filter=Control.MOUSE_FILTER_IGNORE
 var material:=ShaderMaterial.new()
 material.shader=CUTOUT
 art.material=material
 return art

static func _button(text:String) -> Button:
 var button:=Button.new()
 button.text=text
 button.custom_minimum_size.y=24
 button.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 button.add_theme_font_size_override("font_size",11)
 button.add_theme_color_override("font_color",MUTED)
 button.add_theme_color_override("font_pressed_color",CREAM)
 button.add_theme_stylebox_override("normal",_style(Color("172f35"),LINE))
 button.add_theme_stylebox_override("hover",_style(Color("25433e"),MINT))
 button.add_theme_stylebox_override("pressed",_style(Color("29483e"),MINT))
 button.add_theme_stylebox_override("focus",_style(Color.TRANSPARENT,GOLD,2))
 return button

func _build() -> void:
 var dim:=ColorRect.new()
 dim.color=Color(0.01,0.03,0.04,0.62)
 dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(dim)
 var center:=CenterContainer.new()
 center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
 add_child(center)
 var frame:=PanelContainer.new()
 frame.name="CollectionFrame"
 frame.custom_minimum_size=Vector2(584,332)
 frame.add_theme_stylebox_override("panel",_style(INK,LINE,1,12))
 center.add_child(frame)
 var column:=VBoxContainer.new()
 column.add_theme_constant_override("separation",8)
 frame.add_child(column)
 var header:=HBoxContainer.new()
 column.add_child(header)
 var title:=UiStyle.label("COLEÇÃO",20,CREAM,HORIZONTAL_ALIGNMENT_LEFT)
 title.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 header.add_child(title)
 var completed_islands:=int(Save.is_level_completed("fase_1"))+int(Save.is_level_completed("fase_2"))+int(Save.is_level_completed("fase_3"))+int(Save.is_level_completed("fase_4"))+int(Save.is_level_completed("fase_5"))+int(Save.is_level_completed("fase_6"))
 var summary:=UiStyle.label("%d / 6 ILHAS" % completed_islands,10,MINT)
 summary.name="CollectionIslandCount"
 summary.custom_minimum_size.x=82
 header.add_child(summary)
 var cherry:=TextureRect.new()
 var cherry_atlas:=AtlasTexture.new()
 cherry_atlas.atlas=load("res://Sunny-land-files/assets/Misc/Sunnyland items/cherry.png")
 cherry_atlas.region=Rect2(0,0,21,21)
 cherry.texture=cherry_atlas
 cherry.custom_minimum_size=Vector2(18,18)
 cherry.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 cherry.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 cherry.mouse_filter=Control.MOUSE_FILTER_IGNORE
 header.add_child(cherry)
 var wallet:=UiStyle.label(str(Save.get_cherry_balance()),14,GOLD)
 wallet.name="CollectionWallet"
 header.add_child(wallet)
 var tabs:=HBoxContainer.new()
 tabs.add_theme_constant_override("separation",6)
 column.add_child(tabs)
 var tab_group:=ButtonGroup.new()
 for i in 3:
  var tab:=_button(["Amigos","Ilhas e recordes","Lembranças"][i])
  tab.name=["FriendsTab","IslandsTab","MemoriesTab"][i]
  tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  tab.toggle_mode=true
  tab.button_group=tab_group
  tab.pressed.connect(_show_page.bind(i))
  tabs.add_child(tab)
  _tabs.append(tab)
 var friends:=_build_friends()
 friends.name="FriendsPage"
 column.add_child(friends)
 _pages.append(friends)
 var islands:=_build_islands()
 islands.name="IslandsPage"
 column.add_child(islands)
 _pages.append(islands)
 islands.hide()
 var memories:=preload("res://world/Scripts/memories_panel.gd").new()
 column.add_child(memories)
 _pages.append(memories)
 memories.hide()
 _tabs[0].button_pressed=true
 var footer:=HBoxContainer.new()
 footer.add_theme_constant_override("separation",8)
 column.add_child(footer)
 var controls:=UiStyle.label("Setas: explorar  ·  Clique: detalhes",9,MUTED,HORIZONTAL_ALIGNMENT_LEFT)
 controls.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 footer.add_child(controls)
 _back=_button("Voltar · Esc")
 _back.name="CollectionBack"
 _back.custom_minimum_size.x=106
 _back.pressed.connect(func():back_requested.emit())
 footer.add_child(_back)
 _wire_focus()

func _build_friends() -> Control:
 var content:=HBoxContainer.new()
 content.custom_minimum_size.y=202
 content.add_theme_constant_override("separation",12)
 var left:=VBoxContainer.new()
 left.add_theme_constant_override("separation",5)
 content.add_child(left)
 var grid:=GridContainer.new()
 grid.columns=4
 grid.add_theme_constant_override("h_separation",5)
 grid.add_theme_constant_override("v_separation",5)
 left.add_child(grid)
 var group:=ButtonGroup.new()
 for i in CHARACTERS.size():
  var character:Dictionary=CHARACTERS[i]
  var card:=_button("")
  card.name="Character_"+character.id
  card.custom_minimum_size=Vector2(64,77)
  card.toggle_mode=true
  card.button_group=group
  card.pressed.connect(_select_character.bind(i))
  card.focus_entered.connect(_select_character.bind(i))
  grid.add_child(card)
  _cards.append(card)
  var art_column:=VBoxContainer.new()
  art_column.set_anchors_preset(Control.PRESET_FULL_RECT)
  art_column.offset_left=4
  art_column.offset_right=-4
  art_column.offset_top=5
  art_column.offset_bottom=-4
  art_column.add_theme_constant_override("separation",1)
  art_column.mouse_filter=Control.MOUSE_FILTER_IGNORE
  card.add_child(art_column)
  art_column.add_child(_art(character.get("portrait",character.art),Vector2(52,38)))
  art_column.add_child(UiStyle.label(character.short,9,CREAM))
  var state:=character_state(character.id)
  art_column.add_child(UiStyle.label(state.short,8,state.color))
 var caption:=UiStyle.label("Os cartões contam a história de cada amigo.",9,MUTED,HORIZONTAL_ALIGNMENT_LEFT)
 caption.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 caption.custom_minimum_size.x=271
 left.add_child(caption)
 var detail:=PanelContainer.new()
 detail.name="CharacterDetail"
 detail.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 detail.add_theme_stylebox_override("panel",_style(Color("152e32"),LINE,1,10))
 content.add_child(detail)
 var info:=VBoxContainer.new()
 info.add_theme_constant_override("separation",5)
 detail.add_child(info)
 _name_label=UiStyle.label("",16,CREAM,HORIZONTAL_ALIGNMENT_LEFT)
 _name_label.name="SelectedCharacterName"
 info.add_child(_name_label)
 _status=UiStyle.label("",10,MINT,HORIZONTAL_ALIGNMENT_LEFT)
 _status.name="SelectedCharacterStatus"
 info.add_child(_status)
 var body:=HBoxContainer.new()
 body.add_theme_constant_override("separation",8)
 info.add_child(body)
 _portrait=_art(CHARACTERS[0].portrait,Vector2(72,82))
 _portrait.name="SelectedCharacterArt"
 body.add_child(_portrait)
 _description=UiStyle.label("",11,CREAM,HORIZONTAL_ALIGNMENT_LEFT)
 _description.name="SelectedCharacterDescription"
 _description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _description.size_flags_horizontal=Control.SIZE_EXPAND_FILL
 _description.custom_minimum_size=Vector2(140,82)
 body.add_child(_description)
 info.add_child(UiStyle.divider())
 _location=UiStyle.label("",10,MUTED,HORIZONTAL_ALIGNMENT_LEFT)
 _location.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
 _location.custom_minimum_size.y=26
 info.add_child(_location)
 return content

func _build_islands() -> Control:
 var scroll:=ScrollContainer.new()
 scroll.name="IslandScroll"
 scroll.focus_mode=Control.FOCUS_ALL
 scroll.custom_minimum_size.y=202
 scroll.vertical_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
 var content:=HBoxContainer.new()
 scroll.add_child(content)
 content.custom_minimum_size.y=202
 content.add_theme_constant_override("separation",10)
 for phase in [{"id":"fase_1","name":"Vale das Copas","art":"fundo_meio"},{"id":"fase_2","name":"Costa das Marés","art":"Beach/beach_background"},{"id":"fase_3","name":"Floresta Violeta","art":"Magic/magic_background"},{"id":"fase_4","name":"O Submundo","art":"Underworld/underworld_background"},{"id":"fase_5","name":"Laboratório","art":"Lab/V68/background_03.tres"},{"id":"fase_6","name":"Corporação do Mal","art":"CorpV82/background"}]:
  var panel:=PanelContainer.new()
  panel.name="Island_"+phase.id
  panel.custom_minimum_size.x=148
  panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL
  panel.add_theme_stylebox_override("panel",_style(Color("152e32"),LINE,1,10))
  content.add_child(panel)
  var column:=VBoxContainer.new()
  column.add_theme_constant_override("separation",4)
  panel.add_child(column)
  var banner:=_art(phase.art,Vector2(116,32))
  banner.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
  banner.clip_contents=true
  column.add_child(banner)
  column.add_child(UiStyle.label(phase.name,11,CREAM,HORIZONTAL_ALIGNMENT_LEFT))
  var complete:bool=Save.is_level_completed(phase.id)
  column.add_child(UiStyle.label("CONCLUÍDA" if complete else "A EXPLORAR",9,MINT if complete else GOLD,HORIZONTAL_ALIGNMENT_LEFT))
  var stats:Dictionary=Save.get_level_stats(phase.id)
  if stats.is_empty():
   column.add_child(UiStyle.label("—",26,MUTED,HORIZONTAL_ALIGNMENT_LEFT))
   var empty:=UiStyle.label("Conclua esta ilha para registrar sua primeira aventura.",11,MUTED,HORIZONTAL_ALIGNMENT_LEFT)
   empty.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
   column.add_child(empty)
  else:
   var record:=HBoxContainer.new()
   record.add_theme_constant_override("separation",12)
   column.add_child(record)
   var rank:=String(stats.get("rank","D"))
   record.add_child(UiStyle.label(rank,26,UiStyle.RANK_COLORS.get(rank,GOLD)))
   var best:=VBoxContainer.new()
   best.add_theme_constant_override("separation",0)
   record.add_child(best)
   best.add_child(UiStyle.label("MELHOR TEMPO",8,MUTED,HORIZONTAL_ALIGNMENT_LEFT))
   var seconds:=int(maxf(0,float(stats.get("time",0))))
   best.add_child(UiStyle.label("%d:%02d"%[seconds/60,seconds%60],16,CREAM,HORIZONTAL_ALIGNMENT_LEFT))
   column.add_child(UiStyle.label("%d cerejas  ·  %d segredos"%[int(stats.get("cherries",0)),int(stats.get("secrets",0))],11,CREAM,HORIZONTAL_ALIGNMENT_LEFT))
   column.add_child(UiStyle.label("%d inimigos  ·  %d mortes"%[int(stats.get("enemies",0)),int(stats.get("deaths",0))],10,MUTED,HORIZONTAL_ALIGNMENT_LEFT))
 return scroll

func character_state(id:String) -> Dictionary:
 match id:
  "nico":return {"text":"Em viagem", "short":"VIAGEM", "color":MINT}
  "arara":return {"text":"Companheira de viagem" if Save.is_level_completed("fase_1") else "Escapou da corporação", "short":"GUIA", "color":MINT}
  "oliver":return {"text":"Comerciante da caravana", "short":"LOJA", "color":GOLD}
  "turtle":
   if Save.is_level_completed("fase_2"):return {"text":"Resgatada na Costa das Marés", "short":"RESGATADA", "color":MINT}
   return {"text":"Próximo resgate" if Save.is_level_completed("fase_1") else "À espera de Nico", "short":"A SALVAR", "color":GOLD}
  "remi":
   if Save.is_level_completed("fase_3"):return {"text":"Resgatado na Floresta Violeta", "short":"RESGATADO", "color":MINT}
   return {"text":"Próximo resgate" if Save.is_level_completed("fase_2") else "À espera de Nico", "short":"A SALVAR", "color":GOLD}
  "urso":
   if Save.has_story_flag("urso_rescued") or Save.is_level_completed("fase_5"):return {"text":"Resgatado no Laboratório dos Executivos", "short":"RESGATADO", "color":MINT}
   return {"text":"Próximo resgate" if Save.is_level_completed("fase_4") else "À espera de Nico", "short":"A SALVAR", "color":GOLD}
  "jose":
   if Save.has_story_flag("jose_rescued") or Save.is_level_completed("fase_4"):return {"text":"Resgatado no Submundo · companheiro", "short":"RESGATADO", "color":MINT}
   return {"text":"Próximo resgate" if Save.is_level_completed("fase_3") else "À espera de Nico", "short":"A SALVAR", "color":GOLD}
  "mico":
   if Save.has_story_flag("mico_rescued") or Save.is_level_completed("fase_6"):return {"text":"Resgatado na sede da Corporação", "short":"RESGATADO", "color":MINT}
   return {"text":"Último amigo a resgatar" if Save.is_level_completed("fase_5") else "À espera de Nico", "short":"A SALVAR", "color":GOLD}
 return {"text":"Ainda desaparecido", "short":"A SALVAR", "color":GOLD}

func _select_character(index:int,play_sound:bool=true) -> void:
 if index==_selected:return
 _selected=index
 var character:Dictionary=CHARACTERS[index]
 var state:=character_state(character.id)
 _name_label.text=character.name
 _status.text=state.text
 _status.add_theme_color_override("font_color",state.color)
 _description.text=character.bio
 _location.text=character.where
 _portrait.texture=_texture(character.get("portrait",character.art))
 _cards[index].button_pressed=true
 _cards[index].grab_focus()
 if play_sound:Sfx.select()

func _show_page(index:int) -> void:
 if _page==index:return
 _page=index
 for i in _pages.size():
  _pages[i].visible=i==index
  _tabs[i].button_pressed=i==index
 _tabs[index].grab_focus()
 Sfx.select()

func _wire_focus() -> void:
 for i in _cards.size():
  var card:=_cards[i]
  card.focus_neighbor_left=_cards[i-1].get_path() if i%4>0 else card.get_path()
  card.focus_neighbor_right=_cards[i+1].get_path() if i%4<3 else card.get_path()
  card.focus_neighbor_top=_cards[i-4].get_path() if i>=4 else _tabs[0].get_path()
  card.focus_neighbor_bottom=_cards[i+4].get_path() if i<4 else _back.get_path()
 _tabs[0].focus_neighbor_bottom=_cards[0].get_path()
 var island_scroll:=_pages[1] as ScrollContainer
 _tabs[1].focus_neighbor_bottom=island_scroll.get_path()
 island_scroll.focus_neighbor_top=_tabs[1].get_path()
 island_scroll.focus_neighbor_bottom=_back.get_path()
 _back.focus_neighbor_top=_tabs[2].get_path()
 _tabs[2].focus_neighbor_bottom=(_pages[2].cards[0] as Button).get_path()
 for i in _pages[2].cards.size():
  var card:Button=_pages[2].cards[i]
  card.focus_neighbor_top=(_pages[2].cards[i-1] as Button).get_path() if i>0 else _tabs[2].get_path()
  card.focus_neighbor_bottom=(_pages[2].cards[i+1] as Button).get_path() if i<5 else _back.get_path()
