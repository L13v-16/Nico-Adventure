# Nico's Adventure

## Resgate na jaula suspensa — v49

Na abertura do Submundo, depois da queda, Nico encontra José numa jaula pendurada. Ele salta e golpeia a fechadura duas vezes; a jaula desce pela corrente e abre no chão. José caminha para fora antes de agradecer a Nico e explicar como encontrar a saída. A cena mantém roupas e música, permite avançar com E/Enter/Espaço e pular com ESC, restaurando câmera e controles. A jaula permanece aberta na fase. Sprites originais, prompt final e metadados em `world/Arte/Underworld/V49/`.

## Inimigos do Submundo — v48

Esqueletos operários e diabinhos receberam sprites na estética dos inimigos das duas primeiras fases, usando rato e caranguejo como referências diretas. Novos passos, preparação e golpes de picareta, quatro quadros de voo, arremesso de tridente, dano e derrota. O corpo do diabinho se mantém estável durante o bater das asas, e o projétil combina com a arma que ele carrega. Vida, ataques, colisões e congelamento foram preservados. PNGs originais gerados com imagegen integrado, prompts e metadados em `world/Arte/Underworld/V48/`.

## Amigos na estética de Nico e José — v47

Arara Minas, Tartaruga, Remi, Urso, Mico-leão-dourado e Oliver Gancho usam novos sprites e retratos na mesma estética compacta de pixel art do Nico original e do José aprovado. Cada personagem tem oito poses e quatro expressões de rosto. A Arara tem quatro quadros de voo com Nico apoiado nas costas; a Tartaruga tem quatro quadros de caminhada. A arte está integrada ao prólogo, às fases, aos resgates, à loja e à Coleção, com escala e pés ajustados. Nico e José mantêm os desenhos aprovados. PNGs originais gerados com imagegen integrado, prompts finais e metadados dos atlas em `world/Arte/Friends/V47/`.

Abra `project.godot` no Godot 4.7.1 e pressione **F5**. O projeto abre no menu principal.

A primeira fase atravessa a vila, a floresta e a caverna até a casa na árvore. Na varanda, Nico reencontra Arara Minas, que escapou da captura. Os dois combinam uma viagem entre ilhas para resgatar seus amigos e partem em voo. A primeira parada é Costa das Marés, para salvar a Tartaruga; ela aparece destacada como o próximo resgate no mapa. A cutscene termina na tela de resultados, com o botão **Próxima ilha** para seguir à praia.

A chegada tem uma casa de madeira construída entre os galhos de uma árvore, com copa, tronco e raízes integrados à mesma arte. A varanda elevada e os apoios de madeira conectam o caminho à porta. A câmera abre suavemente ao se aproximar do final para mostrar a árvore inteira; o encontro com Arara Minas reutiliza a mesma casa. A imagem está em `world/Arte/Props/casa_arvore_v13.png`; os prompts exatos acompanham o PNG em `PROMPT-CASA-ARVORE-v13.txt` e `PROMPT-CASA-ARVORE-v13-revisao.txt`.

## Despertar dos poderes no altar — v40

Nico levita diante do altar enquanto **dois jatos de água e duas chamas** giram em sentidos opostos, com faixas passando pela frente e por trás do corpo. A água é um efeito visual: as habilidades continuam sendo **fogo e gelo**. Os elementos se concentram em Nico num clarão, ele retorna ao chão e a conversa explica K, Q e o padrão da forja. A animação dura cerca de oito segundos, preserva as roupas equipadas, a música e a posição física do jogador. Enter/E/Espaço avança para as instruções; ESC pula toda a cena com restauração de Nico, HUD e controles. O aprendizado só é liberado ao concluir ou pular a cena.

O encontro espera Nico aterrissar perto do altar. Os novos efeitos usam oito quadros originais de pixel art em `world/Arte/Underworld/V40/streams.png`, gerados com imagegen integrado. O PNG foi preservado sem alterações; prompt e recortes acompanham o arquivo.

## Tiles de chão e gêiseres — v39

O Submundo usa um conjunto novo de **20 tiles**: superfícies de basalto, preenchimentos, bordas, plataformas, minerais e quatro estados de chão com fenda. Cada gêiser substitui uma célula de piso real; sua abertura fica no centro dessa célula, sem monte de pedras ou objeto flutuando acima. O jato é um sprite separado, com quatro quadros, crescimento e recuo durante a erupção. O dano acompanha sua altura visível. Os gêiseres de impulso mantêm a força de lançamento e têm uma pequena seta azul gravada na face da pedra.

O tileset também aparece no poço e na aterrissagem da abertura. PNGs originais, recortes e prompts finais em `world/Arte/Underworld/V39/`; ambos os atlas foram gerados com imagegen integrado e preservados sem edição.

## Pedras, altar e fruta-do-dragão — v38

José quebra uma barricada de pedras com rachadura dourada, quatro estados de impacto/desmoronamento e entulho baixo apoiado no piso. Sua cabeçada considera a largura do alvo. O **Altar dos Contrários** tem pedestal próprio, runas e oito quadros de fogo/gelo. Nico entra no Submundo **sem disparos elementais**, inclusive com aprendizado de uma visita anterior salvo: aproximar-se do altar e concluir a cena libera K e Q para o restante daquela passagem, preservando os poderes após morrer. Voltar à fase começa novamente pelo altar; o registro de aprendizado continua no save e permanece disponível fora do Submundo.

A **fruta-do-dragão foi movida para a Floresta Violeta**, em três pontos do percurso. Cada coleta permite fogo por 20 segundos, sem gelo nem domínio permanente. A Arara explica o efeito; o açaí continua na floresta. Não há fruta-do-dragão no Submundo. Atlas originais gerados com imagegen integrado, recortes e prompts em `world/Arte/Underworld/V38/`.

## Abertura aérea do Submundo — v37

Nico caminha sobre as costas da Arara Minas enquanto ela voa entre nuvens. Uma bola de canhão com o crachá dourado da corporação atravessa o céu e o derruba. A câmera acompanha sua queda pelo poço até a aterrissagem no Submundo; só então entram o título da fase e o encontro com José. Roupas equipadas acompanham as animações do passageiro. ESC pula o voo ou a queda e mantém o mesmo ponto seguro de chegada, com música, HUD e controles restaurados. O antigo canhão e seu patamar na entrada foram retirados.

## Cenário e jogabilidade do Submundo — v36

O Submundo recebeu um novo fundo de caverna em tons mais contidos, um tileset de basalto com blocos maiores e **16 tipos de props**: pedras, entulho, cristais baixos, fungos, estalagmites, estalactites, arcos, colunas em ruínas, correntes quebradas, equipamento de mineiro, carrinhos, trilhos, suportes de madeira, lanternas, estelas e muretas. São 56 peças colocadas em grupos por trecho, substituindo os pilares decorativos repetidos. A decoração fica atrás da área jogável; suas bases entram três pixels no piso. Estalactites e correntes curtas se prendem a arcos e suportes. As correntes longas da arena continuam interativas.

As plataformas e rochas gravitacionais têm um topo horizontal com a largura visível correspondente à colisão. Os cristais ciano e roxo identificam os comportamentos de aproximação e afastamento. O cenário natural fica mais escuro que Nico e que os objetos interativos. A textura interna da lava foi suavizada para reduzir o ruído.

Foram corrigidos **55 recortes** dos atlas anteriores de José, criaturas, objetos, chefe e cutscenes: algumas regiões incluíam pedaços do quadro vizinho e exibiam botas ou linhas soltas acima dos sprites. Os PNGs originais não foram modificados; os recortes agora acompanham a silhueta completa do objeto e a ancoragem de base.

Na transição para a etapa final do Carcereiro, José aparece apoiado na plataforma superior e pode dar a cabeçada sem precisar cair e se recuperar antes. Os operários sobreviventes recuam e entram brevemente na pose de dano, sem causar contato durante esse intervalo. **Segurar K** mantém os disparos no ritmo do tempo de recarga. Obstáculos de José mostram **C · JOSÉ**, e os gêiseres de impulso têm uma pequena seta azul gravada no chão. O altar ensina os poderes uma vez por passagem pelo Submundo.

Artes e prompts finais em `world/Arte/Underworld/V36/`: `props.png`, `terrain.png`, `background.png`, `PROMPT-props.txt`, `PROMPT-terrain.txt`, `PROMPT-background.txt` e `atlas_metadata.json`. Três imagens geradas com a ferramenta integrada de imagens, usando os sprites existentes de Nico e Oliver como referências de estilo; os arquivos originais foram preservados. Os atlas registram as dimensões reais de cada folha.

