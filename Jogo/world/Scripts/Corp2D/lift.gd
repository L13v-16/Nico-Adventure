extends "res://world/Scripts/lab_lift.gd"
func _update_art() -> void:
	if _art==null:return
	_art.hide()
	if not _body.has_meta("deck"):
		var node:=Node2D.new();node.name="LiftDeck";node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
		_body.add_child(node);_body.set_meta("deck",node)
		node.draw.connect(func():preload("res://world/Scripts/Corp2D/polish_art.gd").deck(node,width,28))
	var deck:Node2D=_body.get_meta("deck");deck.position=Vector2(-width/2,0)
	deck.modulate=Color.WHITE if enabled else Color("586471");deck.queue_redraw()
func _draw() -> void:
	var kit:=preload("res://world/Scripts/Corp2D/polish_art.gd")
	for x in [-width*.38,width*.38]:
		kit.steel_post(self,Rect2(x-5,-rise-12,10,rise+24),Color("8895a3"))
		for y in [-rise-12,4.0]:kit.steel_post(self,Rect2(x-9,y,18,10))
		kit.steel_post(self,Rect2(x-8,_body.position.y-4,16,16),Color("b2bcc8"))
