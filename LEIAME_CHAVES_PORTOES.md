# Chaves e Portoes

Sistema de chaves (simples e mestra) e portoes que so abrem com a chave correta.

## O que foi adicionado
- **Chave simples** abre apenas portoes simples (uma folha). **Chave mestra** abre apenas portoes mestres (duplos). Nao abrem um ao outro.
- As chaves **nao sao consumidas** ao abrir (como no Doom).
- **Portao generico** (`Gate`): `key_type` (SIMPLE/MASTER) e `style` (DOOR = porta que gira 90 graus na dobradica; BARS = grade que sobe). Largura/altura (`width`/`height`) valem 0 = padrao do tipo (simples 2,5 x 3,5; mestre 5 x 4,5).
- O tamanho do portao identifica a chave: portao simples (uma folha) usa chave simples; portao grande/duplo usa chave mestra.
- **HUD**: icones das chaves (distintos pela forma, pois a tela e em tons de cinza) no canto inferior direito e mensagens como "Precisa da chave simples" por ~2 s.

## Arquivos
Novos:
- `scripts/GameKeys.gd` (enum `GameKeys.KeyType { SIMPLE, MASTER }`)
- `scripts/KeyPickup.gd`, `scenes/KeyPickup.tscn`
- `scripts/Gate.gd`, `scenes/Gate.tscn`
- `image/key_simple.png`, `image/key_master.png`
- `audio/key_pickup.wav`, `audio/gate_locked.wav`, `audio/gate_open.wav`

Modificados: `scripts/Global.gd`, `scripts/saveSystem.gd`, `scripts/Player.gd`, `scripts/hud.gd`, `scenes/hud.tscn`, `project.godot` (acao `interact` = tecla E).

## Como usar na fase_01
1. Extraia o zip na raiz do projeto (sobrescrevendo os arquivos modificados) e abra no Godot. Na primeira abertura o Godot cria os arquivos `.import` e `.uid` dos novos assets/scripts.
2. **Chave**: arraste `scenes/KeyPickup.tscn` para a fase, posicione na altura de um coletavel (como a municao) e, no Inspector, escolha `Key Type`. O sprite troca no editor.
3. **Portao**: arraste `scenes/Gate.tscn` para a fase. No Inspector escolha `Key Type` (o tamanho do portao muda na hora) e `Style`. Posicione com a **base no chao** (origem do noh = chao, centro do vao) e gire no eixo Y para que o corredor passe ao longo do eixo **Z local** do portao. Ajuste `Width`/`Height` ao vao se necessario.
4. Dica: para `BARS`, a grade sobe para dentro da parede acima do vao; deixe parede acima do portao.

## Controles
- **E**: interagir (abrir portao). Precisa estar a ate ~2,5 m do portao, de qualquer lado.

## Persistencia
- Portoes abertos, chaves possuidas e chaves ja coletadas ficam em `Global` (`openedGates`, `keys`, `collectedKeyPickups`), identificados por `nome_da_cena-nome_do_no`. **Nao renomeie** os nos depois de salvar.
- Sao gravados no save (G) e restaurados ao carregar (C). Saves antigos continuam funcionando (campos ausentes = vazio).
- Em jogo novo, restart (R) ou morte, `Global.reset_keys_and_gates()` zera chaves, portoes e chaves coletadas.