Validação: 65 verificações das mecânicas da fase e 20 de cenário/correções, com dez capturas nativas. Uma travessia de 34 etapas com inimigos e dano ativos chegou à entrada da arena usando controles normais, ataques e poderes. A travessia das duas correntes foi conferida separadamente para geometria; os testes usam saves isolados. A verificação da cabeçada final parte da transição real da etapa três para a quatro, sem reposicionar José manualmente.

## Portal, lava e forja — v35

O portal da saída tem arte própria: arco de obsidiana, correntes e cadeado, quatro quadros trancados, quatro de abertura e oito de vórtice em repetição. Recolher a Chave das Profundezas inicia a quebra das correntes; o vórtice continua animado durante a conversa final. O templo da aquisição dos poderes mantém sua arte própria.

A lava das travessias e da arena usa texturas animadas de superfície e correntes internas, bolhas e respingos. Os gêiseres têm quatro sprites de erupção. O desenho é limitado à área visível para evitar renderizar os reservatórios inteiros fora da câmera. As alturas de dano e os intervalos dos perigos permanecem os mesmos.

A Forja Invertida ganhou uma máquina de pedra e bronze com bigorna invertida, câmaras de calor e frio e oito estados visuais. As válvulas são pedestais com sprites próprios: o próximo alvo fica aceso e identificado como FOGO ou GELO. O painel grande foi substituído por texto curto e quatro indicadores com as imagens das válvulas. A máquina muda conforme o padrão avança e fica animada quando funciona. Dutos, placa do bloco e respiradouros também usam partes do atlas; o vapor tem aviso, jato e dissipação.

As três novas folhas originais e seus prompts finais estão em `world/Arte/Underworld/V35/`: `portal_sheet.png`, `lava_sheet.png`, `forge_sheet.png`, `PROMPT-portal.txt`, `PROMPT-lava.txt` e `PROMPT-forge.txt`. Criadas com a ferramenta integrada de geração de imagens, usando Nico e Oliver como referências visuais; PNGs preservados, recortes AtlasTexture, filtro nearest e alinhamento de base. O arquivo `atlas_metadata.json` registra dimensões e recortes. Validação: 65 verificações de mecânicas, 21 de animação/renderização (13 capturas nativas) e a travessia física de 34 etapas, com save isolado.

## Fase 4 — O Submundo (v34)

A saída da floresta mágica leva ao voo com Arara Minas. Um tiro de canhão da corporação derruba Nico no Submundo; ele encontra **José, o Bode** logo no começo, mas os dois ainda precisam escapar. O resgate de José é registrado separadamente da conclusão da fase. A aventura agora tem quatro fases; **Continuar** leva saves da terceira ilha ao Submundo, e o Modo livre desbloqueia ao concluir as quatro. O saldo e o histórico persistente de cerejas continuam compartilhados: as cerejas já recolhidas não reaparecem ao revisitar.

O percurso tem 54 cerejas com identificadores estáveis, três segredos, dez checkpoints, seis rochas gravitacionais, sete gêiseres, seis esqueletos operários, cinco diabinhos voadores e a caravana de Oliver antes da arena. As cerejas nas rochas acompanham seu movimento.

- **Gêiseres:** observe o brilho da rachadura, as pedras tremendo e as faíscas antes da erupção. Os marcados em azul lançam Nico até as áreas altas.
- **Rochas gravitacionais:** algumas seguem Nico e outras se afastam; param quando ele embarca. Posicione uma ponte com elas. Sua colisão também bloqueia tridentes.
- **José:** C chama a cabeçada no obstáculo próximo; o botão direito marca um alvo específico. Ele quebra paredes, derruba pilares que viram pontes e empurra o bloco da forja. Segue Nico, salta e se reúne a ele depois das travessias.
- **Fogo e gelo:** a fruta-do-dragão da floresta concede fogo por 20 segundos. No Submundo, o Altar dos Contrários libera os dois elementos sem frutas para o restante daquela passagem; Q alterna fogo/gelo e K dispara. Morrer mantém o aprendizado da passagem. Ao entrar novamente na fase, o altar precisa ser ativado outra vez. O poder do açaí continua disponível nas outras fases.
- **Forja Invertida:** empurre o bloco pesado para alimentar a máquina; acerte a válvula laranja com fogo e a azul com gelo, repetindo fogo/gelo. Um elemento ou uma válvula errados reiniciam o padrão. Evite o vapor e aproveite as plataformas móveis.
- **Correntes:** E segura; ↑/↓ sobe/desce; Espaço solta e salta. Use as duas correntes e os patamares durante a subida da lava.

**O Carcereiro das Profundezas** tem quatro etapas: saltar ondas de corrente e atacar quando ela prende; escalar a arena com a lava subindo; aquecer a armadura com fogo e tornar as correntes quebradiças com gelo para expor o núcleo; atrair o guardião ao círculo dourado e chamar a cabeçada de José para quebrar a proteção final. Morrer reinicia a luta, mantendo os poderes aprendidos. Após a vitória, o guardião permanece apoiado na plataforma e liberta a **Chave das Profundezas**; recolha-a e siga para a saída da corporação. A conversa final preserva a música e leva aos resultados.

Arte de produção em **`world/Arte/Underworld/`**: José com caminhada, salto, cabeçada, dano e retratos falantes; esqueletos e diabinhos animados; 16 poses do Carcereiro; gêiseres, pilares, blocos, chave, frutas e tridentes. O tileset próprio de basalto cobre chão, paredes, bordas, plataformas da forja e da arena, incluindo o suporte do guardião. As regiões do atlas removem a folga superior para alinhar a superfície visível à colisão. O templo tem oito estados, do altar apagado à abertura elemental. A jaula aberta e a saída reutilizam as artes da mesma coleção. As cutscenes mostram o ataque no céu, a queda, o encontro com José, a aquisição dos poderes e a fuga.

As sete imagens originais foram criadas com a **ferramenta integrada de geração de imagens**, usando os sprites existentes de Nico e Oliver como referência de estilo. Os PNGs originais foram preservados; os recortes são recursos AtlasTexture do Godot, com filtro nearest e ancoragem pelos pés. Os prompts finais acompanham os arquivos: `PROMPT-jose.txt`, `PROMPT-enemies.txt`, `PROMPT-props.txt`, `PROMPT-boss.txt`, `PROMPT-background.txt`, `PROMPT-terrain.txt` e `PROMPT-scenes.txt`. `atlas_metadata.json` registra os recortes e estados.

**Música:** `world/Audio/Underworld/hollow_chain_murmurs.wav` toca na exploração e nos diálogos; `obsidian_chainbreaker.wav` assume na luta. São cópias integrais dos dois WAVs fornecidos, com repetição e volume de música. Loja e mochila mantêm sua própria faixa.

Validação no Godot 4.7.1: 65 verificações de mecânicas/combate/progressão da fase, 68 de menu/persistência/Coleção e 48 de regressão do açaí. Travessias físicas do percurso e das duas correntes usam comandos normais, com combate desativado ou invulnerabilidade apenas nos cenários de teste de geometria. As capturas nativas conferem o chão, as plataformas, as cenas, a forja e a arena; esses testes não alteram o save do jogador.

## Personagens

| Personagem | Descrição | Arte |
|---|---|---|
| Nico | Guaxinim com lenço verde e mochila | `world/Arte/Nico/` |
| Arara Minas | Arara azul e amarela, bico forte, companheira de viagem | `world/Arte/Amigos/arara_minas.tres` |
| Remi | Esquilo castanho, cauda fofa e lenço azul | `world/Arte/Magic/remi.tres` |
| José, o Bode | Bode forte, chifres curvos, barba grisalha e lenço laranja; acompanha Nico com suas cabeçadas | `world/Arte/Underworld/jose.tres` |
| Urso | Urso-pardo grande, gentil e de olhar cansado | `world/Arte/Amigos/urso.tres` |
| Tartaruga | Companheira idosa, de olhar sereno e casco marcado pelas travessias | `world/Arte/Tartaruga/turtle.tres` |
| Urus, o Urubu | Executivo de terno que mantém a tartaruga presa no cais | `world/Arte/Beach/urus.tres` |
| Mico-leão-dourado | Pelagem dourada, juba e cauda longa | `world/Arte/Amigos/mico_leao_dourado.tres` |

Remi foi atualizado para esquilo conforme a direção atual da história; sua nova arte também aparece no prólogo, no mapa e na Coleção. As novas artes aparecem na abertura e no mapa do resgate durante a cutscene final.

