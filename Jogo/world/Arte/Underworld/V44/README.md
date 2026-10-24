# Arte e combate — v44

Gerados com **imagegen integrado** (modo built-in), sem editar os PNGs resultantes. Godot faz os recortes via AtlasTexture e usa filtro nearest. As origens exatas e regiões estão nos metadados.

- `guardian_actions.png`: 16 quadros novos do Carcereiro, mantendo sua identidade, armadura de obsidiana, chifres e correntes. Prompt completo: `PROMPT.txt`. Recortes: `action_00.tres` a `action_15.tres`; animações: `guardian.tres`; origem: `atlas_metadata.json`.
- `sanctuary.png`: santuário divino com mármore claro, ouro, arco solar e braseiros de fogo e gelo. Prompt completo: `sanctuary-prompt.txt`. Recorte: `sanctuary_texture.tres`; estados compatíveis com o ritual: `sanctuary.tres`; origem: `sanctuary-metadata.json`.

O santuário ocupa o patamar central do Submundo. Raios e partículas são animados pelo Godot; o ritual mantém os jatos de água e chamas ao redor de Nico. A aquisição jogável continua sendo fogo e gelo. A antiga caixa de contrapeso e as duas plataformas do corredor da forja foram removidas; o aprendizado no santuário libera a forja.
