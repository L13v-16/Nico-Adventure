# Carcereiro — arte da segunda etapa e recarga de Nico

Criados com o **imagegen integrado**, usando o Carcereiro de V44, as correntes de V43 e a captura da arena como referências. Os PNGs RGBA foram copiados integralmente, sem edição de pixels ou remoção posterior de fundo. `atlas_metadata.json` registra origem, hashes, dimensões, recortes e pivôs.

- `guardian_ring.png`: oito poses de preparação/chuva, varredura, carga de plasma, disparo e recuperação. Prompt exato: [guardian-prompt.txt](guardian-prompt.txt).
- `ring_effects.png`: 16 sprites de ferragem em queda, impactos, quatro quadros da bola de espinhos, quatro da esfera verde, selo intacto/rachado/quebrado e efeito de devolução. Prompt exato: [effects-prompt.txt](effects-prompt.txt).
- `guardian.tres` preserva as animações anteriores e acrescenta as seis animações desta etapa. Os recortes `guardian_*.tres` usam canvas comum de 720 pixels, pés em `ground_foot=700` e âncoras de cada pulso para os selos acompanharem a pose e a direção.
- `effects_*.tres` usa canvas comum de 420 pixels e pivôs próprios, conservando o alinhamento da animação da esfera e da bola de espinhos. O código usa filtro nearest-neighbor.

Na segunda etapa, os ataques de Nico têm recarga mínima de **1 segundo**, compartilhada entre J/X e K. Trocar de golpe, usar luvas ou aumentar o dano não contorna o intervalo. A HUD mostra o tempo restante. Fora desta etapa, as recargas anteriores continuam.

Cada atordoamento admite **uma devolução válida**. Outra devolução durante a mesma janela não soma progresso; golpes diretos e bônus de dano não pulam os sete acertos desta etapa. A próxima janela volta a aceitar uma devolução quando o atordoamento acaba. As regras de chuva, varredura, selos e canhões continuam.

Validação: 95 verificações na janela Vulkan, nove capturas e 66 verificações da fase completa. Percurso natural da segunda etapa: sete devoluções reais e zero dano, sem forçar invulnerabilidade. Todos os saves de teste são isolados.
