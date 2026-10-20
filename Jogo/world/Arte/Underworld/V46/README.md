# José no modelo do Nico — v46

Referências diretas: `world/Arte/Nico/idle_1.png` (33×32), `run_1.png`, `run_3.png`, `jump.png`, `hud_1.png` e `rosto_1.png`. O arquivo `nico-reference.png` é uma ampliação desses originais renderizada pelo Godot com nearest-neighbor, sem suavização, para orientar a geração. A arte final prioriza os blocos simples, a paleta curta e a construção do rosto dos sprites originais, mantendo chifres, barba, colete e lenço laranja de José.

Gerado com **imagegen integrado (modo built-in)**. Os PNGs finais foram copiados sem editar seus pixels:

- `jose_sprites.png`: dezesseis poses, consumidas por `sprite_00.tres` a `sprite_15.tres`. Prompt completo em `sprites-prompt.txt`.
- `jose_portraits.png`: retratos neutro, falando, preocupado e feliz. Prompt completo em `portraits-prompt.txt`.

Origem exata, dimensões e regiões em `atlas_metadata.json`. Os recortes respeitam os intervalos transparentes do atlas, sem cortar pés ou chifres. Canvas comum, filtro nearest e ancoragem pelos pés mantêm a escala entre poses; José em pé mede cerca de 32 pixels no mundo.

Os recursos estáveis `../jose.tres`, `../jose_idle.tres`, `../jose_blink.tres` e `../jose_portrait_*.tres` apontam para esta versão. Isso atualiza o companheiro, diálogos, Coleção, apresentação dos amigos, sequestro e fuga montada. Caminhada tem quatro quadros; corrida de cabeçada tem dois; há preparação, impacto, recuperação, salto, queda, alegria, dano e fala. O controlador mostra a recuperação depois do impacto e volta José para Nico quando ficam próximos.
