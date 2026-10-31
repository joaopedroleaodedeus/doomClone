extends Control
# =============================================================================
# CodeVisualizer.gd
# -----------------------------------------------------------------------------
# Ferramenta de "Compreensão de Programas" para o projeto DoomClone.
# Faz uma análise estática simples de todos os arquivos .gd do projeto e
# gera DUAS visualizações distintas, salvas como PNG na raiz do projeto:
#
#   1) res://viz_polimetrica.png    -> Visão Polimétrica (bottom-up), inspirada
#      em Lanza & Ducasse (2003): largura = nº de métodos, altura = LOC total,
#      cor = intensidade de LOC (mais escuro = mais linhas). Cada barrinha
#      laranja dentro do retângulo representa o tamanho de um método.
#
#   2) res://viz_dependencias.png   -> Grafo de dependências (quem chama
#      método de quem), útil para identificar acoplamento entre scripts.
#
# COMO USAR:
#   1. Copie este arquivo para dentro da pasta do projeto DoomClone-master
#      (ex.: raiz do projeto, ao lado de Player.gd).
#   2. No editor do Godot: Scene > New Scene > escolha nó raiz "Control".
#   3. No painel do nó, arraste este script para o campo "Script" (Attach).
#   4. Salve a cena (ex.: CodeVisualizer.tscn).
#   5. Com a cena aberta, aperte F6 ("Run Current Scene") - NÃO precisa
#      mudar a cena principal do jogo.
#   6. Uma janela abre, desenha as duas visões, salva os PNGs e fecha sozinha.
#      Veja o console (aba "Output") para o resumo textual das métricas.
# =============================================================================

# ---------------------------------------------------------------------------
# MODELO DE DADOS
# ---------------------------------------------------------------------------
class ScriptInfo:
	var path := ""
	var name := ""
	var extends_name := ""
	var loc := 0          # linhas de código (ignora linhas vazias/comentários)
	var raw_lines := 0
	var functions := []   # Array de {"name": String, "loc": int}
	var num_vars := 0
	var calls := []       # nomes de métodos chamados no padrão "algo.metodo("

var infos := []          # Array<ScriptInfo>
var call_edges := []     # Array de {"from":String, "to":String, "label":String}

var frame_count := 0
var stage := 0           # 0 = ocioso | 1 = desenha polimétrica | 2 = desenha grafo | 3 = fim

const EXCLUDE_FILES = ["CodeVisualizer.gd"]
const FONT_SIZE = 14     # Godot 4: draw_string() recebe o tamanho da fonte explicitamente


func _ready():
	anchor_right = 1.0
	anchor_bottom = 1.0
	get_window().size = Vector2i(1280, 800)

	_collect_scripts("res://")
	_analyze_calls()
	_print_report()

	if infos.size() == 0:
		push_error("Nenhum arquivo .gd encontrado em res://. Verifique o caminho do projeto.")
		get_tree().quit()
		return

	stage = 1
	queue_redraw()


