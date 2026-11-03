class_name Character
extends CharacterBody3D

@onready var anim_player: AnimationPlayer = $AnimationPlayer
@onready var raycast: RayCast3D = $RayCast


func move_in_direction(direction: Vector3, speed: float, delta: float) -> void:
	move_and_collide(direction * speed * delta)
