extends CharacterBody3D

const MOVE_SPEED = 3
const ATTACK_RANGE = 1.5 # Replace Magic Number with Symbolic Constant

@onready var raycast = $RayCast
@onready var anim_player = $AnimationPlayer


var lifeHit: int = 3
var player = null
var dead = false
var myName: String


func _ready():
	anim_player.play("walk")
	add_to_group("zombies")
	myName = get_tree().current_scene.name + "-" + name
	if Global.enemyDeadDict.has(myName): queue_free()

func _physics_process(delta):
	if dead:
		return
	if player == null:
		return

	var vec_to_player = player.position - position
	vec_to_player = vec_to_player.normalized()
	raycast.target_position = vec_to_player * ATTACK_RANGE # Replace Magic Number with Symbolic Constant

	move_and_collide(vec_to_player * MOVE_SPEED * delta)

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
		Global.enemyDeadDict[myName] = true

func set_player(p):
	player = p
