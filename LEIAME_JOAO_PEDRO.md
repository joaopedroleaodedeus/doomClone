# Ponto de Salvamento - Joao Pedro Fernandes

## O que foi adicionado
- Cena `SavePoint` (pedestal de pedra com cristal flutuante que gira e balanca, emissivo, com luz `OmniLight3D` suave) feita so com primitivas, sem modelos externos.
- Ao chegar perto (raio de ~3 m) aparece a dica "[E] Salvar". Apertando **E** o jogo e salvo, toca um som e aparece "Jogo salvo" (ou "Falha ao salvar" se der erro). Ha 1 segundo de espera entre salvamentos.
- `SaveSystem.savegame()` agora retorna `bool` (true = salvou).
- **Salvar com G foi removido** do `Player.gd`. Carregar com **C** continua funcionando. A acao `gravar` continua no `project.godot` (nao foi alterado), so nao e mais usada.

## Arquivos
Novos:
- `scripts/SavePoint.gd`
- `scenes/SavePoint.tscn`
- `audio/save_point.wav` (brilho ascendente, 22050 Hz mono 16-bit)

Modificados (versao completa, ja inclui o cronometro do Gilberto):
- `scripts/saveSystem.gd` - `savegame() -> bool`
- `scripts/Player.gd` - removido o salvar com G

## Como colocar
1. Extraia o zip na raiz do projeto, sobrescrevendo os arquivos.
2. Abra o projeto no Godot (ele importa o `.wav` sozinho).
3. Na fase, arraste `scenes/SavePoint.tscn` para onde quiser um ponto de salvamento. A origem do noh fica no **chao** (o cristal fica ~2 m acima). O jogador precisa estar a ate 3 m.

## Ordem dos commits
Extraia somente depois do commit de Gilberto (Cronometro de Fase), pois `saveSystem.gd` e `Player.gd` incluem as mudancas dele.

## Controles
- E: salvar (perto do ponto de salvamento)
- C: carregar o ultimo save
