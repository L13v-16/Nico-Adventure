# Modelos fornecidos — Nico e Largato (v81)

Nico: meshy-model-2026-10-23T18-02-29-313Z.glb.
Largato: meshy-model-2026-10-23T18-54-17-723Z.glb, o último arquivo enviado.
O arquivo anterior do boss não é utilizado. source-manifest.json registra os hashes.

As cópias *_source.glb preservam os arquivos recebidos sem alterações. As texturas
WebP foram extraídas pelo importador do Godot. As cenas jogáveis usam superfícies
otimizadas, mantendo coordenadas UV, normais e cores: 58.158 triângulos para Nico
e 51.736 para Largato, em vez dos mais de 800 mil de cada fonte.

Cada cena tem Skeleton3D com 18 ossos, quatro pesos normalizados por vértice,
Skin e AnimationPlayer. Os pés foram ancorados no zero e a frente alinhada a -Z.
As animações procedurais usam movimentos conservadores adequados às poses
estáticas dos arquivos. Incluem espera, corrida, salto, queda, pulo duplo,
deslize, giro, queda forte, ataques, poderes, dano, derrota, transporte de
bateria, conversa, operação, cauda e derretimento. O giro também gira o corpo
pela mecânica existente. A pose compacta no deslize acompanha a colisão baixa.

O factory de Lab3D aplica os modelos no controle e nas cutscenes 3D. O começo
em 2D e o retorno final em 2D continuam usando os sprites existentes.
As fontes de alta resolução não são carregadas pelo jogo nem incluídas no
executável; permanecem no projeto e no ZIP de fontes para edição.

Para reconstruir no editor/console do Godot, após importar o projeto:
Godot --headless --path . --script res://tools/rig_meshy_characters.gd
Edite pesos/poses em world/Scripts/Lab3D/imported_motion.gd antes de reconstruir.
rig-report.json registra polígonos, vértices, ossos e clipes exportados.
