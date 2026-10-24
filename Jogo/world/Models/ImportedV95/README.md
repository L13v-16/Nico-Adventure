# Antagonistas do laboratório — v95

Lobo: `meshy-model-2026-10-24T22-11-43-841Z.glb`, copiado sem alteração em `wolf_source.glb`. `source-manifest.json` registra SHA-256 da fonte recebida. Largato reutiliza o GLB correto de ImportedV81, sem substituir sua identidade.

As cenas derivadas preservam UVs, normais e texturas, com 38.390 triângulos para o Lobo e 51.736 para Largato. Cada um tem 18 ossos e quatro pesos normalizados por vértice. `rig-report.json` registra medidas e clipes. Frente -Z e pés no nível zero.

Os novos pesos separam a bota da seringa, mantêm o jaleco no torso e isolam a cauda da cabeça. Clipes exclusivos do laboratório não alteram Nico nem seus amigos. Os avisos de cauda, seringa e salto antecedem a ação, com durações alinhadas às janelas de combate. O controle do chefe seleciona uma animação por atualização e preserva o relógio da reação de dano. O derretimento continua cartunesco na cutscene.

Reconstrução após importar:
`Godot --headless --path . --script res://tools/rig_lab_v95.gd`

A fonte de alta resolução e o gerador ficam no projeto/ZIP de código; o executável inclui as cenas otimizadas. Materiais originais são preservados nas cutscenes; o tom temporário de dano usa cópias locais por instância. Os sprites e o Lobo da fase final 2D permanecem independentes.
