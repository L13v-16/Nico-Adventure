extends Node2D
## Two flank seals, then a single earned melee hit. No platform escalation.
const Chains=preload("res://world/Scripts/underworld_chain_art.gd")
var boss: CharacterBody2D
var fire_ready := false
var ice_ready := false
var open_left := 0.0
var recovery := 1.2
var attack_left := 3.8
var warning := 0.0
var target_x := 0.0
var hits := 0
var clock := 0.0
func _ready() -> void:z_index=5
func _physics_process(delta:float) -> void:
	if not boss.active or boss.phase!=6:return
	clock+=delta;recovery=maxf(0,recovery-delta)
	if open_left>0:
		open_left=maxf(0,open_left-delta)
		if open_left==0:fire_ready=false;ice_ready=false;recovery=1.0
		boss._sprite.play(&"exposed")
	else:
		boss._sprite.play(&"windup" if warning>0 else (&"heated" if fire_ready else (&"frozen" if ice_ready else &"guard")))
		attack_left-=delta
		if attack_left<=0 and warning<=0:
			warning=1.1;target_x=clampf(boss._player.position.x,6500,7390);Sfx.play("warden_chain",-8)
		if warning>0:
			warning=maxf(0,warning-delta)
			if warning==0:
				boss._target_x=target_x;boss._slam();attack_left=4.0
	boss._sprite.flip_h=false
	boss._sprite.modulate=Color("ffe5bc") if recovery>.6 and hits>0 else Color.WHITE
	boss._fill.size.x=492*float(3-hits)/3
	boss._phase_caption.text="6 / 6 · OS ÚLTIMOS SELOS · %d / 3"%hits
	boss._caption.text=advice();queue_redraw()
func element(element:String,source:Vector2) -> void:
	if open_left>0 or recovery>0:return
	if element=="fire" and source.x<boss.position.x-8:fire_ready=true;Sfx.play("warden_fire_charge",-9)
	elif element=="ice" and source.x>boss.position.x+8:ice_ready=true;Sfx.play("warden_ice_charge",-9)
	else:
		Fx.popup(source+Vector2(0,-25),"FOGO À ESQUERDA · GELO À DIREITA",Color("ffe0b4"),9);return
	if fire_ready and ice_ready:
		open_left=4.5;warning=0;attack_left=4.0
		Sfx.play("warden_break",-5);Fx.burst(boss.position+Vector2(0,-55),Color("cfecff"),16,130)
	queue_redraw()
func strike(amount:float) -> void:
	if amount<=0 or open_left<=0 or recovery>0:return
	hits+=1;open_left=0;fire_ready=false;ice_ready=false;recovery=1.1
	boss.health=3-hits;attack_left=3.5;warning=0
	boss._clear_projectiles();Sfx.play("warden_hurt",-5)
	Fx.popup(boss.position+Vector2(0,-132),"SELO ROMPIDO! %d / 3"%hits,Color("e4ffbc"),10)
	if hits>=3:boss._defeat()
func advice() -> String:
	if open_left>0:return "SELOS ABERTOS · APROXIME-SE E USE J / X · %.1fs"%open_left
	if recovery>0:return "SELOS SE RECOMPONDO · PREPARE O PRÓXIMO ELEMENTO"
	if fire_ready:return "VÁ À DIREITA · Q: GELO · K NO SELO AZUL"
	if ice_ready:return "VÁ À ESQUERDA · Q: FOGO · K NO SELO LARANJA"
	return "K: FOGO PELO LADO ESQUERDO + GELO PELO DIREITO · PULE AS ONDAS"
func _draw() -> void:
	for side in [-1.0,1.0]:
		var ready:bool=fire_ready if side<0 else ice_ready
		var color:=Color("ffc078") if side<0 else Color("9ce9ff")
		var at:=Vector2(side*43,-35)
		Chains.strand(self,Vector2(side*22,-83),at,5,9,color)
		draw_texture_rect(Chains.CLASP,Rect2(at-Vector2(8,12),Vector2(16,24)),false,color)
		draw_arc(at,17+sin(clock*4)*2,0,TAU,20,Color(color,.4 if ready else 1),2)
		if ready:draw_line(at+Vector2(-7,0),at+Vector2(-2,5),Color.WHITE,2);draw_line(at+Vector2(-2,5),at+Vector2(8,-7),Color.WHITE,2)
	if open_left>0:draw_arc(Vector2(0,-45),28,0,TAU,24,Color("eaffb5"),2)
	if warning>0:
		var at:=Vector2(target_x-boss.position.x,0)
		draw_rect(Rect2(at+Vector2(-26,-3),Vector2(52,3)),Color("ffb87a"))
		draw_string(ThemeDB.fallback_font,at+Vector2(-35,-14),"PULE!",HORIZONTAL_ALIGNMENT_CENTER,70,10,Color("ffdcaa"))
