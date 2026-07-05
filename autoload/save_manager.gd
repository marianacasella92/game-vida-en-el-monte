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
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))

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

	var build_system: Node = get_tree().get_first_node_in_group("build_system")
	if build_system:
		build_system.clear_pieces()
		build_system.load_pieces(data.get("pieces", []))

	var world: Node = get_tree().current_scene
	if world and world.has_method("load_crops"):
		world.load_crops(data.get("crops", []))
