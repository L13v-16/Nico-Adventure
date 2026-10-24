extends "res://world/Scripts/lab_lift.gd"
func _update_art() -> void:
	var index:=int(enabled)+int(state=="boarding")+int(state=="rising")
	if index==_state_index:return
	_state_index=index;_art.texture=preload("res://world/Scripts/Corp2D/art.gd").cell("props",1)
	_art.scale=Vector2(width/_art.texture.get_width(),.055)
	_art.position=Vector2(-width/2,0);_art.modulate=Color.WHITE if enabled else Color("586471")
