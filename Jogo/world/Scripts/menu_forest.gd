extends Control
## A distant living forest. Decorative actors never run player/NPC gameplay code.
const BACKGROUND=preload("res://world/Arte/MenuV91/village.png")
const Art=preload("res://world/Scripts/magic_art.gd")
const Actions=preload("res://world/Scripts/menu_actions.gd")
const CHERRY=preload("res://Sunny-land-files/assets/Misc/Sunnyland items/cherry.png")
var clock:=0.0
var active:=true
var actors:Dictionary={}
var _world:Node2D
var _foreground:Control
const DISTANCE_SCALE:=.65
const GROUPS:={"nico":0,"arara":0,"turtle":1,"oliver":1,"jose":2,"urso":2,"remi":3,"mico":3}
const CENTERS:=[Vector2(325,279),Vector2(405,279),Vector2(495,279),Vector2(585,279)]
const SLOTS:=[Vector2(320,265),Vector2(410,284),Vector2(504,256),Vector2(592,288)]
static var _last_arrangement:Array=[]
var arrangement:Array=[]
var _places:Array[Vector2]=[]
var _rng:=RandomNumberGenerator.new()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	_rng.randomize()
	_world=Node2D.new();_world.y_sort_enabled=true;add_child(_world)
	var nico:=SpriteFrames.new();nico.remove_animation("default")
	for data in [["idle",4,4],["run",6,9]]:
		nico.add_animation(data[0]);nico.set_animation_speed(data[0],data[2])
		for frame in range(1,data[1]+1):nico.add_frame(data[0],load("res://world/Arte/Nico/%s_%d.png"%[data[0],frame]))
	_add_actor("nico",nico,22)
	for data in [["arara",30],["turtle",24],["oliver",23],["jose",27],["urso",34],["remi",25],["mico",24]]:
		var path:String="Underworld/jose" if data[0]=="jose" else "Friends/V47/"+data[0]
		_add_actor(data[0],load("res://world/Arte/"+path+".tres"),data[1])
	_foreground=Control.new();_foreground.mouse_filter=Control.MOUSE_FILTER_IGNORE;_foreground.draw.connect(_draw_details);add_child(_foreground)
	_randomize_layout()

func _add_actor(id:String,frames:SpriteFrames,width:float) -> void:
	var root:=Node2D.new();root.name=id;_world.add_child(root)
	var sprite:=Art.actor(frames,width*DISTANCE_SCALE);root.add_child(sprite);Actions.install(sprite,id);actors[id]=root

func _randomize_layout() -> void:
	arrangement=[0,1,2,3]
	for i in range(3,0,-1):
		var other:=_rng.randi_range(0,i);var old:int=arrangement[i];arrangement[i]=arrangement[other];arrangement[other]=old
	if arrangement==_last_arrangement:arrangement.append(arrangement.pop_front())
	_last_arrangement=arrangement.duplicate();_places.clear()
	for index:int in arrangement:_places.append(SLOTS[index]+Vector2(_rng.randi_range(-3,3),_rng.randi_range(-2,2)))
	clock=_rng.randf_range(0,32);_update_cast()

func _map_point(id:String,point:Vector2) -> Vector2:
	var group:int=GROUPS[id]
	return _places[group]+(point-CENTERS[group])*.72

func set_active(value:bool) -> void:
	var reopening:=value and not active
	active=value
	if reopening:_randomize_layout()
	_world.modulate=Color.WHITE if value else Color(.55,.6,.55)
	for actor:Node2D in actors.values():
		var sprite:=actor.get_child(0) as AnimatedSprite2D
		if not value:sprite.pause()
		else:sprite.play()
	queue_redraw();_foreground.queue_redraw()

func _process(delta:float) -> void:
	if not active:return
	clock+=delta;_update_cast();queue_redraw();_foreground.queue_redraw()

