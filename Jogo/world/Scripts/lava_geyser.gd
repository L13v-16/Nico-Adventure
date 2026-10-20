extends Node2D
@export var launch_geyser:=false
@export var phase:=0.0
var cycle:=0.0
var state:="dormant"
var _launched:=0.0
var _sprite:Sprite2D
const Art=preload("res://world/Scripts/underworld_art.gd")
const LAVA=preload("res://world/Arte/Underworld/V35/lava.tres")
func _ready() -> void:
	add_to_group("lava_geysers")
	cycle=phase
	_sprite=Art.prop(0,Vector2(52,15),Vector2(-26,-9))
	add_child(_sprite)
func _physics_process(delta:float) -> void:
	cycle=fposmod(cycle+delta,4.8)
	_launched=maxf(0,_launched-delta)
	var next:="dormant" if cycle<2.2 else ("warning" if cycle<3.45 else ("erupting" if cycle<4.25 else "cooling"))
	if next!=state:
		state=next
		var index:=0 if state=="dormant" else (1 if state=="warning" else (2 if state=="erupting" else 3))
		_sprite.texture=load(Art.ROOT+"prop_%02d.tres"%index)
		var size:=Vector2(48,112) if state=="erupting" else Vector2(52,15)
		_sprite.scale=size/_sprite.texture.get_size()
		_sprite.position=Vector2(-size.x/2,-size.y+6)
		if state=="warning":Sfx.alert()
	_sprite.position.x=roundf(-24+sin(cycle*65)*1.5) if state=="warning" else (-24 if state=="erupting" else -26)
	if state=="erupting":
		_sprite.texture=LAVA.get_frame_texture(&"jet",int(cycle*9)%4)
		_sprite.scale=Vector2(48,112)/_sprite.texture.get_size()
		var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
		if player!=null and not player.is_dead() and absf(player.position.x-position.x)<23 and player.position.y+11>position.y-107 and player.position.y<position.y+9:
			if launch_geyser and _launched<=0:
				_launched=0.7
				player.launch_from_spring(650)
				Fx.burst(player.position,Color("ffd485"),10,100)
			elif not launch_geyser and player.elements.temporary_fire<=0:player.take_damage(1,position)
	queue_redraw()
func _draw() -> void:
	if launch_geyser:
		draw_rect(Rect2(-6,7,12,3),Color("86e0ed"))
		draw_line(Vector2(0,4),Vector2(0,-12),Color("b5f3f5"),2)
		draw_line(Vector2(0,-12),Vector2(-4,-7),Color("b5f3f5"),2)
		draw_line(Vector2(0,-12),Vector2(4,-7),Color("b5f3f5"),2)
	if state=="warning":
		for i in 8:
			var t:=fposmod(cycle*1.5+float(i)/8,1.0)
			draw_rect(Rect2(roundf(sin(i*2.3)*18),roundf(-t*35),2,2),Color("ffca77"))
