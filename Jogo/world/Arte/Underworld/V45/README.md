# Cenário do Submundo — v45

Sprites criados com **imagegen integrado (built-in)**, usando capturas do próprio jogo como referência. Os três PNGs foram copiados sem alterações. Regiões, preenchimento e origem exata estão em `atlas_metadata.json`; o recorte é feito por AtlasTexture no Godot, com filtro nearest.

- `pillar.png`: coluna íntegra, rachando, caindo e ponte de pedra quebrada. Prompt completo: `pillar-prompt.txt`. Consumo: `pillar_00.tres` a `pillar_03.tres`, `underworld_obstacle.gd` e `fallen_pillar_bridge.gd`. A coluna mantém proporção natural; a ponte tem topo sólido correspondente ao desenho.
- `launch_pad.png`: quatro estados do gêiser de impulso, com plataforma de basalto e setas turquesa. Prompt completo: `launch-pad-prompt.txt`. Consumo: `launch_pad.tres` e `lava_geyser.gd`. Canvas comum conserva posição/tamanho entre estados; chão e colisão estão alinhados com a plataforma.
- `cliff.png`: cantos superiores e laterais verticais próprias, sem repetir a saliência do topo pela parede. Prompt completo: `cliff-prompt.txt`. Consumo: `cliff_00.tres` a `cliff_03.tres`, `underworld_tiles.gd` e `underworld_terrain.gd`.

Os quatro indicadores vermelho/azul/vermelho/azul da forja são desenhados pelo Godot dentro do piso e acendem conforme o progresso. O efeito de queda é sintetizado pelo sistema de som existente e acompanha a cutscene. A arena do Carcereiro sobe como um piso inteiro, transportando Nico e José pela física.
