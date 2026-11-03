
extends Node # Global

const initialLife = 100
const initialAmmo = 20

var life: int = initialLife
var ammo: int = initialAmmo

var enemyDeadDict: Dictionary = {}

var playerPosition: Vector3 = Vector3.ZERO
var hasLoadedGame: bool = false


func is_enemy_dead(enemy_id: String) -> bool:
	return enemyDeadDict.has(enemy_id)


func mark_enemy_dead(enemy_id: String) -> void:
	enemyDeadDict[enemy_id] = true


func get_dead_enemies() -> Dictionary:
	return enemyDeadDict.duplicate()


func set_dead_enemies(data: Dictionary) -> void:
	enemyDeadDict = data.duplicate()
