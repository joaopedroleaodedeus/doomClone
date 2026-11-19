extends Control
# Menu inicial: Novo Jogo / Continuar / Sair.

const LEVEL_PATH := "res://scenes/fase_01.tscn"
const MENU_MUSIC = preload("res://audio/music_menu.wav")

@onready var new_game_button: Button = $Center/VBox/NewGameButton
@onready var continue_button: Button = $Center/VBox/ContinueButton
@onready var quit_button: Button = $Center/VBox/QuitButton


func _ready() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Music.play_track(MENU_MUSIC)

	# "Continuar" so aparece se existe um save
	continue_button.visible = SaveSystem.has_save()

	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# foco no primeiro botao (teclado / controle)
	new_game_button.grab_focus()


func _on_new_game_pressed() -> void:
	Global.reset_all()
	get_tree().change_scene_to_file(LEVEL_PATH)


func _on_continue_pressed() -> void:
	if SaveSystem.read_save():
		get_tree().change_scene_to_file(LEVEL_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
