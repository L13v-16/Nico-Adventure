extends StaticBody2D
var level:Node2D
var sector:=0
var kind:="lever"
var destination:=-1
var link:=""
var activated:=false
var disabled_left:=0.0
var width:=45.0
var _clock:=0.0
var _timer:=0.0
var _art:Sprite2D
var _collider:CollisionShape2D
const Art=preload("res://world/Scripts/Corp2D/art.gd")
const Polish=preload("res://world/Scripts/Corp2D/polish_art.gd")
func _ready() -> void:
	add_to_group("corp_devices");collision_mask=0;collision_layer=4
	if kind in ["glass","reactor_fire","reactor_ice","press","camera","turret"]:add_to_group("enemies")
	var index:int={"door":4,"lever":6,"conveyor":2,"camera":8,"turret":8,"security":9,"reactor_fire":10,"reactor_ice":11,"glass":12,"press":13,"record":14,"lockdown":9,"secret":14,"office":14,"prototype":14,"plan":14}.get(kind,9)
	if kind in ["camera","turret"]:
		var mount:=Node2D.new();mount.name="WallMount";mount.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(mount)
		mount.draw.connect(func():Polish.wall_mount(mount,width))
	_art=Art.sprite("props",index,width);add_child(_art)
	if kind in ["record","office","prototype","secret","security","lockdown","plan"]:
		_art.material=preload("res://world/Scripts/polish99_art.gd").material()
		_art.texture=preload("res://world/Scripts/polish99_art.gd").cell("presentation",{"record":11,"office":10,"prototype":9,"secret":12,"security":14,"lockdown":13,"plan":12}[kind]);_art.scale=Vector2.ONE*(width/_art.texture.get_width());_art.position=Vector2(-width/2,-_art.texture.get_height()*_art.scale.y)
	if kind=="record" and link=="forest":_art.texture=preload("res://world/Scripts/polish99_art.gd").cell("presentation",8);_art.scale=Vector2.ONE*(width/_art.texture.get_width());_art.position=Vector2(-width/2,-_art.texture.get_height()*_art.scale.y)
	if kind=="conveyor":
		_art.hide()
		var deck:=Node2D.new();deck.name="BeltDeck";deck.position.x=-width/2;deck.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(deck)
		deck.draw.connect(func():Polish.deck(deck,width,24,true,not activated))
	if kind=="press":_art.hide()
	var shape:=RectangleShape2D.new();shape.size=Vector2(width*.75,minf(55,_art.texture.get_height()*_art.scale.y))
	_collider=CollisionShape2D.new();_collider.shape=shape;_collider.position.y=-shape.size.y/2;add_child(_collider)
	if kind=="glass":collision_layer=1|4
	if link=="boss":hide();collision_layer=0
func hint() -> String:
	if link=="boss" and (level._encounter==null or level._encounter.phase!=2):return ""
	match kind:
		"plan":return "E · Rever o plano do circo"
		"door":return "E · "+("Sala dos computadores" if destination==5 else ("Voltar ao centro de controle" if sector==5 else ("Cobertura" if level.lockdown and sector==3 else "Entrar no próximo setor")))
		"lever":return "E · Inverter esteiras e acionar o braço"
		"security":return "E · Desligar vigilância e zerar alerta"
		"record","office","prototype":return "E · Examinar "+("protótipo" if kind=="prototype" else "arquivo")
		"lockdown":return "E · Copiar provas e liberar o elevador da cobertura"
		"secret":return "E · Sala reservada: cartão ou emblema corporativo"
		"reactor_fire":return "K · FOGO no regulador vermelho"
		"reactor_ice":return "K · GELO no regulador azul"
		"glass":return "J · Quebrar vidro"
	return ""
func interact() -> void:
	match kind:
		"plan":level.reveal_plan()
		"door":level.travel(self)
		"lever":
			activated=not activated;_art.texture=Art.cell("props",7 if activated else 6);Sfx.play("lab_clink",-10)
			level.reverse_circuit(link,activated)
		"security":
			activated=true;level.alert=0;level.security_off=maxf(level.security_off,12*level.sabotage_multiplier());level.tell("Vigilância desligada. Portas liberadas.");Sfx.play("lab_clink",-14)
		"record","office","prototype":
			if not activated and Save.collect_fragment("fase_6","record:"+link):activated=true;level.secrets_found+=1
			level.show_record(link,kind)
		"lockdown":
			if not level._plan_seen:level.tell("As provas principais estão na sala dos computadores. Entre pela porta à esquerda deste terminal.")
			elif not level.lockdown:activated=true;level.start_lockdown()
		"secret":
			if level.player.equipment.is_equipped("executive_card") or level.player.equipment.is_equipped("corporate_emblem"):
				if not activated:
					if Save.collect_fragment("fase_6","record:beach"):activated=true;level.secrets_found+=1;level.unlock_secret(self)
				else:level.tell("Arquivo reservado já aberto.")
			else:level.tell("Arquivo opcional. O cartão ou emblema de Oliver abre esta sala.")
