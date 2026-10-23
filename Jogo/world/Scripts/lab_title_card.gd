extends Control
## Native lettering remains sharp at every window size; no text is baked into art.
const Brand=preload("res://world/Scripts/corporate_brand.gd")
var reveal:=0.0:
	set(value):reveal=value;queue_redraw()
var _heavy:FontVariation
var _clock:=0.0
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_heavy=FontVariation.new();_heavy.base_font=ThemeDB.fallback_font;_heavy.variation_embolden=1.0
	_heavy.variation_transform=Transform2D(Vector2(1,0),Vector2(-.12,1),Vector2.ZERO)
func _process(delta:float) -> void:
	if not is_visible_in_tree():return
	_clock+=delta
	queue_redraw()
func _draw() -> void:
	if _heavy==null:return
	var ratio:=minf(size.x/640.0,size.y/360.0)
	var anchor:=(size-Vector2(640,360)*ratio)*.5
	draw_set_transform(anchor+Vector2(roundf((1-reveal)*-700),0)*ratio,0,Vector2.ONE*ratio)
	var ink:=Color("101d2c");var muted:=Color("97b5bd");var cream:=Color("fff3d1")
	var panel:=PackedVector2Array([Vector2(38,104),Vector2(588,104),Vector2(602,118),Vector2(602,248),Vector2(588,262),Vector2(38,262)])
	var shadow:=panel.duplicate()
	for i in shadow.size():shadow[i]+=Vector2(4,6)
	draw_colored_polygon(shadow,Color("070f1b",.75))
	draw_colored_polygon(panel,ink)
	draw_polyline(PackedVector2Array([Vector2(38,261),Vector2(588,261),Vector2(601,248),Vector2(601,118),Vector2(588,105)]),Color("465668"),2)
	draw_rect(Rect2(38,104,532,3),Brand.GOLD)
	draw_rect(Rect2(38,107,3,155),Brand.GOLD)
	draw_rect(Rect2(168,134,398,1),Color("334858"))
	draw_rect(Rect2(168,221,398,1),Color("334858"))
	Brand.mark(self,Rect2(72,139,64,73))
	draw_string(ThemeDB.fallback_font,Vector2(168,126),"CORPORAÇÃO  /  DIVISÃO DE PESQUISA",HORIZONTAL_ALIGNMENT_LEFT,398,10,Brand.GOLD)
	var title_at:=Vector2(roundf(168+(1-reveal)*24),174)
	draw_string(_heavy,title_at+Vector2(2,3),"LABORATÓRIO",HORIZONTAL_ALIGNMENT_LEFT,350,31,Color("050e18"))
	draw_string(_heavy,title_at,"LABORATÓRIO",HORIZONTAL_ALIGNMENT_LEFT,350,31,cream)
	draw_string(_heavy,Vector2(title_at.x,204),"DOS EXECUTIVOS",HORIZONTAL_ALIGNMENT_LEFT,350,23,cream)
	draw_rect(Rect2(529,149,38,57),Color("223344"))
	draw_string(_heavy,Vector2(532,181),"05",HORIZONTAL_ALIGNMENT_LEFT,36,25,Brand.GOLD)
	draw_string(ThemeDB.fallback_font,Vector2(534,197),"ILHA",HORIZONTAL_ALIGNMENT_LEFT,34,8,muted)
	var lit:=.6+.3*sin(_clock*4)
	draw_rect(Rect2(169,237,4,4),Color(Brand.GOLD,lit))
	draw_string(ThemeDB.fallback_font,Vector2(181,242),"ACESSO RESTRITO",HORIZONTAL_ALIGNMENT_LEFT,170,9,Brand.GOLD)
	draw_string(ThemeDB.fallback_font,Vector2(410,242),"RESGATE: URSO",HORIZONTAL_ALIGNMENT_LEFT,157,9,muted)
	draw_set_transform(Vector2.ZERO)
