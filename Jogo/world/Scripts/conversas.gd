extends RefCounted
## Perguntas que o Nico pode fazer aos moradores da vila.
##
## Cada conversa é uma lista de opções. "texto" é o que o Nico pergunta,
## "resposta" é o que o morador responde e "fim" (opcional) encerra a conversa
## em vez de voltar para a lista de perguntas. "cara" (1 a 4) escolhe a
## expressão do morador na resposta, quando ele tem a folha de caras.

const CONVERSAS := {
	"raposa": [
		{
			"texto": "Quem levou os nossos amigos?",
			"resposta": "Os capangas da Corporação. Um deles usava crachá dourado: o Lobo Lázaro, o chefão da trilha.",
			"cara": 4,
		},
		{
			"texto": "Para onde levaram os nossos amigos?",
			"resposta": "Vi os veículos seguirem para o cais. Remi, José, Urso e o mico-leão-dourado estavam com eles. Procure pistas depois da caverna.",
			"cara": 1,
		},
		{
			"texto": "Quem manda nessa Corporação?",
			"resposta": "Três figurões: o Lobo Lázaro, Triple H e o Urubu. Cada um armou um escritório no meio do caminho.",
			"cara": 4,
		},
		{
			"texto": "Vou indo. Cuide-se!",
			"resposta": "Boa sorte, Nico. Toca nas bandeiras de pano: elas marcam o retorno e você não volta do começo.",
			"cara": 3,
			"fim": true,
		},
	],
	"porco": [
		{
			"texto": "Você viu quem levou os amigos?",
			"resposta": "Vi a van preta de perto. Tinha o símbolo da Corporação na porta e um urubu de terno dirigindo.",
			"cara": 4,
		},
		{
			"texto": "Quantos capangas tem pelo caminho?",
			"resposta": "Uns quatro, pelo que eu contei. Dois na trilha e dois rondando a saída da caverna.",
			"cara": 1,
		},
		{
			"texto": "O que eles querem com a gente?",
			"resposta": "Dizem que querem construir um parque temático. Sabe o que isso significa, né? Nada de bom.",
			"cara": 1,
		},
		{
			"texto": "Já vou. Valeu, Espeto!",
			"resposta": "Vai lá, Nico. Junte cerejas pelo caminho e use as bandeiras para recuperar a vida.",
			"cara": 3,
			"fim": true,
		},
	],
}


## Perguntas da conversa indicada. Devolve uma lista vazia quando não existe.
static func perguntas(id: String) -> Array:
	if not CONVERSAS.has(id):
		return []
	return CONVERSAS[id]
