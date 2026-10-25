extends StaticBody2D
## Hand-authored rolling route; both damage and freezing use the normal attack API.
var path:PackedVector2Array
var target:=1
var speed:=108.0
var frozen:=0.0
var level:Node2D
var _spin:=0.0
var _art:Sprite2D
var _dead:=false
func _ready() -> void:
	add_to_group("corp_shots");add_to_group("enemies");collision_layer=4;collision_mask=0;z_index=5
	position=path[0]
	var shape:=CollisionShape2D.new();var circle:=CircleShape2D.new();circle.radius=9;shape.shape=circle;add_child(shape)
	_art=Sprite2D.new();_art.texture=preload("res://world/Arte/Magic/V26/barrel.tres");_art.scale=Vector2.ONE*(21.0/_art.texture.get_width());_art.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST;add_child(_art)
func _physics_process(delta:float) -> void:
	if _dead or level.intro_active or level.completed:return
	if frozen>0:frozen=maxf(0,frozen-delta);_art.modulate=Color("9bdfff");return
	_art.modulate=Color.WHITE
	var before:=position;var remaining:=speed*delta
	while remaining>0 and target<path.size():
		var distance:=position.distance_to(path[target])
		if remaining>=distance:position=path[target];target+=1;remaining-=distance
		else:position=position.move_toward(path[target],remaining);remaining=0
	_spin-=delta*5;_art.rotation=_spin
	if target>=path.size():queue_free();return
	var center:Vector2=level.player.position+Vector2(0,-4)
	if Geometry2D.get_closest_point_to_segment(center,before,position).distance_to(center)<17 and not level.player.is_dead():
		level.player.take_damage(1,position);take_damage(1,center)
func take_damage(_amount:float,_source:Vector2) -> void:
	if _dead:return
	_dead=true;collision_layer=0;Fx.burst(position,Color("dcb88a"),9,90);Sfx.play("lab_clink",-17);queue_free()
func take_element(element:String,source:Vector2) -> void:
	if element=="ice":frozen=3.5
	else:take_damage(1,source)
func freeze_for(seconds:float) -> void:frozen=maxf(frozen,seconds)
func is_dead() -> bool:return _dead
