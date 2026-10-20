extends Node2D
var unlocked:=false
var _was_unlocked:=false
var _arch:AnimatedSprite2D
var _title:Label
func _ready() -> void:
	_arch=preload("res://world/Scripts/underworld_art.gd").actor("V35/portal",128)
	_arch.name="PortalSprite"
	_arch.process_mode=Node.PROCESS_MODE_ALWAYS
	add_child(_arch)
	_arch.play(&"locked")
	_arch.animation_finished.connect(func():
		if _arch.animation==&"opening" and unlocked:_arch.play(&"open")
	)
	_title=Label.new()
	_title.text="CHAVE DAS PROFUNDEZAS"
	_title.position=Vector2(-78,-137)
	_title.size=Vector2(156,20)
	_title.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	_title.add_theme_font_size_override("font_size",8)
	_title.add_theme_color_override("font_color",Color("f6cb8b"))
	_title.add_theme_color_override("font_shadow_color",Color("171321"))
	_title.add_theme_constant_override("shadow_offset_y",1)
	add_child(_title)
func _process(_delta:float) -> void:
	if unlocked!=_was_unlocked:
		_was_unlocked=unlocked
		_arch.play(&"opening" if unlocked else &"locked")
		_title.text="SAÍDA · CORPORAÇÃO" if unlocked else "CHAVE DAS PROFUNDEZAS"
		if unlocked:Sfx.checkpoint()