## Fase 2 — Costa das Marés

Na praia, Nico e Arara Minas encontram a tartaruga presa por **Urus, o Urubu**. A fase tem sete jangadas/elevadores, cinco bandeiras, 60 cerejas, três segredos, cinco guardas e três caranguejos. O mar devolve Nico à última bandeira. Cais altos e fragmentos recompensam a exploração.

- **Caranguejos:** caia sobre o casco para derrotá-los e ganhar um rebote. Socos não atravessam o casco; tocar de lado causa dano.
- **Açaí:** três frutos concedem 12 segundos de proteção, dano dobrado e golpes congelantes. A aura roxa e a barra indicam o tempo restante. O poder termina ao cair no mar ou concluir a fase.
- **Urus:** escolha entre os dois canhões e salte dentro da boca. As miras têm alcances fixos; observe o voo do chefe e a indicação verde **PULE AGORA**. O lançamento pode errar. Três impactos derrotam Urus.
- **Resgate:** depois da luta, quebre o cadeado com J/X para libertar a tartaruga. A cena de conversa usa os sprites da tartaruga idosa e seu retrato falante.

Para chegar à praia, conclua a floresta e escolha **Próxima ilha** nos resultados. **Continuar** também leva à praia após concluir a primeira fase. Cada fase guarda seu próprio resultado. Depois de concluir as quatro fases, **Modo livre** permite revisitar as quatro ilhas; essa opção fica bloqueada até terminar a aventura.

## Caravana, trilha da praia e encontro

A **Caravana das Marés** fica no trecho de areia antes da travessia para a arena. Oliver Gancho, o rato de tapa-olho, atende pela janela de sua caravana animada, que se desloca devagar. Aproxime Nico e pressione **E** para comprar; use as abas **Suprimentos**, **Equipamentos** e **Estilo** (←/→), escolha com setas/Enter ou mouse e use **ESC** para sair. **I** abre a mochila, inclusive depois que a caravana partir. Loja e mochila pausam o mundo, a trilha da fase e a duração dos poderes. **Pixels and Trinkets** toca em repetição enquanto o painel está aberto; a trilha anterior retoma do mesmo ponto ao fechar, e passar da loja para a mochila mantém a música contínua. A faixa respeita o volume de música do jogo.

O painel da loja usa madeira escura, verde-oliva e detalhes dourados, com uma nova ilustração de Oliver Gancho atrás do balcão sob o toldo da caravana. Saldo e apresentação do vendedor ficam no cabeçalho; as abas e a lista de itens aparecem abaixo, com rolagem para acompanhar a seleção. A arte e seu prompt estão em `world/Arte/Caravan/rato_balcao_v11.png` e `PROMPT-BALCAO-v11.txt`.

| Item | Cerejas | Efeito |
|---|---:|---|
| Coração | 4 | Recupera um coração, se faltar vida. |
| Açaí | 7 | Renova 12 segundos de proteção e golpes fortes. |
| Escudo | 10 | Absorve três golpes; não acumula com outro escudo. |

Os suprimentos acima continuam disponíveis. Os novos itens entram na mochila; equipamentos e roupas são equipados ao comprar. Na mochila, **Equipar** e **Retirar** trocam a aparência e os bônus sem gastar mais cerejas. **Usar** consome a provisão selecionada na hora escolhida. Biscoitos não são consumidos com a vida cheia.

| Equipamento | Cerejas | Efeito |
|---|---:|---|
| Garras Afiadas | 12 | Dano básico +20%, com cálculo fracionário real. |
| Tênis de Explorador | 10 | Corrida +10%: 300 → 330. |
| Folha Protetora | 5 | Anula o próximo golpe válido e desaparece. |
| Açaí Congelante | 8 | Habilita golpes congelantes por 30 s e prolonga o gelo em 2 s. |
| Gelo Duradouro | 12 | Prolonga o congelamento em 2 s enquanto equipado. |

Estilo: **Chapéu de Palha (5)**, **Óculos Escuros (5)**, **Capa de Super-herói (8)**, **Pijama (7)**, **Roupa de Inverno (9)** e **Cauda Colorida (9)**. As peças usam encaixes próprios para cada quadro do Nico: tênis acompanham cada pé, roupas acompanham tronco, mangas e pernas, e acessórios seguem cabeça e mãos. Corrida, salto, queda, dano e mudança de direção compartilham a transformação do sprite, incluindo a deformação de pouso e ataque e o piscar da invulnerabilidade. As peças permanecem na cutscene do resgate. A cauda deixa um rastro colorido em movimento. Pijama e roupa de inverno usam o mesmo espaço; os demais acessórios podem ser combinados. Comprar outra roupa guarda a anterior.

**O gelo é um poder do açaí.** Ataque com J/X/clique durante o efeito para congelar guardas e caranguejos. O açaí comum congela por 2 s; o Açaí Congelante ou o Gelo Duradouro elevam para 4 s, e os dois juntos para 6 s. Inimigos congelados param e não causam dano de contato. O caranguejo continua exigindo um salto por cima para ser derrotado. Urus e a jaula não congelam.

Depois do primeiro encontro, a caravana avisa que seguirá viagem e parte ao Nico se afastar **mais de 300 pixels na horizontal**, para qualquer lado. Há uma breve animação de partida; voltar durante a animação ou usar uma bandeira não faz a loja reaparecer nessa tentativa. Ela permanece disponível até ser encontrada. Uma nova tentativa recria a loja e reinicia as coletas e o inventário daquela tentativa, preservando o saldo de cerejas.

Peças duráveis, estoque não usado e a folha não consumida permanecem após respawn, nesta tentativa. O açaí gelado ativo termina em morte, respawn ou conclusão; seu tempo não corre nos menus. A mochila comporta até três unidades por tipo de provisão: Açaí Congelante, Biscoito de Mel e Açaí de Viagem. A Folha Protetora não impede quedas no mar e é consumida antes do escudo de três golpes.

A HUD mostra somente o **SALDO** disponível em ambas as fases, sem a quantidade máxima por fase. A carteira é compartilhada entre as ilhas e salva a cada coleta e compra em `user://save.cfg`; trocar de fase, reiniciar uma tentativa, voltar ao menu ou reabrir o jogo preserva o saldo. Coletar soma uma cereja; comprar desconta o preço uma única vez. A pontuação e os totais dos resultados continuam contando apenas as coletas daquela tentativa, sem somar o saldo trazido de outras fases. Os resultados e a Coleção também mostram o saldo guardado. Cair no mar remove açaí e escudo, preservando a carteira. A loja não cobra por vida cheia, escudo já equipado ou saldo insuficiente.

**Jogar** recomeça a floresta sem apagar a carteira ou os recordes. **Continuar** fica disponível assim que a aventura é iniciada. **Apagar progresso**, em Opções, limpa o saldo e os recordes e volta a bloquear o Modo livre, preservando as preferências. Saves antigos mantêm seus resultados; como não registravam as compras e o saldo disponível, a nova carteira começa em zero, sem converter recordes em dinheiro.

**Pixel Shore Shenanigans** toca na praia e **Tidal Wrath Royale** assume durante a luta com Urus. As duas faixas fornecidas foram incluídas integralmente, com repetição e controle pelo volume de música. Ao sair da praia, volta a trilha do menu/floresta.

Arara Minas tem seis quadros novos, com corpo estável durante o voo e Nico alinhado sobre suas costas. No resgate, a tartaruga olha para a esquerda, em direção a Nico e Arara. Os sprites, retrato e caravana estão em `world/Arte/Caravan/`; a Arara está em `world/Arte/Amigos/`. Os prompts acompanham as artes.

## Menu e apoios da floresta

As conversas com moradores, a abertura da história e as cutscenes com Arara Minas e a tartaruga mantêm a música da fase tocando, mesmo com o mundo e o cronômetro pausados. Fechar, pular ou sair da conversa libera essa exceção; o menu de pausa continua suspendendo a trilha. Loja e mochila mantêm a prioridade de **Pixels and Trinkets**, com retomada da música anterior no mesmo ponto.

Os dez checkpoints das duas fases usam a spritesheet `world/Arte/Checkpoint/checkpoint_v16.png`: 192×96 pixels, com doze células de 32×48. Seis quadros âmbar indicam um ponto ainda não ativado; seis verdes mostram o retorno ativo, com tecido tremulando e pequenos brilhos. `checkpoint_v16.tres` contém as duas animações prontas para o Godot. O mastro fica ancorado ao chão; áreas de toque e pontos de retorno permanecem nas mesmas posições. O prompt de criação acompanha a arte.

