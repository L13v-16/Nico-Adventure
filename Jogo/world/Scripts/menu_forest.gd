extends Control
## Decorative village. Actual game sprites, independent paths, no gameplay code.
const BACKGROUND=preload("res://world/Arte/MenuV93/clearing.png")
const Art=preload("res://world/Scripts/magic_art.gd")
const Actions=preload("res://world/Scripts/menu_actions.gd")
const CHERRY=preload("res://Sunny-land-files/assets/Misc/Sunnyland items/cherry.png")
const DISTANCE_SCALE:=.65
const BOUNDS:=Rect2(285,270,330,40)
const SPEED:={"nico":12.0,"arara":17.0,"turtle":4.5,"oliver":8.0,"jose":10.0,"urso":7.0,"remi":15.0,"mico":16.0}
const REST:={
	"nico":["wave","think","clap","rest"],"arara":["groom","wave","peck","stretch"],
	"turtle":["snack","nod","wave","rest"],"oliver":["wave","inspect","chuckle","shrug"],
	"jose":["wave","nod","laugh","hoof"],"urso":["wave","clap","stretch","doze"],
	"remi":["throw","catch","tail","wave"],"mico":["catch","clap","throw","wave"]
}
var clock:=0.0
var active:=true
var actors:Dictionary={}
var lives:Dictionary={}
var _world:Node2D
var _foreground:Control
var _rng:=RandomNumberGenerator.new()
var _social_cooldown:=3.0
var encounter:Dictionary={}
var encounters_started:=0
static var _last_order:Array=[]
var arrangement:Array=[]

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
	var actor:=Node2D.new();actor.name=id;_world.add_child(actor)
	var sprite:=Art.actor(frames,width*DISTANCE_SCALE);actor.add_child(sprite);Actions.install(sprite,id);actors[id]=actor

func _randomize_layout() -> void:
	arrangement=actors.keys()
	for i in range(arrangement.size()-1,0,-1):
		var j:=_rng.randi_range(0,i);var old:String=arrangement[i];arrangement[i]=arrangement[j];arrangement[j]=old
	if arrangement==_last_order:arrangement.append(arrangement.pop_front())
	_last_order=arrangement.duplicate();lives.clear();encounter.clear();_social_cooldown=3
	for i in arrangement.size():
		var id:String=arrangement[i]
		var at:=Vector2(294+i*43,_rng.randf_range(275,305))
		lives[id]={"at":at,"target":at,"timer":_rng.randf_range(.3,2.5),"state":"rest","action":"ambient_"+str(REST[id][_rng.randi_range(0,3)]),"age":0.0,"left":bool(i%2),"height":0.0}
		_render_actor(id)
	_update_scale();queue_redraw()

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

func _update_scale() -> void:
	_world.scale=size/Vector2(640,360)

func _process(delta:float) -> void:
	if not active:return
	var step:=minf(delta,.05);clock+=step;_social_cooldown-=step
	_update_scale()
	for id:String in lives:
		var life:Dictionary=lives[id]
		life.age+=step;life.timer-=step
		if life.state=="social":continue
		if life.state=="walk":
			var before:Vector2=life.at
			var desired:Vector2=life.target
			var avoidance:=Vector2.ZERO
			for other:String in lives:
				if other==id:continue
				var offset:Vector2=life.at-lives[other].at
				if offset.length()<17 and offset.length()>0.01:avoidance+=offset.normalized()*(17-offset.length())*.55
			life.at=BOUNDS.get_center()+(before.move_toward(desired+avoidance,SPEED[id]*step)-BOUNDS.get_center()).clamp(-BOUNDS.size*.5,BOUNDS.size*.5)
			if absf(life.at.x-before.x)>.005:life.left=life.at.x<before.x
			if id=="arara":life.height=move_toward(life.height,12+sin(life.age*2)*3,step*14)
			if life.at.distance_to(desired)<3 or life.timer<=0:_rest(id)
		elif life.timer<=0:_choose(id)
		if life.state!="walk":life.height=move_toward(life.height,0,step*14)
	_update_encounter(step)
	if encounter.is_empty() and _social_cooldown<=0:_find_company()
	for id:String in lives:_render_actor(id)
	queue_redraw();_foreground.queue_redraw()

func _choose(id:String) -> void:
	var life:Dictionary=lives[id]
	if _rng.randf()<.25:_rest(id);return
	life.state="walk";life.age=0;life.timer=_rng.randf_range(7,15)
	var destination:=Vector2(_rng.randf_range(BOUNDS.position.x,BOUNDS.end.x),_rng.randf_range(BOUNDS.position.y,BOUNDS.end.y))
	if id=="turtle":destination=life.at+(destination-life.at).limit_length(30)
	life.target=destination
	life.action="fly" if id=="arara" else ("run" if id=="nico" else "walk")

func _rest(id:String) -> void:
	var life:Dictionary=lives[id]
	life.state="rest";life.age=0;life.timer=_rng.randf_range(2,5)
	life.action="ambient_"+str(REST[id][_rng.randi_range(0,REST[id].size()-1)])

