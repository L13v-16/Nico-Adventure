extends Node2D
const Art=preload("res://world/Scripts/magic_art.gd")
const Actions=preload("res://world/Scripts/menu_actions.gd")
var boss:Node2D
var level:Node2D
var crew:Array[Node2D]=[]
var state:="wait"
var timer:=2.5
var clock:=0.0
var barrel_timer:=0.0
var openings:=0
var _aim:=Vector2.ZERO
const STEPS:=[Vector3(-310,-52,138),Vector3(-224,-104,138),Vector3(-138,-156,138),Vector3(-52,-208,138),Vector3(-80,-240,148)]
func _ready() -> void:
	level=boss.level
	for info in STEPS:
		var step:=preload("res://world/Scripts/Corp2D/terrain.gd").new();step.position=boss.position+Vector2(info.x,info.y);step.width=info.z;step.depth=28;step.platform=true;step.z_index=2;level.add_child(step);boss.steps.append(step)
	var supports:=Node2D.new();supports.name="AssaultSupports";supports.position=boss.position;supports.z_index=0;level.add_child(supports);supports.draw.connect(_draw_supports.bind(supports))
	for i in 5:
		var id:String=["arara","turtle","remi","jose","urso"][i]
		var frames:SpriteFrames=load("res://world/Arte/"+("Underworld/jose.tres" if id=="jose" else "Friends/V47/"+id+".tres"))
		var root:=Node2D.new();root.z_index=4;root.position=Vector2.ZERO;add_child(root)
		var sprite:=Art.actor(frames,[53,38,38,43,57][i]);root.add_child(sprite);Actions.install(sprite,id);crew.append(root)
func tick(delta:float) -> void:
	clock+=delta;timer-=delta
	for i in crew.size():
		var root:=crew[i];var sprite:=root.get_child(0) as AnimatedSprite2D
		root.position=[Vector2(126,-224),Vector2(-365,0),Vector2(252,0),Vector2(285,0),Vector2(190,0)][i]
		var action:StringName=&"idle"
		if i==0:root.position.y+=sin(clock*3)*3;action=&"fly" if sprite.sprite_frames.has_animation("fly") else &"idle"
		if state=="warning" and i==3:action=&"windup"
		if state in ["assist","open"]:
			if i==0:root.position.x-=smoothstep(0,1,1.1-timer)*28 if state=="assist" else 28
			if i==2:root.position.y-=absf(sin(clock*2))*22;action=&"ambient_throw"
			if i==3:root.position.x=190-absf(sin(clock*4))*50;action=&"charge"
			if i==4:action=&"ambient_clap"
			if i==1:action=&"ambient_nod"
		if not sprite.sprite_frames.has_animation(action):action=&"idle"
		sprite.flip_h=i in [0,2,3,4];Actions.display(sprite,action,clock)
	if state=="open":
		barrel_timer-=delta
		if barrel_timer<=0 and timer>2.5:_barrel();barrel_timer=2.1
		if boss._window_hit:
			boss.vulnerable=0;state="wait";timer=3.5;level.clear_shots();level.tell("Acerto! Os amigos estão se preparando para o próximo golpe.")
	if timer<=0:
		match state:
			"wait":
				state="warning";timer=1.35;_aim=level.player.position;boss._pose(1);Sfx.play("lab_scan",-10);level.tell("Lázaro prepara o golpe! Desvie da marca vermelha.")
			"warning":
				state="assist";timer=1.1;boss._pose(2);Sfx.play("warden_slam",-9);level.player._add_shake(3)
				for side in [-1,1]:level.shoot(boss.position+Vector2(side*110,-5),Vector2(side*155,0),true)
				level.shoot(_aim+Vector2(0,-160),Vector2(0,155),false,false)
				level.tell("Minas distrai os sensores! Remi corta os cabos; José e Urso seguram a trava!")
			"assist":
				state="open";timer=18;barrel_timer=1.4;openings+=1;boss.open_window(18);Sfx.play("lab_door",-9)
				level.tell("VISOR ABERTO · suba! Salte os tambores; J quebra e GELO congela.")
			"open":state="wait";timer=3.5;boss.vulnerable=0;level.clear_shots();level.tell("O visor fechou. Os amigos vão abrir outra oportunidade!")
	queue_redraw()
func _barrel() -> void:
	var barrel:=preload("res://world/Scripts/Corp2D/assault_barrel.gd").new();barrel.level=level
	var points:=PackedVector2Array([Vector2(68,-251),Vector2(-80,-251),Vector2(-80,-219),Vector2(-52,-219),Vector2(-52,-167),Vector2(-138,-167),Vector2(-138,-115),Vector2(-224,-115),Vector2(-224,-63),Vector2(-310,-63),Vector2(-310,-11),Vector2(-390,-11)])
	for i in points.size():points[i]+=boss.position
	barrel.path=points;level.add_child(barrel);Sfx.play("lab_clink",-19)
func reset() -> void:
	state="wait";timer=3.0;barrel_timer=0;boss.vulnerable=0;queue_redraw()
func _draw() -> void:
	# Sliding opaque shutter covers the pilot until the friends lift the lock.
	var open:=state=="open"
	if not open:draw_style_box(_shutter(),Rect2(-67,-273,62,42))
	else:draw_arc(Vector2(-40,-254),34,PI,TAU,16,Color("a9ffd3"),3)
	if state in ["assist","open"] and fposmod(clock,1)<.3:
		draw_line(Vector2(106,-222),Vector2(-35,-245),Color("9ff4ff"),2)
		draw_line(Vector2(246,-25),Vector2(114,-80),Color("ffd087"),2)
	if state=="warning":
		draw_line(_aim-boss.position+Vector2(-24,0),_aim-boss.position+Vector2(24,0),Color("ff8c77"),4)
	for i in boss.steps.size():
		var step:Node2D=boss.steps[i]
		var p:=step.position-boss.position
		draw_line(p+Vector2(7,31),p+Vector2(step.width-7,31),Color("d2b16e"),2)
static func _shutter() -> StyleBoxFlat:
	var style:=StyleBoxFlat.new();style.bg_color=Color("243943");style.border_color=Color("7ea9ad");style.set_border_width_all(2);return style

func _draw_supports(canvas:Node2D) -> void:
	var texture:Texture2D=preload("res://world/Scripts/Corp2D/polish_art.gd").cell(3)
	for i in 3:
		var info:Vector3=STEPS[i]
		var y:=info.y+28
		while y<0:
			var h:=minf(14,-y)
			canvas.draw_texture_rect(texture,Rect2(info.x+info.z-17,y,10,h),false,Color("6d7789"));y+=h
		canvas.draw_texture_rect(texture,Rect2(info.x+info.z-22,-5,20,5),false)
