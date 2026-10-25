extends RefCounted
## Illustration rewards only: fragments are never spent.
const ENTRIES := [
	{"id":"picnic","title":"Cerejas para todos","need":1,"text":"Nico, Remi e Tartaruga dividem um piquenique ao pé da casa na árvore."},
	{"id":"beach","title":"Castelos e marés","need":3,"text":"Arara Minas traz a bandeirinha. Tartaruga e Nico cuidam do castelo."},
	{"id":"stargazing","title":"Só mais uma estrela","need":6,"text":"Urso monta o telescópio; Remi e Nico descobrem desenhos no céu."},
	{"id":"kite","title":"Vento de liberdade","need":9,"text":"José corre com a pipa enquanto Minas ensina o caminho do vento."},
	{"id":"market","title":"Por conta da casa","need":12,"text":"Oliver Gancho abre a caravana para um lanche com Nico e Mico."},
	{"id":"festival","title":"Nossa própria festa","need":18,"text":"Sem plateia nem contratos: os amigos fazem música só por diversão."},
]
static func unlocked_count(fragments:int) -> int:
	var count:=0
	for entry in ENTRIES:
		if fragments>=int(entry.need):count+=1
	return count
static func image_path(index:int) -> String:return "res://world/Arte/MemoriesV96/"+("market-v2" if index==4 else str(ENTRIES[index].id))+".png"
