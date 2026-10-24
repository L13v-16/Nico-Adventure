# Ações dos amigos — v89

Oito atlas, **64 poses novas**, organizadas em **32 ações** (duas poses por ação).
Gerados com a ferramenta integrada **image_gen**, usando as referências já
aprovadas de Nico, Friends/V47 e José/V46. Os oito PNGs foram copiados sem
alterações. Os prompts completos estão nos arquivos `*-prompt.txt` e a
origem de cada imagem está em `sources.json`.

| Personagem / PNG | Ações, na ordem das células 0–7 |
| --- | --- |
| `nico.png` | acenar, pensar, bater palmas, descansar sentado |
| `arara.png` | acenar com a asa, limpar penas, bicar, alongar asas |
| `turtle.png` | cumprimentar, comer folha, descansar, assentir |
| `oliver.png` | acenar, examinar moeda, rir, dar de ombros |
| `jose.png` | acenar, assentir, raspar o chão com o casco, rir |
| `urso.png` | acenar, alongar, bater palmas, cochilar sentado |
| `remi.png` | acenar, lançar cereja, receber cereja, mover a cauda |
| `mico.png` | acenar, lançar cereja, receber cereja, bater palmas |

Cada imagem tem quatro colunas e duas linhas. `atlases.tres` contém os
recortes pela região opaca de cada pose, com margens virtuais consistentes.
As divisões seguem os espaços vazios entre sprites; não cortam asas ou
caudas que passam de uma divisão uniforme. `atlas-validation.json` registra
as dimensões, regiões e SHA-256 das imagens originais.

`world/Scripts/menu_actions.gd` acrescenta os clipes `ambient_*` em cópias
locais dos SpriteFrames. A escala é normalizada pela altura da primeira
pose em pé e pelo sprite original; todas as poses do mesmo personagem
usam o mesmo fator, inclusive sentado e com as asas levantadas. O apoio é
registrado pela base visível de cada pose. Os arquivos compartilhados de
personagens e as animações existentes do jogo não são modificados.

O menu usa ciclos diferentes para cada dupla. Arremessos têm preparação,
soltura, voo decorativo e recepção. As mãos aguardam o instante da chegada
antes de mostrar a cereja recebida. A fruta desenhada é apenas decorativa:
não é um item da fase, não acessa a carteira e não muda o save.
