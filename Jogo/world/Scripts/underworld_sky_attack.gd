extends Control
## Encenação em coordenadas de tela: nenhum ator altera a física de Nico.
const DURATION := 9.6
const IMPACT := 3.25
const LANDING := 8.5
const Ui = preload("res://world/Scripts/ui_style.gd")
const BACKDROP = preload("res://world/Arte/Underworld/V36/background.png")
const WALL = preload("res://world/Arte/Underworld/V39/terrain_04.tres")
const FLOOR = preload("res://world/Arte/Underworld/V39/terrain_00.tres")
var clock := 0.0
var stage := "flight"
var bird: AnimatedSprite2D
var rider: Node2D
var anim: AnimatedSprite2D
var ball_at := Vector2(740,70)
var impact_at := Vector2.ZERO
var _caption: Label
var _hit := false
var _landed := false
var _warned := false
var _fall_sound:=false
var _fall_player:AudioStreamPlayer
var _shade: Control
var player: CharacterBody2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(640,360)
	player.hide()
	bird = AnimatedSprite2D.new()
	bird.name = "AraraMinas"
	bird.sprite_frames = preload("res://world/Arte/Amigos/arara_minas.tres")
	bird.centered = false
	bird.scale = Vector2.ONE * 2.25
	add_child(bird)
	bird.play(&"fly")
	rider = Node2D.new()
	rider.name = "NicoRider"
	rider.scale = Vector2.ONE * 1.93
	anim = AnimatedSprite2D.new()
	anim.name = "anim"
	anim.sprite_frames = player.get_node("anim").sprite_frames
	anim.centered = false
	anim.position = Vector2(-16.5,-30)
	rider.add_child(anim)
	add_child(rider)
	var clothing := preload("res://world/Scripts/equipment_visual.gd").new()
	clothing.model = player.equipment
	rider.add_child(clothing)
	anim.play(&"run")
	_shade = Control.new()
	_shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade.draw.connect(_draw_foreground)
	add_child(_shade)
	_caption = Ui.label("",13,Color("fff1cf"),HORIZONTAL_ALIGNMENT_CENTER)
	_caption.position = Vector2(30,310)
	_caption.size = Vector2(580,30)
	add_child(_caption)
	var hint := Ui.label("ESC · pular",10,Color("c6d9e8"),HORIZONTAL_ALIGNMENT_RIGHT)
	hint.position = Vector2(520,12)
	hint.size = Vector2(102,20)
	add_child(hint)
	update_scene(0)

func update_scene(time: float) -> void:
	clock = time
	stage = "flight" if time < 2.5 else ("attack" if time < IMPACT else ("fall" if time < 5.7 else ("shaft" if time < 7.7 else "landing")))
	if time >= 2.5 and not _warned:
		_warned = true
		Sfx.alert()
	var flight_at := Vector2(170+time*15,113+sin(time*3)*3)
	if time < IMPACT:
		bird.position = flight_at.round()
		rider.position = (flight_at+Vector2(77+sin(time*2)*6,80)).round()
		impact_at = rider.position-Vector2(0,34)
		ball_at = Vector2(735,64).lerp(impact_at,clampf((time-2.5)/(IMPACT-2.5),0,1)).round()
	else:
		if not _hit:
			_hit = true
			Sfx.hit()
		if time>=IMPACT+0.2 and time<LANDING and not _fall_sound:
			_fall_sound=true
			_fall_player=AudioStreamPlayer.new()
			_fall_player.stream=Sfx._streams["sky_fall"]
			_fall_player.bus="SFX"
			_fall_player.volume_db=-6
			add_child(_fall_player)
			_fall_player.play()
		var fall := time-IMPACT
		bird.position = (Vector2(219,113)+Vector2(fall*90,-fall*95)).round()
		bird.rotation = -minf(fall,0.3)
		bird.visible = time < 5.3
		ball_at = impact_at+Vector2(-fall*440,fall*95)
		rider.position = Vector2(302+sin(fall*2)*13,lerpf(181,204,clampf(fall,0,1)))
		rider.rotation = sin(fall*4)*0.2 if time < 7.7 else 0.0
		if time < IMPACT+0.35:anim.play(&"hurt")
		elif time < LANDING:anim.play(&"fall")
		else:anim.play(&"idle")
		if time >= 7.7:
			rider.position = Vector2(302,lerpf(204,280,pow(clampf((time-7.7)/0.8,0,1),2)))
		if time >= LANDING and not _landed:
			_landed = true
			if is_instance_valid(_fall_player):_fall_player.stop()
			Sfx.land(1.0)
	_caption.text = "ARARA MINAS  ·  Próxima parada: a ilha dos nossos amigos!" if time < 2.5 else ("NICO  ·  Minas, cuidado! Um tiro da empresa!" if time < IMPACT else ("ARARA MINAS  ·  Nico!" if time < 4.8 else ("" if time < LANDING else "NICO  ·  Onde eu vim parar...?")))
	queue_redraw()
	_shade.queue_redraw()

