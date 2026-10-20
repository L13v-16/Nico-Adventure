# Inimigos do Submundo — v48

Sprites refeitos a partir dos **inimigos reais das fases 1 e 2**: rato quadrúpede e caranguejo. A referência `enemies-reference.png` foi renderizada pelo Godot com nearest-neighbor a partir de `Rato/rato_v21.tres` e `Beach/crab.tres`. O Nico original também foi fornecido como referência complementar da linguagem de pixels do jogo.

## Artes e prompts finais

Gerados com **imagegen integrado**, em fundo transparente. Os PNGs foram copiados sem edição dos pixels ou do alpha. Os atlas são consumidos por recortes AtlasTexture.

| Arquivo original | Conteúdo | Prompt completo |
| --- | --- | --- |
| `skeleton.png` | Esqueleto operário com capacete laranja, macacão e picareta; 12 poses | `skeleton-prompt.txt` |
| `imp.png` | Diabinho com asas, chifres e tridente; 11 poses e um projétil separado | `imp-prompt.txt` |

`atlas_metadata.json` registra os caminhos das imagens geradas, recortes, telas comuns, margens e pontos de alinhamento. `skeleton_00.tres` a `skeleton_11.tres` e `imp_00.tres` a `imp_11.tres` referenciam diretamente os PNGs preservados.

## Animações e integração

O esqueleto tem repouso/piscada, quatro passos, dois quadros de preparação, dois de golpe, dano e desmoronamento no chão. O diabinho tem quatro quadros de voo, dois de aviso, dois de arremesso, dano, recuperação e derrota, além do tridente horizontal. Os recursos antigos `Underworld/skeleton.tres`, `imp.tres` e `enemies_frame_*.tres` apontam para os novos sprites.

A escala do esqueleto continua definida pela tela de 46 pixels, com pés alinhados em todas as poses. A do diabinho mantém 42 pixels; a córnea serve como referência para estabilizar cabeça e tronco enquanto as asas mudam de posição. O ponto de alinhamento mantém o corpo sobre a colisão e o lançamento. Ao morrer, volta a valer o apoio da pose caída no chão. O projétil usa o tridente do mesmo atlas, com as dimensões e velocidade anteriores.

Vida, colisões, patrulha, alcance e tempo dos ataques, congelamento e regras de derrota permanecem os mesmos. Verificações cobrem recursos novos, alinhamento dos pés, ciclos repetidos sem deslocamento acumulado, tridente real, congelamento, dano e queda do diabinho após a derrota. O teste completo do Submundo também foi executado. Todos usam APPDATA isolado, sem ler ou alterar o save do jogador.
