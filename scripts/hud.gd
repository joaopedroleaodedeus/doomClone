extends Control

@onready var ammo_label: Label = $VBoxContainer/AmmoLabel
@onready var life_label: Label = $VBoxContainer/LifeLabel


func _process(delta: float) -> void:
	life_label.text = "Vida: " + str(Global.life)
	ammo_label.text = "Munição: " + str(Global.ammo)
