@tool
extends Node3D
# Portao generico (porta ou grade), simples ou duplo, aberto com chave.
# - key_type SIMPLE = uma folha; MASTER = duas folhas (portao duplo, mais pesado).
# - style DOOR = folha solida que gira 90 graus na dobradica; BARS = grade que sobe.
# A geometria e gerada por codigo (noh "Generated", sem owner => nao e salva na cena),
# e refeita ao mudar qualquer export, inclusive no editor.
# Convencao: o portao ocupa o plano local XY (largura em X, altura em Y a partir do
# chao em y=0) e a passagem e ao longo do eixo local Z.

enum Style { DOOR, BARS }

const OPEN_TIME := 1.0
const SIMPLE_WIDTH := 2.5
const SIMPLE_HEIGHT := 3.5
const MASTER_WIDTH := 5.0
const MASTER_HEIGHT := 4.5
const ZONE_DEPTH := 5.0  # ~2.5 m de cada lado

@export var key_type: GameKeys.KeyType = GameKeys.KeyType.SIMPLE:
	set(value):
		key_type = value
		_rebuild()

@export var style: Style = Style.DOOR:
	set(value):
		style = value
		_rebuild()

## Largura total do vao em metros. 0 = padrao do tipo (simples 2.5, mestra 5.0).
@export_range(0.0, 20.0, 0.1, "or_greater") var width: float = 0.0:
	set(value):
		width = value
		_rebuild()

## Altura do vao em metros. 0 = padrao do tipo (simples 3.5, mestra 4.5).
@export_range(0.0, 20.0, 0.1, "or_greater") var height: float = 0.0:
	set(value):
		height = value
		_rebuild()

var _generated: Node3D
var _zone: Area3D
var _pivots: Array[Node3D] = []
var _bodies: Array[StaticBody3D] = []
var _dirs: Array[float] = []  # +1 folha da esquerda, -1 folha da direita
var _opened := false
var _opening := false
var _swing := 1.0  # lado para onde as portas abrem (afastando do jogador)
var _gate_id := ""


func _ready() -> void:
	if not Engine.is_editor_hint():
		_gate_id = get_tree().current_scene.name + "-" + name
		_opened = Global.is_gate_opened(_gate_id)
	_rebuild()


func _w() -> float:
	if width > 0.0:
		return width
	return MASTER_WIDTH if key_type == GameKeys.KeyType.MASTER else SIMPLE_WIDTH


func _h() -> float:
	if height > 0.0:
		return height
	return MASTER_HEIGHT if key_type == GameKeys.KeyType.MASTER else SIMPLE_HEIGHT


# ---------------------------------------------------------------- geometria

func _rebuild() -> void:
	if not is_inside_tree():
		return
	var old := get_node_or_null("Generated")
	if old != null:
		remove_child(old)
		old.queue_free()
	_pivots.clear()
	_bodies.clear()
	_dirs.clear()

	_generated = Node3D.new()
	_generated.name = "Generated"
	add_child(_generated)  # sem owner: nao e salvo na cena

	var master := key_type == GameKeys.KeyType.MASTER
	var w := _w()
	var h := _h()
	var bars := style == Style.BARS
	var leaf_t: float
	if bars:
		leaf_t = 0.2 if master else 0.15
	else:
		leaf_t = 0.4 if master else 0.25
	var frame_t := 0.55 if master else 0.3  # espessura do batente
	var frame_d := leaf_t + 0.3  # profundidade do batente

	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color(0.22, 0.22, 0.24)
	metal.roughness = 0.7
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.55, 0.4, 0.28)
	wood.roughness = 0.9

	# Batente: dois postes + verga, com colisao
	var frame_body := StaticBody3D.new()
	frame_body.name = "FrameBody"
	_generated.add_child(frame_body)
	var post_size := Vector3(frame_t, h + frame_t, frame_d)
	var lintel_size := Vector3(w + 2.0 * frame_t, frame_t, frame_d)
	for sx in [-1.0, 1.0]:
		var ppos := Vector3(sx * (w * 0.5 + frame_t * 0.5), (h + frame_t) * 0.5, 0.0)
		_add_mesh_box(_generated, post_size, ppos, metal)
		_add_shape_box(frame_body, post_size, ppos)
	var lpos := Vector3(0.0, h + frame_t * 0.5, 0.0)
	_add_mesh_box(_generated, lintel_size, lpos, metal)
	_add_shape_box(frame_body, lintel_size, lpos)

	# Folhas
	var leaf_count := 2 if master else 1
	var leaf_w := (w * 0.5 if master else w) - 0.04
	for i in leaf_count:
		var dir := 1.0 if i == 0 else -1.0
		var center := 0.0
		if master:
			center = -w * 0.25 if i == 0 else w * 0.25
		var pivot := Node3D.new()
		pivot.name = "Leaf%d" % i
		_generated.add_child(pivot)
		var cx := 0.0  # centro do conteudo em relacao ao pivo
		if bars:
			pivot.position = Vector3(center, 0.0, 0.0)  # pivo embaixo, no centro
			_build_bars_leaf(pivot, leaf_w, h, master, metal)
		else:
			cx = dir * leaf_w * 0.5
			pivot.position = Vector3(center - cx, 0.0, 0.0)  # pivo na dobradica externa
			_build_door_leaf(pivot, cx, dir, leaf_w, h, leaf_t, master, wood, metal)
		var body := StaticBody3D.new()
		body.name = "Body"
		pivot.add_child(body)
		var leaf_col_t := leaf_t if not bars else 0.2
		_add_shape_box(body, Vector3(leaf_w, h, leaf_col_t), Vector3(cx, h * 0.5, 0.0))
		_pivots.append(pivot)
		_bodies.append(body)
		_dirs.append(dir)

	# Zona de interacao (so o jogador a detecta; ela nao e detectavel)
	_zone = Area3D.new()
	_zone.name = "InteractionZone"
	_zone.collision_layer = 0
	_zone.collision_mask = 1
	var zshape := CollisionShape3D.new()
	var zbox := BoxShape3D.new()
	zbox.size = Vector3(w + 2.0 * frame_t + 0.5, h + 2.0, ZONE_DEPTH)
	zshape.shape = zbox
	zshape.position = Vector3(0.0, h * 0.5, 0.0)
	_zone.add_child(zshape)
	_generated.add_child(_zone)

	# Portao ja aberto (save / cena recarregada)
	if _opened and not Engine.is_editor_hint():
		_aplicar_progresso(1.0)
		_desativar_colisao()


