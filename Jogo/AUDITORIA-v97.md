# Auditoria dos pedidos anteriores — v97

A revisão respeita as mudanças de decisão: a Corporação final continua em 2D; o laboratório começa e termina em 2D e tem o miolo em 3D; água na cena do altar representa o poder de gelo; acessórios visuais de Nico continuam desativados, mantendo itens e seus efeitos.

## Lacunas corrigidas nesta revisão

- Os três arquivos secretos do laboratório e o relatório LG-17 exibiam somente um aviso com prazo curto. Agora usam o leitor CRT da Corporação, com texto integral e capturas das fases relacionadas. Logística mostra floresta e praia; biotermia mostra floresta mágica e Submundo; LG-17 mostra o laboratório.
- O leitor restaura a pausa, os controles e a visibilidade anterior de cada HUD na saída normal e na remoção inesperada. A música de diálogo permanece ativa durante a leitura. O arquivo pode ser relido sem multiplicar fragmentos.
- O visualizador de lembranças agora mantém o foco de Tab, Shift+Tab e setas dentro do painel; Enter e Esc devolvem o foco ao cartão selecionado. A abertura repetida não empilha imagens.
- Instruções de arquivos, portas 3D, conversas opcionais e cenas da Corporação exibem a tecla configurada para Interagir. Lobo Lázaro aparece também na apresentação da praia.
- O reinício da etapa final do robô redesenha o visor fechado imediatamente, além de limpar tambores e conservar uma única rota de plataformas.

## Pedidos conferidos na implementação existente

| Grupo de pedidos | Estado conferido |
| --- | --- |
| Primeira fase maior, plataformas móveis, ataque e colisões | Mantidos os ajustes de percurso e movimento já implementados; nenhuma geometria das quatro primeiras ilhas foi alterada nesta revisão. |
| Menu distante da floresta, casas e amigos autônomos | Mantido o cenário do menu e o passeio dos personagens; Coleção, opções e mapa continuam pausando o cenário. |
| Vida e retrato à direita, cerejas sem máximo, poderes na HUD | Componentes existentes preservados. O novo leitor oculta e restaura cada camada sem tornar visível uma HUD que já estava oculta. |
| Praia, açaí/gelo, caranguejos, canhões e Urus | Preservados; nenhuma mudança de mecânica ou assets nesta revisão. |
| Oliver Gancho, loja, música, carteira e mochila persistentes | Preservados; os arquivos e o álbum não dão nem gastam cerejas. |
| Floresta mágica, cipós, Remi, fruta-do-dragão e Triple H | Preservados; continuam o limite de dano por stun e a terceira etapa dos trampolins. |
| Submundo, José, santuário, forja e Carcereiro | Preservados os gatilhos de aquisição dos poderes e as restaurações da HUD. |
| Laboratório, modelos fornecidos e Largato | Preservados a transformação 2D/3D, as salas, os enigmas, os modelos e as animações revisadas. Arquivos agora completos. |
| Corporação, plano do circo, Lobo Lázaro e ajuda dos amigos | Mantidos o quarto do computador, a câmera fixa, o combate a pé, o robô, o visor e os tambores. Corrigidos leitor e reinício visual. |
| Resgate final de Mico, vilões presos e reencontro | Mantido o encerramento e seus mesmos efeitos de progresso ao assistir ou pular. |
| Mapa entre ilhas, modo livre e cerejas únicas | Mantidos os critérios de desbloqueio e os identificadores persistentes. |
| Lembranças por fragmentos | Mantidas as seis imagens, os limites 1/3/6/9/12/18 e a migração dos segredos antigos. Melhorada a navegação do álbum. |
| Controles remapeáveis | Mantidos; corrigidos os prompts dos fluxos revisados. |

## Limites da revisão

A auditoria combina leitura de código e validação nativa dos fluxos alterados. Não representa uma nova travessia manual integral das seis fases. Assets e trilhas anteriores são preservados por comparação de hashes. Os testes usam perfis APPDATA separados e não leem nem modificam o save real do jogador. O relatório de entrega registra as verificações efetivamente executadas.
