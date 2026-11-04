extends Character

const MOUSE_SENS = 0.5
const WALK_SPEED = 10
const RUN_SPEED = 15

@onready var spot_light_3d: SpotLight3D = $Camera/SpotLight3D



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	await get_tree().process_frame
	get_tree().call_group("zombies", "set_player", self)
	if Global.hasLoadedGame:
		global_position = Global.playerPosition
		Global.hasLoadedGame = false
	else:
		Global.life = Global.initialLife
		Global.ammo = Global.initialAmmo

func _input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= MOUSE_SENS * event.relative.x

func _process(_delta):
	if Input.is_action_pressed("exit"):
		get_tree().quit()
	if Input.is_action_pressed("restart"):
		kill()
	if Input.is_action_just_pressed("flashlight"):
		spot_light_3d.visible = !spot_light_3d.visible

func _physics_process(delta):
	_move(delta)
	_handle_shooting()

func _move(delta):
	var input = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var move_vec = Vector3(input.x, 0, input.y)
	move_vec = move_vec.rotated(Vector3.UP, rotation.y)
	move_in_direction(move_vec, _current_speed(), delta)

func _current_speed():
	if Input.is_action_pressed("run"):
		return RUN_SPEED
	return WALK_SPEED

func _can_shoot():
	return Input.is_action_pressed("shoot") and !anim_player.is_playing() and Global.ammo > 0

func _handle_shooting():
	if not _can_shoot():
		return
	Global.ammo -= 1
	anim_player.play("shoot")
	if not raycast.is_colliding():
		return
	var coll = raycast.get_collider()
	if coll.has_method("kill"):
		coll.kill()

func kill():
	if Global.life < 1:
		get_tree().reload_current_scene()
	else:
		Global.life -= 2
