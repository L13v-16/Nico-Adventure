extends Node2D
## Screen-space entrance; all character and door textures are existing game art.
const Art=preload("res://world/Scripts/lab_art.gd")
const Chains=preload("res://world/Scripts/underworld_chain_art.gd")
const GUARDIAN=preload("res://world/Arte/Underworld/V59/guardian.tres")
const FEET=preload("res://world/Arte/Underworld/V59/guardian_feet.tres")
const FLOOR:=247.0
const IMPACT:=5.65
const DURATION:=13.3
var player_frames:SpriteFrames
var clock:=0.0
var beat:="arrival"
var broken:=false
var mount:Node2D
var monster:AnimatedSprite2D
var nico:AnimatedSprite2D
var jose:AnimatedSprite2D
var nico_rig:Node2D
var jose_rig:Node2D
var door:Sprite2D
var panels:Array[Node2D]=[]
var _front:Node2D
var _seats:Dictionary={}
var _cues:Dictionary={}
func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	var shore:=Sprite2D.new();shore.texture=preload("res://world/Arte/Beach/beach_background.png");shore.centered=false
	shore.scale=Vector2(640.0/shore.texture.get_width(),250.0/shore.texture.get_height());shore.modulate=Color("9aafbc");shore.z_index=-20;add_child(shore)
	var building:=Node2D.new();building.z_index=-5;building.draw.connect(_draw_building);add_child(building)
	for x in [431,617]:
		var column:=Art.prop("column",46);column.position+=Vector2(x,FLOOR);column.scale.y*=2.1;column.position.y=FLOOR-431*column.scale.y
		add_child(column)
	for x in range(0,640,80):
		var floor_art:=Art.prop("floor_00",82,true);floor_art.position+=Vector2(x+40,FLOOR);floor_art.z_index=3;add_child(floor_art)
	door=Art.prop("door",196);door.position+=Vector2(524,FLOOR);door.z_index=-1;add_child(door)
	for i in 2:
		var rig:=Node2D.new();rig.z_index=6;rig.hide();add_child(rig);panels.append(rig)
		var leaf:=Sprite2D.new();leaf.texture=_crop(Art.texture("door"),Rect2(85+i*80,55,80,151))
		leaf.scale=Vector2.ONE*(196.0/346);leaf.material=Art.Art.material();rig.add_child(leaf)
	mount=Node2D.new();add_child(mount)
	monster=AnimatedSprite2D.new();monster.centered=false;monster.sprite_frames=GUARDIAN
	monster.material=Art.Art.material();monster.material.set_shader_parameter("alpha_cutoff",.94)
	monster.scale=Vector2.ONE*(208.0/GUARDIAN.get_frame_texture(&"idle",0).get_width());monster.flip_h=true;mount.add_child(monster)
	nico_rig=Node2D.new();nico_rig.z_index=4;add_child(nico_rig)
	nico=Art.Art.actor(player_frames,42);nico_rig.add_child(nico)
	jose_rig=Node2D.new();jose_rig.z_index=4;add_child(jose_rig)
	jose=Art.Art.actor(preload("res://world/Arte/Underworld/jose.tres"),43);jose_rig.add_child(jose)
	_front=Node2D.new();_front.z_index=8;_front.draw.connect(_draw_effects);add_child(_front)
	update_scene(0)
func _crop(base:AtlasTexture,region:Rect2) -> AtlasTexture:
	var texture:=AtlasTexture.new();texture.atlas=base.atlas;texture.region=Rect2(base.region.position+region.position,region.size);texture.filter_clip=true;return texture
func _pose(actor:AnimatedSprite2D,animation:StringName,time:float) -> void:
	# Deterministic frame selection also keeps jumps and paused beat previews exact.
	actor.animation=animation
	var count:=actor.sprite_frames.get_frame_count(animation)
	var frame:=maxi(0,int(time*actor.sprite_frames.get_animation_speed(animation)))
	actor.frame=frame%count if actor.sprite_frames.get_animation_loop(animation) else mini(frame,count-1)
	actor.pause()
	if actor!=monster:Art.Art.reanchor(actor)
func _anchor_monster() -> void:
	var texture:=monster.sprite_frames.get_frame_texture(monster.animation,monster.frame)
	var foot:float=FEET.get_meta("feet").get(texture.resource_path,texture.get_meta("ground_foot",texture.get_height()))
	monster.position=Vector2(-texture.get_width()*.5*monster.scale.x,-foot*monster.scale.y)
