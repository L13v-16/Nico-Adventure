extends Area2D

@onready var anim: AnimatedSprite2D = $Anim
var collected := false
@export var cherry_id := ""
var _level_id := ""


func _ready() -> void:
	var level:Node=get_parent()
	while level!=null and not level.has_method("_build_stats"):level=level.get_parent()
	if level==null:return
	_level_id=String(level.get("level_id"))
	if cherry_id.is_empty():cherry_id="scene:"+String(level.get_path_to(self))
	if Save.is_free_mode() and Save.has_collected_cherry(_level_id,cherry_id):
		collected=true
		hide()
		set_deferred("monitoring",false)
		queue_free()

func _physics_process(delta:float) -> void:
	if collected or not monitoring:return
	var player:=get_tree().get_first_node_in_group("player") as CharacterBody2D
	if player==null or player.is_dead() or player._finished:return
	var radius:float=player.equipment.get_magnet_radius()
	if radius<=0 or global_position.distance_to(player.global_position)>radius:return
	var ray:=PhysicsRayQueryParameters2D.create(global_position,player.global_position,1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():return
	global_position=global_position.move_toward(player.global_position+Vector2(0,-3),180*delta)
	if global_position.distance_to(player.global_position)<13:_on_body_entered(player)


func _on_body_entered(body: Node2D) -> void:
	if collected or not body.is_in_group("player"):
		return
	if not body.collect_item(cherry_id,_level_id):
		return
	collected = true
	set_deferred("monitoring", false)
	anim.play("collect")
	Sfx.cherry()
	Fx.burst(global_position, Color(1.0, 0.45, 0.55), 8, 110.0)
	Fx.popup(global_position + Vector2(0.0, -14.0), "+1", Color(1.0, 0.9, 0.92), 8)


func _on_anim_animation_finished() -> void:
	if collected:
		queue_free()
