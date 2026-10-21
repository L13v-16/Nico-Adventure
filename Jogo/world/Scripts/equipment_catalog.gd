extends RefCounted
## Dados compartilhados pela mochila, pelo modelo de equipamentos e pela loja.
## Ícones são opcionais até a arte terminar de importar.

const ORDER := ["claws", "sneakers", "leaf", "frozen_acai", "lasting_ice", "swift_gloves", "jump_brooch", "honey_biscuit", "travel_acai", "straw_hat", "sunglasses", "cape", "pajamas", "winter", "rainbow_tail", "sailor_bandana", "aviator_goggles"]
const ITEMS := {
	"claws": {"name": "Garras Afiadas", "price": 12, "slot": "hands", "description": "Ataque básico +20%.", "icon": "res://world/Arte/Equipment/V56/claws.tres"},
	"sneakers": {"name": "Tênis de Explorador", "price": 10, "slot": "feet", "description": "Velocidade de movimento +10%.", "icon": "res://world/Arte/Equipment/V56/sneakers.tres"},
	"leaf": {"name": "Folha Protetora", "price": 5, "slot": "charm", "description": "Anula 1 golpe e desaparece após o uso.", "icon": "res://world/Arte/Equipment/V56/leaf.tres"},
	"frozen_acai": {"name": "Açaí Congelante", "price": 8, "slot": "use", "description": "K dispara gelo por 30 s. Golpes e disparos congelam por mais tempo.", "icon": "res://world/Arte/Equipment/frozen_acai.png"},
	"lasting_ice": {"name": "Gelo Duradouro", "price": 12, "slot": "relic", "description": "Congelamento dos inimigos dura mais 2 s.", "icon": "res://world/Arte/Equipment/V56/lasting_ice.tres"},
	"straw_hat": {"name": "Chapéu de Palha", "price": 5, "slot": "head", "description": "Um chapéu leve para os dias de sol.", "icon": "res://world/Arte/Equipment/V56/straw_hat.tres"},
	"sunglasses": {"name": "Óculos Escuros", "price": 5, "slot": "face", "description": "Estilo para explorar a praia.", "icon": "res://world/Arte/Equipment/V56/sunglasses.tres"},
	"cape": {"name": "Capa de Super-herói", "price": 8, "slot": "back", "description": "Uma capa para o herói das ilhas.", "icon": "res://world/Arte/Equipment/V56/cape.tres"},
	"pajamas": {"name": "Pijama", "price": 7, "slot": "outfit", "description": "Conforto para a próxima aventura.", "icon": "res://world/Arte/Equipment/V56/pajamas.tres"},
	"winter": {"name": "Roupa de Inverno", "price": 9, "slot": "outfit", "description": "Um casaco quentinho com acabamento de lã.", "icon": "res://world/Arte/Equipment/V56/winter.tres"},
	"rainbow_tail": {"name": "Cauda Colorida", "price": 9, "slot": "tail", "description": "As cores do arco-íris na cauda de Nico.", "icon": "res://world/Arte/Equipment/V56/rainbow_tail.tres"},
	"honey_biscuit": {"name": "Biscoito de Mel", "price": 6, "slot": "use", "description": "Guarde na mochila: recupera 1 coração. Até 3 unidades.", "icon": "res://world/Arte/Equipment/V29/honey_biscuit.tres"},
	"travel_acai": {"name": "Açaí de Viagem", "price": 12, "slot": "use", "description": "K dispara gelo, com proteção e ataque dobrado por 12 s. Até 3.", "icon": "res://world/Arte/Equipment/V29/travel_acai.tres"},
	"swift_gloves": {"name": "Luvas Ágeis", "price": 14, "slot": "hands", "description": "Recarga dos ataques -15%. Ocupa o lugar das garras.", "icon": "res://world/Arte/Equipment/V56/swift_gloves.tres"},
	"jump_brooch": {"name": "Broche do Saltador", "price": 12, "slot": "relic", "description": "Impulso do salto comum +10%. Substitui Gelo Duradouro.", "icon": "res://world/Arte/Equipment/V56/jump_brooch.tres"},
	"sailor_bandana": {"name": "Bandana do Marujo", "price": 7, "slot": "head", "description": "Bandana vermelha com faixa clara. Estilo de aventureiro!", "icon": "res://world/Arte/Equipment/V56/sailor_bandana.tres"},
	"aviator_goggles": {"name": "Óculos de Aviador", "price": 7, "slot": "face", "description": "Lentes âmbar para acompanhar Arara Minas entre as ilhas.", "icon": "res://world/Arte/Equipment/V56/aviator_goggles.tres"}
}


static func category(item_id: String) -> String:
	var slot: String = ITEMS.get(item_id, {}).get("slot", "")
	if slot == "use": return "supplies"
	return "style" if slot in ["head", "face", "back", "outfit", "tail"] else "equipment"


static func is_consumable(item_id: String) -> bool:
	return ITEMS.has(item_id) and ITEMS[item_id]["slot"] == "use"


static func icon_material(item_id: String) -> Material:
	if not String(ITEMS[item_id]["icon"]).contains("/V29/") and not String(ITEMS[item_id]["icon"]).contains("/V56/"): return null
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://world/Scripts/characters_cutout.gdshader")
	ink.set_shader_parameter("alpha_cutoff", 0.94)
	return ink
