extends CharacterBody2D
@onready var timer: Timer = $timer

@export_group("Enemy Properties")
@export var speed: float = 100.0
@export var health: int = 1

var direction : int = -1

@onready var anim: AnimatedSprite2D = $anim

func _ready() -> void:
	timer.timeout.connect(_on_timer_time_out)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
		
		velocity.x = speed*direction
		
		if direction > 0:
			anim.flip_h = true
		else:
			anim.flip_h = false
			
		
	move_and_slide()

func _on_timer_time_out():
	direction *= -1
