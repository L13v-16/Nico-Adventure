extends Control
## A distant living forest. Decorative actors never run player/NPC gameplay code.
const BACKGROUND=preload("res://world/Arte/MenuV88/forest.png")
const Art=preload("res://world/Scripts/magic_art.gd")
const CHERRY=preload("res://Sunny-land-files/assets/Misc/Sunnyland items/cherry.png")
var clock:=0.0
var active:=true
var actors:Dictionary={}
var _world:Node2D
var _foreground:Control

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
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
	_update_cast()

func _add_actor(id:String,frames:SpriteFrames,width:float) -> void:
	var root:=Node2D.new();root.name=id;_world.add_child(root)
	root.add_child(Art.actor(frames,width));actors[id]=root

func set_active(value:bool) -> void:
	active=value
	_world.modulate=Color.WHITE if value else Color(.55,.6,.55)
	for actor:Node2D in actors.values():
		var sprite:=actor.get_child(0) as AnimatedSprite2D
		if not value:sprite.pause()
		else:sprite.play()
	queue_redraw();_foreground.queue_redraw()

func _process(delta:float) -> void:
	if not active:return
	clock+=delta;_update_cast();queue_redraw();_foreground.queue_redraw()

func _pose(id:String,x:float,y:float,animation:StringName,face_left:bool=false) -> void:
	var actor:Node2D=actors[id];actor.position=Vector2(roundf(x),roundf(y))
	var sprite:=actor.get_child(0) as AnimatedSprite2D
	sprite.flip_h=face_left;sprite.play(animation)

func _update_cast() -> void:
	_world.scale=size/Vector2(640,360)
	# Nico walks out to Minas, chats, then strolls back. Minas circles overhead.
	var t:=fposmod(clock,32)
	var nico_x:=lerpf(283,329,clampf(t/7,0,1)) if t<14 else lerpf(329,283,clampf((t-14)/7,0,1))
	_pose("nico",nico_x,279,"run" if t<7 or (t>=14 and t<21) else "idle",t>=14)
	if t<7:_pose("arara",lerpf(330,365,t/7),250-sin(t*.9)*7,"fly",true)
	elif t<14:_pose("arara",365,lerpf(250,279,smoothstep(7,8,t)),"fly" if t<8 else "talk",true)
	elif t<23:_pose("arara",lerpf(365,327,(t-14)/9),255-sin((t-14)/9*PI)*21,"fly",true)
	else:_pose("arara",327,lerpf(255,279,smoothstep(23,24,t)),"fly" if t<24 else "idle")
	# Oliver and the elderly turtle greet each other at the edge of the path.
	var visit:=fposmod(clock+5,36)
	var turtle_x:=lerpf(383,401,clampf(visit/10,0,1)) if visit<19 else lerpf(401,383,clampf((visit-19)/10,0,1))
	_pose("turtle",turtle_x,278,"walk" if visit<10 or (visit>=19 and visit<29) else "talk",visit>=19)
	_pose("oliver",428,280,"talk" if visit>=10 and visit<19 else "idle",true)
	# José and Urso walk toward each other, celebrate and part again.
	var stroll:=fposmod(clock+2,28)
	var meet:=smoothstep(0,6,stroll)*(1-smoothstep(17,23,stroll))
	var walking:=stroll<6 or (stroll>=17 and stroll<23)
	_pose("jose",lerpf(461,483,meet),280,"walk" if walking else "happy",stroll>=17)
	_pose("urso",lerpf(530,513,meet),279,"walk" if walking else "talk",stroll<17)
	# Remi and Mico chase along the trail, stopping to toss a cherry between them.
	var play:=fposmod(clock,22)
	var chase:=smoothstep(0,6,play)*(1-smoothstep(12,18,play))
	var running:=play<6 or (play>=12 and play<18)
	_pose("remi",lerpf(554,583,chase),277,"walk" if running else "happy",play>=12)
	_pose("mico",lerpf(587,615,chase),281,"walk" if running else "happy",play<12)
	if play>=18 and play<19:
		actors.mico.position.y-=sin((play-18)*PI)*8
		_pose("mico",actors.mico.position.x,actors.mico.position.y,"jump" if play<18.5 else "fall",true)

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
		var ground:=279.0
		if id=="arara" and actor.position.y<274:continue
		draw_line(Vector2(actor.position.x-7,ground+1),Vector2(actor.position.x+7,ground+1),Color(0,.03,.02,.25),2)
	draw_set_transform(Vector2.ZERO)

func _draw_details() -> void:
	_foreground.draw_set_transform(Vector2.ZERO,0,size/Vector2(640,360))
	var play:=fposmod(clock,22)
	var toss:=play-6 if play<10 else play-18
	if (play>=6 and play<10) or (play>=18 and play<22):
		var u:=clampf(toss/2.4,0,1)
		if u>0 and u<1:
			var at:Vector2=actors.remi.position.lerp(actors.mico.position,u)+Vector2(0,-14-sin(u*PI)*19)
			_foreground.draw_texture_rect_region(CHERRY,Rect2(at-Vector2(3,3),Vector2(6,6)),Rect2(0,0,21,21))
	var talk:=fposmod(clock,32)
	if talk>=8 and talk<13:_speech(Vector2(348,245))
	var visit:=fposmod(clock+5,36)
	if visit>=11 and visit<18:_speech(Vector2(417,249))
	# A few fireflies drift above the path; none cross the left menu column.
	for i in 10:
		var point:=Vector2(282+fposmod(i*43+clock*(2+i%3),344),228+sin(clock*.6+i*2)*18)
		var alpha:float=.25+.35*(.5+.5*sin(clock*1.4+i))
		_foreground.draw_rect(Rect2(point,Vector2(1,1)),Color(1,.9,.48,alpha))
	_foreground.draw_set_transform(Vector2.ZERO)

func _speech(at:Vector2) -> void:
	_foreground.draw_rect(Rect2(at,Vector2(14,7)),Color("e5e7ba"))
	_foreground.draw_rect(Rect2(at+Vector2(2,6),Vector2(2,3)),Color("e5e7ba"))
	for i in 3:_foreground.draw_rect(Rect2(at+Vector2(3+i*4,3),Vector2(1,1)),Color("335444"))
