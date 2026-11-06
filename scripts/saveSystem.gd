
extends Node # SaveSystem

const SAVE_DIR = "DoomClone"
const SAVE_FILE = "savegame.txt"

var savePath: String


func _ready():
	var documentsPath = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	savePath = documentsPath.path_join(SAVE_DIR).path_join(SAVE_FILE)


func savegame():
	var player = get_tree().get_first_node_in_group("Player")

	if player == null:
		push_error("SaveSystem: Jogador não encontrado no grupo Player.")
		return

	# Cria o diretório caso não exista
	var directory = savePath.get_base_dir()
	var error = DirAccess.make_dir_recursive_absolute(directory)

	if error != OK and error != ERR_ALREADY_EXISTS:
		push_error("SaveSystem: Não foi possível criar o diretório.")
		return

	# Atualiza a posição no Global
	Global.playerPosition = player.global_position

	# Organiza os dados
	var saveData = {
		"life": Global.life,
		"ammo": Global.ammo,
		"enemyDeadDict": Global.get_dead_enemies(),
		"collectedPickups": Global.get_collected_pickups(),
		"playerPosition": _vector3_to_array(Global.playerPosition)
	}

	# Abre o arquivo em modo de escrita (sobrescreve)
	var file = FileAccess.open(savePath, FileAccess.WRITE)

	if file == null:
		push_error("SaveSystem: Erro ao abrir arquivo para escrita.")
		return

	file.store_string(JSON.stringify(saveData, "\t"))
	file.close()

	print("Save realizado com sucesso!")


func loadGame():
	# Verifica se o arquivo existe
	if not FileAccess.file_exists(savePath):
		push_error("SaveSystem: Nenhum arquivo de save encontrado.")
		return

	var file = FileAccess.open(savePath, FileAccess.READ)

	if file == null:
		push_error("SaveSystem: Erro ao abrir arquivo para leitura.")
		return

	var content = file.get_as_text()
	file.close()

	# Converte o JSON
	var json = JSON.new()
	var error = json.parse(content)

	if error != OK:
		push_error("SaveSystem: Arquivo de save inválido.")
		return

	var saveData = json.data

	if typeof(saveData) != TYPE_DICTIONARY:
		push_error("SaveSystem: Estrutura de save inválida.")
		return

	# Recupera os dados no Global
	Global.life = int(saveData.get("life", Global.initialLife))
	Global.ammo = int(saveData.get("ammo", Global.initialAmmo))
	Global.set_dead_enemies(saveData.get("enemyDeadDict", {}))
	Global.set_collected_pickups(saveData.get("collectedPickups", {}))

	# Recupera a posição do jogador
	var positionData = saveData.get("playerPosition", [])

	if typeof(positionData) != TYPE_ARRAY or positionData.size() != 3:
		push_error("SaveSystem: Posição do jogador inválida.")
		return

	Global.playerPosition = _array_to_vector3(positionData)

	Global.hasLoadedGame = true

	print("Save carregado com sucesso!")

	# Reinicia a cena atual
	get_tree().reload_current_scene()


func _vector3_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


func _array_to_vector3(values: Array) -> Vector3:
	return Vector3(
		float(values[0]),
		float(values[1]),
		float(values[2])
	)
