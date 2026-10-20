# Amigos no modelo de Nico e José — v47

Arara Minas, Tartaruga, Remi, Urso, Mico-leão-dourado e Oliver Gancho receberam sprites e portraits usando como referências diretas o Nico original e o José aprovado na v46. Contorno azul-escuro, pixels em blocos, poucos tons, olhos pequenos e proporções compactas. Nico e José permanecem com suas artes aprovadas.

## Arquivos e prompts finais

As seis imagens originais foram geradas com **imagegen integrado**, com fundo transparente, e copiadas sem edição dos pixels ou do alpha. Os prompts finais completos estão nesta pasta:

| Personagem | PNG original | Prompt final |
| --- | --- | --- |
| Arara Minas | `arara.png` | `arara-prompt.txt` |
| Tartaruga | `turtle.png` | `turtle-prompt.txt` |
| Remi | `remi.png` | `remi-prompt.txt` |
| Urso | `urso.png` | `urso-prompt.txt` |
| Mico-leão-dourado | `mico.png` | `mico-prompt.txt` |
| Oliver Gancho | `oliver.png` | `oliver-prompt.txt` |

Referências de estilo: `../../Underworld/V46/nico-reference.png`, `../../Underworld/V46/jose_sprites.png` e `../../Underworld/V46/jose_portraits.png`. Os caminhos das imagens geradas, retângulos dos quadros, margens e pontos de montaria constam em `atlas_metadata.json`.

## Quadros e integração

Cada PNG tem 4 colunas e 3 linhas: oito poses de corpo e quatro retratos (repouso, fala, preocupação e alegria). Os arquivos `*_body_00.tres` a `*_body_07.tres` e `*_portrait_*.tres` recortam a imagem original usando AtlasTexture. As margens mantêm uma tela comum por personagem e os pés estáveis.

A Arara tem quatro quadros de voo, além de repouso, piscada, passo e fala; o ponto `ride` mantém Nico apoiado nas costas durante o bater das asas. A Tartaruga mantém quatro patas e quatro quadros de caminhada. Remi preserva o lenço azul; José, o laranja; Oliver preserva o tapa-olho, a bandana e o colete. As duas últimas poses de Oliver mostram o mercador atrás do balcão.

Os SpriteFrames antigos de Amigos, Tartaruga, Remi e Oliver apontam para os novos quadros, preservando os caminhos usados pelas cenas. `friend_art.gd` também resolve os carregamentos dinâmicos das cutscenes e da Coleção. Os retratos de diálogo usam desenhos de rosto próprios. A caravana mantém sua janela com recorte e escala do mercador ajustados; a praia e a abertura aérea preservam o tamanho dos atores no jogo.

Validação: seis atlas e seus retratos, alinhamento dos pés por pose, Coleção, prólogo, partida da primeira ilha, chegada à praia, loja, resgate da Tartaruga, chegada à floresta, resgate de Remi e quatro poses de Arara levando Nico. Capturas nativas e teste completo do Submundo foram executados com APPDATA isolado, sem ler ou alterar o save do jogador.
