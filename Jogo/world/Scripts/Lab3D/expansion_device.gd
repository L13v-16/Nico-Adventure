extends Node3D
## Persistent, physical interactions for the longer laboratory route.
## Progress lives on these room nodes; no extra save currency or farming rewards.
const Art = preload("res://world/Scripts/Lab3D/models.gd")
var level: Node3D
var sector := 0
var kind := "power_cell"
var circuit := ""
var active := false
var phase := 0
var frozen_left := 0.0
var destination := 0
var width := -1.0
var depth := -1.0
var height := 4.5
var push_direction := Vector3.RIGHT
var push_strength := 3.0
var secret_record := false
var record_text := "Registro de pesquisa: LG-17 mantém estáveis os enxertos de Largato."
var inserted: Node3D
var carried := false
var collected := false
var _body: PhysicsBody3D
var _art: Node3D
var _moving: Node3D
var _label: Label3D
var _light: MeshInstance3D
var _ice: MeshInstance3D
var _rotor: Node3D
var _beam: MeshInstance3D
var _home := Transform3D.IDENTITY
var _clock := 0.0
var _scan_state := 0
var _scan_timer := 2.4
var _scan_fired := 0
var _locked_aim := Vector3.ZERO
var _socket: Node3D

func _ready() -> void:
	add_to_group("lab3d_expansion")
	_home = global_transform
	if width <= 0:
		width = 24.0 if kind == "blast_gate" else 4.0
	if depth <= 0:
		depth = .6 if kind == "blast_gate" else (10.0 if kind == "ventilation_fan" else 16.0)
	if ResourceLoader.exists("res://world/Models/Lab3D/" + kind + ".tscn"):
		_art = Art.instantiate(kind)
	else:
		var factory: Script = load("res://world/Scripts/Lab3D/expansion_models.gd")
		_art = factory.make(kind, Art)
	_art.name = "ExpansionArt"
	add_child(_art)
	if kind in ["power_socket", "thermal_relay", "archive_console", "security_scanner", "ventilation_fan", "blast_gate"]:
		_art.rotation.y = PI
	match kind:
		"power_cell":
			_body = _shape(Vector3(.58, .84, .52), Vector3(0, .43, 0), 1)
			_label = _make_label("E · PEGAR CÉLULA", 1.9)
		"power_socket":
			_body = _shape(Vector3(1.5, 1.15, 1.3), Vector3(0, .575, 0), 1)
			_label = _make_label("E · INSERIR CÉLULA", 2.25)
			_light = Art.ball(self, "PowerStatus", Vector3(0, 1.15, .7), Vector3(.22, .22, .13), "e5ae69", .6)
		"thermal_relay":
			_body = _shape(Vector3(1.65, 1.83, 1.1), Vector3(0, .915, 0), 17)
			add_to_group("lab3d_targets")
			_label = _make_label("1 · FOGO  →  2 · GELO", 3.0)
			_light = Art.ball(self, "ThermalStatus", Vector3(0, 1.8, .72), Vector3(.25, .25, .13), "f0ae68", .7)
		"piston_bridge":
			_body = _shape(Vector3(width, .35, depth), Vector3(0, -.175, 0), 1, true)
			_body.name = "BridgeBody"
			_moving = _body
			remove_child(_art)
			_body.add_child(_art)
			_art.scale = Vector3(width / 4.0, 1.0, depth / 16.0)
			_body.position.y = 0.0 if active else -3.0
			for side in [-1.0, 1.0]:
				Art.box(self, "PistonGuide", Vector3(side * (width * .5 + .25), -1.6, 0), Vector3(.2, 3.4, depth + .5), "304c5e", .5)
				Art.box(self, "GuideStrip", Vector3(side * (width * .5 + .25), .12, 0), Vector3(.16, .1, depth + .5), "d5b473", .3, .2)
			_label = _make_label("PONTE · SEM ENERGIA", 1.1)
		"ventilation_fan":
			_body = _shape(Vector3(2.1, 2.6, 1.4), Vector3(0, 1.3, 0), 16)
			add_to_group("lab3d_targets")
			_label = _make_label("GELO · PARAR VENTILAÇÃO", 3.2)
			_rotor = _art.find_child("Rotors", true, false) as Node3D
			_ice = _freeze_shell(Vector3(0, 1.35, 0), Vector3(2.35, 2.7, 1.6))
		"security_scanner":
			_body = _shape(Vector3(1.6, 2.4, 1.3), Vector3(0, 1.3, 0), 16)
			add_to_group("lab3d_targets")
			_label = _make_label("ESCÂNER · GELO DESATIVA", 3.1)
			_light = Art.ball(self, "ScanStatus", Vector3(0, 1.8, .72), Vector3(.18, .18, .1), "79ceda", .6)
			_beam = Art.box(self, "LockedWarning", Vector3.ZERO, Vector3(.08, .08, 1), "f3bd64", 0, .7)
			_beam.hide()
			_ice = _freeze_shell(Vector3(0, 1.3, 0), Vector3(1.9, 2.7, 1.6))
		"archive_console":
			_body = _shape(Vector3(1.65, 1.7, 1.2), Vector3(0, .85, 0), 1)
			_label = _make_label("E · LER ARQUIVO", 2.8)
		"blast_gate":
			_body = _shape(Vector3(width, height, maxf(depth, .65)), Vector3(0, height * .5, 0), 1, true)
			_body.name = "GateBody"
			_moving = _body
			_art.scale = Vector3(width / 24.0, height / 4.5, 1.0)
			var panels := _art.find_child("GatePanels", true, false) as Node3D
			if panels != null:
				panels.reparent(_body, true)
			_body.position.y = height + .65 if active else 0.0
			_label = _make_label("PORTÃO · SEM ENERGIA", height + .45)
			for side in [-1.0, 1.0]:
				Art.box(self, "GateGuide", Vector3(side * (width * .5 + .12), height * .5, 0), Vector3(.24, height + .4, .8), "355364", .5)
	if active:
		phase = 2
	_update_labels()