O menu inicial tem fundo simples em azul-petróleo, horizonte discreto e Nico animado à direita. Logo e opções ficam à esquerda, com espaço livre em volta e botões discretos. O item selecionado recebe realce; teclado e mouse continuam disponíveis. Os subpainéis usam o mesmo fundo suave para facilitar a leitura. Os quatro apoios pequenos de grama têm pontas esquerda e direita espelhadas, com topo contínuo e colisão de mão única. As alturas foram ajustadas para saltos mais confortáveis; as cerejas próximas aos dois primeiros apoios acompanham o novo trajeto. A árvore mantém a escala original e agora tem o tronco conectado da raiz à copa.

## Controles

- Setas ou A/D: andar; Espaço, Enter ou W: pular.
- J, X ou clique esquerdo: atacar; E: conversar ou abrir a loja; I: mochila; ESC: pausa/fechar painel; R: retornar à bandeira.
- Na cutscene final: E, Enter, Espaço ou clique esquerdo avançam, ESC pula. A sequência também avança sozinha.

## Arquivos principais

- `world/word_01.tscn`: floresta, colisões, props e chegada.
- `world/beach_02.tscn`: praia, terreno, jangadas, inimigos e resgate, editáveis no Godot.
- `world/Scripts/beach_level.gd`: fluxo da praia; `beach_boss.gd` e `beach_cannon.gd`: luta e lançamentos.
- `world/Scripts/crab_enemy.gd`: patrulha, contato lateral e derrota por salto.
- `world/Scripts/acai_power.gd`: poder temporário, aura e contador.
- `world/Scripts/equipment_catalog.gd`, `equipment_model.gd`, `equipment_inventory.gd` e `equipment_visual.gd`: preços, estoque, slots, mochila e aparência.
- `world/Arte/Equipment/`: onze ícones, onze sobreposições para vestir Nico e prompts de arte.
- `world/Scripts/beach_finale.gd`: resgate e retratos da conversa.
- `prefabs/nico.tscn`: personagem reutilizável, com a física e os sprites da floresta.
- `world/Arte/Beach/`: fundo, atlas16×16, props e animações; `world/Arte/Tartaruga/`: corpo e retratos.
- `world/Scripts/level.gd`: fluxo da partida, salvamento, cutscene e resultados.
- `world/Scripts/island_finale.gd`: cenas e diálogos do encontro e da partida.
- `world/Scripts/forest_atmosphere.gd`: folhas, poeira, vento e luz nas janelas.
- `world/Arte/Props/casa_arvore_v13.png`: árvore, cabana e varanda da chegada e do encontro com Arara Minas.
- `world/Scripts/story_intro.gd`: abertura com os personagens.
- `world/Arte/Amigos/`: PNGs e animações SpriteFrames reutilizáveis.

O jogo tem duas fases jogáveis. O menu oferece **Jogar**, **Continuar**, **Modo livre**, **Coleção**, **Opções**, **Créditos** e **Sair**. A antiga seleção de fases foi removida. O Modo livre é liberado após concluir tanto a floresta quanto o resgate da tartaruga na praia; seu painel oferece apenas as duas ilhas existentes. A lista de fases da campanha fica em `CAMPAIGN_LEVEL_IDS`, em `save.gd`, para acompanhar futuras expansões.

Mais detalhes de controles, edição, arte e validação estão em `LEIA-ME.txt`.


## Abertura e apoio dos cenários (v17)

A abertura agora usa a floresta da fase em camadas, luz e folhas em movimento, personagens com seus frames de animação, voo e pouso de Arara Minas, chegada e partida do veículo, tentativa de resgate e a corrida de Nico. Sete tomadas têm títulos curtos, cortes suaves, texto progressivo e uma faixa de leitura separada. Enter, Espaço ou clique revelam o texto e depois avançam; ESC pula. A sequência avança sozinha e mantém a música durante a pausa do mundo.

Os 41 enfeites estáticos da praia tiveram seus pontos de apoio conferidos no TileMap. Palmeiras, conchas, vegetação, corais e postes entram três pixels na superfície para integrar a base à areia, inclusive nos patamares elevados. As colisões, plataformas móveis, itens e pontos de reaparecimento permanecem nos mesmos lugares.


## Lobo da corporação e chegada à praia (v18)

O lobo da corporação, de terno escuro e crachá dourado, é o líder do sequestro e o futuro chefão final da história. A abertura mostra suas poses de chegada, ordem, captura e satisfação: ele leva José até a jaula enquanto Arara Minas escapa voando. O veículo parte com quatro amigos presos. A luta final com o lobo fica para uma ilha futura; Urus continua sendo o chefe da praia. As quatro poses recortadas, a folha de sprites e o recurso SpriteFrames estão em world/Arte/Corporacao/, com o prompt exato da arte gerada.

Depois do título da fase 2, Arara Minas conversa com Nico sobre a Tartaruga idosa, a corporação e Urus. As dicas explicam que caranguejos são derrotados por um salto descendente sobre o casco (socá-los não funciona), que encostar de lado machuca, que o açaí permite congelar os inimigos e que é preciso esperar as jangadas, tocar as bandeiras e escolher o canhão e o momento do lançamento contra Urus. Retratos animados e cartões ilustrados acompanham as falas. E, Enter, Espaço ou clique revelam e avançam o texto; ESC pula. A conversa também avança sozinha, mantém a trilha da praia e pausa o cronômetro e os inimigos. Ao fechar, restaura câmera, HUD e controles. Ela aparece também ao seguir pelo botão Próxima ilha.


## Fluidez da primeira fase (v19)

A plataforma móvel do centro da caverna foi removida. As duas bordas de pedra avançam um tile, deixando um vão livre de 128 pixels. O teto do corredor foi elevado por baixo, preservando a rota de cima e dando espaço para o salto inteiro. Oito tiles suspensos que bloqueavam o salto sobre as plataformas móveis também foram retirados. Tudo fica salvo no TileMap, editável no Godot.

A floresta tem seis plataformas móveis, com aceleração e desaceleração suaves e uma pausa de 0,25 segundo em cada ponta. A balsa antes da ilha alta e as duas do rio ficam alinhadas às margens, para não prender Nico na parede ao desembarcar. As travessias do rio têm chegada próxima à altura da margem e ciclos mais curtos. Nico conserva a velocidade e a altura do salto; só na floresta há aceleração e frenagem mais rápidas, tolerância de 0,13 segundo depois da borda e buffer de salto de 0,16 segundo antes do pouso. Os padrões da praia são preservados.

São nove checkpoints: o segundo passa para a entrada da caverna, e há bandeiras extras na rota superior, no fundo da caverna, após o elevador e na ilha de descanso do rio. A área de toque é mais tolerante e os retornos ficam fora das patrulhas. Os quatro inimigos da floresta foram reposicionados ou tiveram suas patrulhas ajustadas para deixar espaço de pouso; avisam por 0,6 segundo antes de investir e dão mais tempo de recuperação. Inimigos derrubados no abismo passam a contar como derrotados e são removidos. A floresta continua com 44 cerejas e três segredos.

## Lobo andando e caminhão da corporação (v20)

O lobo caminha com seis quadros próprios: alterna os passos e os braços, mantendo o terno, a gravata e o crachá dourado. Os pés usam a mesma linha de apoio das poses anteriores. A cadência acompanha a distância percorrida na chegada; ao parar, ele assume a pose de comando.

O caminhão foi redesenhado em pixel art, com cabine, escapamento, faróis, carroceria rebitada e emblema dourado. Quatro quadros animam as rodas e a luz âmbar durante o deslocamento. Estacionado, ele fica imóvel. Os quatro amigos aparecem dentro do compartimento, com as grades desenhadas à frente; o veículo, os passageiros e as grades acompanham juntos a suspensão na partida. A poeira sai pela traseira.

Arte gerada com imagegen integrado e preparada por recorte e redução nearest. Em world/Arte/Corporacao/: wolf_walk_1.png a wolf_walk_6.png (112x96, pés em y92), truck_drive_1.png a truck_drive_4.png (224x128, pneus em y116), as duas spritesheets e os recursos wolf_walk_v20.tres e truck_drive_v20.tres. Prompts exatos: PROMPT-LOBO-ANDAR-v20.txt e PROMPT-CAMINHAO-v20.txt. O roteiro, as sete tomadas, os controles para avançar/pular e a continuidade da música são preservados.

## Rato inimigo de quatro patas (v21)

