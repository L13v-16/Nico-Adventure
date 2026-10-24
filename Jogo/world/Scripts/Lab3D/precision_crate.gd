extends StaticBody3D
const Art=preload("res://world/Scripts/Lab3D/models.gd")
var level:Node3D
var sector:=0
var spring:=false
var dead:=false
var _art:Node3D
var _bounce_cooldown:=0.0
func _ready() -> void:
	add_to_group("lab3d_crates");collision_layer=1;collision_mask=0
	var shape:=BoxShape3D.new();shape.size=Vector3(1.4,1.4,1.4)
	var col:=CollisionShape3D.new();col.shape=shape;col.position.y=.7;add_child(col)
	_art=Art.instantiate("bounce_crate" if spring else "supply_crate");add_child(_art)
func _physics_process(delta:float) -> void:
	if dead or level.sector!=sector or level.intro_active or level.completed:return
	_bounce_cooldown=maxf(0,_bounce_cooldown-delta)
	_art.scale.y=move_toward(_art.scale.y,1.0,3*delta)
	var player:CharacterBody3D=level.player
	var gap:Vector3=player.global_position-global_position
	# feet on the lid; walking into the side never activates a jump.
	if spring and _bounce_cooldown<=0 and absf(gap.x)<.95 and absf(gap.z)<.95 and gap.y>=1.30 and gap.y<=1.58 and player.velocity.y<=.1:
		_bounce_cooldown=.28;_art.scale.y=.72;player.bounce(13.4)
func take_damage(_amount:float,_source:Vector3) -> void:
	if dead or spring:return
	dead=true;collision_layer=0;_art.hide();Sfx.play("lab_clink",-10)
	level.spark(global_position+Vector3.UP*.7,"d4a46d")
	# Broken crates stay broken for this visit. They never mint currency.
func hint() -> String:
	return "CAIXA ELÁSTICA · caia em cima para saltar mais alto; ajuste a direção no ar." if spring else "J: GIRO quebra caixas · Espaço novamente no ar: PULO DUPLO."
