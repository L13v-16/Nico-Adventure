extends RefCounted
## Dados compartilhados pela mochila, pelo modelo de equipamentos e pela loja.
## Ícones são opcionais até a arte terminar de importar.

const NEW_ITEMS := ["pitaya_juice", "first_aid_kit", "bark_shield", "mint_tea", "cherry_magnet", "courage_medallion"]
const ORDER := ["executive_card", "industrial_insulator", "magnetic_boots", "emergency_battery", "sabotage_chip", "corporate_emblem", "pitaya_juice", "first_aid_kit", "bark_shield", "mint_tea", "cherry_magnet", "courage_medallion", "claws", "sneakers", "leaf", "frozen_acai", "lasting_ice", "swift_gloves", "jump_brooch", "honey_biscuit", "travel_acai", "straw_hat", "sunglasses", "cape", "pajamas", "winter", "rainbow_tail", "sailor_bandana", "aviator_goggles"]
const ITEMS := {
	"executive_card": {"name": "Cartão de Acesso Executivo", "price": 18, "slot": "relic", "description": "Abre o arquivo reservado da corporação. Nenhum caminho principal exige compra.", "icon": "res://world/Arte/CorpV82/executive_card.tres"},
	"industrial_insulator": {"name": "Isolante Industrial", "price": 20, "slot": "hands", "description": "Na corporação, reduz descargas repetidas e absorve a descarga que tiraria o último coração.", "icon": "res://world/Arte/CorpV82/industrial_insulator.tres"},
	"magnetic_boots": {"name": "Botas Magnéticas", "price": 18, "slot": "feet", "description": "Na corporação, reduz o vento em 85% e o arrasto das esteiras pela metade.", "icon": "res://world/Arte/CorpV82/magnetic_boots.tres"},
	"emergency_battery": {"name": "Bateria de Emergência", "price": 7, "slot": "use", "description": "Recupera 1 coração, uma vez por tentativa da fase final. Não é consumida com vida cheia.", "icon": "res://world/Arte/CorpV82/emergency_battery.tres"},
	"sabotage_chip": {"name": "Chip de Sabotagem", "price": 20, "slot": "relic", "description": "Máquinas da corporação permanecem desligadas ou congeladas 60% mais tempo.", "icon": "res://world/Arte/CorpV82/sabotage_chip.tres"},
	"corporate_emblem": {"name": "Emblema Corporativo", "price": 16, "slot": "charm", "description": "Libera o arquivo reservado com provas e cerejas na corporação.", "icon": "res://world/Arte/CorpV82/corporate_emblem.tres"},
	"pitaya_juice": {"name":"Suco de Pitaya", "price":12, "slot":"use", "description":"K dispara fogo por 20 s. Guarde na mochila para usar quando precisar.", "icon":"res://world/Arte/Equipment/V57/pitaya_juice.tres"},
	"first_aid_kit": {"name":"Kit de Socorro", "price":12, "slot":"use", "description":"Recupera todos os corações. Use pela mochila quando estiver ferido.", "icon":"res://world/Arte/Equipment/V57/first_aid_kit.tres"},
	"bark_shield": {"name":"Escudo de Casca", "price":9, "slot":"use", "description":"Guarde na mochila: absorve 2 golpes. Use quando estiver sem escudo.", "icon":"res://world/Arte/Equipment/V57/bark_shield.tres"},
	"mint_tea": {"name":"Chá de Hortelã", "price":9, "slot":"use", "description":"Recarga dos golpes e disparos -25% por 20 s. Respeita a espera mínima dos chefes.", "icon":"res://world/Arte/Equipment/V57/mint_tea.tres"},
	"cherry_magnet": {"name":"Ímã de Cerejas", "price":16, "slot":"relic", "description":"Atrai cerejas próximas sem atravessar paredes. Ocupa o lugar da relíquia.", "icon":"res://world/Arte/Equipment/V57/cherry_magnet.tres"},
	"courage_medallion": {"name":"Medalhão da Coragem", "price":18, "slot":"charm", "description":"Proteção após receber dano dura mais 0,35 s. Substitui a Folha Protetora.", "icon":"res://world/Arte/Equipment/V57/courage_medallion.tres"},
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


static func is_for_sale(item_id: String) -> bool:
	return ITEMS.has(item_id) and category(item_id) != "style"


static func description(item_id: String) -> String:
	return "Recordação da coleção. O visual original de Nico é mantido." if category(item_id)=="style" else String(ITEMS[item_id]["description"])


static func is_consumable(item_id: String) -> bool:
	return ITEMS.has(item_id) and ITEMS[item_id]["slot"] == "use"


static func icon_material(item_id: String) -> Material:
	if not String(ITEMS[item_id]["icon"]).contains("/V29/") and not String(ITEMS[item_id]["icon"]).contains("/V56/") and not String(ITEMS[item_id]["icon"]).contains("/V57/"): return null
	var ink := ShaderMaterial.new()
	ink.shader = preload("res://world/Scripts/characters_cutout.gdshader")
	ink.set_shader_parameter("alpha_cutoff", 0.94)
	return ink
