extends Character

const MOVE_SPEED = 3
const ATTACK_RANGE = 1.5


var lifeHit: int = 3
var player = null
var dead = false
var myName: String


func _ready():
	anim_player.play("walk")
	add_to_group("zombies")
	myName = get_tree().current_scene.name + "-" + name
	if Global.is_enemy_dead(myName): queue_free()

func _physics_process(delta):
	if dead:
		return
	if player == null:
		return

	var vec_to_player = player.position - position
	vec_to_player = vec_to_player.normalized()
	raycast.target_position = vec_to_player * ATTACK_RANGE

	move_in_direction(vec_to_player, MOVE_SPEED, delta)

	if raycast.is_colliding():
		var coll = raycast.get_collider()
		if coll != null and coll.name == "Player":
			coll.kill()

func kill():
	if lifeHit > 1:
		lifeHit -= 1
	else: 
		dead = true
		$CollisionShape.set_deferred("disabled", true)
		anim_player.play("die")
		Global.mark_enemy_dead(myName)

func set_player(p):
	player = p
