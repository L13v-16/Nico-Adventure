extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
const ACCELERATION = 1500.0
const FRICTION = 2000.0

enum State { IDLE, RUN, JUMP, FALL, HURT, DIE }

var current_state: State = State.IDLE

@onready var anim: AnimatedSprite2D = $anim


func _physics_process(delta: float) -> void:
	# Aplica gravidade
	if not is_on_floor():
		velocity.y += get_gravity().y * delta
	
	# Pulo
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	if Input.is_action_just_released("ui_accept") and velocity.y < 0:
		velocity.y *= 0.5
	
	# Movimento horizontal
	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCELERATION * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, FRICTION * delta)
		
	# Atualiza o estado atual com base na física e direção
	update_state(direction)
	
	# Executa a animação correspondente ao estado atual
	play_state_animation()
	
	# Move personagem
	move_and_slide()
	
	# Função responsável por gerenciar a direção do sprite e o estado atual[cite: 1]
func update_state(direction: float) -> void:
	# Vira o sprite na direção em que o jogador está se movendo[cite: 1]
	if direction > 0:
		anim.flip_h = false
	elif direction < 0:
		anim.flip_h = true

	# Atualiza o estado conforme o movimento/física[cite: 1]
	if not is_on_floor():
		if velocity.y < 0:
			current_state = State.JUMP
		else:
			current_state = State.FALL
	else:
		if direction != 0:
			current_state = State.RUN
		else:
			current_state = State.IDLE


# Função responsável por tocar a animação baseada no current_state[cite: 1]
func play_state_animation() -> void:
	if not anim:
		return

	match current_state:
		State.IDLE:
			anim.play("idle")
		State.RUN:
			anim.play("run")
		State.JUMP:
			anim.play("jump")
		State.FALL:
			anim.play("fall")
		State.HURT:
			anim.play("hurt")
		State.DIE:
			anim.play("die")
