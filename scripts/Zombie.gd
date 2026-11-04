extends Character

const MOVE_SPEED = 3
const ATTACK_RANGE = 1.5


var lifeHit: int = 3
var player = null
var myName: String


func _ready():
	anim_player.play("walk")
	add_to_group("zombies")
	myName = get_tree().current_scene.name + "-" + name
	if Global.is_enemy_dead(myName): queue_free()
	player = get_tree().get_first_node_in_group("Player")
	assert(player != null, "Zombie: nenhum nó no grupo 'Player' foi encontrado na cena.")

func _physics_process(delta):
	var vec_to_player = player.position - position
	var direction = vec_to_player.normalized()
	raycast.target_position = direction * ATTACK_RANGE

	move_in_direction(direction, MOVE_SPEED, delta)

	if raycast.is_colliding() and raycast.get_collider() == player:
		player.kill()

func kill():
	if lifeHit > 1:
		lifeHit -= 1
	else: 
		set_physics_process(false)
		$CollisionShape.set_deferred("disabled", true)
		anim_player.play("die")
		Global.mark_enemy_dead(myName)
