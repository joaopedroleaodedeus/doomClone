extends CharacterBody3D

const MOUSE_SENS = 0.5
const WALK_SPEED = 10 # Replace Magic Number with Symbolic Constant
const RUN_SPEED = 15

@onready var anim_player = $AnimationPlayer
@onready var raycast = $RayCast

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
	if Input.is_action_just_pressed("carregar"):
		SaveSystem.loadGame()
	if Input.is_action_just_pressed("gravar"):
		SaveSystem.savegame()
	if Input.is_action_pressed("exit"):
		get_tree().quit()
	if Input.is_action_pressed("restart"):
		kill()
	if Input.is_action_just_pressed("flashlight"):
		spot_light_3d.visible = !spot_light_3d.visible

func _physics_process(delta): # _physics_process(delta) alterado para que mantenha apenas as funções separadas (Extract Method)
	_move(delta)
	_handle_shooting()

func _move(delta): # antes se encontrava no _physics_process(delta), mas agora é uma função propria que cuida do movimento(Extract Method)
	var input = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards") # código alterado para um mais eficiente Substitute Algorithm
	var move_vec = Vector3(input.x, 0, input.y)
	move_vec = move_vec.rotated(Vector3.UP, rotation.y) # Replace Magic Number with Symbolic Constant 
	move_and_collide(move_vec * _current_speed() * delta) #current speed virou uma função propria

func _current_speed():
	if Input.is_action_pressed("run"): #  antes era codigo dentro do _physics_process, agora ele foi adicionado em uma função propria via consulta (Replace Temp with Query)
		return RUN_SPEED
	return WALK_SPEED

func _handle_shooting():# antes se encontrava no _physics_process(delta), mas agora é uma função propria que cuida do disparo da arma (Extract Method)
	if Input.is_action_pressed("shoot") and !anim_player.is_playing() and Global.ammo > 0:
		Global.ammo -= 1
		anim_player.play("shoot")
		var coll = raycast.get_collider()
		if raycast.is_colliding() and coll.has_method("kill"):
			coll.kill()

func kill():
	if Global.life < 1:
		get_tree().reload_current_scene()
	else:
		Global.life -= 2
