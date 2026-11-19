extends Node3D
# Ponto de salvamento: pedestal de pedra com um cristal flutuante.
# O jogador perto do pedestal aperta E ("interact") para gravar o jogo.
# Usado por SavePoint.tscn. A origem do noh fica no chao, no centro do pedestal.

const BOB_HEIGHT := 0.12
const BOB_SPEED := 1.8
const SPIN_SPEED := 0.9  # radianos por segundo
const SAVE_COOLDOWN := 1.0  # evita salvar varias vezes seguidas
const LIGHT_FLASH_ENERGY := 4.0

@onready var _crystal: Node3D = $Crystal
@onready var _light: OmniLight3D = $CrystalLight
@onready var _zone: Area3D = $InteractionZone
@onready var _sfx: AudioStreamPlayer3D = $SaveSfx

var _crystal_base_y := 0.0
var _light_base_y := 0.0
var _light_base_energy := 1.0
var _time := 0.0
var _cooldown := 0.0


func _ready() -> void:
	_crystal_base_y = _crystal.position.y
	_light_base_y = _light.position.y
	_light_base_energy = _light.light_energy
	_zone.body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	_cooldown = maxf(_cooldown - delta, 0.0)
	var bob := sin(_time * BOB_SPEED) * BOB_HEIGHT
	_crystal.position.y = _crystal_base_y + bob
	_light.position.y = _light_base_y + bob
	_crystal.rotate_y(SPIN_SPEED * delta)


# Dica "[E] Salvar" uma vez a cada vez que o jogador entra na zona
func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		Global.show_message("[E] Salvar")


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	if not _player_in_zone():
		return
	get_viewport().set_input_as_handled()
	if _cooldown > 0.0:
		return
	_cooldown = SAVE_COOLDOWN
	if SaveSystem.savegame():
		_sfx.play()
		_flash()
		Global.show_message("Jogo salvo")
	else:
		Global.show_message("Falha ao salvar")


func _player_in_zone() -> bool:
	for b in _zone.get_overlapping_bodies():
		if b.is_in_group("Player"):
			return true
	return false


# Pulso rapido de luz ao salvar
func _flash() -> void:
	_light.light_energy = LIGHT_FLASH_ENERGY
	var tw := create_tween()
	tw.tween_property(_light, "light_energy", _light_base_energy, 0.6) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