func _make_label(text: String, y: float) -> Label3D:
	var label := Art.label(self, text, Vector3(0, y, .15), 25, "f2dfaf")
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return label

func _shape(size: Vector3, at: Vector3, layer: int, moving := false) -> PhysicsBody3D:
	var body: PhysicsBody3D = AnimatableBody3D.new() if moving else StaticBody3D.new()
	body.collision_layer = layer
	body.collision_mask = 0
	body.set_meta("receiver", self)
	add_child(body)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position = at
	body.add_child(collision)
	return body

func _freeze_shell(at: Vector3, size: Vector3) -> MeshInstance3D:
	var shell := Art.box(self, "FreezeShell", at, size, "a1e8ef")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.55, .9, 1.0, .24)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.roughness = .15
	material.emission_enabled = true
	material.emission = Color("6cbac9")
	material.emission_energy_multiplier = .15
	shell.material_override = material
	shell.hide()
	return shell

func _physics_process(delta: float) -> void:
	if not is_instance_valid(level) or sector != level.sector or level.intro_active or level.completed:
		return
	_clock += delta
	frozen_left = maxf(0.0, frozen_left - delta)
	var player: CharacterBody3D = level.player
	if kind == "power_cell":
		if carried:
			if not is_instance_valid(player) or level.carried_cell != self:
				reset_carry()
			else:
				global_position = player.global_position + player.forward * .65 + Vector3.UP * .70
				global_rotation.y = atan2(-player.forward.x, -player.forward.z)
		elif is_instance_valid(_socket):
			global_position = _socket.global_position + Vector3(0, .75, 0)
	elif kind == "piston_bridge":
		_body.position.y = move_toward(_body.position.y, 0.0 if active else -3.0, 2.5 * delta)
	elif kind == "blast_gate":
		_body.position.y = move_toward(_body.position.y, height + .65 if active else 0.0, 4.0 * delta)
	elif kind == "ventilation_fan":
		if is_instance_valid(_rotor) and frozen_left <= 0:
			_rotor.rotation.z += delta * 12.0
		var relative: Vector3 = to_local(player.global_position)
		if frozen_left <= 0 and absf(relative.x) < width * .5 and absf(relative.z) < depth * .5 and relative.y > -.7 and relative.y < 3.5:
			# Move against real collision surfaces rather than teleporting through cover.
			player.move_and_collide(push_direction.normalized() * push_strength * delta)
	elif kind == "security_scanner":
		_tick_scanner(delta, player)
	if _ice != null:
		_ice.visible = frozen_left > 0
	_update_labels()

