extends Node3D
const Art=preload("res://world/Scripts/Lab3D/models.gd")
const Layout=preload("res://world/Scripts/Lab3D/layout.gd")
const CODES:={1:"CRIO",4:"ARQ",5:"BIO"}
const COLORS:={1:"91dfea",4:"eac279",5:"9cddb0"}
const SYMBOLS:={1:"❄",4:"ϟ",5:"✿"}
const ORDER:=[2,0,1]
var level:Node3D
var sector:=1
var solved:=false
var collected:=false
var progress:=0
var targets:Array[Node3D]=[]
var cabinet:Node3D
var _card:Node3D
var _label:Label3D
var _cooldown:=0.0
var _clock:=0.0
var _persistent:=true
var _wires:Array[MeshInstance3D]=[]
func _ready() -> void:
	name="RoomAccessPuzzle";_persistent=not Save.is_free_mode()
	collected=_persistent and Save.has_story_flag(_flag("card"))
	solved=collected or (_persistent and Save.has_story_flag(_flag("solved")))
	progress=3 if solved else 0
	_build();_restore_circuit();_refresh()
func _flag(suffix:String) -> String:return "lab_puzzle_%d_%s"%[sector,suffix]
func _device(kind:String) -> Node3D:
	for object in get_tree().get_nodes_in_group("lab3d_devices"):
		if object.sector==sector and object.kind==kind:return object
	return null
func _expansion(kind:String) -> Node3D:
	for object in get_tree().get_nodes_in_group("lab3d_expansion"):
		if object.sector==sector and object.kind==kind:return object
	return null
func _build() -> void:
	var room:Node3D=level.sectors[sector]
	var at:Vector3={1:Vector3(7,0,-10),4:Vector3(-4,0,-23),5:Vector3(0,0,-56)}[sector]
	cabinet=Art.instantiate("card_dispenser");cabinet.position=at;add_child(cabinet)
	var body:=StaticBody3D.new();body.collision_layer=1;cabinet.add_child(body)
	var shape:=BoxShape3D.new();shape.size=Vector3(1.5,1.1,1.15)
	var collision:=CollisionShape3D.new();collision.shape=shape;collision.position.y=.55;body.add_child(collision)
	_card=Art.instantiate("keycard");_card.position=Vector3(0,1.5,.22);_card.scale=Vector3.ONE*.9;cabinet.add_child(_card)
	_card.get_node("Stripe").material_override=Art.material(COLORS[sector],0,.25)
	var badge:=Art.label(_card,CODES[sector],Vector3(0,-.08,.09),16,COLORS[sector]);badge.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	_label=Art.label(cabinet,"",Vector3(0,2.8,.1),25,COLORS[sector]);_label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	if sector in [1,5]:
		var pad_at:=Vector3(5,1.2,-8) if sector==1 else Vector3(-5,2.15,-52)
		Layout.floor_piece(room,pad_at.x,pad_at.z,3.2,3.2,pad_at.y)
		Art.box(room,"PuzzlePillar",Vector3(pad_at.x,pad_at.y*.5,pad_at.z),Vector3(1.1,pad_at.y,1.1),"3b596e",.4)
		_target("plate",pad_at)
		var source_z:float=-12.7 if sector==1 else -48.0
		_wires.append(Art.box(self,"PuzzleConduit",Vector3(pad_at.x,.09,(source_z+pad_at.z)*.5),Vector3(.14,.08,absf(source_z-pad_at.z)),"405e70",.4))
		_wires.append(Art.box(self,"PuzzleConduitRiser",Vector3(pad_at.x+1.4,pad_at.y*.5,pad_at.z),Vector3(.12,pad_at.y,.12),"405e70",.4))
		_sign("GELO NO VAZAMENTO → PULE NO BOTÃO" if sector==1 else "RELÉ ESTÁVEL → GELO NO ROTOR → PULO DUPLO",Vector3(0,3.5,-7 if sector==1 else -44))
	else:
		for i in 3:_target("fuse",[Vector3(-5,0,-16),Vector3(0,0,-18),Vector3(5,0,-16)][i],i)
		_sign("BATERIA → GIRO NOS CONTATOS\nIII → I → II",Vector3(0,3.8,-13))
func _target(kind:String,at:Vector3,index:int=0) -> void:
	var target:=preload("res://world/Scripts/Lab3D/puzzle_target.gd").new();target.puzzle=self;target.kind=kind;target.index=index;target.position=at;add_child(target);targets.append(target)
func _sign(text:String,at:Vector3) -> void:
	var display_at:=Vector3(at.x,6.35,at.z)
	Art.box(self,"PuzzleSign",display_at+Vector3(0,0,-.08),Vector3(8,1.25,.12),"1c384b",.4)
	Art.label(self,text,display_at,25,COLORS[sector])
	var ceiling:=13.7 if sector==1 else 9.7
	for side in [-1.0,1.0]:Art.cylinder(self,"SignHanger",Vector3(display_at.x+side*3.5,(ceiling+7)*.5,display_at.z),.035,ceiling-7,"537283",-1,.4)