O pequeno inimigo terrestre ganhou uma nova arte de rato em pixel art: focinho comprido, orelhas arredondadas, pelagem cinza-azulada e cauda rosada. Ele mantém a postura quadrúpede, com o corpo baixo e seis quadros de caminhada alternando as patas. O mesmo recurso aparece nos quatro inimigos da floresta e nos cinco guardas da praia. Oliver Gancho continua com sua própria arte.

O sprite usa células de 36x28, a linha de apoio e o posicionamento originais. O formato das colisões, velocidade, patrulha, investida, dano, congelamento do açaí e efeito de derrota são preservados. A cena world/skank.tscn aponta para world/Arte/Rato/rato_v21.png e usa o shader de recorte já existente para manter a transparência limpa. O atlas, seis PNGs individuais e o SpriteFrames reutilizável estão em world/Arte/Rato/. Arte criada com imagegen integrado; o prompt exato está em PROMPT-RATO-v21.txt.

## Animação do lobo revisada (v22)

A abertura passa a usar três novas spritesheets do lobo: oito quadros de caminhada, quatro quadros de levantamento e oito poses de ação, incluindo quatro passos para carregar José. O crachá, a cabeça e o apoio dos pés são registrados na mesma célula de 112x96. A renderização usa o tamanho nativo, sem respirar por escala nem reamostrar o corpo a 1,075x. A cadência dos passos acompanha a distância percorrida.

O lobo se agacha, levanta José com quatro poses, caminha segurando-o e usa o apoio traseiro do caminhão para alcançar a jaula. José acompanha suas mãos e chega à mesma posição e tamanho do sprite dentro da jaula antes da troca. Depois, o lobo desce do apoio, anda até a cabine e aparece pela janela como motorista na partida. A antiga pose que deslizava pelo chão e a mudança abrupta para um lobo pequeno no teto foram substituídas. O espelhamento horizontal também foi corrigido para preservar o apoio e a posição dos personagens ao virarem à direita.

Os sete planos continuam com texto progressivo, avanço por Enter/Espaço/clique, salto por ESC e música durante a pausa do mundo. O plano do sequestro dura 7,2 segundos para acomodar as ações. Os mapas, a física de Nico, inimigos, equipamentos, saldos e salvamentos são preservados. As novas artes, SpriteFrames e prompts exatos da geração integrada estão em world/Arte/Corporacao/V22/.

## Oliver Gancho e Coleção (v23)

Oliver ganhou uma nova arte de pixel art para combinar com Nico: cabeça expressiva, contorno azul-escuro, poucos tons por material, bandana vermelha, tapa-olho, colete ocre e calça verde. O sprite da caravana usa pixels nativos e uma piscada breve, com a parte inferior do corpo escondida pelo balcão. O retrato da Coleção e a imagem de Oliver atrás do balcão da loja seguem o mesmo modelo. Os arquivos e os três prompts exatos da geração integrada ficam em world/Arte/Caravan/V23/. Os PNGs foram preparados por recorte, redução nearest e posicionamento inteiro, preservando o alpha; o shader de recorte de personagens mantém as bordas limpas.

A Coleção do menu agora tem duas abas. Amigos reúne oito cartões: Nico, Arara Minas, Tartaruga, Oliver Gancho, Remi, José, Urso e Mico-leão-dourado. Setas ou clique selecionam um cartão e mostram nome, arte, descrição, estado e local do encontro/resgate. Ilhas e recordes apresenta as duas fases com imagem, nota, melhor tempo, cerejas, segredos, inimigos e mortes. O cabeçalho exibe saldo de cerejas e ilhas concluídas; Voltar ou Esc retorna ao menu. O painel cabe no viewport de 640x360 e mantém o foco visível na navegação.

Os estados seguem o salvamento: Arara vira companheira após a floresta, a tartaruga só é marcada como resgatada depois da praia e os quatro amigos das ilhas futuras continuam desaparecidos. A Coleção consulta os dados sem alterar saldo ou progresso. Ela é um álbum de consulta; as regras do modo livre continuam ligadas à conclusão das duas fases. Compras, preços, equipamentos, trilhas, partida da caravana, mapas e física permanecem com as regras anteriores.

## Enquadramento nas janelas (v24)

Oliver fica centralizado na janela da caravana, com uma pequena margem acima das orelhas e o corpo escondido pelo balcão. Um recorte na abertura impede que qualquer parte do sprite passe sobre a madeira durante a piscada ou o movimento da caravana.

O rosto do lobo usa um recorte proporcional dentro do vidro da cabine do caminhão. Sua máscara acompanha a mesma origem arredondada e o mesmo balanço da carroceria na cutscene. Os quadros do caminhão e as duas expressões de Oliver foram conferidos com renderizações com e sem os personagens: somente os pixels internos das janelas mudam. As animações da abertura, compras, música, saldo, Coleção e demais regras permanecem funcionando.


## Fase 3 — Floresta Violeta (v25)

Depois da praia, **Próxima ilha** leva à floresta mágica para resgatar **Remi, o esquilo**. Saves que já concluíram a praia passam a abrir esta fase pelo botão Continuar, mantendo saldo e recordes. A Coleção registra três ilhas e o resgate de Remi. O modo livre agora exige as três fases disponíveis.

A fase tem 6.384 pixels de extensão, oito bandeiras, 73 cerejas, três segredos, cinco besouros, cinco mariposas e a Hiena. Chão, raízes, plantas e cogumelos usam os mesmos pontos de apoio. O fundo tem paralaxe, vaga-lumes e tons roxos; a abertura com Arara Minas ensina as mecânicas.

- **Cogumelos vermelhos:** pule sobre o chapéu. O impulso alcança mais de 200 pixels de altura e independe de manter o botão de salto pressionado. Há três no percurso e dois na arena.
- **Cipós vivos:** aperte **E** perto da ponta para agarrar. Use **A / D** ou as setas para ganhar balanço; **Espaço / W** ou **E** solta com impulso. O personagem conserva a velocidade tangencial. Um cipó também desloca seu ponto de apoio sozinho.
- **Plantas luminosas:** tocá-las abre/fecha a planta e reposiciona suavemente o cipó correspondente. Voltar a tocar permite alternar novamente o caminho.
- **Besouros de espinhos:** recebem golpes laterais e não devem ser pisados. Eles avisam antes de uma pequena investida.
- **Mariposas:** avisam antes do rasante. Podem ser atacadas ou derrotadas ao cair sobre elas. Ambos os inimigos podem ser congelados pelo açaí.
- **Hiena HaHa (Triple H):** devolva um barril com **J / X**; a chefe só fica tonta quando ele volta e a atinge. Durante o combo de socos ou sua breve recuperação, acerte por trás para abrir outra janela. Golpes frontais e ataques contra a guarda são bloqueados; errar um ataque não a deixa tonta. Enquanto vulnerável, use um novo golpe ou pule na cabeça. Desvie dos chutes, investidas, saltos e cristais. Na segunda metade, os arremessos incluem um barril e um cristal. A bandeira permite tentar novamente e limpa todos os projéteis.
- **Resgate:** derrote a Hiena e quebre o cadeado com **J / X**. Remi sai da gaiola e conversa com Nico e Arara Minas; o resultado fica salvo antes da cena.

A caravana de Oliver aparece antes do chefe e segue as regras de compras e partida já usadas na praia. **I** abre a mochila. Duas frutas de açaí e as provisões da loja ajudam no caminho. A trilha original da floresta continua nos diálogos, muda durante a luta e dá prioridade à música da loja/mochila quando abertas.

**Arte:** imagens geradas com a ferramenta integrada de geração de imagens, em `world/Arte/Magic/`. Há spritesheets da Hiena (16 poses), dos besouros e mariposas (16 poses), dos cogumelos/plantas/árvores (12 células), de Remi (corpo e retratos, oito células), além do fundo. Recursos AtlasTexture alinham os pés sem redesenhar os PNGs e mantêm a transparência com o shader de recorte do jogo. Os prompts exatos acompanham as imagens nos arquivos `PROMPT-*.txt`; `atlas_metadata.json` registra os recortes. As duas músicas originais sintetizadas estão em `world/Audio/Magic/`.


## Polimento da Floresta Violeta e ringue da Hiena (v26)

As árvores, plantas, Arara e os besouros agora alinham a parte opaca dos sprites ao chão, considerando o preenchimento de cada quadro de animação. Há espaço livre em volta da Arara e do ringue. Os vaga-lumes usam duas poses de asas e cruzam a tela nos dois sentidos.

