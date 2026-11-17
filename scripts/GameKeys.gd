class_name GameKeys
extends RefCounted
# Definicoes compartilhadas das chaves. Fica separado do Global (autoload)
# porque enums de autoload nao funcionam de forma confiavel em @export / @tool.

enum KeyType { SIMPLE, MASTER }


# Nome legivel (pt-BR) para mensagens do HUD.
static func nome_chave(tipo: KeyType) -> String:
	match tipo:
		KeyType.MASTER:
			return "chave mestra"
		_:
			return "chave simples"
