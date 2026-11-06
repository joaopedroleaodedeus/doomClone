extends Area3D
# Coletavel de municao ou vida. Usado por AmmoPickup.tscn e HealthPickup.tscn.

enum Kind { AMMO, HEALTH }

const AMMO_AMOUNT := 10
const HEALTH_AMOUNT := 25
const BOB_HEIGHT := 0.15
const BOB_SPEED := 3.0

@export var kind: Kind = Kind.AMMO

@onready var sprite: Sprite3D = $Sprite3D
@onready var sfx: AudioStreamPlayer3D = $PickupSfx

var pickupId: String
var _base_y: float
var _time := 0.0


func _ready():
	pickupId = get_tree().current_scene.name + "-" + name
	if Global.is_pickup_collected(pickupId):
		queue_free()
		return
	_base_y = sprite.position.y


func _process(delta):
	_time += delta
	sprite.position.y = _base_y + sin(_time * BOB_SPEED) * BOB_HEIGHT


func _physics_process(_delta):
	for body in get_overlapping_bodies():
		if body.is_in_group("Player") and _apply():
			_consume()
			return


# Aplica o efeito no jogador. Retorna false se nao fez nada (vida ja cheia).
func _apply() -> bool:
	match kind:
		Kind.AMMO:
			Global.ammo += AMMO_AMOUNT
		Kind.HEALTH:
			if Global.life >= Global.initialLife:
				return false
			Global.life = mini(Global.life + HEALTH_AMOUNT, Global.initialLife)
	return true


func _consume():
	Global.mark_pickup_collected(pickupId)
	set_process(false)
	set_physics_process(false)
	sprite.visible = false
	$CollisionShape.set_deferred("disabled", true)
	sfx.play()
	await sfx.finished
	queue_free()