func _build_door_leaf(pivot: Node3D, cx: float, dir: float, leaf_w: float, h: float,
		t: float, master: bool, wood: Material, metal: Material) -> void:
	# placa grossa
	_add_mesh_box(pivot, Vector3(leaf_w, h, t), Vector3(cx, h * 0.5, 0.0), wood)
	# tabuas em relevo nas duas faces
	var n := maxi(2, int(leaf_w / 0.8))
	var pw := leaf_w / n
	for k in n:
		var x := cx - leaf_w * 0.5 + pw * (k + 0.5)
		for sz in [-1.0, 1.0]:
			_add_mesh_box(pivot, Vector3(pw * 0.82, h * 0.92, 0.07),
					Vector3(x, h * 0.5, sz * (t * 0.5 + 0.025)), wood)
	# faixas de metal
	for fy in [0.22, 0.78]:
		_add_mesh_box(pivot, Vector3(leaf_w, 0.16, t + 0.14), Vector3(cx, h * fy, 0.0), metal)
	# macaneta na borda livre
	_add_mesh_box(pivot, Vector3(0.14, 0.14, t + 0.3),
			Vector3(cx + dir * (leaf_w * 0.5 - 0.2), h * 0.48, 0.0), metal)


func _build_bars_leaf(pivot: Node3D, leaf_w: float, h: float, master: bool, metal: Material) -> void:
	var bar_w := 0.12 if master else 0.09
	var nb := maxi(3, int(leaf_w / 0.28))
	for k in nb:
		var x := -leaf_w * 0.5 + leaf_w * (k + 0.5) / nb
		_add_mesh_box(pivot, Vector3(bar_w, h, bar_w), Vector3(x, h * 0.5, 0.0), metal)
	for fy in [0.2, 0.8]:
		_add_mesh_box(pivot, Vector3(leaf_w, 0.14, 0.12), Vector3(0.0, h * fy, 0.0), metal)


func _add_mesh_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)


func _add_shape_box(body: StaticBody3D, size: Vector3, pos: Vector3) -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	body.add_child(cs)


# ------------------------------------------------------------ interacao

func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or _opened or _opening:
		return
	if not event.is_action_pressed("interact"):
		return
	var player := _find_player_in_zone()
	if player == null:
		return
	get_viewport().set_input_as_handled()
	if Global.has_key(key_type):
		_swing = 1.0 if to_local(player.global_position).z >= 0.0 else -1.0
		_open()
	else:
		_locked()


func _find_player_in_zone() -> Node3D:
	if _zone == null:
		return null
	for b in _zone.get_overlapping_bodies():
		if b.is_in_group("Player"):
			return b as Node3D
	return null


func _locked() -> void:
	var sfx := get_node_or_null("LockedSfx") as AudioStreamPlayer3D
	if sfx != null and not sfx.playing:
		sfx.play()
	Global.show_message("Precisa da " + GameKeys.nome_chave(key_type))


func _open() -> void:
	_opening = true
	Global.mark_gate_opened(_gate_id)
	var sfx := get_node_or_null("OpenSfx") as AudioStreamPlayer3D
	if sfx != null:
		sfx.play()
	var tw := create_tween()
	tw.tween_method(_aplicar_progresso, 0.0, 1.0, OPEN_TIME) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(_on_aberto)


func _on_aberto() -> void:
	_desativar_colisao()
	_opened = true
	_opening = false


# p = 0 (fechado) .. 1 (aberto)
func _aplicar_progresso(p: float) -> void:
	for i in _pivots.size():
		if style == Style.DOOR:
			_pivots[i].rotation.y = _dirs[i] * _swing * deg_to_rad(90.0) * p
		else:
			_pivots[i].position.y = _h() * p


func _desativar_colisao() -> void:
	for body in _bodies:
		for c in body.get_children():
			if c is CollisionShape3D:
				c.set_deferred("disabled", true)
