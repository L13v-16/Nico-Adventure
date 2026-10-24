# Corporação — cenário, arquivos, Lobo e epílogo (v86)

Artes raster geradas com a ferramenta integrada image_gen. Prompts completos e arquivos de origem em `prompts.json`. Os quatro PNGs gerados são copiados sem alterações: `industrial.png`, `wolf_combat.png`, `prison.png` e `town.png`.

O atlas industrial oferece centro, pontas esquerda/direita, lateral de piso, esteiras com roletes, prensa, computador, moldura CRT, placa e grades. Os recortes explícitos e o registro dos pés estão em `polish_art.gd`. Plataformas usam peças na espessura correta; os elevadores não comprimem o sprite inteiro. A prensa mantém sua base fixa e movimenta somente o pistão. As esteiras exibem setas no sentido real do movimento.

Os três `sign_*.png` são sprites completos com os jargões existentes, compostos no próprio Godot a partir da placa nova e tipografia legível. `tools/bake_corporation_art.gd` recria as placas; executar com argumento `photos` recria os três `evidence_*.png`, capturados diretamente de Nico atacando guardas na corporação. As fotos são coloridas na fonte e ganham preto e branco e linhas de varredura em tempo real no terminal verde. A tela permanece aberta para leitura, possui três registros e fecha com E ou Esc.

O Lobo começa a pé: prepara uma investida ou arremessa uma caneta; ambos deixam uma abertura para contra-ataque. São quatro pontos de vida, com no máximo um ponto de dano por abertura. Em seguida, ele entra no robô por uma cutscene. As três etapas anteriores da máquina, os reguladores de fogo/gelo e a ajuda dos cinco amigos permanecem.

O epílogo mostra a queda do robô, Lobo/Urus/Triple H/Largato atrás das grades e o reencontro na praça com Nico, Arara Minas, Tartaruga, Remi, José, Urso, Oliver e Mico. José já havia domado o Carcereiro; ele não integra os vilões presos. E/Enter avança capítulos, Esc pula o epílogo. O resultado continua salvo e o modo livre é liberado somente com as seis fases completas.
