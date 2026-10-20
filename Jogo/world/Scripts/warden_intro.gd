extends CanvasLayer
## Short, skippable entrance. Owns the pause and restores it on scene disposal.
var boss: CharacterBody2D
var _clock := 0.0
var _done := false
var _impact := false
var _canvas: Control
var _level: Node2D
var _hud_visible := true
var _old_offset := Vector2.ZERO
var _old_zoom := Vector2.ONE
var _old_smoothing := true
var _old_timing := true
var _old_pause := false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 80
	_level = boss.get_parent()
	_old_pause = get_tree().paused
	_old_timing = _level._timing
	_hud_visible = _level.get_node("HUD").visible
	_level.get_node("HUD").hide()
	_level.intro_active = true
	_level._timing = false
	_level.pause_menu.can_open = false
	var camera: Camera2D = boss._player.get_node("Camera2D")
	_old_offset = camera.offset
	_old_zoom = camera.zoom
	_old_smoothing = camera.position_smoothing_enabled
	camera.position_smoothing_enabled = false
	get_tree().paused = true
	Sfx.begin_dialogue_music(self)
	Sfx.play("warden_roar", -5)
	boss._bar.hide()
	_canvas = Control.new()
	_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas.draw.connect(_draw_scene)
	add_child(_canvas)

func _process(delta: float) -> void:
	if _done: return
	_clock += delta
	var camera: Camera2D = boss._player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * lerpf(0.92, 1.12, smoothstep(0.0, 2.3, _clock))
	camera.offset = Vector2(7040, 20) - boss._player.position
	camera.force_update_scroll()
	boss.position.x = lerpf(7245, 7100, smoothstep(0.0, 1.5, _clock))
	boss._sprite.modulate = Color.WHITE * lerpf(0.35, 1.0, minf(_clock / 1.2, 1.0))
	boss._sprite.modulate.a = 1.0
	boss._sprite.play(&"walk" if _clock < 1.5 else (&"windup" if _clock < 2.3 else (&"slam" if _clock < 2.8 else &"guard")))
	if _clock >= 2.3 and not _impact:
		_impact = true
		Sfx.play("warden_slam", -3)
		Fx.burst(boss.position, Color("d3a67b"), 24, 160)
	_canvas.queue_redraw()
	if _clock >= 5.0: finish()

func _unhandled_input(event: InputEvent) -> void:
	if _clock < 0.3: return
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("ui_cancel") or event.is_action_pressed("interagir"):
		get_viewport().set_input_as_handled()
		finish()

func finish() -> void:
	if _done: return
	_done = true
	_restore()
	queue_free()

func _restore() -> void:
	# Scene changes may remove the level before this child exits.
	if get_tree() != null: get_tree().paused = _old_pause
	if not is_instance_valid(_level) or not _level.is_inside_tree(): return
	_level.intro_active = false
	_level._timing = _old_timing
	_level.pause_menu.can_open = true
	_level.get_node("HUD").visible = _hud_visible
	if is_instance_valid(boss):
		boss.position = Vector2(7100, 100)
		boss._sprite.modulate = Color.WHITE
		boss._sprite.play(&"guard")
		boss._timer = 1.4
		boss._bar.show()
		var camera: Camera2D = boss._player.get_node("Camera2D")
		camera.offset = _old_offset
		camera.zoom = _old_zoom
		camera.position_smoothing_enabled = _old_smoothing
	Sfx.end_dialogue_music(self)

func _exit_tree() -> void:
	if not _done: _restore()

func _draw_scene() -> void:
	_canvas.draw_rect(Rect2(0, 0, 640, 30), Color("100e19"))
	_canvas.draw_rect(Rect2(0, 278, 640, 82), Color("100e19"))
	if _clock >= 1.8:
		_canvas.draw_string(ThemeDB.fallback_font, Vector2(32, 306), "O CARCEREIRO DAS PROFUNDEZAS", HORIZONTAL_ALIGNMENT_CENTER, 576, 19, Color("ffd398"))
		_canvas.draw_string(ThemeDB.fallback_font, Vector2(28, 329), "\"A chave pertence a quem quebrar minhas correntes.\"", HORIZONTAL_ALIGNMENT_CENTER, 584, 12, Color("e5d4d1"))
	_canvas.draw_string(ThemeDB.fallback_font, Vector2(30, 20), "GUARDIÃO DA CHAVE", HORIZONTAL_ALIGNMENT_LEFT, 400, 10, Color("bba8ba"))
	_canvas.draw_string(ThemeDB.fallback_font, Vector2(420, 350), "Enter / E / Esc: pular", HORIZONTAL_ALIGNMENT_RIGHT, 190, 9, Color("bba8ba"))
	if _clock > 2.3 and _clock < 2.55:
		_canvas.draw_rect(Rect2(0, 30, 640, 248), Color(1.0, 0.64, 0.32, (2.55 - _clock) * 0.65))
