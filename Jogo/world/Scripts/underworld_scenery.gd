extends RefCounted
## Marcos de cenário planejados por trecho. A faixa de passagem fica livre.
const ROOT:="res://world/Arte/Underworld/V36/"
static func prop(parent:Node,id:int,width:float,at:Vector2,shade:Color=Color.WHITE,ceiling:bool=false) -> Sprite2D:
	var sprite:=Sprite2D.new()
	sprite.name="Scenery_%02d"%id
	sprite.texture=load(ROOT+"props_%02d.tres"%id)
	sprite.centered=false
	sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material=preload("res://world/Scripts/magic_art.gd").material()
	sprite.material.set_shader_parameter("alpha_cutoff",0.94)
	var ratio:=width/sprite.texture.get_width()
	sprite.scale=Vector2.ONE*ratio
	sprite.position=at+Vector2(-width/2,0 if ceiling else -sprite.texture.get_height()*ratio+3)
	sprite.modulate=shade
	sprite.set_meta("scenery_id",id)
	sprite.set_meta("ground_surface",at)
	sprite.set_meta("ceiling",ceiling)
	parent.add_child(sprite)
	return sprite
static func build(parent:Node) -> void:
	var near:=Color("b7a9b6")
	var far:=Color("71667d")
	# Entrada da mina, travessias de basalto e ruínas do templo.
	for item in [
		[12,142,Vector2(130,100)],[10,40,Vector2(360,100)],
		[11,84,Vector2(360,100)],[9,26,Vector2(310,100)],
		[13,18,Vector2(432,100)],[0,28,Vector2(820,100)],
		[6,148,Vector2(1455,100)],[7,24,Vector2(1610,100)],
		[12,126,Vector2(1940,100)],[13,19,Vector2(1880,100)],
		[6,144,Vector2(2710,36)],[7,27,Vector2(2950,36)],
		[14,26,Vector2(3390,-40)],[7,32,Vector2(3720,-40)],
		[12,140,Vector2(4025,100)],[10,43,Vector2(4755,100)],
		[11,96,Vector2(4755,100)],[13,18,Vector2(4875,100)],
		[6,144,Vector2(5390,100)],[12,130,Vector2(5740,100)],
		[13,18,Vector2(6220,100)],[15,90,Vector2(6320,100)],
		[7,38,Vector2(6475,100)],[6,190,Vector2(6650,100)],
		[7,38,Vector2(7420,100)],[14,24,Vector2(7630,100)],
		[13,19,Vector2(7945,100)]
	]:
		if item[2].x>4010 and item[2].x<4810:continue
		prop(parent,item[0],item[1],item[2],far if item[0] in [6,7,12,15] else near)
	for item in [
		[1,22,Vector2(54,100)],[3,18,Vector2(700,100)],[2,17,Vector2(852,100)],
		[0,24,Vector2(1354,100)],[3,19,Vector2(1665,100)],[1,21,Vector2(2180,100)],
		[4,34,Vector2(2580,36)],[2,18,Vector2(2875,36)],[1,26,Vector2(3120,36)],
		[2,19,Vector2(3680,-40)],[3,17,Vector2(3760,-40)],
		[9,24,Vector2(3950,100)],[1,23,Vector2(4270,100)],[0,25,Vector2(4880,100)],
		[4,30,Vector2(5230,100)],[2,16,Vector2(5440,100)],[3,17,Vector2(5885,100)],
		[9,25,Vector2(6180,100)],[0,30,Vector2(6420,100)],
		[2,18,Vector2(6950,100)],[1,24,Vector2(7340,100)],[0,28,Vector2(7990,100)]
	]:
		if item[2].x>4010 and item[2].x<4810:continue
		prop(parent,item[0],item[1],item[2],near)
	# Pontas e correntes presas aos arcos/suportes, sem peças suspensas no vazio.
	for at in [Vector2(1455,4),Vector2(2710,-63),Vector2(5390,1),Vector2(6650,-30)]:
		prop(parent,5,43,at,far,true)
	for at in [Vector2(168,-10),Vector2(1970,4),Vector2(4059,-7),Vector2(5764,-1)]:
		if at.x>4010 and at.x<4810:continue
		prop(parent,8,15,at,far,true)