# ---------------------------------------------------------------------------
# COLETA DOS ARQUIVOS .gd (recursivo)
# ---------------------------------------------------------------------------
func _collect_scripts(base_path):
	var dir = DirAccess.open(base_path)
	if dir == null:
		return
	dir.include_navigational = false
	dir.include_hidden = false # ignora pastas ocultas (ex.: .godot)
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		var full_path = _join_path(base_path, file_name)
		if dir.current_is_dir():
			_collect_scripts(full_path)
		elif file_name.ends_with(".gd") and not EXCLUDE_FILES.has(file_name):
			_parse_script(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()


func _join_path(base, name):
	if base.ends_with("/"):
		return base + name
	return base + "/" + name


# ---------------------------------------------------------------------------
# PARSER ESTÁTICO SIMPLES DE UM ARQUIVO .gd
# ---------------------------------------------------------------------------
func _parse_script(path):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return

	var lines = []
	while not file.eof_reached():
		lines.append(file.get_line())
	var file_len = file.get_length()
	file.close()
	if lines.size() > 0 and lines[lines.size() - 1] == "" and file_len > 0:
		lines.remove_at(lines.size() - 1) # remove linha vazia final gerada pelo EOF

	var info = ScriptInfo.new()
	info.path = path
	info.name = path.get_file().get_basename()
	info.raw_lines = lines.size()

	var func_starts = [] # [{"name":String, "line":int}]
	var call_regex = RegEx.new()
	call_regex.compile("\\.(\\w+)\\s*\\(")

	for i in range(lines.size()):
		var raw = lines[i]
		var stripped = raw.strip_edges()

		if stripped == "" or stripped.begins_with("#"):
			continue
		info.loc += 1

		if info.extends_name == "" and stripped.begins_with("extends "):
			info.extends_name = stripped.substr(8).strip_edges()

		if raw.begins_with("func "): # sem indentação => método de topo (classe)
			var after = raw.substr(5)
			var paren = after.find("(")
			var fname = after.substr(0, max(paren, 0)).strip_edges()
			func_starts.append({"name": fname, "line": i})
		elif raw.begins_with("var ") or raw.begins_with("const ") or raw.begins_with("onready var ") or raw.begins_with("@onready var "):
			info.num_vars += 1

		for m in call_regex.search_all(raw):
			var mname = m.get_string(1)
			if not info.calls.has(mname):
				info.calls.append(mname)

	# calcula o tamanho (LOC) de cada método = distância até o próximo método
	for f in range(func_starts.size()):
		var start = func_starts[f].line
		var end = lines.size()
		if f + 1 < func_starts.size():
			end = func_starts[f + 1].line
		info.functions.append({"name": func_starts[f].name, "loc": end - start})

	infos.append(info)


# ---------------------------------------------------------------------------
# ANÁLISE DE DEPENDÊNCIAS (grafo de chamadas entre scripts)
# ---------------------------------------------------------------------------
func _analyze_calls():
	var definers = {} # nome_do_metodo -> [nomes de scripts que o definem]
	for info in infos:
		for f in info.functions:
			if not definers.has(f.name):
				definers[f.name] = []
			definers[f.name].append(info.name)

	for info in infos:
		for called_name in info.calls:
			if definers.has(called_name):
				for definer_name in definers[called_name]:
					if definer_name != info.name:
						var exists = false
						for e in call_edges:
							if e.from == info.name and e.to == definer_name and e.label == called_name:
								exists = true
								break
						if not exists:
							call_edges.append({"from": info.name, "to": definer_name, "label": called_name})


# ---------------------------------------------------------------------------
# RELATÓRIO TEXTUAL NO CONSOLE (ajuda a escrever o relatório da atividade)
# ---------------------------------------------------------------------------
func _print_report():
	print("==================== RELATÓRIO DE COMPREENSÃO DE PROGRAMAS ====================")
	for info in infos:
		print("Script: %s  (extends %s)" % [info.name, info.extends_name])
		print("  LOC: %d | Métodos: %d | Vars/consts: %d" % [info.loc, info.functions.size(), info.num_vars])
		for f in info.functions:
			print("    - %s(): %d linhas" % [f.name, f.loc])
	print("---- Dependências detectadas (chamadas entre scripts) ----")
	for e in call_edges:
		print("  %s --[%s()]--> %s" % [e.from, e.label, e.to])
	print("=================================================================================")


# ---------------------------------------------------------------------------
# DESENHO
# ---------------------------------------------------------------------------
func _draw():
	match stage:
		1:
			_draw_polymetric_view()
		2:
			_draw_dependency_graph()


func _draw_polymetric_view():
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1))
	var f = get_theme_default_font()

	draw_string(f, Vector2(20, 30), "Visão Polimétrica - Projeto DoomClone", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0))
	draw_string(f, Vector2(20, 52),
		"Largura = nº de métodos | Altura = LOC total | Cor = intensidade de LOC | barras internas = tamanho de cada método",
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.35, 0.35, 0.35))

	var max_loc = 1
	for info in infos:
		max_loc = max(max_loc, info.loc)

	var x = 100
	var baseline = size.y - 160

	for info in infos:
		var w = 60 + info.functions.size() * 34
		var h = 40 + info.loc * 6
		var intensity = 1.0 - (float(info.loc) / float(max_loc)) * 0.65
		var color = Color(intensity, intensity, intensity)

		var rect = Rect2(Vector2(x, baseline - h), Vector2(w, h))
		draw_rect(rect, color)
		draw_rect(rect, Color(0, 0, 0), false, 2.0)

		# barras internas: uma por método, altura proporcional ao LOC do método
		var mx = x + 12
		for m in info.functions:
			var mh = min(m.loc * 5, h - 16)
			var mrect = Rect2(Vector2(mx, baseline - 8 - mh), Vector2(20, mh))
			draw_rect(mrect, Color(0.95, 0.62, 0.13))
			draw_rect(mrect, Color(0, 0, 0), false, 1.0)
			mx += 26

		draw_string(f, Vector2(x, baseline + 22), info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0))
		draw_string(f, Vector2(x, baseline + 42), "LOC: %d" % info.loc, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.2, 0.2, 0.2))
		draw_string(f, Vector2(x, baseline + 60), "Métodos: %d" % info.functions.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.2, 0.2, 0.2))
		draw_string(f, Vector2(x, baseline + 78), "Vars: %d" % info.num_vars, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.2, 0.2, 0.2))

		x += w + 100


