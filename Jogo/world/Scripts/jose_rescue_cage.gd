extends Node2D
## A jaula é parte do cenário: permanece aberta depois do resgate.
const Art=preload("res://world/Scripts/underworld_art.gd")
const Chain=preload("res://world/Scripts/underworld_chain_art.gd")
const TEX=[preload("res://world/Arte/Underworld/V49/cage_00.tres"),preload("res://world/Arte/Underworld/V49/cage_01.tres"),preload("res://world/Arte/Underworld/V49/cage_02.tres"),preload("res://world/Arte/Underworld/V49/cage_03.tres")]
var base:=Vector2(0,-52)
var damage:=0
var opened:=false
var rig:Node2D
var prisoner:AnimatedSprite2D
var prisoner_root:Node2D
var front:Sprite2D
var back:Sprite2D
var _scale:=0.0
var _clock:=0.0
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	material=preload("res://world/Scripts/magic_art.gd").material()
	material.set_shader_parameter("alpha_cutoff",0.94)
	preload("res://world/Scripts/underworld_scenery.gd").prop(self,12,190,Vector2.ZERO,Color("b7a9b6")).z_index=-2
	rig=Node2D.new();rig.name="CageRig";add_child(rig)
	_scale=float(TEX[0].get_meta("native_scale"))
	back=_piece(preload("res://world/Arte/Underworld/V49/cage_04.tres"),0)
	back.modulate=Color("94909f")
	prisoner_root=Node2D.new();prisoner_root.z_index=1;rig.add_child(prisoner_root)
	prisoner=Art.actor("jose",44);prisoner.name="CaptiveJose";prisoner_root.add_child(prisoner)
	prisoner.play(&"idle");prisoner.flip_h=true
	front=_piece(TEX[0],2)
	set_pose(0)
func _piece(texture:Texture2D,depth:int) -> Sprite2D:
	var sprite:=Sprite2D.new();sprite.texture=texture;sprite.centered=false
	sprite.scale=Vector2.ONE*_scale;sprite.position=Vector2(-texture.get_width()*.5,-texture.get_height())*_scale
	sprite.z_index=depth;sprite.material=preload("res://world/Scripts/magic_art.gd").material()
	sprite.material.set_shader_parameter("alpha_cutoff",0.94)
	rig.add_child(sprite);return sprite
func set_pose(time:float) -> void:
	_clock=time
	damage=0 if time<1.55 else (1 if time<3.15 else 2)
	var lowering:=smoothstep(3.65,5.15,time)
	var sway:=sin(time*2.4)*1.3*(1-lowering)
	base=Vector2(sway,lerpf(-52,0,lowering))
	var hit_time:=time-1.55 if time<3.15 else time-3.15
	if damage>0 and hit_time>=0 and hit_time<.3:base.x+=sin(hit_time*70)*2*(1-hit_time/.3)
	rig.position=base.round()
	var frame:=0 if damage==0 else (1 if damage==1 else (2 if time<5.65 else 3))
	front.texture=TEX[frame]
	prisoner.visible=not opened
	prisoner_root.position=Vector2(-10 if time<5.8 else -10-minf((time-5.8)*32,40),-3+smoothstep(6.9,7.2,time)*3)
	prisoner_root.z_index=1 if time<5.8 else 3
	prisoner.play(&"idle" if time<5.8 else &"walk")
	queue_redraw()
func release() -> void:
	set_pose(7.4);opened=true;prisoner.hide();front.texture=TEX[3];rig.position=Vector2.ZERO;queue_redraw()
func _draw() -> void:
	if not is_node_ready():return
	var top:=rig.position+Vector2(0,-TEX[0].get_height()*_scale+2)
	Chain.strand(self,Vector2(0,-143),top,3,0,Color("b8b3bd"))
	draw_texture_rect(preload("res://world/Arte/Underworld/V49/cage_07.tres"),Rect2(-5,-150,10,17),false)
	if damage>=2:
		var t:=clampf((_clock-3.15)/.6,0,1)
		var where:=Vector2(-2+sin(t*3)*8,lerpf(-76,-3,t*t))
		draw_texture_rect(preload("res://world/Arte/Underworld/V49/cage_05.tres"),Rect2(where,Vector2(12,9)),false)
