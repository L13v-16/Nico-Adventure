extends StaticBody2D
## A mesma caixa física e visual define cada ilha; os pés dos props usam seu topo.
@export var width := 320.0
@export var depth := 480.0
@export var one_way := false
const TILE := preload("res://world/Arte/Tiles/forest_terrain_v2.png")

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(width, depth)
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = Vector2(width * 0.5, depth * 0.5)
	collider.one_way_collision = one_way
	collider.one_way_collision_margin = 8.0
	add_child(collider)
	var art := Node2D.new()
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://world/Scripts/magic_terrain.gdshader")
	art.material = ink
	art.draw.connect(_paint.bind(art))
	add_child(art)

func _paint(art: Node2D) -> void:
	for x in range(0, int(width), 16):
		for y in range(0, int(depth), 16):
			var tile_y := 0 if y == 0 else 16 + (int(y / 16) % 2) * 16
			var tile_x := (int(x / 16) + int(y / 16) * 3) % 4 * 16
			art.draw_texture_rect_region(TILE, Rect2(x,y,minf(16,width-x),minf(16,depth-y)), Rect2(tile_x,tile_y,minf(16,width-x),minf(16,depth-y)))
	art.draw_rect(Rect2(0,3,2,depth-3),Color("261c41"))
	art.draw_rect(Rect2(width-2,3,2,depth-3),Color("261c41"))
