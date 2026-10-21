extends Node2D
## Ferragens: a mira para antes da queda; a corrente rasteira permite saltar.
const Chains=preload("res://world/Scripts/underworld_chain_art.gd")
var boss:CharacterBody2D
var kind:="rain"
var direction:=1.0
var clock:=0.0
var impacted:=false
var target_x:=0.0
func _ready() -> void:
	add_to_group("underworld_projectiles")
	add_to_group("warden_ring_hazards")
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	z_index=5
	target_x=position.x
func _physics_process(delta:float) -> void:
	if not is_instance_valid(boss) or not boss.active or boss.phase!=2:queue_free();return
	clock+=delta
	position.y=boss.arena_floor_y()
	var player:CharacterBody2D=boss._player
	if kind=="rain":
		if clock>=1.35 and not impacted:
			impacted=true
			Sfx.play("warden_slam",-15)
			Fx.burst(global_position,Color("f0b479"),8,65)
			if absf(player.position.x-target_x)<25 and absf(player.position.y+11-position.y)<32:player.take_damage(1,global_position)
		if clock>=1.65:queue_free();return
	else:
		if clock>.95:
			position.x+=direction*255*delta
			if absf(player.position.x-position.x)<25 and player.position.y+11>position.y-24 and player.position.y<position.y+10:player.take_damage(1,global_position)
		if position.x<6470 or position.x>7450 or clock>5:queue_free();return
	queue_redraw()
func _draw() -> void:
	var ink:=Color("ffbd79")
	if kind=="rain":
		if clock<1.35:
			var radius:=lerpf(26,12,clampf(clock/1.35,0,1))
			draw_arc(Vector2(0,-2),radius,PI,TAU,16,ink,2)
			draw_line(Vector2(-24,0),Vector2(24,0),ink,2)
			for y in range(-96,-18,14):draw_rect(Rect2(-1,y,2,5),Color(ink,.5))
		if clock>=.9:
			var y:=lerpf(-180,-4,clampf((clock-.9)/.45,0,1))
			Chains.strand(self,Vector2(0,y-44),Vector2(0,y),6)
			draw_texture_rect(Chains.CLASP,Rect2(-12,y-18,24,26),false)
	else:
		if clock<.95:
			draw_line(Vector2.ZERO,Vector2(direction*125,0),ink,3)
			draw_polyline(PackedVector2Array([Vector2(direction*100,-10),Vector2(direction*125,0),Vector2(direction*100,10)]),ink,2)
		else:
			Chains.strand(self,Vector2(-direction*80,-8),Vector2(0,-8),7,4)
			draw_set_transform(Vector2(0,-13),clock*direction*7)
			draw_texture_rect(Chains.COIL,Rect2(-18,-18,36,36),false)
			draw_set_transform(Vector2.ZERO)
			draw_line(Vector2(-18,-1),Vector2(18,-1),ink,2)