Os cipós têm arte própria de tronco trançado, folhas, apoio e nó de mão em `world/Arte/Magic/V26/vine_atlas.png`. O balanço limita o ângulo a 0,92 rad e a velocidade angular a 2,25 rad/s. Ao saltar, o impulso vertical fica entre -270 e -160 px/s e o horizontal entre -420 e 420 px/s. A travessia inteira foi repetida com os limites novos. Cada cipó tem cinco cerejas no arco real do personagem; elas acompanham o apoio móvel e as plantas, sem alterar o saldo já coletado.

A Hiena luta em um ringue com tablado, postes acolchoados e três cordas. Ela se aproxima para um combo de dois socos, dá chutes de maior alcance, arremessa barris e cristais e conserva a investida e o salto marcado. Cada golpe tem antecipação. Na versão atual, a abertura precisa ser conquistada: rebata um barril com J / X ou acerte por trás durante os socos. Cristais arremessados podem ser quebrados com J / X. O açaí mantém seus golpes congelantes contra os inimigos da floresta. A segunda metade inclui dois arremessos seguidos. Morrer ou vencer limpa os projéteis e reabre a passagem. Remi continua sendo libertado após quebrar o cadeado.

Trilhas fornecidas pelo jogador, copiadas sem conversão:
- Fase e diálogos: **Glimmergrove Pathways.wav**, em `world/Audio/Magic/glimmergrove_pathways.wav`.
- Luta: **Wrestlecackle Beatdown.wav**, em `world/Audio/Magic/wrestlecackle_beatdown.wav`.
- A caravana/mochila mantém a prioridade de **Pixels and Trinkets** e devolve a trilha correta ao fechar.

Três novas imagens foram criadas com a ferramenta integrada de geração de imagens: atlas do cipó e vaga-lumes, atlas do ringue/objetos e 12 novas poses da Hiena (socos, chute, guarda e arremesso). Os PNGs originais permanecem intactos; recursos de recorte isolam os personagens e alinham os pés. Os prompts exatos e os metadados acompanham a arte em `world/Arte/Magic/V26/`.


## Ajustes de cenário e contra-ataques (v27)

As quatro árvores usam recortes completos da copa às raízes. Cristais e pequenos cogumelos têm recortes próprios, sem pedaços da linha vizinha do atlas alterando seu ponto de apoio. Os PNGs originais são preservados; `world/Arte/Magic/atlas_grounding_v27.json` documenta os recortes corrigidos.

Hiena HaHa, apelidada Triple H, só fica tonta por um barril devolvido ou um golpe pelas costas durante seu combo de socos/curta recuperação. Não há mais atordoamento automático ao errar os outros golpes. Barris devolvidos deixam de ferir Nico e voltam até a chefe; cristais continuam quebráveis. Os dois cogumelos da arena ficam em suportes nas hastes laterais, alcançáveis com o salto comum. A derrota, mesmo em uma posição aérea, termina no chão do ringue.

Remi tem um apoio independente no chão da cena, na mesma escala do resgate: acena, pisca e fala sem a oscilação vertical anterior. Seus recortes foram corrigidos e o ator é removido quando o diálogo termina. A música continua durante a conversa e o progresso é salvo antes dela.

Validação: 49 verificações de combate, saltos reais até os trampolins, barril em movimento rebatido com o comando normal, resgate e música; 170 poses/lados/tamanhos renderizados com os pés no apoio; percurso completo dos quatro cipós e plataformas principais sem mortes. Saves de teste ficam isolados dos saves do jogador.


## Novos produtos de Oliver Gancho (v29)

| Item | Cerejas | Efeito |
|---|---:|---|
| Biscoito de Mel | 6 | Guarde e use na mochila para recuperar um coração. Não é gasto com vida cheia. |
| Açaí de Viagem | 12 | Guarde e ative na mochila: os mesmos 12 segundos de proteção e ataque dobrado da fruta comum. |
| Luvas Ágeis | 14 | Recarga dos ataques -15%; ocupam o slot das Garras Afiadas. |
| Broche do Saltador | 12 | Impulso do salto comum +10%; ocupa o slot de Gelo Duradouro. Não altera canhões, cogumelos ou o impulso do cipó. |
| Bandana do Marujo | 7 | Acessório vermelho para a cabeça; substitui o chapéu. |
| Óculos de Aviador | 7 | Óculos com lentes âmbar; substituem os óculos escuros. |

O catálogo passou de 11 para 17 itens, além dos três suprimentos de uso imediato. As provisões guardáveis têm limite de três unidades por tipo e não são equipadas automaticamente. Peças duráveis são equipadas na compra; trocar de peça no mesmo slot retira seu bônus anterior. A mochila tem uma aba Suprimentos e mostra os bônus de impulso e recarga. Os timers continuam pausados enquanto loja ou mochila estão abertas. Roupas, luvas e broche acompanham as mesmas âncoras de animação de Nico, incluindo os lados e as poses de salto, corrida e dano.

Os seis ícones foram gerados com a ferramenta integrada de imagens. O PNG original, sem alterações, está em `world/Arte/Equipment/V29/shop_items_atlas.png`; o prompt exato está em `PROMPT-SHOP-ITEMS.txt` e os recortes estão em `atlas_metadata.json`. Recursos AtlasTexture e shader de recorte exibem os ícones na loja/mochila. Os novos acessórios no personagem são desenhados em pixels pelo código de equipamentos para preservar o tamanho e acompanhar cada pose.

Validação: compras e débitos únicos, limites, uso pela mochila, bloqueio de cura desnecessária, pausa do açaí, substituição dos slots, recarga e salto reais, acessórios em dez combinações de pose/direção, interface dentro da tela e partida da caravana. A correção de estabilidade do açaí foi mantida e verificada na praia e na floresta com o renderizador Vulkan.


## Revisão geral de fluidez e interface (v30)

- **Ataque mais responsivo:** uma nova pressão de J/X nos últimos 120 ms da recarga é guardada e executada assim que Nico pode atacar. Segurar o botão não cria golpes automáticos. Dano, pausa, mochila, caravana e canhões cancelam comandos pendentes para evitar um ataque involuntário ao retornar.
- **Um painel para o açaí:** fruta comum e Açaí Congelante compartilham um indicador com tempo restante, dano dobrado, duração do gelo e barras de duração. O painel mostra os dois efeitos juntos e se reposiciona abaixo das instruções durante os chefes. Os contadores continuam atualizando durante os voos dos canhões e param nos menus.
- **Interação com a caravana:** o aviso E / Loja do Oliver usa coordenadas da tela, com tamanho fixo e limites que o mantêm abaixo da HUD e acima das instruções inferiores. A aproximação, compra e regra de partida permanecem funcionando.
- **Pausa ao sair da janela:** mudar para outro aplicativo abre a pausa durante a jogabilidade. Ao voltar, use Continuar; o jogo não retoma sozinho. Aberturas, resultados, loja e diálogos já pausados não recebem uma segunda pausa.
- **Tremor opcional:** Opções → Tremor da câmera permite desligar os deslocamentos dos impactos. A preferência é guardada no save sem alterar carteira ou fases concluídas; saves antigos usam o efeito habilitado como padrão.
- **Inimigos consistentes:** besouros e mariposas preservam a direção anterior quando o deslocamento ou a posição relativa é zero. Uma derrota limpa movimento e gelo residual.
- **Troca de sprites:** 59 quadros do atlas mágico têm pontos de apoio calculados previamente. O recurso nativo `ground_contacts_v30.tres` acompanha a exportação; o JSON vizinho documenta os dados. A primeira troca desses quadros não precisa ler novamente os pixels da imagem para encontrar os pés.

Validação: 28 verificações novas de comandos, HUD, foco, opções, inimigos e recortes; 50 da loja/mochila; 48 de estabilidade do açaí; 49 do ringue, combate e resgate; 170 combinações de sprites renderizadas; percursos físicos completos da floresta inicial e da floresta mágica sem mortes. Os testes usam saves isolados e não alteram o progresso do jogador.


## Cerejas persistentes no modo livre (v31)

O jogo registra quais cerejas foram coletadas em cada ilha, incluindo as da campanha e as que acompanham os cipós. No modo livre, somente as ainda não coletadas aparecem; cada uma pode acrescentar uma única cereja à carteira. Reiniciar a fase, trocar de ilha, gastar na loja, voltar ao menu ou fechar o jogo não repõe essas coletas. A seleção de ilhas explica essa regra.

Histórico e saldo são gravados juntos: uma falha de gravação não consome a cereja nem concede saldo parcial. As cerejas da floresta mágica têm identificadores estáveis mesmo quando o cipó se move. Os totais originais das fases e os recordes continuam preservados. A campanha mantém suas regras de coleta; Novo jogo apaga também o histórico ao reiniciar o progresso.

