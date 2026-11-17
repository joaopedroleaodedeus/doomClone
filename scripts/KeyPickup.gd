@tool
extends Area3D
# Chave coletavel (simples ou mestra). Usado por KeyPickup.tscn.
# @tool: o sprite troca no editor quando key_type muda.

const BOB_HEIGHT := 0.15
const BOB_SPEED := 3.0
const TEXTURES = [
	preload("res://image/key_simple.png"),
	preload("res://image/key_master.png"),
]

@export var key_type: GameKeys.KeyType = GameKeys.KeyType.SIMPLE:
	set(value):
		key_type = value
		_atualizar_sprite()

var pickupId: String
var _base_y := 0.0
var _time := 0.0
var _sprite: Sprite3D
var _sfx: AudioStreamPlayer3D


func _ready() -> void:
	_sprite = get_node_or_null("Sprite3D") as Sprite3D
	_sfx = get_node_or_null("PickupSfx") as AudioStreamPlayer3D
	_atualizar_sprite()
	if Engine.is_editor_hint():
		return
	pickupId = get_tree().current_scene.name + "-" + name
	if Global.is_key_pickup_collected(pickupId):
		queue_free()
		return
	_base_y = _sprite.position.y


func _atualizar_sprite() -> void:
	# o setter pode rodar antes de o no estar pronto, entao busca pelo caminho
	var s := get_node_or_null("Sprite3D") as Sprite3D
	if s != null:
		s.texture = TEXTURES[key_type]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_time += delta
	_sprite.position.y = _base_y + sin(_time * BOB_SPEED) * BOB_HEIGHT


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for body in get_overlapping_bodies():
		if body.is_in_group("Player"):
			_consume()
			return


func _consume() -> void:
	Global.give_key(key_type)
	Global.mark_key_pickup_collected(pickupId)
	Global.show_message("Pegou a " + GameKeys.nome_chave(key_type))
	set_process(false)
	set_physics_process(false)
	_sprite.visible = false
	$CollisionShape.set_deferred("disabled", true)
	_sfx.play()
	await _sfx.finished
	queue_free()
