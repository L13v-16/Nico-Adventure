ARTE DA PRAIA — exportações pixel art

Modo: imagegen integrado. Originais, prompts exatos e exportador ficam em
outputs/Praia-arte/ no workspace da tarefa.

Usar filtro de textura Nearest. Nenhuma imagem contém texto ou interface.

beach_background.png — 1280 x 360, RGB totalmente opaco.
Panorama de céu, ilhas distantes e mar turquesa. Horizonte por volta de y=96.
O panorama já foi reduzido para 640 x 180 com Nearest e ampliado em 2x.
Pode servir como camada fixa à câmera ou parallax horizontal lento.

beach_tiles.png — 64 x 64, RGB totalmente opaco.
Atlas 4 x 4 de tiles de 16 x 16 pixels, sem margens ou gutter.
Coordenadas de atlas (x=0..3):
  y=0: superfície de areia clara e corpo de areia ocre.
  y=1: miolo de areia; sem borda de superfície.
  y=2: miolo de rocha costeira ocre escura.
  y=3: madeira de cais com tábuas horizontais.
Cada linha oferece quatro variações contíguas do mesmo material.

Props isolados RGBA, transparência gerada preservada:
  palm.png          — 96 x 128, palmeira completa com tronco contínuo.
  shells.png        — 32 x 22, duas conchas.
  coral.png         — 28 x 28, coral rosa sobre uma pedra.
  beach_grass.png   — 32 x 24, vegetação costeira.
  mooring_post.png  — 24 x 28, poste de amarração com corda.
Os pés de cada prop estão na última linha da imagem. Para Sprite2D
centralizado, definir position.y = solo_y - metade da altura da textura.
Props são decorativos: colisões devem pertencer ao terreno e aos apoios.
