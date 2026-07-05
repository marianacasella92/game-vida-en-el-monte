extends Node

signal inventory_changed()

const SLOT_COUNT: int = 9
const TOOL_SLOTS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]

var items: Dictionary = {}
var selected_slot: int = 0

func _ready() -> void:
	reset()

## Vuelve al inventario inicial de partida nueva. Usado por _ready() y por
## SaveManager.reset_game().
func reset() -> void:
	items = {
		0: {"id": "seed", "name": "Semilla", "stack": 1},
	}
	selected_slot = 0
	inventory_changed.emit()

func add_item(item_id: String, item_name: String, stack: int = 1) -> void:
	for slot in range(SLOT_COUNT):
		if items.has(slot) and items[slot].get("id", "") == item_id:
			items[slot]["stack"] += stack
			inventory_changed.emit()
			return
	if items.size() < SLOT_COUNT:
		for slot in range(SLOT_COUNT):
			if not items.has(slot):
				items[slot] = {"id": item_id, "name": item_name, "stack": stack}
				inventory_changed.emit()
				return

func remove_item(slot: int, amount: int = 1) -> void:
	if not items.has(slot):
		return
	items[slot]["stack"] -= amount
	if items[slot]["stack"] <= 0:
		items.erase(slot)
	inventory_changed.emit()

func select_slot(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	selected_slot = slot
	inventory_changed.emit()

func deselect() -> void:
	selected_slot = -1
	inventory_changed.emit()

func get_selected_item() -> Dictionary:
	if selected_slot >= 0 and items.has(selected_slot):
		return items[selected_slot]
	return {}

func has_item(item_id: String) -> bool:
	for slot in items.values():
		if slot.get("id", "") == item_id:
			return true
	return false

func get_save_data() -> Dictionary:
	return {"items": items, "selected_slot": selected_slot}

## JSON.stringify() convierte las claves de Dictionary a string siempre — al
## guardar, los slots (int) del inventario se vuelven "0", "1", etc. en el
## archivo. Al restaurar hay que reconstruirlos como int, si no items.has(0)
## (con selected_slot int) deja de encontrar nada guardado.
func apply_save_data(data: Dictionary) -> void:
	var raw_items: Dictionary = data.get("items", {})
	items = {}
	for key in raw_items:
		items[int(key)] = raw_items[key]
	selected_slot = data.get("selected_slot", 0)
	inventory_changed.emit()
