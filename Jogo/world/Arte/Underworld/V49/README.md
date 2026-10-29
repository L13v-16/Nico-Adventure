# Resgate de José na jaula suspensa — v49

Depois da queda de Nico e do título do Submundo, José aparece preso numa jaula pendurada em uma estrutura de madeira. Nico se aproxima, salta duas vezes e golpeia a fechadura usando o efeito de ataque do próprio personagem. O primeiro golpe racha o cadeado; o segundo o quebra. A jaula desce pela corrente, encosta no chão e abre. José caminha para fora e só então começa a conversa de resgate.

## Arte original e prompt

`cage.png` foi gerado com **imagegen integrado**, usando os sprites originais de Nico/José e o cenário do Submundo como referências. O PNG e seu canal alpha foram copiados sem edição. O prompt final, incluindo a revisão de espaçamento/transparência, está em `cage-prompt.txt`. O shader de recorte existente elimina o alpha suave residual em tempo de execução.

O atlas contém oito objetos/estados: jaula fechada, cadeado rachado, porta entreaberta, porta aberta, fundo da jaula, cadeado partido, elos quebrados e roldana. `cage_00.tres` a `cage_07.tres` fazem os recortes. Os cinco estados da jaula são registrados pelo anel de suspensão e pela base em uma tela comum. `atlas_metadata.json` registra fonte, retângulos, margens, ponto da base e escala. A madeira e as correntes reutilizam os sprites já presentes no jogo.

## Integração e controles

`jose_rescue_cage.gd` monta a jaula no mapa, com José entre fundo e grades. `jose_cage_rescue.gd` encena os movimentos de Nico, os golpes, a descida e a saída de José. Nico usa seu ator real e mantém as roupas equipadas. A física de movimento fica suspensa durante a cena e volta ao final da conversa. Os golpes são apenas visuais, sem acertar inimigos fora do enquadramento.

A animação dura 7,4 segundos. E/Enter/Espaço avança entre momentos; ESC conclui o resgate com a jaula aberta, Nico e José no chão, sem ataque ativo. A câmera volta à de Nico, a música do Submundo continua e a conversa explica a saída e as cabeçadas. O progresso de resgate é gravado ao concluir ou pular a conversa. O poder permanente de fogo/gelo continua restrito ao altar.

Validação cobre ordem da abertura, José atrás das grades antes dos golpes, fechadura rachada, golpes no ar, descida, abertura, caminhada, posição no chão, conversa posterior, câmera/HUD/controles e ESC em seis momentos, além de avanço por Enter e teste completo do Submundo. Todos os testes usam APPDATA isolado, sem ler ou modificar os saves do jogador.
