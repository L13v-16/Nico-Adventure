# Panorama do menu — v88

`forest.png` foi criada com a ferramenta integrada **image_gen**, usando
`world/Arte/fundo_menu.png` apenas como referência do acabamento em pixel art.
A imagem recebida foi copiada sem alterações. O prompt completo está em
`prompt.txt`. A logo original do jogo é exibida separadamente.

`world/Scripts/menu_forest.gd` anima oito personagens decorativos com a arte
existente de Nico, Friends/V47 e José. Não instancia controladores de jogo,
não acessa o save, não concede itens nem modifica progresso. A superfície
da trilha fica em torno de y=279 no canvas lógico de 640 × 360.

Nico conversa com Arara Minas, que pousa após voar sobre a trilha. Oliver
cumprimenta a Tartaruga; José e Urso se encontram; Remi e Mico passeiam e
trocam uma cereja decorativa. As cenas usam ciclos independentes. Ao abrir
um painel, as animações pausam e o fundo escurece; ao voltar, são retomadas.

Os botões ficam à esquerda, sobre um sombreado gradual. A logo fica no
alto, ao centro. Os painéis de opções, Coleção e mapa continuam separados.