func _pose(id:String,x:float,y:float,animation:StringName,face_left:bool=false,beat:float=-1.0) -> void:
	var actor:Node2D=actors[id];actor.position=_map_point(id,Vector2(x,y)).round()
	var sprite:=actor.get_child(0) as AnimatedSprite2D
	sprite.flip_h=face_left;Actions.display(sprite,animation,clock if beat<0 else beat)

func _update_cast() -> void:
	_world.scale=size/Vector2(640,360)
	var t:=fposmod(clock,32)
	var nico_x:=lerpf(283,329,clampf(t/7,0,1)) if t<14 else lerpf(329,283,clampf((t-14)/7,0,1))
	var nico_action:StringName=&"run" if t<7 or (t>=14 and t<21) else &"idle"
	if t>=7 and t<8:nico_action=&"ambient_wave"
	elif t>=8 and t<10:nico_action=&"ambient_think"
	elif t>=10 and t<13:nico_action=&"ambient_clap"
	elif t>=24:nico_action=&"ambient_rest"
	_pose("nico",nico_x,279,nico_action,t>=14)
	if t<7:_pose("arara",lerpf(330,365,t/7),250-sin(t*.9)*7,"fly",true)
	elif t<8:_pose("arara",365,lerpf(250,279,smoothstep(7,8,t)),"fly",true)
	elif t<14:_pose("arara",365,279,"ambient_groom" if t<11 else "ambient_wave",true)
	elif t<23:_pose("arara",lerpf(365,327,(t-14)/9),255-sin((t-14)/9*PI)*21,"fly",true)
	elif t<24:_pose("arara",327,lerpf(255,279,smoothstep(23,24,t)),"fly")
	else:_pose("arara",327,279,"ambient_peck" if t<28 else "ambient_stretch")
	var visit:=fposmod(clock+5,36)
	var turtle_x:=lerpf(383,401,clampf(visit/10,0,1)) if visit<19 else lerpf(401,383,clampf((visit-19)/10,0,1))
	var turtle_action:StringName=&"walk" if visit<10 or (visit>=19 and visit<29) else &"idle"
	if visit>=10 and visit<14:turtle_action=&"ambient_snack"
	elif visit>=14 and visit<17:turtle_action=&"ambient_nod"
	elif visit>=17 and visit<19:turtle_action=&"ambient_wave"
	elif visit>=29:turtle_action=&"ambient_rest"
	_pose("turtle",turtle_x,278,turtle_action,visit>=19)
	var oliver_action:StringName=&"idle"
	if visit>=9 and visit<10:oliver_action=&"ambient_wave"
	elif visit>=10 and visit<13:oliver_action=&"ambient_inspect"
	elif visit>=13 and visit<16:oliver_action=&"ambient_chuckle"
	elif visit>=16 and visit<19:oliver_action=&"ambient_shrug"
	_pose("oliver",428,280,oliver_action,true)
	var stroll:=fposmod(clock+2,28)
	var meet:=smoothstep(0,6,stroll)*(1-smoothstep(17,23,stroll))
	var jose_action:StringName=&"walk"
	var urso_action:StringName=&"walk"
	if stroll>=6 and stroll<17:
		jose_action=&"ambient_wave" if stroll<8 else (&"ambient_nod" if stroll<11 else (&"ambient_laugh" if stroll<14 else &"ambient_hoof"))
		urso_action=&"ambient_wave" if stroll<8 else (&"ambient_clap" if stroll<11 else &"ambient_stretch")
	elif stroll>=23:jose_action=&"idle";urso_action=&"ambient_doze"
	_pose("jose",lerpf(461,483,meet),280,jose_action,stroll>=17)
	_pose("urso",lerpf(530,513,meet),279,urso_action,stroll<17)
	var play:=fposmod(clock,22)
	var chase:=smoothstep(0,6,play)*(1-smoothstep(12,18,play))
	var remi_action:StringName=&"walk"
	var mico_action:StringName=&"walk"
	var action_beat:=0.0
	if play>=6 and play<12:
		action_beat=play-6
		remi_action=&"ambient_throw" if play<8 else (&"ambient_tail" if play<10 else &"ambient_wave")
		mico_action=&"ambient_catch" if play<8 else (&"ambient_clap" if play<10 else &"ambient_wave")
	elif play>=18:
		action_beat=play-18
		remi_action=&"ambient_catch" if play<20 else &"ambient_tail"
		mico_action=&"ambient_throw" if play<20 else &"ambient_clap"
	var remi_beat:=clock
	var mico_beat:=clock
	if play>=6 and play<8:remi_beat=action_beat;mico_beat=maxf(0,action_beat-.6)
	elif play>=18 and play<20:remi_beat=maxf(0,action_beat-.6);mico_beat=action_beat
	_pose("remi",lerpf(554,583,chase),277,remi_action,play>=12 and play<18,remi_beat)
	_pose("mico",lerpf(587,615,chase),281,mico_action,play>=6,mico_beat)