func _tick_scanner(delta: float, player: CharacterBody3D) -> void:
	if frozen_left > 0:
		_beam.hide()
		_scan_state = 0
		_scan_timer = 1.2
		_scan_fired = 0
		return
	_scan_timer -= delta
	if _scan_state == 0:
		_beam.hide()
		if _scan_timer <= 0:
			if player.global_position.distance_to(global_position)>16.0:
				_scan_timer=.35
				return
			var line:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP*1.6,player.global_position+Vector3.UP,1)
			line.exclude=[_body.get_rid()]
			if not get_world_3d().direct_space_state.intersect_ray(line).is_empty():
				_scan_timer=.35
				return
			_locked_aim = player.global_position + Vector3.UP
			_scan_state = 1
			_scan_timer = .9
			_scan_fired = 0
			Sfx.play("lab_scan", -15)
	elif _scan_state == 1:
		_warning_line()
		if _scan_timer <= 0:
			_scan_state = 2
			_scan_timer = .7
	else:
		_warning_line()
		var elapsed := .7 - _scan_timer
		while _scan_fired < 3 and elapsed >= float(_scan_fired) * .23:
			var start: Vector3 = global_position + Vector3.UP * 1.6
			var direction: Vector3 = (_locked_aim - start).normalized().rotated(Vector3.UP, deg_to_rad(float(_scan_fired - 1) * 7.0))
			# Muzzle lies outside the target-only collider, so darts cannot hit their source.
			start += direction * 1.3
			level.enemy_shot(start, start + direction * 24.0, 12.0, _body)
			_scan_fired += 1
		if _scan_timer <= 0:
			_scan_state = 0
			_scan_timer = 2.4
			_beam.hide()

func _warning_line() -> void:
	var start: Vector3 = global_position + Vector3.UP * .13
	var target := Vector3(_locked_aim.x, start.y, _locked_aim.z)
	var distance := start.distance_to(target)
	if distance < .1:
		_beam.hide()
		return
	_beam.show()
	_beam.global_position = start.lerp(target, .5)
	_beam.scale.z = distance
	_beam.look_at(target, Vector3.UP)
	var direction: Vector3 = _locked_aim - global_position
	if Vector2(direction.x, direction.z).length() > .1:
		_art.rotation.y = atan2(-direction.x, -direction.z)

func aim_point() -> Vector3:
	return global_position + Vector3.UP * (1.7 if kind == "thermal_relay" else 1.4)

func accepts(element: String) -> bool:
	if kind == "thermal_relay":
		return not active and ((phase == 0 and element == "fire") or (phase == 1 and element == "ice"))
	if kind in ["ventilation_fan", "security_scanner"]:
		return element == "ice" and frozen_left <= 0
	return false