func _seat(x:float) -> Vector2:
	var texture:=monster.sprite_frames.get_frame_texture(monster.animation,monster.frame)
	var key:=texture.resource_path+str(x)
	if not _seats.has(key):
		var pixels:=texture.get_image();var margin:Vector2=texture.margin.position if texture is AtlasTexture else Vector2.ZERO
		var u:float=(x-monster.position.x)/monster.scale.x
		if monster.flip_h:u=texture.get_width()-1-u
		var column:=clampi(int(u-margin.x),0,pixels.get_width()-1);var height:=-80.0
		for y in pixels.get_height():
			if pixels.get_pixel(column,y).a>=.94:height=monster.position.y+(y+margin.y)*monster.scale.y;break
		_seats[key]=height
	return Vector2(x,float(_seats[key]))
func update_scene(time:float) -> void:
	clock=clampf(time,0,DURATION);broken=clock>=IMPACT
	beat="arrival" if clock<1.7 else ("dismount" if clock<3.1 else ("windup" if clock<4.65 else ("charge" if clock<IMPACT else ("impact" if clock<6.35 else ("recover" if clock<8.8 else "enter")))))
	var x:=lerpf(112,225,smoothstep(0,1.7,clock))
	if clock>=3.1:x=lerpf(225,211,smoothstep(3.8,4.65,clock))
	if clock>=4.65:x=lerpf(211,388,smoothstep(4.65,5.45,clock))
	if clock>=6.35:x=lerpf(388,342,smoothstep(6.35,7.6,clock))
	mount.position=Vector2(roundf(x),FLOOR)
	var pose:StringName=&"walk" if clock<1.7 or (clock>=4.65 and clock<5.45) else (&"windup" if clock>=3.8 and clock<4.65 else (&"slam" if clock>=5.45 and clock<6.35 else (&"recover" if clock>=6.35 and clock<7.6 else &"idle")))
	var start:=5.45 if pose==&"slam" else (6.35 if pose==&"recover" else (3.8 if pose==&"windup" else 0.0))
	_pose(monster,pose,(clock-start)*(1.5 if beat=="charge" else 1));_anchor_monster()
	var drop:=smoothstep(1.7,3.1,clock)
	nico_rig.position=(mount.position+_seat(-40)).lerp(Vector2(119,FLOOR),drop)+Vector2(0,-sin(drop*PI)*40)
	jose_rig.position=(mount.position+_seat(0)).lerp(Vector2(177,FLOOR),drop)+Vector2(0,-sin(drop*PI)*32)
	if clock>=8.8:nico_rig.position=Vector2(lerpf(119,570,smoothstep(8.8,11.7,clock)),FLOOR)
	_pose(nico,&"jump" if drop>0 and drop<1 else (&"run" if clock>=8.8 else &"idle"),clock)
	_pose(jose,&"jump" if drop>0 and drop<1 else (&"windup" if clock>=3.1 and clock<4.2 else (&"happy" if clock>=6.35 and clock<8.8 else &"talk")),clock)
	nico.flip_h=false;jose.flip_h=false
	nico_rig.modulate.a=1-smoothstep(10.95,11.55,clock)
	door.texture=Art.texture("door_open" if broken else "door")
	var dt:=maxf(0,clock-IMPACT)
	for i in 2:
		panels[i].visible=broken
		panels[i].position=Vector2(500+i*45,FLOOR-56)+Vector2((-145 if i==0 else 124)*dt,-135*dt+230*dt*dt)
		panels[i].rotation=(-1.8 if i==0 else 2.3)*dt
		panels[i].modulate.a=1-smoothstep(1.2,1.8,dt)
	position=Vector2.ZERO
	if broken and dt<.55 and Save.is_camera_shake_enabled():position=Vector2(roundf(sin(dt*91)*5*(1-dt/.55)),roundf(cos(dt*73)*3*(1-dt/.55)))
	for cue in [[.5,"warden_chain",-16],[3.8,"warden_roar",-12],[4.7,"lab_alarm",-15],[5.45,"warden_slam",-5],[IMPACT,"warden_break",-5],[5.8,"lab_clink",-8],[6.15,"lab_clink",-13],[8.8,"lab_door",-10]]:
		if clock>=cue[0] and not _cues.has(cue[0]):_cues[cue[0]]=true;Sfx.play(cue[1],cue[2])
	_front.queue_redraw()
