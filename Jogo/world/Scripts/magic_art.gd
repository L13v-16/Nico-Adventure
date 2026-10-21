extends RefCounted
## Atlas nativo alinhado pelos pés; a amostragem inteira mantém a pixel art.
const CUTOUT := preload("res://world/Scripts/characters_cutout.gdshader")
const PROPS := preload("res://world/Arte/Magic/props.tres")
const CONTACTS := preload("res://world/Arte/Magic/ground_contacts_v30.tres")
static var _foot_cache: Dictionary = {}
static var _contacts: Dictionary = CONTACTS.get_meta("feet",{})

static func material() -> ShaderMaterial:
	var ink := ShaderMaterial.new()
	ink.shader = CUTOUT
	return ink

static func actor(frames: SpriteFrames, native_width: float) -> AnimatedSprite2D:
	var sprite := AnimatedSprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.sprite_frames = frames
	sprite.centered = false
	var sample: Texture2D = frames.get_frame_texture(frames.get_animation_names()[0], 0)
	var ratio := native_width / sample.get_width()
	sprite.scale = Vector2.ONE * ratio
	sprite.position = Vector2(-native_width * 0.5, -sample.get_height() * ratio)
	sprite.material = material()
	sprite.frame_changed.connect(reanchor.bind(sprite))
	sprite.animation_changed.connect(reanchor.bind(sprite))
	reanchor(sprite)
	return sprite

static func reanchor(sprite: AnimatedSprite2D) -> void:
	if sprite.sprite_frames==null or not sprite.sprite_frames.has_animation(sprite.animation):return
	var texture:Texture2D=sprite.sprite_frames.get_frame_texture(sprite.animation,sprite.frame)
	if texture==null:return
	var cutoff:=0.78
	if sprite.material is ShaderMaterial:
		var configured=sprite.material.get_shader_parameter("alpha_cutoff")
		if configured is float:cutoff=configured
	var key:=str(texture.get_instance_id())+":"+str(cutoff)
	if not _foot_cache.has(key) and texture.has_meta("ground_foot"):
		_foot_cache[key]=float(texture.get_meta("ground_foot"))
	if not _foot_cache.has(key):
		var stored:Dictionary=_contacts.get(texture.resource_path,{})
		var cutoff_key:=str(roundi(cutoff*100))
		if stored.has(cutoff_key):_foot_cache[key]=float(stored[cutoff_key])
	if not _foot_cache.has(key):
		var image:=texture.get_image()
		var foot:=image.get_height()
		var found:=false
		for y in range(image.get_height()-1,-1,-1):
			for x in image.get_width():
				if image.get_pixel(x,y).a>=cutoff:
					foot=y+1
					found=true
					break
			if found:break
		# AtlasTexture.get_image() devolve o recorte sem o preenchimento do atlas.
		# A margem também participa da posição renderizada dos pés.
		_foot_cache[key]=float(foot)+(texture.margin.position.y if texture is AtlasTexture else 0.0)
	var previous:Vector2=sprite.get_meta("ground_art_offset",sprite.position)
	var anchor:=sprite.position-previous
	var offset:=Vector2(-texture.get_width()*sprite.scale.x*0.5,-float(_foot_cache[key])*sprite.scale.y)
	sprite.position=anchor+offset
	sprite.set_meta("ground_art_offset",offset)

static func prop(animation: StringName, native_width: float) -> AnimatedSprite2D:
	var sprite := actor(PROPS, native_width)
	sprite.material.set_shader_parameter("alpha_cutoff",0.94)
	sprite.play(animation)
	reanchor(sprite)
	return sprite

## As raízes têm pontas em alturas diferentes. Enterrar a base permite que
## o terreno à frente cubra as pontas e encoste também nas raízes mais altas.
static func planted_tree(animation: StringName, native_width: float, surface: Vector2) -> AnimatedSprite2D:
	var tree := prop(animation, native_width)
	var root_depth := roundf(native_width * 0.10)
	tree.position += surface + Vector2(0, root_depth)
	tree.set_meta("ground_surface", surface)
	tree.set_meta("root_depth", root_depth)
	return tree
