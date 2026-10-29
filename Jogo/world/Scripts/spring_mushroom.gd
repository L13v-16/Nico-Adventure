extends Node2D
signal bounced(player: CharacterBody2D)
@export var launch_speed := 680.0
const Art := preload("res://world/Scripts/magic_art.gd")
const CAP_Y := -26.0
var _sprite: AnimatedSprite2D
var _cooldown := 0.0

func _ready() -> void:
	add_to_group("spring_mushrooms")
	process_physics_priority = 10
	_sprite = Art.prop(&"idle",56)
	add_child(_sprite)
	_sprite.animation_finished.connect(func(): _sprite.play(&"idle"))
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(44,6)
	collider.shape = shape
	collider.position.y = CAP_Y+3
	collider.one_way_collision = true
	body.add_child(collider)
	add_child(body)

func _physics_process(delta: float) -> void:
	_cooldown = maxf(0,_cooldown-delta)
	var player := get_tree().get_first_node_in_group("player") as CharacterBody2D
	if _cooldown > 0 or not is_instance_valid(player) or player.is_dead(): return
	var feet := player.global_position.y + 11
	var cap := global_position.y + CAP_Y
	if absf(player.global_position.x-global_position.x) < 26 and player.velocity.y >= 0 and feet >= cap-5 and feet <= cap+10:
		launch(player)

func launch(player: CharacterBody2D) -> void:
	if _cooldown > 0 or player.is_dead(): return
	_cooldown = 0.22
	player.global_position.y = global_position.y+CAP_Y-12
	player.launch_from_spring(launch_speed)
	_sprite.play(&"bounce")
	Fx.burst(global_position+Vector2(0,CAP_Y),Color("ffadb4"),12,120)
	Sfx.jump()
	bounced.emit(player)
