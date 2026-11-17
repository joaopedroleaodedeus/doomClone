extends Control

const MESSAGE_TIME := 2.0

@onready var ammo_label: Label = $VBoxContainer/AmmoLabel
@onready var life_label: Label = $VBoxContainer/LifeLabel
@onready var key_simple_icon: TextureRect = $KeysBox/KeySimpleIcon
@onready var key_master_icon: TextureRect = $KeysBox/KeyMasterIcon
@onready var message_label: Label = $MessageLabel
@onready var message_timer: Timer = $MessageTimer


func _ready() -> void:
	message_label.visible = false
	message_timer.one_shot = true
	message_timer.timeout.connect(_on_message_timer_timeout)
	Global.hud_message.connect(_on_hud_message)


func _process(delta: float) -> void:
	life_label.text = "Vida: " + str(Global.life)
	ammo_label.text = "Munição: " + str(Global.ammo)
	# chaves distinguidas pela forma do icone (a tela e em tons de cinza)
	key_simple_icon.visible = Global.has_key(GameKeys.KeyType.SIMPLE)
	key_master_icon.visible = Global.has_key(GameKeys.KeyType.MASTER)


func _on_hud_message(text: String) -> void:
	message_label.text = text
	message_label.visible = true
	message_timer.start(MESSAGE_TIME)


func _on_message_timer_timeout() -> void:
	message_label.visible = false
