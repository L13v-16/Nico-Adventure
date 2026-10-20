extends RefCounted
## Uma única referência de arte por amigo, em todas as telas.
const PATHS={
  "res://world/Arte/Amigos/arara_idle_1.png": "res://world/Arte/Friends/V47/arara_body_00.tres",
  "res://world/Arte/Amigos/arara_idle_2.png": "res://world/Arte/Friends/V47/arara_body_01.tres",
  "res://world/Arte/Amigos/arara_fly_1.png": "res://world/Arte/Friends/V47/arara_body_04.tres",
  "res://world/Arte/Amigos/arara_fly_2.png": "res://world/Arte/Friends/V47/arara_body_05.tres",
  "res://world/Arte/Amigos/arara_fly_3.png": "res://world/Arte/Friends/V47/arara_body_06.tres",
  "res://world/Arte/Amigos/arara_fly_4.png": "res://world/Arte/Friends/V47/arara_body_07.tres",
  "res://world/Arte/Amigos/remi.png": "res://world/Arte/Friends/V47/remi_body_00.tres",
  "res://world/Arte/Amigos/remi_2.png": "res://world/Arte/Friends/V47/remi_body_01.tres",
  "res://world/Arte/Tartaruga/turtle.png": "res://world/Arte/Friends/V47/turtle_body_00.tres",
  "res://world/Arte/Tartaruga/turtle_idle_1.png": "res://world/Arte/Friends/V47/turtle_body_00.tres",
  "res://world/Arte/Tartaruga/turtle_walk_1.png": "res://world/Arte/Friends/V47/turtle_body_02.tres",
  "res://world/Arte/Tartaruga/turtle_idle_2.png": "res://world/Arte/Friends/V47/turtle_body_01.tres",
  "res://world/Arte/Tartaruga/turtle_walk_2.png": "res://world/Arte/Friends/V47/turtle_body_03.tres",
  "res://world/Arte/Tartaruga/portrait_idle.png": "res://world/Arte/Friends/V47/turtle_portrait_neutral.tres",
  "res://world/Arte/Tartaruga/portrait_talk.png": "res://world/Arte/Friends/V47/turtle_portrait_talk.tres",
  "res://world/Arte/Amigos/urso.png": "res://world/Arte/Friends/V47/urso_body_00.tres",
  "res://world/Arte/Amigos/urso_2.png": "res://world/Arte/Friends/V47/urso_body_01.tres",
  "res://world/Arte/Amigos/mico_leao_dourado.png": "res://world/Arte/Friends/V47/mico_body_00.tres",
  "res://world/Arte/Amigos/mico_leao_dourado_2.png": "res://world/Arte/Friends/V47/mico_body_01.tres",
  "res://world/Arte/Caravan/V23/oliver_idle_v23.png": "res://world/Arte/Friends/V47/oliver_body_00.tres",
  "res://world/Arte/Caravan/V23/oliver_idle_1_v23.png": "res://world/Arte/Friends/V47/oliver_body_00.tres",
  "res://world/Arte/Caravan/V23/oliver_portrait_v23.png": "res://world/Arte/Friends/V47/oliver_portrait_neutral.tres",
  "res://world/Arte/Caravan/V23/oliver_counter_v23.png": "res://world/Arte/Friends/V47/oliver_body_06.tres"
}
static func resolve(path:String) -> String:return PATHS.get(path,path)
static func texture(path:String) -> Texture2D:return load(resolve(path))
static func ride_point(texture:Texture2D,size:Vector2) -> Vector2:return texture.get_meta("ride",texture.get_size()*Vector2(.54,.55))*size/texture.get_size()

static func bounds(texture:Texture2D) -> Rect2i:
	var rect:=texture.get_image().get_used_rect()
	if texture is AtlasTexture:rect.position+=Vector2i(texture.margin.position.round())
	return rect
