# Revisão v99

## Amigos e apresentação

- Retratos de diálogo nos oito cartões e no painel da Coleção.
- Nico usa novas poses expressivas e há áudio de carga/fechamento da jaula. Tartaruga idosa participa do grupo do prólogo, do sequestro e do caminhão; nomes reenquadrados para os seis amigos.
- Roteiro de resgates usa as cinco ilhas ilustradas e retratos, com Submundo abaixo da rota.
- Resultados com Nico inteiro: espera, comemora, reage ou recupera o fôlego conforme a nota. Revelação animada, entrada do painel e partículas; controles cabem na tela.

## Cenário e inimigos

- Removidas frutas dispensáveis imediatamente antes dos chefes da praia e da floresta mágica. Introduções de poderes ao longo das fases mantidas.
- Quatro espécies na Floresta Violeta: besouro, mariposa, cogumelo lançador de esporos e criatura de espinhos. Novos quadros de movimento, aviso e ataque; gelo também interrompe os novos inimigos e esporos.
- Parede sólida de basalto no limite direito do Submundo, permanente e independente dos portões temporários do chefe.
- Oliver no degrau ao lado de sua caravana. Dezoito estações montadas nas paredes de três salas do laboratório, com monitores, teclados, ventilação, cabos e luzes.
- Oito computadores/dispensadores em pixel art: funções diferenciadas na Corporação e indicação LG-17 na interface do laboratório. Barras e instruções de Largato e do Carcereiro ficam ao lado da HUD de poderes, sem encobrir a seleção de fogo/gelo.

## Combates

- Carcereiro: novas poses de caminhada, preparação, correntes, salto, aterrissagem, armadura aquecida/congelada e recuperação; áudio metálico/elemental e sequência visual FOGO → GELO → ATAQUE acima da armadura.
- Largato: cinco padrões iniciais com avisos e recuperação (cauda, rajada, salto, investida, onda). Sobrecarga alterna armadilha de frasco, rajada e onda; inundação fica no fundo da arena, deixando passagem na frente.
- LG-17 liberada ao estabilizar os mecanismos na segunda etapa, antes da terceira. Dose visível, sinal verde, aviso no dispensador e na HUD; estoque pode ser recolhido e guardado para o final. Mantidos três acertos, projéteis reais e recarga entre lançamentos.
- Lázaro mantém o personagem original e recebe oito poses de ação, enquadramento dos pés, direção correta, freada e recuperação.
- Etapa final: tartaruga intercepta ondas de verdade, Remi atua nos cabos, José investe e Urso sustenta a trava. Degraus iluminados, direção de subida e tempo do visor visíveis. Janela de 21 s; primeiro tambor mais tardio e ritmo menos apertado; gelo e ataque continuam funcionando nos tambores.

## Arte e validação

Quatro spritesheets novas, 52 poses/objetos. Geração pelo image_gen integrado com os sprites atuais como referência. PNGs copiados sem edição raster. [Prompts, referências e hashes](world/Arte/PolishV99/prompts.json); [metadados dos recortes](world/Arte/PolishV99/atlases.tres). Recortes medidos pelas partes opacas conectadas, com canvas e apoio dos pés consistentes; sombras semitransparentes e peças de células vizinhas não definem o contato com o chão.

Verificações nativas cobrem novas cenas, retratos, resultados S/D, quatro espécies, esporos, parede física, armadura elemental, poses de Lázaro, proteção da tartaruga, cinco ataques de Largato, sobrecarga, recolhimento antecipado de LG-17 e três projéteis acertando o chefe. Incluem também a regressão de álbum, arquivos, poderes, subida física nas plataformas finais, persistência e resgate do mico. Capturas no Godot e conferência do pacote Windows; APPDATA isolado, sem acessar o save real. Não equivale a uma nova campanha inteira jogada manualmente.
