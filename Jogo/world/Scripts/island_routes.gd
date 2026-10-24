extends RefCounted
## One campaign order shared by the travel scene and the free-mode map.
const MAP_SCENE := "res://world/island_map.tscn"
const ISLANDS := [
	{"id":"fase_1", "name":"Floresta", "full":"Vale das Copas", "friend":"Arara Minas", "scene":"res://world/word_01.tscn", "cell":0, "rect":Rect2(34,78,100,90)},
	{"id":"fase_2", "name":"Praia", "full":"Costa das Marés", "friend":"Tartaruga", "scene":"res://world/beach_02.tscn", "cell":1, "rect":Rect2(158,141,100,90)},
	{"id":"fase_3", "name":"Floresta mágica", "full":"Floresta Violeta", "friend":"Remi", "scene":"res://world/magic_03.tscn", "cell":2, "rect":Rect2(262,76,104,92)},
	{"id":"fase_4", "name":"Submundo", "full":"As Profundezas", "friend":"José", "scene":"res://world/underworld_04.tscn", "cell":3, "rect":Rect2(314,232,102,88)},
	{"id":"fase_5", "name":"Laboratório", "full":"Laboratório dos Executivos", "friend":"Urso", "scene":"res://world/lab_05.tscn", "cell":4, "rect":Rect2(417,76,106,96)},
	{"id":"fase_6", "name":"Corporação", "full":"A Corporação do Mal", "friend":"Todos os amigos", "scene":"res://world/corporation_06.tscn", "cell":5, "rect":Rect2(522,144,100,94)},
]

static func index_of_id(id: String) -> int:
	for index in ISLANDS.size():
		if ISLANDS[index].id == id:return index
	return -1

static func index_of_scene(scene: String) -> int:
	for index in ISLANDS.size():
		if ISLANDS[index].scene == scene:return index
	return -1

static func point(index: int) -> Vector2:
	var rect: Rect2 = ISLANDS[index].rect
	return rect.position + rect.size * Vector2(.5,.42)

static func travel(tree: SceneTree, source_id: String, destination: String, skip_intro: bool) -> Error:
	var source := index_of_id(source_id)
	var target := index_of_scene(destination)
	if source < 0 or target != source + 1:return ERR_INVALID_PARAMETER
	var save: Node = tree.root.get_node("Save")
	# The travellers aim for the laboratory. The existing sky-attack cinematic
	# then explains their unplanned arrival in the underworld below the islands.
	var intercepted: bool = source == 2 and target == 3 and not save.is_free_mode()
	save.pending_island_trip = {"source":source, "target":target, "planned":4 if intercepted else target, "skip_intro":skip_intro, "free":save.is_free_mode(), "intercepted":intercepted}
	var error := tree.change_scene_to_file(MAP_SCENE)
	if error != OK:save.pending_island_trip.clear()
	return error
