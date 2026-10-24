# Controles e interações — v92

No menu inicial, abra **Opções > Configurar teclas**. Clique na tecla principal ou alternativa e pressione a nova tecla. Esc cancela a captura. Clique com o botão direito na alternativa para removê-la. Restaurar o padrão exige uma confirmação.

As ações de movimento 2D e do laboratório 3D têm configurações separadas. Ataque, interação, poderes, mochila e pausa são compartilhados. Conflitos entre ações que podem acontecer na mesma fase são avisados e não são aplicados. A mesma tecla pode ser usada em contextos separados, como o pulo 2D e avançar no laboratório 3D. É possível inverter as duas teclas da mesma ação.

As escolhas são salvas em `user://controls.cfg`, separadas do progresso e do áudio. A atualização usa arquivo temporário e substituição após gravação completa. Configuração inválida recebe o padrão. Mouse e eventos de controle existentes são preservados. Setas, Enter e Esc continuam disponíveis para navegar nos menus; Esc também permanece como saída de emergência da pausa. Restaurar controles não apaga cerejas, itens ou progresso.

Pulo, andar, cipós, correntes, mochila, checkpoint e ações das fases passam pelo InputMap. Os avisos principais da HUD usam as teclas escolhidas. O quadro de controles é a referência completa, inclusive para as ações específicas do laboratório 3D.

A vila recebe seis cenas decorativas: Minas voa em volta de Nico e recebe aplausos; Oliver divide uma cereja com a Tartaruga; José empurra uma pedrinha e Urso comemora; Remi e Mico brincam de perseguição e saltos; todos se cumprimentam; Nico e Minas fazem malabarismo com uma cereja. As cenas usam sprites existentes, permanecem nos grupos sorteados e pausam com o menu. Não executam lógica de jogo nem alteram o save.
