extends Node # Music
# Autoload de musica de fundo. Um unico AudioStreamPlayer criado por codigo, que continua
# tocando entre trocas de cena e durante a pausa (process_mode = ALWAYS).

const NORMAL_VOLUME_DB := -8.0
const PAUSED_VOLUME_DB := -16.0  # volume abafado enquanto o jogo esta pausado

var _player: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_player = AudioStreamPlayer.new()
	_player.name = "MusicPlayer"
	_player.volume_db = NORMAL_VOLUME_DB
	add_child(_player)
	# Loop: os .wav nao tem ponto de loop configurado no import, entao recomeca ao terminar.
	_player.finished.connect(_on_finished)


# Toca a faixa em loop. Se essa mesma faixa ja esta tocando, nao reinicia.
func play_track(stream: AudioStream) -> void:
	if stream == null:
		return
	if _player.stream == stream and _player.playing:
		return
	_player.stream = stream
	_player.play()


func stop() -> void:
	_player.stop()


# Abaixa (true) ou restaura (false) o volume; usado pelo menu de pausa.
func set_dimmed(dimmed: bool) -> void:
	_player.volume_db = PAUSED_VOLUME_DB if dimmed else NORMAL_VOLUME_DB


func _on_finished() -> void:
	_player.play()