func _restore_circuit() -> void:
	if not solved:return
	if sector==4:
		var socket:=_expansion("power_socket");var cell:=_expansion("power_cell")
		socket.active=true;socket.inserted=cell;cell.carried=false;cell.active=true;cell._socket=socket;cell._body.collision_layer=0;cell.reparent(socket,true);cell.global_position=socket.global_position+Vector3.UP*.75;socket.activate_circuit();socket._update_labels()
	elif sector==5:
		var relay:=_expansion("thermal_relay");relay.active=true;relay.phase=2;relay.activate_circuit();relay._update_labels()
func _physics_process(delta:float) -> void:
	if level.sector!=sector or level.intro_active or level.completed:return
	_clock+=delta;_cooldown=maxf(0,_cooldown-delta)
	if solved and not collected:
		_card.rotation.y+=delta;_card.position.y=1.5+sin(_clock*3)*.1
		var gap:Vector3=level.player.global_position-(global_position+cabinet.position+Vector3(0,1.4,.6))
		if gap.length()<1.8 and _cooldown<=0:_collect()
	_refresh()
func press_plate() -> void:
	if solved or _cooldown>0:return
	_cooldown=.5
	if sector==1:
		if _device("pool").frozen_left<=0:level.notice("O botão precisa de refrigeração: congele o vazamento antes de saltar nele.");return
	else:
		if not _expansion("thermal_relay").active:level.notice("Primeiro estabilize o relé com FOGO e GELO.");return
		if _expansion("ventilation_fan").frozen_left<=0:level.notice("Congele o rotor antes de subir no botão com pulo duplo.");return
	_unlock()
func turn_fuse(index:int) -> void:
	if solved or sector!=4:return
	if not _expansion("power_socket").active:level.notice("Sem energia. Instale a bateria no encaixe antes de girar os contatos.");return
	if index!=ORDER[progress]:
		progress=0;level.notice("Ordem incorreta. Observe a placa: III → I → II. Tente novamente.");Sfx.play("lab_scan",-14)
	else:
		progress+=1;Sfx.play("lab_clink",-10)
		if progress==3:_unlock()
		else:level.notice("Contato %d/3 confirmado. Próximo: %s."%[progress,["I","II","III"][ORDER[progress]]])
	_refresh()
func _unlock() -> void:
	solved=true;progress=3
	if _persistent:Save.set_story_flag(_flag("solved"))
	level.notice("Enigma resolvido! Pegue o cartão %s no dispensador."%CODES[sector],5);level.spark(global_position+cabinet.position+Vector3.UP*1.6,COLORS[sector]);Sfx.checkpoint();_refresh()
func _collect() -> void:
	if collected or not solved:return
	if _persistent and not Save.set_story_flag(_flag("card")):_cooldown=1;level.notice("Não foi possível guardar o cartão. Aproxime-se para tentar novamente.");return
	collected=true;level.notice("Cartão %s obtido! Ele abre a saída deste setor."%CODES[sector],5);Sfx.checkpoint();_refresh()
func _refresh() -> void:
	_card.visible=not collected
	cabinet.get_node("Guard").visible=not solved;cabinet.get_node("Guard2").visible=not solved;cabinet.get_node("Lock").visible=not solved
	cabinet.get_node("Status").material_override=Art.material("8ee2bf" if solved else COLORS[sector],0,.4)
	_label.text="%s %s · %s"%[SYMBOLS[sector],CODES[sector],"COLETADO ✓" if collected else ("LIBERADO · PEGUE" if solved else "TRAVADO · ENIGMA")]
	for target in targets:
		var ready:=solved
		if sector==4:ready=solved or target.index in ORDER.slice(0,progress)
		elif sector==1:ready=solved or _device("pool").frozen_left>0
		else:ready=solved or (_expansion("thermal_relay").active and _expansion("ventilation_fan").frozen_left>0)
		target.set_status("91e2b9" if ready else COLORS[sector])
		for wire in _wires:wire.material_override=Art.material(COLORS[sector] if ready else "405e70",.2,.35 if ready else 0)
func hint() -> String:
	if collected:return "Cartão %s no inventário · E na porta de saída."%CODES[sector]
	if solved:return "Cartão %s liberado · aproxime-se do dispensador para pegar."%CODES[sector]
	if sector==1:return "CRIO · congele o vazamento com K e salte sobre o botão elevado à direita."
	if sector==4:return "ARQ · conecte a bateria; depois use J nos contatos III → I → II (%d/3)."%progress
	return "BIO · estabilize o relé, congele o ventilador e use pulo duplo no botão elevado."
