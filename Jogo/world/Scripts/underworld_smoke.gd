extends Node
## Screen-space ash banks, behind the scenery and just in front of the world.
## HUD and dialogue keep their own higher canvas layers.
const SMOKE_SHADER = preload("res://world/Scripts/underworld_smoke.gdshader")
var _clock := 0.0
var _materials: Array[ShaderMaterial] = []

func _ready() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 4107
	noise.frequency = 0.025
	noise.fractal_octaves = 3
	var texture := NoiseTexture2D.new()
	texture.width = 256
	texture.height = 128
	texture.seamless = true
	texture.generate_mipmaps = false
	texture.noise = noise
	_add_bank("DistantSmoke", -5, texture, false)
	_add_bank("ForegroundSmoke", 0, texture, true)

func _add_bank(bank_name: String, canvas_layer: int, noise: Texture2D, foreground: bool) -> void:
	var canvas := CanvasLayer.new()
	canvas.name = bank_name
	canvas.layer = canvas_layer
	add_child(canvas)
	var veil := ColorRect.new()
	veil.name = "Veil"
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var smoke := ShaderMaterial.new()
	smoke.shader = SMOKE_SHADER
	smoke.set_shader_parameter("smoke_noise", noise)
	smoke.set_shader_parameter("foreground", foreground)
	veil.material = smoke
	canvas.add_child(veil)
	_materials.append(smoke)

func _process(delta: float) -> void:
	_clock += delta
	var camera := get_viewport().get_camera_2d()
	var camera_x: float = camera.get_screen_center_position().x if camera != null else 0.0
	for smoke in _materials:
		smoke.set_shader_parameter("elapsed", _clock)
		smoke.set_shader_parameter("camera_x", camera_x)