func take_element(element: String, _source: Vector3, _seconds := 3.0) -> void:
	if not accepts(element):
		return
	if kind == "thermal_relay":
		if phase == 0:
			phase = 1
			level.notice("Relé aquecido. Agora use GELO para estabilizar o circuito.")
			level.spark(aim_point(), "f6b26f")
		else:
			phase = 2
			active = true
			activate_circuit()
			level.notice("FOGO → GELO: circuito estável. A passagem foi liberada.")
			level.spark(aim_point(), "8de5c3")
		Sfx.play("lab_clink", -9)
	else:
		frozen_left = 8.0
		_scan_state = 0
		_scan_timer = 1.2
		_scan_fired = 0
		level.spark(aim_point(), "9ce6ed")
		level.notice("Ventilação congelada por 8 segundos." if kind == "ventilation_fan" else "Escâner congelado por 8 segundos. Passe agora!")
		Sfx.play("lab_clink", -12)
	_update_labels()

func interact() -> bool:
	match kind:
		"power_cell":
			if is_instance_valid(_socket):
				return false
			if carried:
				drop()
				level.notice("Célula deixada no chão. E para pegar novamente.")
			elif is_instance_valid(level.carried_cell):
				level.notice("Nico já está carregando uma célula.")
			else:
				carried = true
				level.carried_cell = self
				_body.collision_layer = 0
				level.notice("Leve a célula até o encaixe iluminado. E para inserir.")
			Sfx.play("lab_clink", -12)
			return true
		"power_socket":
			if active:
				level.notice("Célula conectada. O circuito continua ligado.")
			elif not is_instance_valid(level.carried_cell):
				level.notice("Traga uma célula de energia. E pega e encaixa a célula.")
			else:
				var cell: Node3D = level.carried_cell
				if cell.sector != sector or (cell.circuit != "" and cell.circuit != circuit):
					level.notice("Esta célula pertence a outro circuito.")
					return true
				inserted = cell
				cell.carried = false
				cell._socket = self
				cell.active = true
				cell._body.collision_layer = 0
				cell.reparent(self, true)
				cell.global_position = global_position + Vector3.UP * .75
				level.carried_cell = null
				active = true
				activate_circuit()
				level.spark(global_position + Vector3.UP * 1.5, "8ee2bf")
				level.notice("Célula conectada. Portão e ponte energizados!")
				Sfx.checkpoint()
			_update_labels()
			return true
		"thermal_relay":
			level.notice(hint())
			return true
		"blast_gate":
			level.notice("Passagem liberada." if active else "Portão fechado: conecte a célula ou estabilize o relé deste setor.")
			return true
		"archive_console":
			var images:Array={4:[["forest","VALE DAS COPAS"],["beach","COSTA DAS MARÉS"]],5:[["magic","FLORESTA VIOLETA"],["underworld","SUBMUNDO"]],6:[["lab","LABORATÓRIO DOS EXECUTIVOS"]]}.get(sector,[["lab","LABORATÓRIO DOS EXECUTIVOS"]])
			level.show_archive({4:"LOGÍSTICA · ROTAS DE CAPTURA",5:"PESQUISA · BIOTERMIA",6:"PESQUISA · LG-17"}.get(sector,"ARQUIVO DE PESQUISA"),record_text,images)
			if secret_record and not collected and Save.collect_fragment("fase_5","archive:%d:%s"%[sector,str(position)]):
				collected = true
				level.secrets_found += 1
				Sfx.checkpoint()
				level.spark(aim_point(), "e4c47a")
			active = true
			_update_labels()
			return true
	return false

func activate_circuit() -> void:
	if circuit.is_empty():
		return
	for device in get_tree().get_nodes_in_group("lab3d_expansion"):
		if device != self and device.sector == sector and device.circuit == circuit and device.kind in ["piston_bridge", "blast_gate"]:
			device.active = true
			device.phase = 2
			device._update_labels()