Saves anteriores não registravam a posição de cada cereja. Por isso, as ilhas já concluídas nesses saves ficam sem cerejas no modo livre, preservando a carteira e os resultados existentes. O jogo não transforma essa migração em uma coleta perfeita.

Validação: 238 verificações de identidade, saldo, persistência nas três fases, reinício real, migração e reversão após falha de gravação; nove verificações na janela Vulkan cobrindo menu, coleta por colisão, reinício e enquadramento. As 177 cerejas foram identificadas e não concedem crédito duplicado no modo livre. O percurso físico da primeira fase passou sem mortes. Todos os saves usados nos testes são isolados.


## Raízes apoiadas no terreno (v32)

As 13 árvores da Floresta Violeta entram de seis a oito pixels no solo, conforme seu tamanho. O terreno desenhado à frente cobre as pontas mais baixas e encontra as raízes mais altas, eliminando o vão que continuava visível quando apenas a ponta inferior era alinhada. Árvores próximas das bordas ficam inteiramente dentro da ilha de apoio. O encaixe é preservado ao recalcular a âncora do sprite.

Validação: 99 verificações de contato das raízes, estabilidade da âncora, camada visual e apoio das 13 árvores; 24 combinações renderizadas de variação, tamanho e direção. Capturas da fase real foram feitas com Vulkan nos 13 locais. Colisões, plataformas, cerejas e posições dos personagens mantêm suas regras.

**Ajuste v33:** o encaixe foi aprofundado para 16–19 pixels, conforme o tamanho de cada árvore, enterrando mais das raízes para reforçar a ligação visual com o chão. Novas capturas dos 13 locais foram feitas na janela Vulkan.

## Atmosfera do Submundo (v41)

Fumaça de cinzas em duas camadas, com deriva lenta e paralaxe: uma atrás do cenário e outra discreta nas bordas inferiores da tela. O efeito usa ruído contínuo em shader, com passos de dois pixels, e acompanha o enquadramento sem cobrir a HUD ou interceptar comandos. Pausa e retoma com a fase; existe apenas no Submundo.

Validação: 15 verificações sem janela e 21 na janela Vulkan, incluindo textura contínua, camadas, pausa, retomada, renderização real e limpeza ao sair da fase. Entrada, forja e arena foram capturadas com saves isolados.

## Carcereiro: entrada e última corrente (v42)

A luta do Submundo tem uma entrada animada de cinco segundos, com aproximação do guardião, pose de ataque, impacto, nome e fala. Enter, E ou Esc pulam a cena; novas tentativas dispensam sua repetição. A música continua durante a entrada. Correntes presas ficam visíveis e o chefe reage aos golpes. Onze efeitos sintetizados próprios distinguem rugido, correntes, pancadas, lava, armadura, fogo, gelo, disparo e libertação; usam o volume SFX das opções.

Após a cabeçada de José e os últimos golpes, surge a etapa **Última Corrente**: uma estrutura cilíndrica com quatro alturas, 16 plataformas em órbita e apoios laterais. Os canhões de obsidiana são ativados na sequência **fogo → gelo → fogo**, usando K e Q. O elemento errado não dispara e um canhão só concede um acerto. Correntes marcam a posição antes do golpe; mover-se evita o impacto. Os apoios separam a subida em trechos; quedas recuperam Nico com dano, mortes mantêm os canhões já usados nesta tentativa. A transição recupera a vida. O último disparo liberta o guardião, revela a chave e restaura o caminho de saída.

Sprites novos dos canhões e seus oito estados em `world/Arte/Underworld/V42/`; imagem gerada pelo imagegen integrado, preservada sem alteração, com recortes nativos e prompt documentados. O guardião reutiliza a arte já existente. Disparos elementais passam a detectar alvos quando nascem dentro de uma colisão, corrigindo tiros muito próximos dos canhões.

Validação: combate completo por comandos e projéteis reais; percurso físico da estrutura com corrida e saltos comuns; pausa, retomada, quedas, dicas de ataque, morte, cenas descartadas durante entrada/disparo, chave e encerramento. Saves isolados.

## Rédeas do Submundo (v43)

A cena final agora mostra José tentando domar o Carcereiro com suas correntes. Ele lança o gancho, prende o guardião e segura as rédeas enquanto Nico e José sobem. Os dois partem montados nele; a câmera abre para o litoral e acompanha o salto em direção à próxima ilha. Falas novas, retratos, resistência do monstro, sons de elos e montagem fazem parte da sequência de aproximadamente 19 segundos.

Enter/E/Espaço ou clique avançam para a próxima ação; Esc pula para os resultados. Música, conclusão, chave e progresso mantêm o fluxo da fase. A encenação usa cópias dos atores e conserva as roupas articuladas de Nico. Pontos de apoio são calculados sobre o quadro atual do guardião para acompanhar a inclinação das costas.

O atlas `world/Arte/Underworld/V43/chains.png` contém oito sprites: trecho horizontal, vertical, laço frontal/traseiro, gancho, fecho, trecho curvo e corrente enrolada. Criados com imagegen integrado; PNG original preservado, recortes nativos, prompt e origem documentados na mesma pasta. As novas correntes aparecem na cena, na escalada e no golpe preso do chefe.

Validação: sequência natural completa, oito momentos renderizados, roupas equipadas, apoio dos passageiros, enquadramento do salto, avanço/pulo, música, restauração dos atores e resultados. Regressão do Submundo inclui forja, José, correntes de escalada, combate, canhões, chave e conclusão; saves isolados.

## Carcereiro: animações e ritmo de combate (v44)

Dezesseis novos quadros em `world/Arte/Underworld/V44/` ampliam preparação da corrente, pancada, corrente presa, recuperação, dano e rugido. A arte mantém a identidade e a paleta do guardião, usa recortes nativos com preenchimento fixo e apoia cada quadro no chão. PNG original preservado, origem e prompt incluídos; geração pelo imagegen integrado.

O fecho dourado da corrente presa virou um alvo real: J/X e os poderes podem atingir a corrente junto de Nico, sem precisar atravessar a arena para alcançar o corpo do chefe. Corpo e fecho compartilham a mesma proteção contra acertos duplicados. O golpe tem 2,6 segundos de abertura e uma recuperação visível de 0,65 segundo, com tempo para recuar; a troca de estado funciona também quando a taxa de quadros cai.

Na subida da lava, o Carcereiro mira por 0,4 segundo antes de lançar uma corrente em direção fixa. Rochas e chão bloqueiam esse projétil. Atingir o patamar superior cria uma retomada da luta na armadura: morrer dali em diante dispensa repetir a subida. Fogo seguido de gelo abre uma janela de três segundos para o contra-ataque.

A última etapa preserva os canhões e a escalada. Uma ativação bem-sucedida limpa o aviso de ataque e dá um segundo de proteção; eventos repetidos de um mesmo canhão não contam novamente. O último disparo encerra o combate sem correntes causando dano durante a vitória. A HUD separa etapa e instrução, e a câmera ajusta centro e aproximação à distância entre Nico e o guardião.

Validação: animações e apoio dos quadros renderizados; J real contra a corrente distante; primeira etapa vencida com saltos e ataques sem perder vida; mira fixa, bloqueio e dano dos projéteis; retomada superior; canhões, último disparo, chave e saída. Regressão completa do Submundo, sempre com saves isolados.

Santuário e forja (v44): o centro da fase agora abriga um santuário divino de mármore claro e ouro, arco solar, braseiros dos dois elementos, raios suaves e partículas. A câmera mostra a estrutura inteira durante a levitação com água e chamas. O poder continua sendo adquirido somente ali. A caixa de contrapeso e as duas plataformas suspensas sem apoio foram retiradas do corredor da forja; o santuário libera o mecanismo. Fogo → gelo → fogo → gelo e os jatos de vapor continuam como desafio, com instruções e runas acima do chão. Sprite e prompt em world/Arte/Underworld/V44/sanctuary*.


Submundo: cenário, som e subida acessível (v45)

O voo de abertura ganhou um som descendente de queda, ligado ao volume de efeitos, disparado uma única vez depois do impacto e interrompido ao aterrissar ou sair da cena. A música continua.

Sprites próprios substituem a pilastra esticada: coluna de basalto com proporções naturais, rachadura, queda e ponte de pedra formada pela cabeçada de José. As laterais dos abismos usam paredes verticais contínuas, com a borda superior somente na primeira fileira. Os gêiseres de impulso têm uma plataforma sólida com setas turquesa e quatro estados visuais; continuam lançando Nico para cima. Originais, prompts e recortes em world/Arte/Underworld/V45/.