func _draw_dependency_graph():
	draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1))
	var f = get_theme_default_font()

	draw_string(f, Vector2(20, 30), "Grafo de Dependências - Projeto DoomClone", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0))
	draw_string(f, Vector2(20, 52), "Setas = chamadas de método entre scripts (acoplamento)", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.35, 0.35, 0.35))

	var positions = {}
	var n = max(infos.size(), 1)
	var center = size / 2
	var radius = min(size.x, size.y) * 0.32

	for i in range(infos.size()):
		var angle = TAU * i / n
		positions[infos[i].name] = center + Vector2(cos(angle), sin(angle)) * radius

	for e in call_edges:
		var p1 = positions[e.from]
		var p2 = positions[e.to]
		draw_line(p1, p2, Color(0.15, 0.4, 0.85), 2.5)
		var mid = p1.lerp(p2, 0.5)
		draw_string(f, mid, e.label + "()", HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.1, 0.1, 0.55))

	for info in infos:
		var pos = positions[info.name]
		draw_circle(pos, 55, Color(1, 0.85, 0.3))
		draw_arc(pos, 55, 0, TAU, 48, Color(0, 0, 0), 2.0)
		draw_string(f, pos + Vector2(-34, -2), info.name, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0, 0, 0))
		draw_string(f, pos + Vector2(-34, 18), "%d métodos" % info.functions.size(), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, Color(0.25, 0.25, 0.25))


# ---------------------------------------------------------------------------
# CAPTURA DE TELA E SALVAMENTO DOS PNGs
# ---------------------------------------------------------------------------
func _process(_delta):
	if stage == 0 or stage == 3:
		return

	frame_count += 1
	if frame_count < 4:
		return # espera alguns frames para garantir que o _draw() já renderizou

	frame_count = 0

	if stage == 1:
		_save_screenshot("res://viz_polimetrica.png")
		print("Salvo: res://viz_polimetrica.png")
		stage = 2
		queue_redraw()
	elif stage == 2:
		_save_screenshot("res://viz_dependencias.png")
		print("Salvo: res://viz_dependencias.png")
		stage = 3
		print("Concluído! Duas visualizações geradas com sucesso.")
		get_tree().quit()


func _save_screenshot(path):
	var img = get_viewport().get_texture().get_image() # no Godot 4 a imagem já vem na orientação correta
	img.save_png(path)
