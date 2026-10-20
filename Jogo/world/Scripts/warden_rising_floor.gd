extends AnimatableBody2D
## Toda a arena sobe. O movimento físico transporta Nico e José sem saltos.
const Tiles=preload("res://world/Scripts/underworld_tiles.gd")
const WIDTH:=1008.0
const WAIT:=2.0
const TRAVEL:=16.0
var boss:CharacterBody2D
func _ready() -> void:
	sync_to_physics=false
	name="RisingArenaFloor"
	process_physics_priority=-20
	collision_layer=1
	collision_mask=0
	position=Vector2(6456,floor_height())
	var shape:=RectangleShape2D.new()
	shape.size=Vector2(WIDTH,96)
	var collider:=CollisionShape2D.new()
	collider.shape=shape
	collider.position=Vector2(WIDTH/2,48)
	add_child(collider)
	reset_physics_interpolation()
	sync_to_physics=true
	z_index=1
func floor_height() -> float:
	if boss.phase>=3:return boss.UPPER_FLOOR
	return lerpf(100,boss.UPPER_FLOOR,smoothstep(WAIT,WAIT+TRAVEL,boss._phase_time))
func _physics_process(_delta:float) -> void:
	position.y=floor_height()
func _draw() -> void:
	draw_rect(Rect2(0,0,WIDTH,96),Color("211e30"))
	for x in range(0,int(WIDTH),32):
		for y in range(0,96,32):
			Tiles.tile(self,Rect2(x,y,minf(32,WIDTH-x),32),int(x/32)%4 if y==0 else 4+(int(x/32)+int(y/32))%4)
