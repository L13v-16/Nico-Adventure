extends StaticBody3D
const Art=preload("res://world/Scripts/Lab3D/models.gd")
var puzzle:Node3D
var kind:="plate"
var index:=0
var dead:=false
var _art:Node3D
var _cooldown:=0.0
var _above:=false
var _spin:=0.0
func _ready() -> void:
	add_to_group("lab3d_puzzle_targets");collision_layer=1 if kind=="plate" else 17;collision_mask=0
	set_meta("receiver",self)
	var shape:=BoxShape3D.new();shape.size=Vector3(1.5,.21,1.5) if kind=="plate" else Vector3(1.2,1.6,1)
	var collider:=CollisionShape3D.new();collider.shape=shape;collider.position.y=.105 if kind=="plate" else .8;add_child(collider)
	_art=Art.instantiate("puzzle_plate" if kind=="plate" else "spin_fuse");add_child(_art)
	if kind!="plate":
		var label:=Art.label(self,["I","II","III"][index],Vector3(0,2,.2),37,"f3d489");label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
func _physics_process(delta:float) -> void:
	if puzzle.level.sector!=puzzle.sector or puzzle.level.intro_active or puzzle.level.completed:return
	_cooldown=maxf(0,_cooldown-delta)
	if _spin>0:_spin=maxf(0,_spin-delta);_art.get_node("Wheel").rotation.z+=delta*TAU*2
	if kind!="plate":return
	var player:CharacterBody3D=puzzle.level.player
	var gap:Vector3=player.global_position-global_position
	var within:=absf(gap.x)<.78 and absf(gap.z)<.78
	if within and gap.y>.45:_above=true
	if not within:_above=false
	if within and _above and gap.y<=.28 and gap.y>=.12 and player.is_on_floor() and _cooldown<=0:
		_above=false;_cooldown=.35;puzzle.press_plate()
		_art.get_node("Button").position.y=.1
	else:_art.get_node("Button").position.y=move_toward(_art.get_node("Button").position.y,.15,delta*.3)
func take_damage(_amount:float,_source:Vector3) -> void:
	if kind=="plate" or _cooldown>0:return
	_cooldown=.55;_spin=.35;puzzle.turn_fuse(index)
func set_status(color:String) -> void:
	_art.get_node("Status").material_override=Art.material(color,0,.5)