func dialogue() -> Array[String]:
	if clock<2.2:return ["JOSÉ","Chegamos! A empresa trancou a entrada.","Da fuga do Submundo direto para a porta dos executivos."]
	if clock<3.8:return ["NICO","Então vamos pedir ajuda ao nosso novo amigo.","José segura as correntes. Nico desce para dar espaço."]
	if clock<IMPACT:return ["JOSÉ","Grandão... abre caminho!",""]
	if clock<6.6:return ["SISTEMA DE SEGURANÇA","Acesso nega— ... acesso liberado.","Danos à propriedade serão descontados do orçamento."]
	if clock<9.2:return ["JOSÉ","Entre, Nico! Eu fico com o grandão e seguro a saída.","A passagem está aberta. Urso espera na câmara de pesquisa."]
	return ["NICO","Urso, aguenta firme. Estou chegando!","José e o guardião ficam protegendo a entrada."]
func _draw_building() -> void:
	_front_building_rect(Rect2(413,29,227,218),Color("192635"))
	_front_building_rect(Rect2(422,39,218,208),Color("69737a"))
	for y in range(45,230,42):
		_front_building_rect(Rect2(425,y,215,3),Color("46545e"))
	for x in [448,596]:_front_building_rect(Rect2(x,40,2,201),Color("82918f"))
	_front_building_rect(Rect2(410,29,230,13),Color("263946"))
	_front_building_rect(Rect2(413,40,227,3),Color("bbad65"))
	var font:=ThemeDB.fallback_font
	var node:=get_child(1)
	node.draw_rect(Rect2(450,51,158,61),Color("0d1923"))
	node.draw_rect(Rect2(450,51,158,2),Color("dfb65e"))
	node.draw_rect(Rect2(450,111,158,1),Color("53606a"))
	preload("res://world/Scripts/corporate_brand.gd").mark(node,Rect2(458,62,27,31))
	node.draw_string(font,Vector2(492,69),"CORPORAÇÃO",HORIZONTAL_ALIGNMENT_LEFT,108,10,Color("f5d484"))
	node.draw_string(font,Vector2(492,83),"LABORATÓRIO",HORIZONTAL_ALIGNMENT_LEFT,108,11,Color("f4efdb"))
	node.draw_string(font,Vector2(492,95),"DOS EXECUTIVOS",HORIZONTAL_ALIGNMENT_LEFT,108,8,Color("b4c5ca"))
	node.draw_string(font,Vector2(458,106),"05  /  ENTRADA DE SERVIÇO",HORIZONTAL_ALIGNMENT_LEFT,145,7,Color("9eb0b9"))
func _front_building_rect(rect:Rect2,color:Color) -> void:get_child(1).draw_rect(rect,color)
func _draw_effects() -> void:
	var dt:=clock-IMPACT
	Chains.strand(_front,mount.position+Vector2(3,-68),mount.position+Vector2(61,-79),4,8)
	if clock<3.1:Chains.strand(_front,jose_rig.position+Vector2(9,-19),mount.position+Vector2(61,-79),3,7)
	else:_front.draw_texture_rect(Chains.COIL,Rect2(mount.position+Vector2(-37,-31),Vector2(44,16)),false)
	if dt>=0 and dt<2:
		for i in 19:
			var speed:=35.0+i%6*20;var side:=-1.0 if i%2 else 1.0
			var at:=Vector2(492+side*speed*dt,183-(30+i%5*22)*dt+100*dt*dt)
			var color:=Color("e6c280") if i%3==0 else Color("aeb6b9")
			color.a=1-smoothstep(.7,1.7,dt);_front.draw_rect(Rect2(at.round(),Vector2(2+i%3,2+i%2)),color)
		for i in 10:
			var at:=Vector2(485+(i-4)*dt*23,223-i%3*10-dt*18)
			_front.draw_rect(Rect2(at.round(),Vector2(12+i%4*6,7+i%3*5)),Color("b7bbb4",maxf(0,.5-dt*.3)))
		if dt<.12:_front.draw_rect(Rect2(0,26,640,238),Color(1,.94,.76,(1-dt/.12)*.5))
