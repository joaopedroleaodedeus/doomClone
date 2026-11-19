extends CanvasLayer
# Menu de pausa. process_mode = ALWAYS (definido na cena), entao continua recebendo input
# com a arvore pausada. ESC (acao "exit") alterna a pausa.

const MAIN_MENU_PATH := "res://scenes/MainMenu.tscn"

@onready var resume_button: Button = $Root/Center/VBox/ResumeButton
@onready var menu_button: Button = $Root/Center/VBox/MenuButton
@onready var quit_button: Button = $Root/Center/VBox/QuitButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	resume_button.pressed.connect(_resume)
	menu_button.pressed.connect(_on_menu_pressed)
	quit_button.pressed.connect(_on_quit_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("exit"):
		get_viewport().set_input_as_handled()
		if get_tree().paused:
			_resume()
		else:
			_pause()


func _pause() -> void:
	get_tree().paused = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	Music.set_dimmed(true)
	resume_button.grab_focus()


func _resume() -> void:
	get_tree().paused = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	Music.set_dimmed(false)


func _on_menu_pressed() -> void:
	get_tree().paused = false
	Music.set_dimmed(false)
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func _on_quit_pressed() -> void:
	get_tree().quit()
