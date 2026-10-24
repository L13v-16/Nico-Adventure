extends RefCounted
## Six silent decorative vignettes. No gameplay, input, saves or NPC scripts.
const General=preload("res://world/Scripts/general_art.gd")
static func update(f:Control) -> void:
	var t:=fposmod(f.clock,96);f.interaction="";f.interaction_progress=0
	for entry:Array in [[42,"voo"],[50,"piquenique"],[58,"pedra"],[66,"brincadeira"],[76,"cumprimento"],[84,"malabarismo"]]:
		if t>=entry[0] and t<entry[0]+6:f.interaction=entry[1];f.interaction_progress=(t-entry[0])/6.0;break
	var u:float=f.interaction_progress;var beat:=u*6
	match f.interaction:
		"voo":
			f._pose("nico",312,279,"ambient_wave" if u<.65 else "ambient_clap",false,beat)
			var land:=smoothstep(.65,1,u)
			f._pose("arara",lerpf(330+30*cos(u*TAU*2),350,land),lerpf(244+sin(u*TAU*2)*11,279,land),"fly" if u<.95 else "ambient_wave",cos(u*TAU*2)<0,beat)
		"piquenique":
			f._pose("turtle",396,278,"ambient_wave" if u<.2 else ("ambient_snack" if u<.75 else "ambient_nod"),false,beat)
			f._pose("oliver",424,280,"ambient_inspect" if u<.4 else ("ambient_chuckle" if u<.8 else "ambient_shrug"),true,beat)
		"pedra":
			var push:=smoothstep(0,.65,u)
			f._pose("jose",lerpf(471,488,push),280,"ambient_hoof" if u<.65 else "ambient_laugh",false,beat)
			f._pose("urso",520,279,"ambient_wave" if u<.65 else "ambient_clap",true,beat)
		"brincadeira":
			var chase:=sin(u*TAU);var jump:=maxf(0,sin(u*TAU*2))*10
			f._pose("remi",578+chase*20,277-jump,"walk" if u<.85 else "ambient_wave",cos(u*TAU)<0,beat)
			f._pose("mico",600-chase*20,281-maxf(0,-sin(u*TAU*2))*10,"walk" if u<.85 else "ambient_clap",cos(u*TAU)>0,beat)
		"cumprimento":
			for entry:Array in [["nico",311,279],["arara",354,279],["turtle",392,278],["oliver",428,280],["jose",480,280],["urso",518,279],["remi",575,277],["mico",610,281]]:
				f._pose(entry[0],entry[1],entry[2],"ambient_wave",entry[0] in ["arara","oliver","urso","mico"],beat)
		"malabarismo":
			f._pose("nico",309,279,"ambient_think" if u<.18 else "ambient_clap",false,beat)
			f._pose("arara",353,279-maxf(0,sin(u*PI))*18,"fly" if u<.8 else "ambient_peck",true,beat)
static func _texture(canvas:Control,texture:Texture2D,at:Vector2,width:float,grounded:bool=false) -> void:
	var size:=Vector2(width,width*texture.get_height()/texture.get_width())
	canvas.draw_texture_rect(texture,Rect2(at-Vector2(size.x/2,size.y if grounded else size.y/2),size),false)
static func draw(f:Control,canvas:Control,cherry:Texture2D) -> void:
	var u:float=f.interaction_progress
	match f.interaction:
		"piquenique":
			if u<.65:
				var travel:=smoothstep(.15,.5,u);var point:=Vector2(419,268).lerp(Vector2(398,269),travel)+Vector2(0,-sin(travel*PI)*5)
				canvas.draw_texture_rect_region(cherry,Rect2(f._map_point("turtle",point)-Vector2(1.5,1.5),Vector2(3,3)),Rect2(0,0,21,21))
		"pedra":
			var point:Vector2=f._map_point("jose",Vector2(lerpf(497,512,smoothstep(0,.65,u)),280))
			_texture(canvas,General.cell("forest",2),point,8,true)
			if u>=.65 and u<.85:_texture(canvas,General.cell("fx",12+mini(3,int((u-.65)/.2*4))),point+Vector2(-4,0),10,true)
		"cumprimento":
			if u>.25 and u<.65:
				for id:String in f.actors:
					var actor:Node2D=f.actors[id];var at:Vector2=actor.position+Vector2(0,-18)
					_texture(canvas,General.cell("fx",8+mini(3,int((u-.25)/.4*4))),at,5)
		"malabarismo":
			if u>.15 and u<.85:
				var travel:float=clampf((u-.15)/.7,0,1);var there:=travel<.5;var arc:=fposmod(travel*2,1)
				var a:Vector2=f.actors.nico.position+Vector2(4,-8);var b:Vector2=f.actors.arara.position+Vector2(-4,-6)
				var at:=a.lerp(b,arc) if there else b.lerp(a,arc);at.y-=sin(arc*PI)*13
				canvas.draw_texture_rect_region(cherry,Rect2(at-Vector2(1.5,1.5),Vector2(3,3)),Rect2(0,0,21,21))