func drop(reset_to_home := false) -> void:
	if not carried:
		return
	carried = false
	if level.carried_cell == self:
		level.carried_cell = null
	if reset_to_home:
		global_transform = _home
	else:
		# Snap onto actual floor beneath the carried cell. If dropped over a gap,
		# return it to its initial safe pickup position instead of losing the puzzle.
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * .4, global_position - Vector3.UP * 5, 1)
		query.exclude = [_body.get_rid()]
		var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.normal.y > .65:
			global_position = hit.position + Vector3.UP * .025
			var overlap := PhysicsShapeQueryParameters3D.new()
			overlap.shape = _body.get_child(0).shape
			overlap.transform = Transform3D(Basis.IDENTITY, global_position + Vector3.UP * .43)
			overlap.collision_mask = 1
			overlap.exclude = [_body.get_rid()]
			if not get_world_3d().direct_space_state.intersect_shape(overlap, 1).is_empty():
				global_transform = _home
		else:
			global_transform = _home
	_body.collision_layer = 1
	_update_labels()

func reset_carry() -> void:
	# Transition/death may call this unconditionally; installed cells stay installed.
	if carried:
		drop(true)

func hint() -> String:
	match kind:
		"power_cell":
			return "" if is_instance_valid(_socket) else ("E: soltar célula · leve ao encaixe" if carried else "E: pegar célula de energia")
		"power_socket":
			return "Célula conectada · circuito ativo" if active else "E: encaixar célula de energia"
		"thermal_relay":
			return "Relé estabilizado · passagem liberada" if active else ("Q: GELO · K: estabilizar o relé aquecido" if phase == 1 else "Q: FOGO · K: aquecer o relé")
		"piston_bridge":
			return "A ponte está subindo: aguarde a plataforma chegar." if active and _body.position.y < -.08 else ("Ponte pronta para atravessar" if active else "A ponte precisa de energia do circuito")
		"ventilation_fan":
			return "Ventilação congelada · %.0fs para atravessar" % ceilf(frozen_left) if frozen_left > 0 else "Vento lateral · K com GELO interrompe a ventilação"
		"security_scanner":
			return "Escâner congelado · %.0fs para atravessar" % ceilf(frozen_left) if frozen_left > 0 else "Linha laranja: saia da mira · GELO desativa o escâner"
		"archive_console":
			return "E: reler registro" if active else "E: ler registro de pesquisa"
		"blast_gate":
			return "Portão energizado · passagem liberada" if active else "Conecte a célula ou estabilize o relé para abrir"
	return ""

func _update_labels() -> void:
	if _label == null:
		return
	match kind:
		"power_cell":
			_label.visible = not carried and not is_instance_valid(_socket)
		"power_socket":
			_label.text = "CIRCUITO CONECTADO" if active else "E · INSERIR CÉLULA"
			_light.material_override = Art.material("8ee2bf" if active else "e5ae69", 0, .6)
		"thermal_relay":
			_label.text = "FOGO ✓  GELO ✓" if active else ("FOGO ✓  →  AGORA GELO" if phase == 1 else "1 · FOGO  →  2 · GELO")
			_light.material_override = Art.material("8ee2bf" if active else ("8bdce9" if phase == 1 else "f0ae68"), 0, .7)
		"piston_bridge":
			_label.text = ("PONTE SUBINDO" if _body.position.y < -.08 else "PONTE PRONTA") if active else "PONTE · SEM ENERGIA"
		"blast_gate":
			_label.text = "PASSAGEM LIBERADA" if active else "PORTÃO · SEM ENERGIA"
		"ventilation_fan":
			_label.text = ("DESCONGELANDO!" if frozen_left < 2 else "GELO · VENTO PARADO") if frozen_left > 0 else "GELO · PARAR VENTILAÇÃO"
		"security_scanner":
			_label.text = ("DESCONGELANDO!" if frozen_left < 2 else "ESCÂNER CONGELADO") if frozen_left > 0 else ("SAIA DA LINHA!" if _scan_state != 0 else "ESCÂNER · GELO DESATIVA")
			_light.material_override = Art.material("9ce6ed" if frozen_left > 0 else ("edac63" if _scan_state != 0 else "79ceda"), 0, .6)
		"archive_console":
			_label.text = "ARQUIVO LIDO · E" if active else "E · LER ARQUIVO"
	_label.modulate = Color("9de7c8") if active else Color("f2dfaf")
