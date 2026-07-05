extends Node

## Guardado manual (botón en el celular) + autoguardado periódico (Milestone 3).
## El trigger real de autoguardado ("dormir") queda pendiente hasta que exista
## el ciclo día/noche — este timer es un placeholder mientras tanto.

const SAVE_PATH := "user://savegame.json"
const AUTOSAVE_INTERVAL := 300.0

func _ready() -> void:
	var timer := Timer.new()
	timer.wait_time = AUTOSAVE_INTERVAL
	timer.autostart = true
	timer.timeout.connect(save_game)
	add_child(timer)

func save_game() -> void:
	var build_system: Node = get_tree().get_first_node_in_group("build_system")
	var world: Node = get_tree().current_scene
	var data := {
		"money": Economy.money,
		"purchased_items": Economy.purchased_items,
		"pieces": build_system.serialize_pieces() if build_system else [],
		"crops": world.serialize_crops() if world and world.has_method("serialize_crops") else [],
		"inventory": Inventory.get_save_data(),
		"player_needs": PlayerNeeds.get_save_data(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("[save] no se pudo abrir %s para escribir (error=%d) — la partida NO se guardó" % [SAVE_PATH, FileAccess.get_open_error()])
		return
	file.store_string(JSON.stringify(data))
	_print_save_summary(data)

## Lista en detalle qué se guardó, desglosando "pieces" por categoría —
## para poder ver de un vistazo si algo colocado en el mundo no llegó a
## contarse (ej. el bug de los pisos que no se guardaban).
func _print_save_summary(data: Dictionary) -> void:
	var pieces: Array = data["pieces"]
	var by_category: Dictionary = {}
	for entry in pieces:
		var category: String = entry.get("category", "?")
		by_category[category] = by_category.get(category, 0) + 1

	print("[save] ---- partida guardada ----")
	print("[save] money=%d" % data["money"])
	print("[save] purchased_items=%s" % [data["purchased_items"].keys()])
	print("[save] inventory items=%s selected_slot=%s" % [data["inventory"]["items"], data["inventory"]["selected_slot"]])
	print("[save] player_needs=%s" % [data["player_needs"]])
	print("[save] crops guardados=%d" % data["crops"].size())
	print("[save] pieces guardadas=%d -> %s" % [pieces.size(), by_category])
	print("[save] ------------------------------")

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return

	Economy.money = data.get("money", 0)
	Economy.purchased_items = data.get("purchased_items", {})
	Economy.money_changed.emit(Economy.money)
	# el "if data.has(...)" es para no pisar el inventario default (con la
	# semilla inicial) si el archivo de guardado es viejo y todavía no tiene
	# esta clave — si la tiene, se restaura tal cual (aunque esté vacía).
	if data.has("inventory"):
		Inventory.apply_save_data(data["inventory"])
	if data.has("player_needs"):
		PlayerNeeds.apply_save_data(data["player_needs"])

	var build_system: Node = get_tree().get_first_node_in_group("build_system")
	if build_system:
		build_system.clear_pieces()
		build_system.load_pieces(data.get("pieces", []))

	var world: Node = get_tree().current_scene
	if world and world.has_method("load_crops"):
		world.load_crops(data.get("crops", []))
