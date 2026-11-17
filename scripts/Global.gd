
extends Node # Global

const initialLife = 100
const initialAmmo = 20

var life: int = initialLife
var ammo: int = initialAmmo

var enemyDeadDict: Dictionary = {}
var collectedPickups: Dictionary = {}

# Chaves: GameKeys.KeyType -> true. Portoes abertos / chaves coletadas: id -> true.
var keys: Dictionary = {}
var openedGates: Dictionary = {}
var collectedKeyPickups: Dictionary = {}

# Mensagem curta para o HUD
signal hud_message(text: String)

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


func is_pickup_collected(pickup_id: String) -> bool:
	return collectedPickups.has(pickup_id)


func mark_pickup_collected(pickup_id: String) -> void:
	collectedPickups[pickup_id] = true


func get_collected_pickups() -> Dictionary:
	return collectedPickups.duplicate()


func set_collected_pickups(data: Dictionary) -> void:
	collectedPickups = data.duplicate()


func has_key(key_type: GameKeys.KeyType) -> bool:
	return keys.has(int(key_type))


func give_key(key_type: GameKeys.KeyType) -> void:
	keys[int(key_type)] = true


# Salva como lista de inteiros (chaves de dicionario viram string no JSON)
func get_keys() -> Array:
	return keys.keys()


func set_keys(data: Array) -> void:
	keys.clear()
	for v in data:
		var k := int(v)
		if GameKeys.KeyType.values().has(k):
			keys[k] = true


func is_gate_opened(gate_id: String) -> bool:
	return openedGates.has(gate_id)


func mark_gate_opened(gate_id: String) -> void:
	openedGates[gate_id] = true


func get_opened_gates() -> Dictionary:
	return openedGates.duplicate()


func set_opened_gates(data: Dictionary) -> void:
	openedGates = data.duplicate()


func is_key_pickup_collected(pickup_id: String) -> bool:
	return collectedKeyPickups.has(pickup_id)


func mark_key_pickup_collected(pickup_id: String) -> void:
	collectedKeyPickups[pickup_id] = true


func get_collected_key_pickups() -> Dictionary:
	return collectedKeyPickups.duplicate()


func set_collected_key_pickups(data: Dictionary) -> void:
	collectedKeyPickups = data.duplicate()


# Usado em novo jogo / restart / morte
func reset_keys_and_gates() -> void:
	keys.clear()
	openedGates.clear()
	collectedKeyPickups.clear()


func show_message(text: String) -> void:
	hud_message.emit(text)
