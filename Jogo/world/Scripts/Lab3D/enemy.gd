extends CharacterBody3D
const Art=preload("res://world/Scripts/Lab3D/models.gd")
var level:Node3D
var species:="mutant"
var sector:=1
var health:=2.0
var dead:=false
var frozen:=0.0
var _home:=Vector3.ZERO
var _clock:=0.0
var _timer:=1.5
var _state:="patrol"
var _aim:=Vector3.ZERO
var _model:Node3D
var _warning:MeshInstance3D
var _ice:MeshInstance3D
var _invulnerable:=0.0
func _ready() -> void:
	add_to_group("lab3d_enemies");add_to_group("lab3d_targets");collision_layer=4;collision_mask=1
	_home=global_position
	var shape:=CapsuleShape3D.new();shape.radius=.55;shape.height=1.8
	var col:=CollisionShape3D.new();col.shape=shape;col.position.y=.9;add_child(col)
	_model=Art.instantiate(species);add_child(_model)
	if species=="drone":health=1
	_warning=Art.ring(self,"AttackWarning",Vector3(0,.045,0),1.1,"f4b465",.5);_warning.hide()
	_ice=Art.box(self,"Frozen",Vector3(0,1,0),Vector3(1.3,2.1,1.3),"9cdae3")
	var glass:=Art.material("9cdae3").duplicate();glass.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA;glass.albedo_color=Color(.55,.86,.92,.35);_ice.material_override=glass;_ice.hide()
func aim_point() -> Vector3:return global_position+Vector3.UP*(.2 if species=="drone" else 1)
func accepts(_element:String) -> bool:return not dead
func _physics_process(delta:float) -> void:
	if dead or sector!=level.sector or level.intro_active or level.completed:return
	_clock+=delta;_timer-=delta;_invulnerable=maxf(0,_invulnerable-delta);frozen=maxf(0,frozen-delta);_ice.visible=frozen>0
	if frozen>0:_timer=maxf(.9,_timer);_warning.hide();return
	var player:CharacterBody3D=level.player
	var gap:Vector3=player.global_position-global_position
	_warning.visible=_state=="warning"
	if species=="drone":
		global_position.y=_home.y+sin(_clock*2)*.25
		if gap.length()<13 and _timer<=0:
			if _state=="warning":level.enemy_shot(global_position,player.global_position+Vector3.UP,10,self);_state="patrol";_timer=2.8
			else:_state="warning";_timer=.95;Sfx.play("lab_scan",-15)
		return
	velocity.y-=24*delta
	match _state:
		"patrol":
			var target:=_home+Vector3(sin(_clock*.65)*3,0,cos(_clock*.65)*1.5)
			var walk:Vector3=target-global_position;walk.y=0;velocity.x=walk.x*1.3;velocity.z=walk.z*1.3
			if walk.length()>.2:_model.rotation.y=atan2(-walk.x,-walk.z)
			_model.get_node("Animations").play("run")
			if gap.length()<9 and _timer<=0:_state="warning";_timer=.9;_aim=player.global_position;velocity.x=0;velocity.z=0;Sfx.play("lab_scan",-16)
		"warning":
			_model.get_node("Animations").play("operate" if species=="technician" else "idle")
			_model.rotation.y=atan2(-(_aim.x-global_position.x),-(_aim.z-global_position.z))
			if _timer<=0:
				_state="attack";_timer=.55
				if species=="technician":level.enemy_shot(global_position+Vector3.UP*1.3,_aim+Vector3.UP,12,self)
				else:
					var run:Vector3=(_aim-global_position).normalized()*8;velocity.x=run.x;velocity.z=run.z;velocity.y=4
		"attack":
			_model.get_node("Animations").play("attack")
			if species!="technician" and gap.length()<1.7:player.take_damage(1,global_position)
			if _timer<=0:_state="recovery";_timer=1.5;velocity.x=0;velocity.z=0
		"recovery":
			_model.get_node("Animations").play("idle")
			if _timer<=0:_state="patrol";_timer=1.3
	move_and_slide()
func take_element(element:String,source:Vector3,seconds:float=3) -> void:
	if element=="ice":frozen=seconds;velocity=Vector3.ZERO;level.spark(global_position+Vector3.UP,"9ce4ee");Sfx.play("lab_clink",-10)
	else:take_damage(1.0,source)
func take_damage(amount:float,_source:Vector3) -> void:
	if dead or _invulnerable>0:return
	_invulnerable=.4;health-=amount;Sfx.hit();level.spark(global_position+Vector3.UP,"edc980")
	if species!="drone":_model.get_node("Animations").play("hurt")
	if health<=0:
		dead=true;collision_layer=0;level.defeated+=1
		var tween:=create_tween();tween.tween_property(_model,"scale",Vector3.ONE*.05,.25);tween.tween_callback(queue_free)
