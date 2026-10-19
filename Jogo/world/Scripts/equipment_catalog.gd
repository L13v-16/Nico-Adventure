extends RefCounted
## Dados compartilhados pela mochila, pelo modelo de equipamentos e pela loja.
## Ícones são opcionais até a arte terminar de importar.

const ORDER := ["claws", "sneakers", "leaf", "frozen_acai", "lasting_ice", "straw_hat", "sunglasses", "cape", "pajamas", "winter", "rainbow_tail"]
const ITEMS := {
	"claws": {"name": "Garras Afiadas", "price": 12, "slot": "hands", "description": "Ataque básico +20%.", "icon": "res://world/Arte/Equipment/claws.png"},
	"sneakers": {"name": "Tênis de Explorador", "price": 10, "slot": "feet", "description": "Velocidade de movimento +10%.", "icon": "res://world/Arte/Equipment/sneakers.png"},
	"leaf": {"name": "Folha Protetora", "price": 5, "slot": "charm", "description": "Anula 1 golpe e desaparece após o uso.", "icon": "res://world/Arte/Equipment/leaf.png"},
	"frozen_acai": {"name": "Açaí Congelante", "price": 8, "slot": "use", "description": "Golpes congelam por mais tempo durante 30 s. Use na mochila.", "icon": "res://world/Arte/Equipment/frozen_acai.png"},
	"lasting_ice": {"name": "Gelo Duradouro", "price": 12, "slot": "relic", "description": "Congelamento dos inimigos dura mais 2 s.", "icon": "res://world/Arte/Equipment/lasting_ice.png"},
	"straw_hat": {"name": "Chapéu de Palha", "price": 5, "slot": "head", "description": "Um chapéu leve para os dias de sol.", "icon": "res://world/Arte/Equipment/straw_hat.png"},
	"sunglasses": {"name": "Óculos Escuros", "price": 5, "slot": "face", "description": "Estilo para explorar a praia.", "icon": "res://world/Arte/Equipment/sunglasses.png"},
	"cape": {"name": "Capa de Super-herói", "price": 8, "slot": "back", "description": "Uma capa para o herói das ilhas.", "icon": "res://world/Arte/Equipment/cape.png"},
	"pajamas": {"name": "Pijama", "price": 7, "slot": "outfit", "description": "Conforto para a próxima aventura.", "icon": "res://world/Arte/Equipment/pajamas.png"},
	"winter": {"name": "Roupa de Inverno", "price": 9, "slot": "outfit", "description": "Um casaco quentinho com acabamento de lã.", "icon": "res://world/Arte/Equipment/winter.png"},
	"rainbow_tail": {"name": "Cauda Colorida", "price": 9, "slot": "tail", "description": "As cores do arco-íris na cauda de Nico.", "icon": "res://world/Arte/Equipment/rainbow_tail.png"}
}


static func category(item_id: String) -> String:
	return "equipment" if ORDER.find(item_id) < 5 else "style"
