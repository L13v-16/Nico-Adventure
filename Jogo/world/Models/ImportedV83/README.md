# Oliver Gancho e Urso — modelos fornecidos (v83)

Oliver: `meshy-model-2026-10-23T19-57-47-492Z.glb`.
Urso: `meshy-model-2026-10-23T20-04-37-830Z.glb`.

As cópias `*_source.glb` preservam integralmente os arquivos fornecidos. As três
texturas WebP de cada personagem foram extraídas sem reencodificação: suas somas
SHA-256 são idênticas às imagens embutidas nos GLBs. O manifesto registra fontes,
tamanhos e hashes. A geometria fornecida não tinha esqueleto nem animações.

As cenas nativas `oliver.tscn` e `urso.tscn` carregam superfícies otimizadas que
mantêm os próprios vértices, UVs, normais e transformação de UV da fonte. Oliver
usa 46.434 triângulos e Urso 44.050, em vez dos 742.954 e 704.816 da origem. As
fontes GLB são material de edição; não são dependências das cenas em runtime.

Ambas as cenas têm frente em **-Z**, pés ancorados em **y=0**, `model_kind` com o
nome do personagem, `Rig/Skeleton3D` com 18 ossos, quatro pesos normalizados por
vértice e `Animations` (`AnimationPlayer`) com `autoplay=idle`. O material usa as
texturas originais com resposta fosca adequada à iluminação do laboratório.

Escala base para integração:

| Cena | Altura | Largura | Profundidade |
|---|---:|---:|---:|
| Oliver | 2,100 | 1,751 | 1,892 |
| Urso | 2,400 | 1,755 | 1,916 |

`idle`, `talk` e `celebrate` usam movimentos suaves de cabeça, braços e respiração,
sem deslocar os pés. Há clipes conservadores de compatibilidade `run`, `operate`,
`hurt`, `jump`, `attack`, `tail` e `RESET`. Não há esticamentos extremos nas malhas
fundidas da pose original. AABB de exibição ampliado evita recortes por culling.

Para reconstruir, importe as fontes no Godot 4.7 e execute:

```text
Godot --headless --path . --script res://tools/rig_friend_models.gd
```

O baker é independente de `ImportedV81`. Não altera Nico, Largato, modelos
procedurais existentes, sprites 2D nem o fluxo de campanha. `rig-report.json`
registra os limites, vértices, triângulos e animações gerados. A integração no
laboratório deve selecionar estas cenas para `oliver` e `urso` pelo factory 3D.
