# Sprites gerais — v90

72 novos sprites gerados com a ferramenta integrada **image_gen**, usando Nico e os inimigos existentes como referência de estilo. Os PNGs originais e seus canais alfa foram preservados; somente recortes e margens nativos de AtlasTexture são usados no jogo.

| Atlas | Sprites | Uso |
|---|---:|---|
| forest.png | 8 | Samambaias, tronco, pedra com hera, toco, galhos, muda, bromélia e raízes na primeira fase |
| beach.png | 8 | Conchas, rocha, madeira, corda, tábuas, capim e coral na praia |
| magic.png | 8 | Vegetação roxa, cogumelos, pedra rúnica, flores, cristais e madeira na floresta mágica |
| underworld.png | 8 | Carvão, ferramentas, corrente, roda, braseiro apagado, estalagmites, obsidiana e minério |
| industrial.png | 8 | Ferramentas, cabo, engrenagens, válvula, aviso, monitor, recipientes e luzes |
| fx.png | 16 | Quatro quadros para cada efeito: fogo, gelo, impacto e aterrissagem |
| enemies.png | 16 | Aviso, recuperação, dano e derrota para guarda, drone, robô e rato executivo |

`prompts.json` registra os prompts completos, as referências e os caminhos de origem. `atlas-validation.json` contém SHA-256, dimensões e regiões verificadas. `atlases.tres` descreve as regiões opacas e margens virtuais. As divisões seguem os espaços transparentes reais, inclusive quando uma folha ou cauda ultrapassa a divisão nominal do grid.

Os detalhes são visuais e não colidem. A posição da base é obtida com uma consulta ao chão real; os dois pixels inferiores ficam enterrados para evitar aparência flutuante. Placas no laboratório 3D ficam presas às paredes e acompanham a visibilidade de seus setores. As poses novas mantêm uma escala fixa por espécie; as animações de andar e atacar existentes continuam presentes.

Os efeitos usam quatro quadros, amostragem próxima e corte alfa. Fogo e gelo preservam a colisão, velocidade, duração e dano dos projéteis. Impactos e poeira terminam sozinhos e acompanham a pausa da fase. Nenhum sprite altera inventário, cerejas ou progresso.
