# Migração Godot 3.5 → Godot 4.5

O projeto foi convertido para o Godot 4.5 mantendo a mesma estrutura de cenas,
os mesmos nomes de nós e a mesma lógica dos scripts. Abaixo, o que mudou e por quê.

## Scripts (.gd)

| Godot 3.5 | Godot 4.5 | Onde |
|---|---|---|
| `extends KinematicBody` | `extends CharacterBody3D` | Player.gd, Zombie.gd |
| `onready var` | `@onready var` | Player.gd, Zombie.gd |
| `yield(get_tree(), "idle_frame")` | `await get_tree().process_frame` | Player.gd |
| `translation` | `position` | Zombie.gd |
| `raycast.cast_to` | `raycast.target_position` | Zombie.gd |
| `$CollisionShape.disabled = true` | `$CollisionShape.set_deferred("disabled", true)` | Zombie.gd (evita erro de física do Godot 4) |
| `OS.set_window_size(...)` | `get_window().size = Vector2i(...)` | CodeVisualizer.gd |
| `update()` | `queue_redraw()` | CodeVisualizer.gd |
| `Directory.new()` / `dir.open()` | `DirAccess.open()` | CodeVisualizer.gd |
| `File.new()` / `file.open()` | `FileAccess.open()` | CodeVisualizer.gd |
| `get_len()` / `remove()` | `get_length()` / `remove_at()` | CodeVisualizer.gd |
| `rect_size` | `size` | CodeVisualizer.gd |
| `get_font("font")` | `get_theme_default_font()` | CodeVisualizer.gd |
| `draw_string(f, pos, txt, cor)` | `draw_string(f, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, cor)` | CodeVisualizer.gd |
| `linear_interpolate()` | `lerp()` | CodeVisualizer.gd |
| `get_texture().get_data()` + `flip_y()` | `get_texture().get_image()` (já vem na orientação certa) | CodeVisualizer.gd |

O CodeVisualizer também passou a reconhecer `@onready var` na contagem de variáveis,
para que as métricas continuem iguais às da versão 3.5.

## Cenas (.tscn) e recursos

- Formato de arquivo `format=2` → `format=3`.
- Tipos de nó: `Spatial` → `Node3D`, `KinematicBody` → `CharacterBody3D`,
  `CollisionShape` → `CollisionShape3D`, `Camera` → `Camera3D`, `RayCast` → `RayCast3D`,
  `Sprite` → `Sprite2D`. **Os nomes dos nós foram mantidos** (`$RayCast`, `$CollisionShape` etc.),
  então os caminhos usados nos scripts não mudaram.
- `CapsuleShape` → `CapsuleShape3D`: no Godot 4 a cápsula já é vertical e a `height` é a altura total,
  por isso a rotação de 90° foi removida e a altura ajustada (Player: raio 1 / altura 3;
  Zombie: raio 0.8 / altura 2.6) — o mesmo tamanho físico de antes.
- `AnimationPlayer`: as animações agora ficam dentro de uma `AnimationLibrary`; `loop = true` → `loop_mode = 1`.
- `Camera3D`: `fov = 70` e `far = 100` definidos explicitamente (valores padrão do Godot 3).
- `TextureRect` da mira: `margin_*` → `offset_*`; `stretch_mode` 4 → 3 (mesmo modo "Keep Centered").
- `default_env.tres`: `ProceduralSky` → `Sky` + `ProceduralSkyMaterial`, com as mesmas cores.

## project.godot

- `config_version=5` e recurso `4.5`.
- Mapeamento de teclas convertido (`scancode` → `keycode`; Esc = `4194305`).
- Resolução da janela fixada em 1024×600 (padrão do Godot 3), para o HUD ficar na mesma posição.
- Renderizador **Compatibility** (OpenGL 3), que roda em praticamente qualquer computador.
  Para usar o Forward+ (Vulkan): *Project → Project Settings → Rendering → Renderer*.

## Arquivos de importação

- Os `.png.import` foram regenerados no formato do Godot 4 e foram criados os arquivos `.gd.uid`
  (devem ser versionados no Git).
- A pasta antiga `.import/` (cache do Godot 3) não é mais usada e pode ser apagada.
  O Godot 4 usa a pasta `.godot/`, que foi adicionada ao `.gitignore`.
