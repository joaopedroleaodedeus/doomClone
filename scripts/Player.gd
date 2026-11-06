extends Character

const MOUSE_SENS = 0.5
const WALK_SPEED = 10
const RUN_SPEED = 15
const STEP_DISTANCE = 3.5  # distancia andada entre dois passos
const STEP_SOUNDS = [preload("res://audio/step_1.wav"), preload("res://audio/step_2.wav")]
const DEATH_SFX = preload("res://audio/player_death.wav")

@onready var spot_light_3d: SpotLight3D = $Camera/SpotLight3D
@onready var shoot_sfx: AudioStreamPlayer = $ShootSfx
@onready var empty_sfx: AudioStreamPlayer = $EmptySfx
@onready var hurt_sfx: AudioStreamPlayer = $HurtSfx
@onready var step_sfx: AudioStreamPlayer = $StepSfx

var _step_progress := STEP_DISTANCE
var _last_position := Vector3.ZERO



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if Global.hasLoadedGame:
		global_position = Global.playerPosition
		Global.hasLoadedGame = false
	else:
		Global.life = Global.initialLife
		Global.ammo = Global.initialAmmo
	_last_position = global_position

func _input(event):
	if event is InputEventMouseMotion:
		rotation_degrees.y -= MOUSE_SENS * event.relative.x

func _process(_delta):
	_handle_saving()
	if Input.is_action_pressed("exit"):
		get_tree().quit()
	if Input.is_action_pressed("restart"):
		get_tree().reload_current_scene()
	if Input.is_action_just_pressed("flashlight"):
		spot_light_3d.visible = !spot_light_3d.visible

func _physics_process(delta):
	_move(delta)
	_handle_footsteps()
	_handle_shooting()

func _handle_saving():
	if Input.is_action_just_pressed("gravar"):
		SaveSystem.savegame()
	if Input.is_action_just_pressed("carregar"):
		SaveSystem.loadGame()

func _move(delta):
	var input = Input.get_vector("move_left", "move_right", "move_forwards", "move_backwards")
	var move_vec = Vector3(input.x, 0, input.y)
	move_vec = move_vec.rotated(Vector3.UP, rotation.y)
	move_in_direction(move_vec, _current_speed(), delta)

func _current_speed():
	if Input.is_action_pressed("run"):
		return RUN_SPEED
	return WALK_SPEED

func _handle_footsteps():
	var moved = Vector2(global_position.x - _last_position.x, global_position.z - _last_position.z).length()
	_last_position = global_position
	if moved < 0.01:
		_step_progress = STEP_DISTANCE  # parado ou bloqueado: o proximo passo toca assim que andar
		return
	_step_progress += moved
	if _step_progress < STEP_DISTANCE:
		return
	_step_progress = 0.0
	step_sfx.stream = STEP_SOUNDS.pick_random()
	step_sfx.pitch_scale = randf_range(0.9, 1.1)
	step_sfx.play()

func _can_shoot():
	return Input.is_action_pressed("shoot") and !anim_player.is_playing() and Global.ammo > 0

func _handle_shooting():
	if Input.is_action_just_pressed("shoot") and Global.ammo <= 0:
		empty_sfx.play()
		return
	if not _can_shoot():
		return
	Global.ammo -= 1
	shoot_sfx.play()
	anim_player.play("shoot")
	if not raycast.is_colliding():
		return
	var coll = raycast.get_collider()
	if coll.has_method("kill"):
		coll.kill()

func kill():
	if Global.life < 1:
		_play_death_sfx()
		get_tree().reload_current_scene()
	else:
		Global.life -= 2
		if not hurt_sfx.playing:
			hurt_sfx.play()

func _play_death_sfx():
	# toca num no fora do Player, que e destruido no reload da cena
	var sfx := AudioStreamPlayer.new()
	sfx.stream = DEATH_SFX
	get_tree().root.add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()
