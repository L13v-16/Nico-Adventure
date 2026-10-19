# Nico's Adventure

Abra `project.godot` no Godot 4.7.1 e pressione **F5**. O projeto abre no menu principal.

A primeira fase atravessa a vila, a floresta e a caverna até a casa na árvore. Na varanda, Nico reencontra Arara Minas, que escapou da captura. Os dois combinam uma viagem entre ilhas para resgatar seus amigos e partem em voo. A primeira parada é Costa das Marés, para salvar a Tartaruga; ela aparece destacada como o próximo resgate no mapa. A cutscene termina na tela de resultados, com o botão **Próxima ilha** para seguir à praia.

A chegada tem uma casa de madeira construída entre os galhos de uma árvore, com copa, tronco e raízes integrados à mesma arte. A varanda elevada e os apoios de madeira conectam o caminho à porta. A câmera abre suavemente ao se aproximar do final para mostrar a árvore inteira; o encontro com Arara Minas reutiliza a mesma casa. A imagem está em `world/Arte/Props/casa_arvore_v13.png`; os prompts exatos acompanham o PNG em `PROMPT-CASA-ARVORE-v13.txt` e `PROMPT-CASA-ARVORE-v13-revisao.txt`.

## Personagens

| Personagem | Descrição | Arte |
|---|---|---|
| Nico | Guaxinim com lenço verde e mochila | `world/Arte/Nico/` |
| Arara Minas | Arara azul e amarela, bico forte, companheira de viagem | `world/Arte/Amigos/arara_minas.tres` |
| Remi | Mico pequeno, marrom-claro, cauda enrolada e orelhas claras | `world/Arte/Amigos/remi.tres` |
| José | Tatu-bola com casco segmentado e orelhas pequenas | `world/Arte/Amigos/jose.tres` |
| Urso | Urso-pardo grande, gentil e de olhar cansado | `world/Arte/Amigos/urso.tres` |
| Tartaruga | Companheira idosa, de olhar sereno e casco marcado pelas travessias | `world/Arte/Tartaruga/turtle.tres` |
| Urus, o Urubu | Executivo de terno que mantém a tartaruga presa no cais | `world/Arte/Beach/urus.tres` |
| Mico-leão-dourado | Pelagem dourada, juba e cauda longa | `world/Arte/Amigos/mico_leao_dourado.tres` |

As descrições seguem o grupo apresentado na história e no Prompt 3 de `PROMPTS-ARTE.txt`. As novas artes aparecem na abertura e no mapa do resgate durante a cutscene final.

## Fase 2 — Costa das Marés

Na praia, Nico e Arara Minas encontram a tartaruga presa por **Urus, o Urubu**. A fase tem sete jangadas/elevadores, cinco bandeiras, 60 cerejas, três segredos, cinco guardas e três caranguejos. O mar devolve Nico à última bandeira. Cais altos e fragmentos recompensam a exploração.

- **Caranguejos:** caia sobre o casco para derrotá-los e ganhar um rebote. Socos não atravessam o casco; tocar de lado causa dano.
- **Açaí:** três frutos concedem 12 segundos de proteção, dano dobrado e golpes congelantes. A aura roxa e a barra indicam o tempo restante. O poder termina ao cair no mar ou concluir a fase.
- **Urus:** escolha entre os dois canhões e salte dentro da boca. As miras têm alcances fixos; observe o voo do chefe e a indicação verde **PULE AGORA**. O lançamento pode errar. Três impactos derrotam Urus.
- **Resgate:** depois da luta, quebre o cadeado com J/X para libertar a tartaruga. A cena de conversa usa os sprites da tartaruga idosa e seu retrato falante.

Para chegar à praia, conclua a floresta e escolha **Próxima ilha** nos resultados. **Continuar** também leva à praia após concluir a primeira fase. Cada fase guarda seu próprio resultado. Depois de concluir as duas fases, **Modo livre** permite revisitar as duas ilhas; essa opção fica bloqueada até terminar a aventura.

## Caravana, trilha da praia e encontro

A **Caravana das Marés** fica no trecho de areia antes da travessia para a arena. Oliver Gancho, o rato de tapa-olho, atende pela janela de sua caravana animada, que se desloca devagar. Aproxime Nico e pressione **E** para comprar; use as abas **Suprimentos**, **Equipamentos** e **Estilo** (←/→), escolha com setas/Enter ou mouse e use **ESC** para sair. **I** abre a mochila, inclusive depois que a caravana partir. Loja e mochila pausam o mundo, a trilha da fase e a duração dos poderes. **Pixels and Trinkets** toca em repetição enquanto o painel está aberto; a trilha anterior retoma do mesmo ponto ao fechar, e passar da loja para a mochila mantém a música contínua. A faixa respeita o volume de música do jogo.

O painel da loja usa madeira escura, verde-oliva e detalhes dourados, com uma nova ilustração de Oliver Gancho atrás do balcão sob o toldo da caravana. Saldo e apresentação do vendedor ficam no cabeçalho; as abas e a lista de itens aparecem abaixo, com rolagem para acompanhar a seleção. A arte e seu prompt estão em `world/Arte/Caravan/rato_balcao_v11.png` e `PROMPT-BALCAO-v11.txt`.

| Item | Cerejas | Efeito |
|---|---:|---|
| Coração | 4 | Recupera um coração, se faltar vida. |
| Açaí | 7 | Renova 12 segundos de proteção e golpes fortes. |
| Escudo | 10 | Absorve três golpes; não acumula com outro escudo. |

Os suprimentos acima continuam disponíveis. Os novos itens entram na mochila; equipamentos e roupas são equipados ao comprar. Na mochila, **Equipar** e **Retirar** trocam a aparência e os bônus sem gastar mais cerejas. **Usar** consome um Açaí Congelante na hora escolhida.

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

Peças duráveis, estoque não usado e a folha não consumida permanecem após respawn, nesta tentativa. O açaí gelado ativo termina em morte, respawn ou conclusão; seu tempo não corre nos menus. A mochila comporta até três açaís congelantes. A Folha Protetora não impede quedas no mar e é consumida antes do escudo de três golpes.

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
