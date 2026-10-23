# Modelos do laboratório 3D

23 cenas Godot nativas, sem dependências externas de modelagem. Abra cada `.tscn` para editar malhas, materiais, pivôs e animações. Personagens olham para -Z; a origem fica nos pés; a escala é de aproximadamente dois metros para Nico. Props de interação olham para -Z e são orientados pelas instâncias do cenário.

Personagens: Nico, José, Urso, Oliver, lobo da corporação, Largato e Carcereiro. Inimigos: técnico, mutante, lagarto e drone. Objetos: cerejas, cartão, caixa, bandeira, caravana, ovo, tanque, seringa, alavanca, dois terminais e injetor.

O gerador é `world/Scripts/Lab3D/models.gd`. Para reconstruir as cenas a partir dele, execute Godot com `--headless --path <projeto> --script res://tools/rebuild_lab_models.gd`. A reconstrução substitui as 23 cenas; guarde suas edições manuais antes. Animações usam pivôs de braços, pernas, torso e cauda. Piso, arquitetura e iluminação são montados em `layout.gd`; monitores e prédios usam shaders próprios. Nenhum PNG anterior foi alterado.

Revisão v76: detalhes de personagens, armadura e objetos estão separados em `character_details.gd`, `guardian_details.gd` e `prop_details.gd`. O gerador integra os três módulos antes de gravar as cenas. Os detalhes são filhos dos pivôs de animação; nomes legíveis e estáveis permitem substituir formas antigas sem deixar malhas duplicadas.

V77 acrescenta 10 cenas de aparelhos e cenário, geradas por expansion_models.gd, totalizando 33 modelos.