func _draw() -> void:
	draw_texture_rect(BACKGROUND,Rect2(Vector2.ZERO,size),false)
	# Feathered shade preserves the panorama while keeping every menu label legible.
	for x in range(0,310,4):
		var opacity:=.78*(1-smoothstep(50,310,x))
		draw_rect(Rect2(x*size.x/640,0,4*size.x/640,size.y),Color(.014,.045,.042,opacity))
	if not active:draw_rect(Rect2(Vector2.ZERO,size),Color(0,.02,.02,.34))
	if _world==null:return
	draw_set_transform(Vector2.ZERO,0,size/Vector2(640,360))
	for id:String in actors:
		var actor:Node2D=actors[id]
		var ground:=_places[GROUPS[id]].y
		if id=="arara" and actor.position.y<ground-4:continue
		draw_line(Vector2(actor.position.x-4,ground+1),Vector2(actor.position.x+4,ground+1),Color(0,.03,.02,.18),1)
	draw_set_transform(Vector2.ZERO)

func _draw_details() -> void:
	_foreground.draw_set_transform(Vector2.ZERO,0,size/Vector2(640,360))
	var play:=fposmod(clock,22)
	var reverse:=play>=18
	var toss:=play-18 if reverse else play-6
	# Preparation .0-.6; airborne .6-1.2; reception and hold 1.2-2.0.
	if (play>=6.6 and play<7.2) or (play>=18.6 and play<19.2):
		var u:=clampf((toss-.6)/.6,0,1)
		var sender:Node2D=actors.mico if reverse else actors.remi
		var receiver:Node2D=actors.remi if reverse else actors.mico
		var start:=sender.position+Vector2(-4 if reverse else 4,-7)
		var end:=receiver.position+Vector2(4 if reverse else -4,-7)
		var at:=start.lerp(end,u)+Vector2(0,-sin(u*PI)*8)
		_foreground.draw_texture_rect_region(CHERRY,Rect2(at-Vector2(1.5,1.5),Vector2(3,3)),Rect2(0,0,21,21))
	var talk:=fposmod(clock,32)
	if talk>=8 and talk<13:_speech(_map_point("nico",Vector2(348,245)))
	var visit:=fposmod(clock+5,36)
	if visit>=11 and visit<18:_speech(_map_point("oliver",Vector2(417,249)))
	# A few fireflies drift above the path; none cross the left menu column.
	for i in 4:
		var point:=Vector2(282+fposmod(i*43+clock*(2+i%3),344),228+sin(clock*.6+i*2)*18)
		var alpha:float=.25+.35*(.5+.5*sin(clock*1.4+i))
		_foreground.draw_rect(Rect2(point,Vector2(1,1)),Color(1,.9,.48,alpha))
	_foreground.draw_set_transform(Vector2.ZERO)

func _speech(at:Vector2) -> void:
	_foreground.draw_rect(Rect2(at,Vector2(10,5)),Color("e5e7ba"))
	_foreground.draw_rect(Rect2(at+Vector2(2,4),Vector2(1,2)),Color("e5e7ba"))
	for i in 3:_foreground.draw_rect(Rect2(at+Vector2(2+i*3,2),Vector2(1,1)),Color("335444"))
