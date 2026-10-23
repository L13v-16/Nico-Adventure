extends Control
## Shared presentation only: reads the live power timers without changing combat.
const ICONS=preload("res://world/Arte/HUD/element_icons_v80.png")
const FIRE:=Color("ffb65b")
const ICE:=Color("86e6ff")
var powers:Node
var state:Dictionary={}
var _last_selected:=""
var _selection_flash:=0.0

func _ready() -> void:
	name="ElementalHUD"
	process_mode=Node.PROCESS_MODE_ALWAYS
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	size=Vector2(144,72)
	refresh()

func _process(delta:float) -> void:
	_selection_flash=maxf(0,_selection_flash-delta)
	refresh()

func refresh() -> void:
	if not is_instance_valid(powers):hide();return
	var player:Node=powers.get_parent()
	var level:Node=player.get_parent()
	var mastery:bool=powers.has_mastery()
	var boss:Node=level.get_node_or_null("Boss")
	var in_boss:bool=is_instance_valid(boss) and boss.get("active")==true
	var allowed:bool=powers.has_any() and not get_tree().paused and not player.is_dead() and not player._finished and level.get("intro_active")!=true and level.get("completed")!=true
	if level.has_method("elemental_hud_text"):
		allowed=allowed and not level.elemental_hud_text(powers.selected).is_empty()
	visible=allowed
	position=Vector2(12,132 if in_boss else 58)
	var remaining:float=powers.cooldown
	var minimum:float=player.get_attack_cooldown_floor() if is_instance_valid(boss) else 0.0
	if minimum>0:remaining=maxf(remaining,player._attack_cooldown)
	var duration:float=maxf(powers.cooldown_duration,minimum)
	var regular:float=0
	if player is CharacterBody2D and is_instance_valid(player._active_acai):regular=player._active_acai.get_time_left()
	elif player is CharacterBody3D:regular=player.acai_left
	state={"selected":powers.selected,"fire":powers.has_fire(),"ice":powers.has_ice(),"mastery":mastery,
		"fire_time":powers.temporary_fire,"ice_time":powers.ice_time_left() if powers.has_method("ice_time_left") else 0.0,
		"cooldown":remaining,"charge":1.0-clampf(remaining/maxf(duration,.01),0,1),"blocked":not powers.can_control(),
		"acai":regular,"freeze":player.equipment.get_freeze_duration(),"frost_boost":player.equipment.get_frost_boost_left()}
	if _last_selected!=powers.selected:_last_selected=powers.selected;_selection_flash=.22
	queue_redraw()

func _text(at:Vector2,value:String,color:Color,font_size:int=8,width:float=-1,alignment:HorizontalAlignment=HORIZONTAL_ALIGNMENT_LEFT) -> void:
	draw_string(ThemeDB.fallback_font,at+Vector2(0,1),value,alignment,width,font_size,Color("070e18"))
	draw_string(ThemeDB.fallback_font,at,value,alignment,width,font_size,color)

func _draw() -> void:
	if state.is_empty():return
	draw_rect(Rect2(1,3,144,72),Color(0,0,0,.3))
	draw_style_box(_panel(),Rect2(0,0,144,72))
	for index in 2:
		var element:String="fire" if index==0 else "ice"
		var available:bool=state[element]
		var selected:bool=state.selected==element and available
		var color:Color=FIRE if index==0 else ICE
		var x:float=6+index*70
		draw_rect(Rect2(x,6,62,46),Color("253649") if selected else Color("101c2b"))
		draw_rect(Rect2(x,6,62,46),color.lerp(Color.WHITE,_selection_flash) if selected else Color("35485b"),false,1)
		var cell:=Vector2(ICONS.get_width()*.5,ICONS.get_height())
		var tint:=Color.WHITE if available else Color(.34,.39,.45,.45)
		draw_texture_rect_region(ICONS,Rect2(x+15,8,32,32),Rect2(Vector2(cell.x*index,0),cell),tint)
		_text(Vector2(x,49),"FOGO" if index==0 else "GELO",color if available else Color("718293"),8,62,HORIZONTAL_ALIGNMENT_CENTER)
		if selected:
			draw_rect(Rect2(x+3,7,3,3),color)
			if float(state.cooldown)>0:
				draw_rect(Rect2(x+3,39,56,2),Color("08111b"))
				draw_rect(Rect2(x+3,39,56*float(state.charge),2),color)
		if not available:
			# Pixel padlock distinguishes an unavailable element from a recharging one.
			draw_rect(Rect2(x+49,13,5,5),Color("8c9aa8"),false,1)
			draw_rect(Rect2(x+48,17,7,5),Color("8c9aa8"))
		elif not state.mastery:
			var seconds:float=state.fire_time if index==0 else state.ice_time
			_text(Vector2(x+1,61),"%ds"%int(ceilf(seconds)),color,8,60,HORIZONTAL_ALIGNMENT_CENTER)
	var status:="K · lançar"
	if state.blocked:status="K · indisponível"
	elif float(state.cooldown)>0:status="K · %.1fs"%float(state.cooldown)
	_text(Vector2(6,69),status,Color("d5e5ed"),8)
	if state.fire and state.ice:_text(Vector2(85,69),"Q · trocar",Color("aec1d0"),8)
	# Açaí's melee bonus remains visible even after permanent powers are learned.
	if float(state.acai)>0 or float(state.frost_boost)>0:
		draw_rect(Rect2(0,76,144,16),Color("101f30"))
		var bonus:="AÇAÍ 2× · %ds"%int(ceilf(state.acai)) if float(state.acai)>0 else "AÇAÍ GELADO · %ds"%int(ceilf(state.frost_boost))
		_text(Vector2(5,87),bonus,Color("c7b2f3"),8)

func _panel() -> StyleBoxFlat:
	var box:=StyleBoxFlat.new()
	box.bg_color=Color("101c2b",.96)
	box.border_color=Color("537387")
	box.set_border_width_all(1)
	box.set_corner_radius_all(3)
	return box