func take_element(element:String,_source:Vector2) -> void:
	if kind in ["camera","turret","press"]:
		disabled_left=(7 if element=="ice" else 4)*level.sabotage_multiplier();Sfx.play("lab_clink",-16)
	elif kind.begins_with("reactor_"):
		if link=="boss" and (level._encounter==null or level._encounter.phase!=2):return
		var correct:bool=(kind=="reactor_fire" and element=="fire") or (kind=="reactor_ice" and element=="ice")
		if correct:
			activated=true;level.power_relay(link,element);Fx.burst(position+Vector2(0,-24),Color("ffb06a") if element=="fire" else Color("a7edff"),10,100)
		else:level.tell("Observe o símbolo: chama vermelha ou cristal azul. Q troca o poder.")
	elif kind=="glass" and element=="fire":take_damage(1,_source)
func take_damage(_amount:float,_source:Vector2) -> void:
	if kind!="glass" or activated:return
	activated=true;collision_layer=0;_art.hide();Fx.burst(position+Vector2(0,-25),Color("c6f4ff"),16,140);Sfx.play("lab_clink",-10)
func is_dead() -> bool:return activated if kind=="glass" else false
func _physics_process(delta:float) -> void:
	if level.sector!=sector or level.intro_active or level.completed:return
	if link=="boss":
		var available:bool=level._encounter!=null and level._encounter.phase==2
		visible=available;collision_layer=4 if available else 0
		if not available:return
	_timer-=delta;disabled_left=maxf(0,disabled_left-delta)
	if disabled_left<=0:_clock+=delta
	queue_redraw()
	if kind=="conveyor":get_node("BeltDeck").queue_redraw()
	_art.modulate=Color("9cdfff") if disabled_left>0 else (Color("a7e6c6") if activated else Color.WHITE)
	var offset:Vector2=level.player.position-position
	if disabled_left>0:return
	if kind in ["camera","turret"] and level.security_off<=0:
		var sweep:=Vector2(-sin(_clock*.8)*100,45)
		if offset.length()<180 and absf(offset.x-sweep.x)<65 and offset.y>0 and not level.player.is_dead():
			var query:=PhysicsRayQueryParameters2D.create(position+Vector2(0,-12),level.player.position,1)
			if get_world_2d().direct_space_state.intersect_ray(query).is_empty():
				level.detect(delta*28)
				if kind=="turret" and _timer<=0:
					level.shoot(position+Vector2(0,-16),offset.normalized()*160);_timer=2
	elif kind=="press":
		var beat:=fposmod(_clock,4.5 if not level.lockdown else 3.6)
		if beat>2.8 and beat<3.2 and absf(offset.x)<width*.4 and offset.y>-20 and offset.y<12:level.player.take_damage(1,position)
	elif kind=="conveyor" and absf(offset.x)<width*.5 and absf(offset.y+11)<8 and level.player.is_on_floor():
		level.player.position.x+=(48 if activated else -48)*delta*(.5 if level.player.equipment.is_equipped("magnetic_boots") else 1)
	queue_redraw()
func _draw() -> void:
	if level==null or level.sector!=sector:return
	if kind=="press":
		var beat:=fposmod(_clock,4.5 if not level.lockdown else 3.6)
		var extension:=smoothstep(2.55,2.85,beat)*(1.0-smoothstep(3.2,3.65,beat))
		Polish.press(self,width,extension,Color("9cdfff") if disabled_left>0 else Color.WHITE)
	if kind in ["camera","turret"] and disabled_left<=0 and level.security_off<=0:
		var center:=-sin(_clock*.8)*100
		draw_colored_polygon(PackedVector2Array([Vector2(0,-12),Vector2(center-52,125),Vector2(center+52,125)]),Color(1,.2,.15,.12))
	if kind=="press" and fposmod(_clock,4.5)>2.0 and fposmod(_clock,4.5)<2.8:
		draw_line(Vector2(-width*.4,-2),Vector2(width*.4,-2),Color("ffb66a"),3)