func _cloud(at: Vector2, width: float, color: Color) -> void:
	draw_rect(Rect2(at,Vector2(width,12)),color)
	draw_rect(Rect2(at+Vector2(12,-8),Vector2(width-28,12)),color)
	draw_rect(Rect2(at+Vector2(26,-16),Vector2(width*0.4,12)),color)

func _draw() -> void:
	var descent := clampf((clock-4.1)/3.5,0,1)
	for i in 30:
		var color := Color("489bd9").lerp(Color("bce5e6"),float(i)/30).lerp(Color("201b30"),descent)
		draw_rect(Rect2(0,i*12,640,12),color)
	for i in 11:
		var x := fposmod(i*193.0-clock*(18+i%3*9),850)-130
		var y := fposmod(i*73.0-clock*10-maxf(clock-IMPACT,0)*180,460)-60
		_cloud(Vector2(x,y).round(),76+i%4*18,Color("e1f1f0").lerp(Color("51445e"),descent))
	var cave := clampf((clock-6.3)/1.1,0,1)
	if cave>0:
		draw_texture_rect(BACKDROP,Rect2(0,0,640,360),false,Color(1,1,1,cave))
		var wall_width := lerpf(0,86,clampf((clock-5.7)/1.7,0,1))
		var scroll := fposmod(maxf(clock-5.7,0)*270,32)
		for y in 14:
			for side in [0,1]:
				for x in 3:
					draw_texture_rect(WALL,Rect2(-96+wall_width+x*32 if side==0 else 640-wall_width+x*32,y*32-scroll-32,32,32),false)
	if clock>=7.7:
		for i in 20:
			draw_texture_rect(FLOOR,Rect2(i*32,280,32,32),false)
		draw_rect(Rect2(0,312,640,48),Color("211b29"))

func _draw_foreground() -> void:
	_shade.draw_rect(Rect2(0,0,640,7),Color("111a2b"))
	_shade.draw_rect(Rect2(0,306,640,54),Color("111a2b"))
	if clock>=2.5 and clock<4.7:
		# Pixel silhouette and the corporation's golden badge identify the shot.
		for i in range(5,0,-1):
			var p := ball_at+Vector2(i*17,-i*4)
			_shade.draw_rect(Rect2(p,Vector2(10,4)),Color("d6d2b3",0.55-float(i)*0.07))
		_shade.draw_rect(Rect2(ball_at-Vector2(11,7),Vector2(22,14)),Color("101724"))
		_shade.draw_rect(Rect2(ball_at-Vector2(7,11),Vector2(14,22)),Color("101724"))
		_shade.draw_rect(Rect2(ball_at-Vector2(8,8),Vector2(16,16)),Color("303c4d"))
		_shade.draw_rect(Rect2(ball_at+Vector2(-6,-7),Vector2(6,3)),Color("637287"))
		_shade.draw_rect(Rect2(ball_at+Vector2(1,-3),Vector2(6,9)),Color("e9ad45"))
		_shade.draw_rect(Rect2(ball_at+Vector2(3,-1),Vector2(2,4)),Color("fff0ab"))
	if clock>=IMPACT and clock<IMPACT+0.25:
		_shade.draw_rect(Rect2(0,0,640,306),Color(1,0.88,0.55,(1-(clock-IMPACT)/0.25)*0.65))
	if clock>=LANDING and clock<LANDING+0.55:
		var t := (clock-LANDING)/0.55
		for side in [-1,1]:
			for i in 4:
				_shade.draw_rect(Rect2(Vector2(302+side*(12+t*(24+i*7)),276-i%2*4),Vector2(7,4)),Color("b7a49e",1-t))
	var fade := clampf((clock-9.15)/0.4,0,1)
	if fade>0:_shade.draw_rect(Rect2(0,0,640,360),Color(0.04,0.03,0.07,fade))