func _find_company() -> void:
	var pairs:Array=[]
	for i in arrangement.size():
		for j in range(i+1,arrangement.size()):
			var a:String=arrangement[i];var b:String=arrangement[j]
			var distance:float=lives[a].at.distance_to(lives[b].at)
			if distance>=18 and distance<49 and absf(lives[a].at.y-lives[b].at.y)<13 and lives[a].height<1 and lives[b].height<1:pairs.append([a,b])
	if pairs.is_empty():_social_cooldown=1;return
	var pair:Array=pairs[_rng.randi_range(0,pairs.size()-1)]
	var a:String=pair[0];var b:String=pair[1]
	var kind:="conversation"
	if a in ["remi","mico"] or b in ["remi","mico"]:kind="cherry"
	elif a=="arara" or b=="arara":kind="greeting"
	elif a=="turtle" or b=="turtle":kind="picnic"
	encounter={"a":a,"b":b,"kind":kind,"age":0.0,"duration":_rng.randf_range(4,6)}
	encounters_started+=1
	for id:String in pair:
		lives[id].state="social";lives[id].age=0;lives[id].height=0
	lives[a].left=lives[a].at.x>lives[b].at.x;lives[b].left=not lives[a].left

func _update_encounter(delta:float) -> void:
	if encounter.is_empty():return
	encounter.age+=delta
	var a:String=encounter.a;var b:String=encounter.b
	lives[a].action="ambient_wave" if encounter.age<1.2 else "ambient_"+str(REST[a][1])
	lives[b].action="ambient_wave" if encounter.age<1.2 else "ambient_"+str(REST[b][2])
	if encounter.kind=="cherry":
		if a in ["remi","mico"]:lives[a].action="ambient_throw"
		if b in ["remi","mico"]:lives[b].action="ambient_catch"
	elif encounter.kind=="picnic":
		if a=="turtle":lives[a].action="ambient_snack"
		if b=="turtle":lives[b].action="ambient_snack"
	if encounter.age>=encounter.duration:
		_rest(a);_rest(b);encounter.clear();_social_cooldown=_rng.randf_range(2,5)

func _render_actor(id:String) -> void:
	var life:Dictionary=lives[id];var actor:Node2D=actors[id]
	actor.position=(life.at-Vector2(0,life.height)).round()
	var sprite:=actor.get_child(0) as AnimatedSprite2D
	sprite.flip_h=life.left
	Actions.display(sprite,StringName(life.action),life.age)

func _draw() -> void:
	draw_texture_rect(BACKGROUND,Rect2(Vector2.ZERO,size),false)
	for x in range(0,280,4):
		var opacity:=.66*(1-smoothstep(30,280,x))
		draw_rect(Rect2(x*size.x/640,0,4*size.x/640,size.y),Color(.014,.035,.043,opacity))
	if not active:draw_rect(Rect2(Vector2.ZERO,size),Color(0,.02,.02,.34))
	if _world==null:return
	draw_set_transform(Vector2.ZERO,0,size/Vector2(640,360))
	for id:String in lives:
		var at:Vector2=lives[id].at
		draw_line(at+Vector2(-4,1),at+Vector2(4,1),Color(0,.03,.02,.22),1)
	draw_set_transform(Vector2.ZERO)

func _draw_details() -> void:
	_foreground.draw_set_transform(Vector2.ZERO,0,size/Vector2(640,360))
	if not encounter.is_empty():
		var a:Vector2=actors[encounter.a].position+Vector2(0,-8)
		var b:Vector2=actors[encounter.b].position+Vector2(0,-8)
		if encounter.kind in ["cherry","picnic"] and encounter.age>=1.2 and encounter.age<2.4:
			var t:float=(encounter.age-1.2)/1.2
			var at:=a.lerp(b,t)+Vector2(0,-sin(t*PI)*9)
			_foreground.draw_texture_rect_region(CHERRY,Rect2(at-Vector2(1.5,1.5),Vector2(3,3)),Rect2(0,0,21,21))
		elif encounter.age>1.5 and encounter.age<4:_speech((a+b)*.5+Vector2(-4,-12))
	for i in 4:
		var point:=Vector2(282+fposmod(i*43+clock*(2+i%3),344),235+sin(clock*.6+i*2)*18)
		_foreground.draw_rect(Rect2(point,Vector2.ONE),Color(1,.9,.48,.3+.2*sin(clock*1.4+i)))
	_foreground.draw_set_transform(Vector2.ZERO)

func _speech(at:Vector2) -> void:
	_foreground.draw_rect(Rect2(at.round(),Vector2(10,5)),Color("e5e7ba"))
	_foreground.draw_rect(Rect2(at.round()+Vector2(2,4),Vector2(1,2)),Color("e5e7ba"))
	for i in 3:_foreground.draw_rect(Rect2(at.round()+Vector2(2+i*3,2),Vector2.ONE),Color("335444"))
