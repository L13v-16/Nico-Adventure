extends Node2D
## Ferragens: a mira para antes da queda; a corrente rasteira permite saltar.
const Chains=preload("res://world/Scripts/underworld_chain_art.gd")
const RingArt=preload("res://world/Scripts/warden_ring_art.gd")
var boss:CharacterBody2D
var kind:="rain"
var direction:=1.0
var clock:=0.0
var impacted:=false
var target_x:=0.0
var speed:=255.0
var warning_time:=.95
const FISSURE_HEIGHT:=96.0
func fissure_height() -> float:
	return FISSURE_HEIGHT*clampf((clock-warning_time)/.12,0,1)*clampf((warning_time+.85-clock)/.3,0,1)
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
	elif kind=="fissure":
		if clock>=warning_time and not impacted:
			impacted=true;Sfx.play("warden_slam",-15)
			Fx.burst(global_position,Color("ffbc82"),10,80)
		if clock>=warning_time and clock<warning_time+.55:
			if absf(player.position.x-target_x)<25 and player.position.y+11>position.y-fissure_height() and player.position.y<position.y+10:player.take_damage(1,global_position)
		if clock>=warning_time+.85:queue_free();return
	else:
		if clock>warning_time:
			# Split off the warning portion so a long frame cannot jump the wave.
			var movement:=minf(delta,clock-warning_time)
			position.x+=direction*speed*movement
			if absf(player.position.x-position.x)<25 and player.position.y+11>position.y-24 and player.position.y<position.y+10:player.take_damage(1,global_position)
		if position.x<6470 or position.x>7450 or clock>6.2:queue_free();return
	queue_redraw()
func _draw() -> void:
	var ink:=Color("ffbd79")
	if kind=="rain":
		if clock<1.35:
			var radius:=lerpf(26,12,clampf(clock/1.35,0,1))
			draw_arc(Vector2(0,-2),radius,PI,TAU,16,ink,2)
			draw_line(Vector2(-24,0),Vector2(24,0),ink,2)
			for y in range(-96,-18,14):draw_rect(Rect2(-1,y,2,5),Color(ink,.5))
		if clock>=.9 and clock<1.35:
			var y:=lerpf(-180,-4,clampf((clock-.9)/.45,0,1))
			RingArt.draw_sprite(self,0 if clock<1.2 else 1,Vector2(0,y),54)
		elif clock>=1.35:RingArt.draw_sprite(self,2 if clock<1.5 else 3,Vector2.ZERO,70)
	elif kind=="fissure":
		if clock<warning_time:
			draw_arc(Vector2(0,-2),27,PI,TAU,20,ink,2)
			draw_line(Vector2(-24,0),Vector2(24,0),ink,2)
			draw_polyline(PackedVector2Array([Vector2(-12,2),Vector2(-3,-6),Vector2(4,0),Vector2(13,-8)]),Color("ffe5b3"),2)
			draw_string(ThemeDB.fallback_font,Vector2(-25,-19),"SAIA!",HORIZONTAL_ALIGNMENT_CENTER,50,8,ink)
		else:
			var height:=fissure_height()
			for x in [-6.0,6.0]:Chains.strand(self,Vector2(x,0),Vector2(x,-height),8,6,Color("ffd1a0"))
			RingArt.draw_sprite(self,2,Vector2.ZERO,58)
	else:
		if clock<warning_time:
			draw_line(Vector2.ZERO,Vector2(direction*125,0),ink,3)
			draw_polyline(PackedVector2Array([Vector2(direction*100,-10),Vector2(direction*125,0),Vector2(direction*100,10)]),ink,2)
		else:
			Chains.strand(self,Vector2(-direction*80,-10),Vector2(-direction*24,-10),6,3)
			RingArt.draw_sprite(self,4+int(clock*10)%4,Vector2(0,-20),70,direction<0)