Na forja, quatro esferas embutidas no chão mostram vermelho → azul → vermelho → azul. Os indicadores se acendem conforme os disparos corretos; válvulas, sequência e jatos de vapor continuam funcionando.

Na segunda etapa do Carcereiro, todo o chão da arena sobe. Há dois segundos de preparação e uma subida suave de 16 segundos, sem exigir saltos nem escalada. O AnimatableBody2D carrega Nico e José pela física; a lava permanece 70 pixels abaixo do piso, e os ataques de corrente têm aviso de 0,8 segundo e intervalo de 3,6 segundos. O piso continua no alto durante o restante da luta, incluindo a retomada após morrer. A câmera acompanha a nova velocidade. A última etapa dos canhões mantém seu funcionamento.

Validação: transporte sem entrada de salto em três posições da arena, distância da lava e preservação dos corações, retomada superior, reprodução/encerramento do som, sprites e colisões da coluna/ponte/gêiser, renderização das laterais e quatro esferas, além da regressão completa com disparos reais, José, forja, chefe, canhões e fuga. Saves isolados em todos os testes.


José no modelo dos sprites do Nico (v46)

Sprites e retratos refeitos a partir dos PNGs originais de Nico, incluindo o personagem 33×32 e o retrato da HUD, ampliados com nearest-neighbor como referência. A versão final usa blocos de cor simples e construção compacta do rosto, conservando o bode de chifres curvos, barba e lenço laranja.

Dezesseis quadros cobrem repouso/piscar, quatro passos, preparação, dois quadros de investida, impacto, recuperação, salto, queda, alegria, dano e fala. Os retratos têm quatro expressões. A escala em pé fica perto de 32 pixels; recortes e preenchimentos comuns preservam os pés entre animações. A recuperação da cabeçada é exibida no controlador, e José se vira para Nico quando ficam próximos.

Os mesmos recursos atualizam o Submundo, os diálogos, a Coleção e as cutscenes de sequestro/apresentação/fuga. Arte final, prompts, referência e metadados em world/Arte/Underworld/V46/. Criados com imagegen integrado; os PNGs gerados foram preservados sem edição.

Validação: comparação renderizada com os sprites originais de Nico, apoio de todos os quadros, diálogos e Coleção, oito momentos da fuga montada e regressão completa com cabeçadas reais, forja, batalha, canhões e conclusão. Todos os testes usam saves isolados.

## Carcereiro: arena mais clara (v50)

Quando alcança uma extremidade da arena, o Carcereiro anuncia um salto ao centro com um círculo no chão. Há preparação, arco de salto e recuperação; Nico pode reposicionar-se sem receber dano de contato durante o salto. O chefe não foge enquanto está vulnerável nem quando um gancho devolvido está a caminho.

A segunda etapa tem um único piso que sobe sozinho, sem escadas de plataformas ou correntes de escalada. A lava permanece abaixo do chão. Os ataques alternam um gancho azul, rebatido com o ataque básico J/X, e ondas baixas que se evitam saltando. Cada ataque tem um segundo de aviso. Devolva dois ganchos para deixar o chefe atordoado e liberar a etapa da armadura após a subida; o contador e as instruções aparecem na HUD. A retomada superior continua disponível depois dessa etapa.

Na Última Corrente, a estrutura foi reduzida de 24 para oito plataformas: seis apoios laterais e duas pontes móveis mais largas. Todas continuam sólidas durante a órbita. Nico aparece à frente do guardião para ficar visível, e a HUD indica número do canhão, lado e elemento. A sequência continua fogo → gelo → fogo, com K para disparar e Q para alternar; José, a chave e a fuga montada permanecem integrados. Os dois pequenos props que ficavam sobre as antigas plataformas da arena foram apoiados no chão.

Validação: 83 verificações na janela Vulkan, incluindo oito saltos ao centro, contra-ataques com J real nos dois sentidos, danos de ganchos não rebatidos, progressão da segunda etapa, travessia com saltos normais e transporte pelas pontes, canhões e restauração visual. Mais 73 verificações do piso ascendente sem saltar e 65 da fase completa, com José, forja, combate e fuga. Cinco capturas foram revisadas. Todos os testes usam saves isolados.

## Carcereiro: ritmo inspirado em Cortex e Mecha-Bandicoot (v51)

Referência pesquisada: [Crash Twinsanity Hands-On, GameSpot, 7/9/2004](https://www.gamespot.com/articles/crash-twinsanity-hands-on/1100-6106483/). O relato descreve o robô no centro de uma passarela circular e o ciclo de evitar mísseis/serra e devolver disparos verdes. A adaptação usa a vista lateral e a arte do Submundo.

A segunda etapa virou o Anel de Correntes. O guardião salta ao centro e fica ao fundo, sem bloquear a faixa de passagem. Uma mureta curva de basalto, feita com os tiles existentes, marca o fundo da arena. O piso inteiro continua subindo automaticamente, com a lava abaixo; a câmera acompanha a altura real e mantém o chefe abaixo da HUD.

O padrão inicial tem três ações separadas: quatro ferragens caem nas posições marcadas do jogador; uma corrente enrolada varre o chão; uma esfera verde se prepara por 1,25 segundo e pode ser devolvida com J/X. As miras das ferragens ficam fixas antes da queda, permitindo correr para fora delas. A varredura tem aviso de 0,95 segundo e pode ser saltada com o pulo normal. A esfera usa a colisão real do ataque básico; fogo/gelo não a devolvem. Uma tentativa perdida termina sem bloquear o próximo ciclo.

São sete devoluções: a segunda rompe o selo da varredura; a quarta rompe o selo da chuva; as três finais encerram o anel. Os selos nas correntes reagem e se quebram visualmente, cada ruptura recupera um coração e dá uma breve proteção, e a barra verde acompanha os acertos restantes. Os padrões eliminados não retornam nessa tentativa. Depois vêm a armadura de fogo/gelo, José e os canhões já existentes. Retomar a última etapa conserva a escala do guardião e sua ausência de dano por contato.

Validação: 51 verificações na janela Vulkan, seis capturas revisadas, 73 de transporte pelo piso sem saltos e 66 da fase completa com José, altar, forja, chefão, canhões e fuga. Um percurso automatizado com os controles reais completou o padrão natural inteiro, devolveu sete esferas e não recebeu dano, sem forçar invulnerabilidade. Saves isolados em todos os testes. Os sprites existentes foram reutilizados; a energia e as miras usam partículas e desenho em blocos no Godot.

## Frutas com disparos elementais (v52)

O açaí agora libera o mesmo disparo de gelo usado após o altar, com K. O açaí normal, encontrado na fase ou comprado na caravana, e o Açaí de Viagem liberam gelo durante seus 12 segundos de efeito. A proteção, o ataque dobrado e o congelamento nos golpes de perto continuam. A fruta-do-dragão libera o disparo de fogo por 20 segundos. Pegar uma fruta seleciona seu elemento; quando ambos estão ativos, Q alterna entre eles. Quando um termina, o elemento restante é selecionado automaticamente.

O Açaí Congelante da mochila também libera o disparo de gelo durante seus 30 segundos. Sua melhoria e o Gelo Duradouro prolongam o congelamento causado pelos projéteis. O gelo congela ratos e caranguejos sem eliminar sua interação de combate; o caranguejo continua sendo derrotado pelo salto no casco. A colisão circular varrida acompanha o tamanho visível do disparo, alcança inimigos baixos e respeita paredes. Alvos com comportamento elemental próprio, como a forja e o Carcereiro, mantêm suas regras.

As instruções da praia, da floresta, da loja e da mochila explicam K e Q. A HUD mostra o elemento disponível e sua duração sem cobrir o painel do açaí ou as instruções do chefão. Frutas não gravam domínio permanente. Antes do altar, os poderes continuam dependendo delas; o altar libera fogo e gelo sem limite de tempo. Pausa preserva os contadores e respawn limpa os efeitos temporários.

Validação: 55 verificações na janela Vulkan com seis capturas, incluindo coleta real de açaí na praia e fruta-do-dragão na floresta, K/Q reais, congelamento de rato e caranguejo, bloqueio por parede, duração, renovação, troca automática, compras/consumo na mochila, relíquia, pausa, respawn e domínio do altar. Mais 66 verificações da fase completa do Submundo, incluindo disparos reais na forja, na armadura e nos canhões. Saves isolados em todos os testes.
